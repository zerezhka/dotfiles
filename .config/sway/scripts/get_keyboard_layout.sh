#!/bin/bash
# Sway keyboard layout wrapper
LAYOUT_CMD="swaymsg -t get_inputs | jq -r '.[] | select(.type == \"keyboard\") | .xkb_active_layout_index' | head -1"
~/.config/scripts/keyboard-layout-notify.sh "$LAYOUT_CMD" "sway"
