#!/bin/bash

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

# Trim whitespace function
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"
    var="${var%"${var##*[![:space:]]}"}"
    echo -n "$var"
}

# Extract keybindings with comments from previous line
mapfile -t LINES < "$HYPR_CONF"
BINDINGS=()

# Add Alacritty-specific bindings manually
BINDINGS+=("<b>Ctrl + Shift + C</b>  <span color='cyan'>[Terminal]</span> <i>Copy selection (in Alacritty)</i>")
BINDINGS+=("<b>Ctrl + Shift + V</b>  <span color='cyan'>[Terminal]</span> <i>Paste from clipboard (in Alacritty)</i>")

for i in "${!LINES[@]}"; do
    line="${LINES[$i]}"
    # Check if line is a bind statement (with or without spaces around =)
    if [[ $line =~ ^bind[em]?[[:space:]]*=[[:space:]]*(.+) ]]; then
        binding="${BASH_REMATCH[1]}"
        # Get comment from previous line if it exists
        if [[ $i -gt 0 ]]; then
            prev_line="${LINES[$((i-1))]}"
            if [[ $prev_line =~ ^#[[:space:]]*\[([^\]]+)\][[:space:]]*(.+) ]]; then
                category="${BASH_REMATCH[1]}"
                description="${BASH_REMATCH[2]}"
                # Parse binding: $mod, key, action, params...
                IFS=',' read -ra PARTS <<< "$binding"
                mod=$(trim "${PARTS[0]}")
                key=$(trim "${PARTS[1]}")
                action=$(trim "${PARTS[2]}")

                # Skip XF86 keys
                if [[ $key == XF86* ]]; then
                    continue
                fi

                # Rename mouse buttons
                if [[ $key == "mouse:272" ]]; then
                    key="LMB"
                elif [[ $key == "mouse:273" ]]; then
                    key="RMB"
                fi

                # Join remaining parts as command
                cmd=""
                for ((j=3; j<${#PARTS[@]}; j++)); do
                    cmd+="${PARTS[$j]},"
                done
                cmd="${cmd%,}"

                BINDINGS+=("<b>$mod + $key</b>  <span color='cyan'>[$category]</span> <i>$description</i>")
            fi
        fi
    fi
done

CHOICE=$(printf '%s\n' "${BINDINGS[@]}" | rofi -dmenu -i -markup-rows -p "Hyprland Keybinds" -no-custom)

