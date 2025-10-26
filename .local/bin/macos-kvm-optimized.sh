#!/bin/bash

# Location: ~/.local/bin/macos-kvm-optimized.sh
# Purpose: Optimized macOS KVM startup script for LightDM session
# Usage: Called by macos-kvm-optimized.desktop session file
# Features: Pure X11, performance optimizations, auto-fullscreen

# macOS KVM Session - Optimized for fullscreen performance
# This session boots macOS KVM directly without window manager overhead

# Set display
export DISPLAY=:0

# Optimize X11 for KVM performance
xset -dpms 2>/dev/null || true
xset s off 2>/dev/null || true
xsetroot -solid black 2>/dev/null || true

# Disable compositing and effects for better performance
export QT_X11_NO_MITSHM=1
export _JAVA_AWT_WM_NONREPARENTING=1

# Set fullscreen mode - get native resolution
SCREEN=$(xrandr | grep " connected" | head -1 | cut -d' ' -f1)
RESOLUTION=$(xrandr | grep " connected" | head -1 | grep -o '[0-9]*x[0-9]*' | head -1)
if [ -n "$SCREEN" ] && [ -n "$RESOLUTION" ]; then
    xrandr --output "$SCREEN" --mode "$RESOLUTION" 2>/dev/null || true
fi

# Change to KVM directory and run boot script
cd $HOME/Projects/ultimate-macOS-KVM/

# Run macOS KVM - when it exits, session ends and returns to login
exec ./boot.sh
