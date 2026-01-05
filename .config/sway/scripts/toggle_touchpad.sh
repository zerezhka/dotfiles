#!/bin/bash
# Toggle touchpad on/off with notification

# Find touchpad identifier
TOUCHPAD=$(swaymsg -t get_inputs | jq -r '.[] | select(.type == "touchpad") | .identifier' | head -1)

if [ -z "$TOUCHPAD" ]; then
    dunstify -r 7777 -a "Touchpad" -u normal -t 2000 "󰟸 Touchpad" "Not found"
    exit 1
fi

# Get current state
STATE=$(swaymsg -t get_inputs | jq -r ".[] | select(.identifier == \"$TOUCHPAD\") | .libinput.send_events")

if [ "$STATE" = "enabled" ]; then
    # Disable touchpad
    swaymsg input "$TOUCHPAD" events disabled
    dunstify -r 7777 -a "Touchpad" -u low -t 2000 "󰟸 Touchpad" "Disabled"
else
    # Enable touchpad
    swaymsg input "$TOUCHPAD" events enabled
    dunstify -r 7777 -a "Touchpad" -u low -t 2000 "󰍽 Touchpad" "Enabled"
fi
