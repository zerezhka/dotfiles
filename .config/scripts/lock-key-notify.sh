#!/bin/bash
# Shared lock key notification logic
# Usage: lock-key-notify.sh <key_name> <state_query_cmd> <notification_id>

KEY_NAME="$1"        # e.g., "CapsLock", "NumLock"
STATE_CMD="$2"       # Command to get current state (must output "on" or "off")
NOTIF_ID="$3"        # Notification ID (e.g., 7777)

state_file="$HOME/.cache/lock_key_${KEY_NAME}_state"

# Get current state
current_state=$(eval "$STATE_CMD" 2>/dev/null)

# Read previous state
previous_state=""
if [ -f "$state_file" ]; then
    previous_state=$(cat "$state_file" 2>/dev/null | tr -d '\n')
fi

# Initialize state file on first run
if [ -z "$previous_state" ]; then
    echo "$current_state" > "$state_file"
    exit 0
fi

# Show notification if state changed
if [ "$previous_state" != "$current_state" ]; then
    if [ "$current_state" = "on" ]; then
        dunstify -r "$NOTIF_ID" -t 800 "" "<span foreground='#00ff00'>●</span> $KEY_NAME ON" 2>/dev/null
    else
        dunstify -r "$NOTIF_ID" -t 800 "" "<span foreground='#ff6b6b'>●</span> $KEY_NAME off" 2>/dev/null
    fi
    echo "$current_state" > "$state_file"
fi
