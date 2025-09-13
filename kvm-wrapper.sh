#!/bin/bash
#/usr/local/bin/kvm-wrapper.sh

# Set display
export DISPLAY=:0

# Basic X11 setup - no window manager needed
xset -dpms 2>/dev/null || true
xset s off 2>/dev/null || true
xsetroot -solid black 2>/dev/null || true

# Change to your project directory and run boot.sh
cd $HOME/Projects/ultimate-macOS-KVM/ # https://github.com/Coopydood/ultimate-macOS-KVM saved in ~/Projects/ , may be change it in future
exec ./boot.sh
