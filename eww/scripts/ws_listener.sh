#!/bin/bash

output_workspaces() {
    active_id=$(hyprctl activeworkspace -j | jq '.id')
    occupied_ids=$(hyprctl workspaces -j | jq '[.[] | .id]')

    json_out="{"

    for i in $(seq 1 10); do
        state="empty"

        if [ "$i" -eq "$active_id" ]; then
            state="active"
        elif echo "$occupied_ids" | jq -e "index($i)" > /dev/null; then
            state="occupied"
        fi

        json_out="$json_out\"$i\": \"$state\""

        if [ "$i" -lt 10 ]; then
            json_out="$json_out,"
        fi
    done

    json_out="$json_out}"
    echo "$json_out"
}

output_workspaces

# Check if required variables exist
if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] || [ -z "$XDG_RUNTIME_DIR" ]; then
    echo "{\"error\": \"HYPRLAND_INSTANCE_SIGNATURE or XDG_RUNTIME_DIR are not defined.\"}" >&2

    export HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances -j | jq -r '.[0] | .instance')
    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        echo "{\"error\": \"Could not get HYPRLAND_INSTANCE_SIGNATURE from hyprctl.\"}" >&2
        exit 1
    fi
fi

SOCKET_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

if [ ! -S "$SOCKET_PATH" ]; then
    echo "{\"error\": \"Socket not found at: $SOCKET_PATH\"}" >&2
    exit 1
fi

socat -u "UNIX-CONNECT:$SOCKET_PATH" - | \
grep --line-buffered -E "workspacev2|activewindowv2|createworkspacev2|destroyworkspacev2" | \
while read -r event; do
    output_workspaces
done
