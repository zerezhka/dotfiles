#!/bin/bash
state_file="$HOME/.cache/sway_numlock_state"

# Get Num Lock state from sysfs LED
numlock_led=$(find /sys/class/leds -name "*numlock" 2>/dev/null | head -1)
if [ -z "$numlock_led" ]; then
    # Fallback: try reading from keyboard input device
    exit 0
fi

numlock_state=$(cat "$numlock_led/brightness" 2>/dev/null)
[ "$numlock_state" = "1" ] && numlock_state="on" || numlock_state="off"

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
