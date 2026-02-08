#!/bin/bash
state_file="$HOME/.cache/hypr_capslock_state"

# Get Caps Lock state from main keyboard
capslock_state=$(hyprctl devices -j 2>/dev/null | jq -r '.keyboards[] | select(.main == true) | .capsLock' 2>/dev/null | head -1)

# If no main keyboard found, use first keyboard
if [ -z "$capslock_state" ]; then
    capslock_state=$(hyprctl devices -j 2>/dev/null | jq -r '.keyboards[0].capsLock' 2>/dev/null)
fi

# Read previous state
previous_state=""
if [ -f "$state_file" ]; then
    previous_state=$(cat "$state_file" 2>/dev/null | tr -d '\n')
fi

# Initialize state file on first run
if [ -z "$previous_state" ]; then
    echo "$capslock_state" > "$state_file"
    exit 0
fi

# Show notification if state changed
if [ "$previous_state" != "$capslock_state" ]; then
    if [ "$capslock_state" = "true" ]; then
        dunstify -r 7777 -t 800 "" "<span foreground='#00ff00'>●</span> CapsLock ON" 2>/dev/null
    else
        dunstify -r 7777 -t 800 "" "<span foreground='#ff6b6b'>●</span> CapsLock off" 2>/dev/null
    fi
    echo "$capslock_state" > "$state_file"
fi
