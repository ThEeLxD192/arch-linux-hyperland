#!/bin/bash

IFACE="wlo1"

last_rx="0"
last_tx="0"

while true; do
    rx1=$(< /sys/class/net/$IFACE/statistics/rx_bytes)
    tx1=$(< /sys/class/net/$IFACE/statistics/tx_bytes)

    sleep 1

    rx2=$(< /sys/class/net/$IFACE/statistics/rx_bytes)
    tx2=$(< /sys/class/net/$IFACE/statistics/tx_bytes)

    rx_kbs=$(( (rx2 - rx1) / 1024 ))
    tx_kbs=$(( (tx2 - tx1) / 1024 ))

    format_speed() {
        local kbs=$1
        if (( kbs >= 1024 )); then
            printf "%.1f MB/s" "$(echo "scale=1; $kbs/1024" | bc)"
        else
            printf "%d KB/s" "$kbs"
        fi
    }

    rx_formatted=$(format_speed $rx_kbs)
    tx_formatted=$(format_speed $tx_kbs)

    # Solo actualiza si cambió
    if [[ "$rx_formatted" != "$last_rx" || "$tx_formatted" != "$last_tx" ]]; then
        eww update network_download_value="${rx_formatted% *}" \
                   network_download_unit="${rx_formatted##* }" \
                   network_upload_value="${tx_formatted% *}" \
                   network_upload_unit="${tx_formatted##* }"
        last_rx="$rx_formatted"
        last_tx="$tx_formatted"
    fi
done
