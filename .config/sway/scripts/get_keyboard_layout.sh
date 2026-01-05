#!/bin/bash
state_file="$HOME/.cache/sway_keyboard_layout_state"
layout_index=$(swaymsg -t get_inputs 2>/dev/null | jq -r '.[] | select(.type == "keyboard") | .xkb_active_layout_index' 2>/dev/null | head -1)

if [ "$layout_index" = "1" ]; then
    current_layout="🇷🇺 RU"
    layout_name="RU"
else
    current_layout="🇺🇸 EN"
    layout_name="EN"
fi

if [ -f "$state_file" ]; then
    previous_layout=$(cat "$state_file")
    if [ "$previous_layout" != "$layout_name" ]; then
        dunstify -r 8888 -a "Keyboard" -u low -t 1000 "$current_layout" 2>/dev/null
    fi
fi

echo "$layout_name" > "$state_file"
echo "$current_layout"

