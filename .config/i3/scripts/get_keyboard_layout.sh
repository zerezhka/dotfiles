#!/bin/bash
state_file="$HOME/.cache/i3_keyboard_layout_state"

# Try xkb-switch first (most reliable)
if command -v xkb-switch &>/dev/null; then
    current=$(xkb-switch)
    if [ "$current" = "ru" ]; then
        layout_name="RU"
        current_layout="🇷🇺 RU"
    else
        layout_name="EN"
        current_layout="🇺🇸 EN"
    fi
# Fallback: use xset LED mask to detect active layout
else
    # Get LED mask and extract bit 13 (group indicator)
    led_mask=$(xset q | grep LED | awk '{print $10}')
    # Convert hex to decimal and check if group bit is set
    if [ "$((0x$led_mask & 0x1000))" != "0" ]; then
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
        dunstify -r 8888 -a "Keyboard" -u normal -t 2000 "Layout" "$current_layout" 2>/dev/null
    fi
fi

echo "$layout_name" > "$state_file"
echo "$current_layout"
