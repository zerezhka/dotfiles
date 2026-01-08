#!/bin/bash
state_file="$HOME/.cache/hypr_keyboard_layout_state"
layout_name=$(hyprctl devices -j 2>/dev/null | jq -r '.keyboards[0].active_keymap' 2>/dev/null | head -1)

if echo "$layout_name" | grep -qi "russian\|ru"; then
    current_layout="🇷🇺 RU"
    layout_name="RU"
else
    current_layout="🇺🇸 EN"
    layout_name="EN"
fi

previous_layout=""
if [ -f "$state_file" ]; then
    previous_layout=$(cat "$state_file" 2>/dev/null | tr -d '\n')
fi

if [ -z "$previous_layout" ]; then
    echo "$layout_name" > "$state_file"
    echo "$current_layout"
    exit 0
fi

if [ "$previous_layout" != "$layout_name" ]; then
    dunstify -r 8888 -t 1000 "$current_layout" 2>/dev/null
    echo "$layout_name" > "$state_file"
fi

echo "$current_layout"
