#!/bin/bash
# Shared keyboard layout notification logic
# Usage: keyboard-layout-notify.sh <layout_query_cmd> <cache_suffix>

LAYOUT_CMD="$1"      # Command that returns layout index (0=EN, 1=RU) or name (us/ru/EN/RU)
CACHE_SUFFIX="$2"    # e.g., "hypr", "i3", "sway"

state_file="$HOME/.cache/keyboard_layout_${CACHE_SUFFIX}_state"

# Get current layout
layout_result=$(eval "$LAYOUT_CMD" 2>/dev/null)

# Normalize to EN or RU
if [ "$layout_result" = "1" ] || [ "$layout_result" = "ru" ] || [ "$layout_result" = "RU" ]; then
    current_layout="🇷🇺 RU"
    layout_name="RU"
else
    current_layout="🇺🇸 EN"
    layout_name="EN"
fi

# Read previous state
previous_layout=""
if [ -f "$state_file" ]; then
    previous_layout=$(cat "$state_file" 2>/dev/null | tr -d '\n')
fi

# Initialize state file on first run
if [ -z "$previous_layout" ]; then
    echo "$layout_name" > "$state_file"
    echo "$current_layout"
    exit 0
fi

# Show notification if changed
if [ "$previous_layout" != "$layout_name" ]; then
    dunstify -r 8888 -t 1000 "$current_layout" 2>/dev/null
    echo "$layout_name" > "$state_file"
fi

# Output for waybar/status bar
echo "$current_layout"
