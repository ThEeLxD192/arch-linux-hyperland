#!/bin/bash

AWK_COMMAND=$'
BEGIN {
    in_streams = 0;
    in_sinks = 0;
    in_sources = 0;
    in_audio = 0; 
    
    default_sink_id = 0;
    default_sink_volume = "0.00";
    default_sink_name = "Default Output";
    default_sink_muted = "false"; # <-- NUEVO
    
    default_source_id = 0;
    default_source_volume = "0.00";
    default_source_name = "Default Input";
    default_source_muted = "false"; # <-- NUEVO
}

# --- SECCIÓN DE DETECCIÓN ---

/^Audio/ { in_audio = 1; } 
/^Video/ { in_audio = 0; } 

/Sinks:/ {
    in_sinks = 1;
    in_sources = 0;
    in_streams = 0;
    next;
}

/Sources:/ {
    in_sinks = 0;
    in_sources = 1;
    in_streams = 0;
    next;
}

/Streams:/ {
    in_sinks = 0;
    in_sources = 0;
    in_streams = 1;
    next;
}

# --- LÓGICA DE SINKS Y SOURCES ---

in_sinks && match($0, /[[:space:]│]*\\* *([0-9]+)\\. (.*) \\[[^]]+\\]$/, a) {
    default_sink_id = a[1];
    default_sink_name = a[2];
    
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", default_sink_name);
    gsub(/\\\\/, "\\\\\\\\", default_sink_name); 
    gsub(/"/, "\\\"", default_sink_name); 

    default_sink_muted = "false"; # <-- REINICIAR
    volume_cmd = "wpctl get-volume " default_sink_id;
    
    if ((volume_cmd | getline vol_line) > 0) {
        if (vol_line ~ /MUTED/) { # <-- CHECK MUTED
            default_sink_muted = "true";
        }
        sub(/Volume: /, "", vol_line);
        vol_percent = vol_line * 100;
        if (vol_percent >= 99 && vol_percent < 100) {
            vol_percent = 100;
        }
        default_sink_volume = sprintf("%.0f", vol_percent);
    } else {
        default_sink_volume = "0.00";
        default_sink_muted = "true"; # <-- Asumir mute si hay error
    }
    close(volume_cmd);
}

in_sources && match($0, /[[:space:]│]*\\* *([0-9]+)\\. (.*) \\[[^]]+\\]$/, a) {
    default_source_id = a[1];
    default_source_name = a[2];

    gsub(/^[[:space:]]+|[[:space:]]+$/, "", default_source_name);
    gsub(/\\\\/, "\\\\\\\\", default_source_name);
    gsub(/"/, "\\\"", default_source_name);

    default_source_muted = "false"; # <-- REINICIAR
    volume_cmd = "wpctl get-volume " default_source_id;
    
    if ((volume_cmd | getline vol_line) > 0) {
        sub(/Volume: /, "", vol_line);
        if (vol_line ~ /MUTED/) {
            default_source_muted = "true"; # <-- CHECK MUTED
            default_source_volume = "0";
        } else {
            vol_percent = vol_line * 100;
            if (vol_percent >= 99 && vol_percent < 100) {
                vol_percent = 100;
            }
            default_source_volume = sprintf("%.0f", vol_percent);
        }
    } else {
        default_source_volume = "0.00";
        default_source_muted = "true"; # <-- Asumir mute si hay error
    }
    close(volume_cmd);
}

# --- LÓGICA DE STREAMS (Modificada) ---

function store_stream() {
    if (stream_id) {
        if (stream_state == "") stream_state = "unknown";
        if (stream_volume == "") stream_volume = "0.00";
        if (stream_muted == "") stream_muted = "false"; # <-- Default para stream
        
        if (stream_media_name == "") stream_media_name = "N/A";
        if (stream_app_name == "") stream_app_name = "N/A";

        gsub(/\\\\/, "\\\\\\\\", stream_app_name);
        gsub(/"/, "\\\"", stream_app_name);
        gsub(/\\\\/, "\\\\\\\\", stream_media_name);
        gsub(/"/, "\\\"", stream_media_name);

        # <-- MODIFICADO: Añadido is_muted -->
        json_obj = sprintf("{\\"id\\": %s, \\"name\\": \\"%s\\", \\"state\\": \\"%s\\", \\"type\\": \\"%s\\", \\"volume\\": %s, \\"is_muted\\": %s}",
                           stream_id, stream_app_name, stream_state, stream_type, stream_volume, stream_muted);

        if (apps[stream_media_name] != "") {
            apps[stream_media_name] = apps[stream_media_name] "," json_obj;
        } else {
            apps[stream_media_name] = json_obj;
        }
    }
}

in_streams && /^$/ {
    in_streams = 0;
}

in_streams && in_audio && /^[[:space:]]{1,11}[0-9]+\\./ {
    store_stream(); 

    stream_id = $1;
    sub(/\\.$/, "", stream_id);

    stream_state = "";
    stream_type = "output";
    stream_muted = "false"; # <-- NUEVO: Reiniciar para el stream
    
    stream_media_name = "N/A"; 
    stream_app_name = "N/A";   

    volume_cmd = "wpctl get-volume " stream_id;
    if ((volume_cmd | getline vol_line) > 0) {
        if (vol_line ~ /MUTED/) { # <-- CHECK MUTED
            stream_muted = "true";
        }
        sub(/Volume: /, "", vol_line);
        vol_percent = vol_line * 100;
        if (vol_percent >= 99 && vol_percent < 100) {
            vol_percent = 100;
        }
        stream_volume = sprintf("%.0f", vol_percent);
    } else {
        stream_volume = "0.00";
        stream_muted = "true"; # <-- Asumir mute si hay error
    }
    close(volume_cmd);

    inspect_cmd = "wpctl inspect " stream_id;
    while ((inspect_cmd | getline line) > 0) {
        
        if (match(line, /application\\.process\\.binary[[:space:]]*=[[:space:]]*(.*)/, a)) {
            stream_media_name = a[1];
            gsub(/^"|"|[[:space:]]+$/, "", stream_media_name); 
        }
        
        if (match(line, /^[[:space:]]*\\*?[[:space:]]*media\\.name[[:space:]]*=[[:space:]]*(.*)/, a)) {
            stream_app_name = a[1];
            gsub(/^"|"|[[:space:]]+$/, "", stream_app_name); 
        }
    }
    close(inspect_cmd);
}

in_streams && /^[[:space:]]{12,}/ {
    if (stream_state == "" && match($0, /\\[(active|paused|init)\\]/, m)) {
        stream_state = m[1];
    }
    if ($0 ~ /</) {
        stream_type = "input";
    }
}

END {
    store_stream(); 

    printf "[";

    # <-- MODIFICADO: Añadido is_muted -->
    audio_app_obj = sprintf("{\\"id\\": %s, \\"name\\": \\"%s\\", \\"state\\": \\"active\\", \\"type\\": \\"output\\", \\"volume\\": %s, \\"is_muted\\": %s}",
                            default_sink_id, default_sink_name, default_sink_volume, default_sink_muted);
    printf "{\\"app_name\\": \\"Audio\\", \\"apps\\": [%s]}", audio_app_obj;

    # <-- MODIFICADO: Añadido is_muted -->
    mic_app_obj = sprintf("{\\"id\\": %s, \\"name\\": \\"%s\\", \\"state\\": \\"active\\", \\"type\\": \\"input\\", \\"volume\\": %s, \\"is_muted\\": %s}",
                          default_source_id, default_source_name, default_source_volume, default_source_muted);
    printf ",{\\"app_name\\": \\"Microphone\\", \\"apps\\": [%s]}", mic_app_obj;

    for (app_name in apps) {
        first_char = toupper(substr(app_name, 1, 1));
        rest_of_string = tolower(substr(app_name, 2));
        formatted_app_name = first_char rest_of_string;
        printf ",";
        printf "{\\"app_name\\": \\"%s\\", \\"apps\\": [%s]}",
               formatted_app_name, apps[app_name];
    }

    printf "]";
}
'

while true; do
    file=$(find /tmp -maxdepth 1 -name 'eww_volume_lock_*' | head -n 1)
    if [ -z "$file" ]; then
        wpctl status | awk "$AWK_COMMAND" | jq -c '.'
    fi
    sleep 0.5
done