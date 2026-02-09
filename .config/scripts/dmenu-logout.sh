#!/bin/bash

OPTIONS="󰐥 Shutdown\n󰍃 Logout\n󰜉 Reboot\n󰌾 Lock"

CHOICE=$(echo -e $OPTIONS | rofi -dmenu -i -p "Choose action:")

case "$CHOICE" in
    *"Shutdown"*)
        systemctl poweroff
        ;;
    *"Logout"*)
        # Detect environment
        if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
            hyprctl dispatch exit
        elif [ -n "$SWAYSOCK" ]; then
            swaymsg exit
        else
            i3-msg exit
        fi
        ;;
    *"Reboot"*)
        systemctl reboot
        ;;
    *"Lock"*)
        # Detect environment
        if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
            hyprlock
        elif [ -n "$SWAYSOCK" ]; then
            swaylock
        else
            betterlockscreen -l dim
        fi
        ;;
esac
