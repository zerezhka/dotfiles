#!/bin/bash
# i3 keyboard layout wrapper
LAYOUT_CMD="if command -v xkblayout-state &>/dev/null; then xkblayout-state print '%s'; else setxkbmap -query | awk '/layout/{print \$2}'; fi"
~/.config/scripts/keyboard-layout-notify.sh "$LAYOUT_CMD" "i3"
