#!/bin/bash
# Toggle touchpad on/off with notification

# Find touchpad device
TOUCHPAD_ID=$(xinput list | grep -i touchpad | grep -o 'id=[0-9]*' | grep -o '[0-9]*' | head -1)

if [ -z "$TOUCHPAD_ID" ]; then
    dunstify -r 7777 -a "Touchpad" -u normal -t 2000 "󰟸 Touchpad" "Not found"
    exit 1
fi

# Get current state
STATE=$(xinput list-props "$TOUCHPAD_ID" | grep "Device Enabled" | awk '{print $4}')

if [ "$STATE" = "1" ]; then
    # Disable touchpad
    xinput disable "$TOUCHPAD_ID"
    dunstify -r 7777 -a "Touchpad" -u low -t 2000 "󰟸 Touchpad" "Disabled"
else
    # Enable touchpad
    xinput enable "$TOUCHPAD_ID"
    dunstify -r 7777 -a "Touchpad" -u low -t 2000 "󰍽 Touchpad" "Enabled"
fi
