#!/bin/bash
state_file="$HOME/.cache/i3_capslock_state"

# Get Caps Lock state via xset
capslock_state=$(xset q | grep "Caps Lock" | awk '{print $4}')

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
    if [ "$capslock_state" = "on" ]; then
        dunstify -r 7777 -t 800 "" "<span foreground='#00ff00'>●</span> CapsLock ON" 2>/dev/null
    else
        dunstify -r 7777 -t 800 "" "<span foreground='#ff6b6b'>●</span> CapsLock off" 2>/dev/null
    fi
    echo "$capslock_state" > "$state_file"
fi
