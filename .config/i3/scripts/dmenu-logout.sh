#!/bin/bash

OPTIONS=" Shutdown\n Logout\n Reboot\n Lock"

CHOICE=$(echo -e $OPTIONS | dmenu -i -p "Choose action:")

case "$CHOICE" in
    " Shutdown")
        systemctl poweroff
        ;;
    " Logout")
        i3-msg exit
        ;;
    " Reboot")
        systemctl reboot
        ;;
    " Lock")
        light-locker-command -l
        ;;
esac
