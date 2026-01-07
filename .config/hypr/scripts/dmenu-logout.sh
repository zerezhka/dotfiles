#!/bin/bash

OPTIONS=" Shutdown\n Logout\n Reboot\n Lock"

CHOICE=$(echo -e $OPTIONS | rofi -dmenu -i -p "Choose action:")

case "$CHOICE" in
    " Shutdown")
        systemctl poweroff
        ;;
    " Logout")
        hyprctl dispatch exit
        ;;
    " Reboot")
        systemctl reboot
        ;;
    " Lock")
        hyprlock
        ;;
esac
