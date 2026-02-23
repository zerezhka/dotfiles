#!/bin/bash
# show_notification.sh
# Usage: show_notification.sh TYPE VALUE
# TYPE: brightness, volume, custom
# VALUE: numeric percent or string message

# Notification ID for replacing previous notifications
NOTIF_ID=9999

case "$1" in
    brightness)
        # VALUE can be +10%, 10%-, or empty
        if [ -n "$2" ]; then
            brightnessctl set "$2" >/dev/null
        fi
        value=$(brightnessctl get)
        max=$(brightnessctl max)
        percent=$(( value*100/max ))

        # Choose icon based on brightness level
        if [ "$percent" -ge 75 ]; then
            ICON="󰃠"  # Full brightness
        elif [ "$percent" -ge 50 ]; then
            ICON="󰃟"  # High brightness
        elif [ "$percent" -ge 25 ]; then
            ICON="󰃞"  # Medium brightness
        elif [ "$percent" -ge 20 ]; then
            ICON="󰃝"  # Low brightness
        else
            # 10-20%: reversed/different visual
            ICON="󰛨"  # Very low / night light
        fi

        dunstify -r "$NOTIF_ID" \
            -a "Brightness" \
            -u low \
            -t 2000 \
            -h int:value:"$percent" \
            "$ICON Brightness" "${percent}%"
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
        vol_num="${vol%\%}"
        muted=$(pactl get-sink-mute "$SINK" | awk '{print $2}')

        # Choose icon based on volume and mute status
        if [ "$muted" = "yes" ]; then
            ICON="󰝟"
            MESSAGE="Muted"
            dunstify -r "$NOTIF_ID" \
                -a "Volume" \
                -u low \
                -t 2000 \
                "$ICON Volume" "$MESSAGE"
        else
            if [ "$vol_num" -ge 70 ]; then
                ICON="󰕾"
            elif [ "$vol_num" -ge 30 ]; then
                ICON="󰖀"
            else
                ICON="󰕿"
            fi

            dunstify -r "$NOTIF_ID" \
                -a "Volume" \
                -u low \
                -t 2000 \
                -h int:value:"$vol_num" \
                "$ICON Volume" "${vol}"
        fi
        ;;

    battery)
        # Set battery path
        BAT_NAME="${2:-BAT1}"
        BAT_PATH="/sys/class/power_supply/$BAT_NAME"

        if [ -f "$BAT_PATH/capacity" ]; then
            percent=$(cat "$BAT_PATH/capacity")
        else
            percent="?"
        fi

        # Check charging status
        if [ -f "$BAT_PATH/status" ]; then
            status=$(cat "$BAT_PATH/status")
        else
            status="Unknown"
        fi

        # Icon based on level and charging status
        if [ "$status" = "Charging" ]; then
            ICON="󰂄"
            urgency="low"
        elif [ "$percent" -ge 80 ]; then
            ICON="󰁹"
            urgency="low"
        elif [ "$percent" -ge 60 ]; then
            ICON="󰁾"
            urgency="low"
        elif [ "$percent" -ge 40 ]; then
            ICON="󰁼"
            urgency="normal"
        elif [ "$percent" -ge 20 ]; then
            ICON="󰁺"
            urgency="normal"
        else
            ICON="󰁺"
            urgency="critical"
        fi

        dunstify -r "$NOTIF_ID" \
            -a "Battery" \
            -u "$urgency" \
            -t 2000 \
            -h int:value:"$percent" \
            "$ICON Battery" "${percent}% ($status)"
        ;;

    wifi)
        # Default interface wlan0
        IFACE="${2:-wlan0}"
        SSID=$(iwgetid -r)

        # Get signal strength if available
        if [ -n "$SSID" ]; then
            signal=$(grep "^\s*$IFACE:" /proc/net/wireless | awk '{print int($3 * 100 / 70)}')

            if [ "$signal" -ge 75 ]; then
                ICON="󰤨"
            elif [ "$signal" -ge 50 ]; then
                ICON="󰤥"
            elif [ "$signal" -ge 25 ]; then
                ICON="󰤢"
            else
                ICON="󰤟"
            fi
        else
            ICON="󰤮"
            SSID="Disconnected"
        fi

        # RX = $10, TX = $2 in /proc/net/dev
        STATS=$(awk -v iface="$IFACE" '$1 ~ iface":" {printf "↑%.1f MB ↓%.1f MB", $10/1024/1024, $2/1024/1024}' /proc/net/dev)

        dunstify -r "$NOTIF_ID" \
            -a "Network" \
            -u low \
            -t 3000 \
            "$ICON WiFi" "SSID: $SSID\n$STATS"
        ;;

    custom)
        dunstify -r "$NOTIF_ID" \
            -a "System" \
            -u normal \
            -t 3000 \
            "$2"
        ;;

    *)
        echo "Usage: $0 {brightness|volume|battery|wifi|custom} [value]"
        exit 1
        ;;
esac
