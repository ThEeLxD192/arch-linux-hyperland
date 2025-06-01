#!/bin/bash

awk '/Mem:/ {
    used=$3; total=$2;
    sub(/i/, "", used);
    sub(/i/, "", total);
    printf "Ram: %s/%s\n", used, total
}' <(free -h)