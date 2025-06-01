#!/bin/bash

last_brightness=$(brightnessctl g)
eww update brightness_status="$last_brightness"

while true; do
  current=$(brightnessctl g)
  if [[ "$current" != "$last_brightness" ]]; then
    eww update brightness_status="$current"
    last_brightness="$current"
  fi
  sleep 1
done