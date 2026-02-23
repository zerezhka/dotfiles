#!/bin/bash
# Hyprland keyboard layout wrapper
LAYOUT_CMD="hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_layout_index' | head -1"
~/.config/scripts/keyboard-layout-notify.sh "$LAYOUT_CMD" "hypr"
