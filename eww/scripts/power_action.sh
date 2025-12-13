#!/bin/sh

ACTION=$(eww get power_dialog_action)

case "$ACTION" in
  "poweroff")
    systemctl poweroff
    ;;
  "reboot")
    systemctl reboot
    ;;
  "logout")
    hyprctl dispatch exit
    ;;
esac