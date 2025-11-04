#!/bin/bash
# show_notification.sh
# Usage: show_notification.sh TYPE VALUE
# TYPE: brightness, volume, custom
# VALUE: numeric percent or string message

ICON=""
MESSAGE=""

case "$1" in
    brightness)
        # VALUE can be +10%, 10%-, or empty
        if [ -n "$2" ]; then
            brightnessctl set "$2"
        fi
        value=$(brightnessctl get)
        max=$(brightnessctl max)
        percent=$(( value*100/max ))
        ICON=" "   # brightness icon
        MESSAGE="$ICON ${percent}%"
        ;;
volume)
    # VALUE can be +5%, -5%, --toggle
    SINK=$(pactl get-default-sink)

    case "$2" in
        +*%) pactl set-sink-volume "$SINK" "$2" ;;
        -*%) pactl set-sink-volume "$SINK" "$2" ;;
        --toggle) pactl set-sink-mute "$SINK" toggle ;;
    esac

    # Get actual volume and mute status
    vol=$(pactl get-sink-volume "$SINK" | grep -Po '[0-9]+%' | head -1)
    muted=$(pactl get-sink-mute "$SINK" | awk '{print $2}')
    ICON="  "
    [ "$muted" = "yes" ] && ICON="  "
    MESSAGE="$ICON ${vol}"
        ;;
    battery)
    # Set battery path
    BAT_NAME="${2:-BAT1}"  # default to BAT1, can override with second argument
    BAT_PATH="/sys/class/power_supply/$BAT_NAME"

    if [ -f "$BAT_PATH/capacity" ]; then
        percent=$(cat "$BAT_PATH/capacity")
    else
        percent="?"
    fi

    # Icon based on level
    if [ "$percent" -ge 80 ]; then
        ICON=" "
    elif [ "$percent" -ge 60 ]; then
        ICON=" "
    elif [ "$percent" -ge 40 ]; then
        ICON=" "
    elif [ "$percent" -ge 20 ]; then
        ICON=" "
    else
        ICON=" "
    fi

    MESSAGE="$ICON ${percent}%"
    ;;
wifi)
        # Default interface wlan0
        IFACE="${2:-wlan0}"
        SSID=$(iwgetid -r)
        # RX = $10, TX = $2 in /proc/net/dev
        STATS=$(awk -v iface="$IFACE" '$1 ~ iface":" {printf "↑%.1f MB ↓%.1f MB", $10/1024/1024, $2/1024/1024}' /proc/net/dev)
        ICON=" "
        MESSAGE="$ICON SSID: ${SSID:-N/A}\n$STATS"
        ;;
    custom)
        MESSAGE="$2"
        ;;
    *)

        echo "Usage: $0 {brightness|volume|battery|wifi|custom} [value]"
        exit 1
        ;;
esac

# Show notification with dunstify, replace previous one
dunstify -r 9999 "$MESSAGE"
