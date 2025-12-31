#!/bin/bash
# Kill any existing waybar instances
pkill -x waybar

# Wait a moment for the process to fully terminate
sleep 0.2

# Set environment variables and start waybar detached from this script
GTK_USE_PORTAL=0 GDK_BACKEND=wayland nohup waybar "$@" > /dev/null 2>&1 &

# Detach from the shell
disown
