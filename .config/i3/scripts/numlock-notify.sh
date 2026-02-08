#!/bin/bash
state_file="$HOME/.cache/i3_numlock_state"

# Get Num Lock state via xset
numlock_state=$(xset q | grep "Num Lock" | awk '{print $8}')

# Read previous state
previous_state=""
if [ -f "$state_file" ]; then
    previous_state=$(cat "$state_file" 2>/dev/null | tr -d '\n')
fi

# Initialize state file on first run
if [ -z "$previous_state" ]; then
    echo "$numlock_state" > "$state_file"
    exit 0
fi

# Show notification if state changed
if [ "$previous_state" != "$numlock_state" ]; then
    if [ "$numlock_state" = "on" ]; then
        dunstify -r 7778 -t 800 "" "<span foreground='#00ff00'>●</span> NumLock ON" 2>/dev/null
    else
        dunstify -r 7778 -t 800 "" "<span foreground='#ff6b6b'>●</span> NumLock off" 2>/dev/null
    fi
    echo "$numlock_state" > "$state_file"
fi
