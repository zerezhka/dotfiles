#!/bin/bash
# i3 CapsLock notification wrapper
STATE_CMD="xset q | grep 'Caps Lock' | awk '{print \$4}'"
~/.config/scripts/lock-key-notify.sh "CapsLock" "$STATE_CMD" 7777
