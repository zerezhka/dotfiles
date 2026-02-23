#!/bin/bash
# Hyprland CapsLock notification wrapper
STATE_CMD="hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .capsLock' | head -1 | sed 's/true/on/; s/false/off/'"
~/.config/scripts/lock-key-notify.sh "CapsLock" "$STATE_CMD" 7777
