#!/bin/bash
# Sway NumLock notification wrapper
STATE_CMD="led=\$(find /sys/class/leds -name '*numlock' 2>/dev/null | head -1); [ -n \"\$led\" ] && cat \"\$led/brightness\" | sed 's/1/on/; s/0/off/' || echo 'off'"
~/.config/scripts/lock-key-notify.sh "NumLock" "$STATE_CMD" 7778
