#!/bin/bash
# Unified lock-key notification monitor — reads kernel sysfs LEDs, works across all WMs.
# Runs as a systemd user service; no per-WM polling loops needed.

declare -A prev=()
declare -A led_path=()
declare -A notif_id=( [capslock]=7777 [numlock]=7778 )
declare -A label=( [capslock]="CapsLock" [numlock]="NumLock" )

for key in capslock numlock; do
    path=$(find /sys/class/leds -maxdepth 1 -name "*${key}" 2>/dev/null | head -1)
    [ -n "$path" ] && led_path[$key]="$path"
done

while true; do
    for key in capslock numlock; do
        path="${led_path[$key]}"
        [ -z "$path" ] && continue

        val=$(cat "$path/brightness" 2>/dev/null)
        state=$([ "$val" = "1" ] && echo "on" || echo "off")
        old="${prev[$key]:-}"

        if [ -z "$old" ]; then
            prev[$key]="$state"
            continue
        fi

        if [ "$state" != "$old" ]; then
            if [ "$state" = "on" ]; then
                dunstify -r "${notif_id[$key]}" -t 800 "" \
                    "<span foreground='#00ff00'>●</span> ${label[$key]} ON"
            else
                dunstify -r "${notif_id[$key]}" -t 800 "" \
                    "<span foreground='#ff6b6b'>●</span> ${label[$key]} off"
            fi
            prev[$key]="$state"
        fi
    done
    sleep 0.3
done
