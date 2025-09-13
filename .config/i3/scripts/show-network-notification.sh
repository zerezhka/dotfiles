#!/bin/bash

# Get current SSID
SSID=$(iwgetid -r)

# Get network statistics for wlan0
# Columns: RX bytes, TX bytes (simplified)
STATS=$(cat /proc/net/dev | grep wlan0 | awk '{printf "↑%.1f MB ↓%.1f MB", $10/1024/1024, $2/1024/1024}')

# Show notification that dismisses after 3 seconds
notify-send --expire-time=3000 "Wi-Fi Status" "SSID: $SSID\n$STATS"
