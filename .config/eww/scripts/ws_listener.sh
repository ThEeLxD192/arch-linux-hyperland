#!/bin/bash

get_ws_occupied() {
    hyprctl clients -j | jq -r '.[].workspace.id' | sort -nu | paste -sd ',' -
}

get_ws_active() {
    hyprctl activeworkspace -j | jq '.id'
}

last_active=""
last_occupied=""

while true; do
    current_active=$(get_ws_active)

    data_clients=$(hyprctl clients -j)
    current_occupied=$(echo "$data_clients" | jq -r '.[].workspace.id' | sort -nu | paste -sd ',' -)

    if [[ "$current_active" != "$last_active" ]]; then
        eww update ws_active="$current_active"
        last_active="$current_active"
    fi

    if [[ "$current_occupied" != "$last_occupied" ]]; then
        eww update ws_occupied="$current_occupied"
        last_occupied="$current_occupied"
    fi

    sleep 0.3
done
