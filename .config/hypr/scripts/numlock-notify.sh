#!/bin/bash
# Hyprland NumLock notification wrapper
STATE_CMD="hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .numLock' | head -1 | sed 's/true/on/; s/false/off/'"
~/.config/scripts/lock-key-notify.sh "NumLock" "$STATE_CMD" 7778
