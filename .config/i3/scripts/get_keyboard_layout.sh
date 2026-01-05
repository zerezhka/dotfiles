#!/bin/bash
state_file="$HOME/.cache/i3_keyboard_layout_state"
layout_index=$(setxkbmap -query | grep layout | awk '{print $2}')

# Get current layout from xkblayout-state or setxkbmap
if command -v xkblayout-state &>/dev/null; then
    layout_name=$(xkblayout-state print "%s" 2>/dev/null)
else
    # Fallback: parse setxkbmap output
    current_layout=$(setxkbmap -query | awk '/layout/{print $2}')
    if echo "$current_layout" | grep -q "ru"; then
        layout_name="RU"
        current_layout="🇷🇺 RU"
    else
        layout_name="EN"
        current_layout="🇺🇸 EN"
    fi
fi

# Show notification on layout change
if [ -f "$state_file" ]; then
    previous_layout=$(cat "$state_file")
    if [ "$previous_layout" != "$layout_name" ]; then
        dunstify -r 8888 -a "Keyboard" -u low -t 1000 "$current_layout" 2>/dev/null
    fi
fi

echo "$layout_name" > "$state_file"
echo "$current_layout"
