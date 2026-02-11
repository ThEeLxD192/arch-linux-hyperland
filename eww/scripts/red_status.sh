#!/bin/bash

CONFIG_FILE="$HOME/.config/eww/scripts/target_interface"

if [ -f "$CONFIG_FILE" ]; then
    IFACE=$(cat "$CONFIG_FILE" | tr -d '[:space:]')
else
    IFACE=$(ip route | grep '^default' | awk '{print $5}' | head -n1)
fi

if [ -z "$IFACE" ]; then IFACE="lo"; fi

print_json() {
    local download=$1
    local upload=$2
    printf '{"download_value": "%s", "upload_value": "%s"}\n' "$download" "$upload"
}

format_speed() {
    local kbs=$1
    if (( kbs >= 1024 )); then
        printf "%.1f MB/s" "$(echo "scale=1; $kbs/1024" | bc)"
    else
        printf "%d KB/s" "$kbs"
    fi
}

if ! command -v bc &> /dev/null; then
    print_json "Error" "bc is not installed"
    exit 1
fi

if [ ! -d "/sys/class/net/$IFACE" ]; then
    print_json "Error" "Interface $IFACE not found"
    exit 1 
fi

while true; do
    rx1=$(< /sys/class/net/$IFACE/statistics/rx_bytes)
    tx1=$(< /sys/class/net/$IFACE/statistics/tx_bytes)

    sleep 1

    rx2=$(< /sys/class/net/$IFACE/statistics/rx_bytes)
    tx2=$(< /sys/class/net/$IFACE/statistics/tx_bytes)

    rx_kbs=$(( (rx2 - rx1) / 1024 ))
    tx_kbs=$(( (tx2 - tx1) / 1024 ))

    rx_formatted=$(format_speed $rx_kbs)
    tx_formatted=$(format_speed $tx_kbs)

    print_json "$rx_formatted" "$tx_formatted"
done

