#!/bin/bash

current_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
if [ -z "$current_ssid" ]; then
    current_ssid="Disconnected"
fi

menu_options="Connect to Wi-Fi\nDisconnect\nConnection Editor\nConnection Info"

choice=$(echo -e "$menu_options" | rofi -dmenu -i -p "Network: $current_ssid")

case "$choice" in
    "Connect to Wi-Fi")
        wifi_list=$(nmcli -t -f SSID,SIGNAL,SECURITY dev wifi list | sort -t: -k2 -nr)
        wifi_display=$(echo "$wifi_list" | awk -F: '{printf "%-25s %3s%% %s\n", $1, $2, $3}')
        selected_line=$(echo "$wifi_display" | rofi -dmenu -i -p "Select Wi-Fi:")
        
        if [ -n "$selected_line" ]; then
            selected_ssid=$(echo "$selected_line" | awk '{print $1}')
            security=$(echo "$wifi_list" | grep "^${selected_ssid}:" | cut -d: -f3)
            
            if [ "$security" != "--" ] && [ -n "$security" ]; then
                password=$(rofi -dmenu -password -p "Password for $selected_ssid:")
                if [ -n "$password" ]; then
                    nmcli dev wifi connect "$selected_ssid" password "$password" 2>&1 | dunstify -r 9999 "Wi-Fi" "Connecting to $selected_ssid..."
                fi
            else
                nmcli dev wifi connect "$selected_ssid" 2>&1 | dunstify -r 9999 "Wi-Fi" "Connecting to $selected_ssid..."
            fi
        fi
        ;;
    "Disconnect")
        nmcli dev disconnect wlan0 2>&1 | dunstify -r 9999 "Wi-Fi" "Disconnecting..."
        ;;
    "Connection Editor")
        ${TERMINAL:-alacritty} -e nmtui &
        ;;
    "Connection Info")
        info=$(nmcli connection show --active 2>/dev/null | grep -E "connection.id|connection.type|ipv4.addresses|ipv4.gateway|ipv4.dns" | sed 's/.*: */\n/g' | tr '\n' ' ')
        dunstify -r 9999 "Network Info" "$info"
        ;;
esac
