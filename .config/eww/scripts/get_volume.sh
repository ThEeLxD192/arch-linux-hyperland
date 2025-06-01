#!/bin/bash

last_icon="-"
last_text="-"

while true; do
    volume_info=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
    volume=$(awk '{print $2}' <<< "$volume_info")
    muted=$(grep -q '\[MUTED\]' <<< "$volume_info" && echo "1" || echo "0")

    if [[ "$muted" == "1" ]]; then
        icon="󰝟"
        text=""
    else
        percent=$(printf "%.0f" "$(bc -l <<< "$volume * 100")")
        if [ "$percent" -lt 33 ]; then
            icon="󰕿"
        elif [ "$percent" -lt 67 ]; then
            icon="󰖀"
        else
            icon="󰕾"
        fi
        text="${percent}%"
    fi

    if [[ "$icon" != "$last_icon" || "$text" != "$last_text" ]]; then
        eww update volume_icon="$icon" volume_text="$text"
        last_icon="$icon"
        last_text="$text"
    fi

    sleep 1
done