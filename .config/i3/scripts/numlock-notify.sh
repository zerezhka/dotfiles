#!/bin/bash
# i3 NumLock notification wrapper
STATE_CMD="xset q | grep 'Num Lock' | awk '{print \$8}'"
~/.config/scripts/lock-key-notify.sh "NumLock" "$STATE_CMD" 7778
