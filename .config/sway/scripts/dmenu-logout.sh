#!/bin/bash

OPTIONS=" Shutdown\n Logout\n Reboot\n Lock"

CHOICE=$(echo -e $OPTIONS | dmenu -i -p "Choose action:")

case "$CHOICE" in
    " Shutdown")
        systemctl poweroff
        ;;
    " Logout")
        swaymsg exit
        ;;
    " Reboot")
        systemctl reboot
        ;;
    " Lock")
        swaylock
        ;;
esac
