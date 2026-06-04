#!/usr/bin/env bash
# Hyprland keybind cheatsheet via rofi.
#
# Parses ~/.config/hypr/hyprland.conf and shows every bind that carries a
# "# [Category] Description" annotation, grouped/sorted by category. The
# annotation is "sticky": it applies to every following bind line until a blank
# line or a non-bind statement (e.g. `submap`) resets it — so blocks like the
# ten workspace binds only need one comment.
#
# Press Enter on a row to actually run that binding (via `hyprctl dispatch`);
# Esc just closes.

HYPR_CONF="$HOME/.config/hypr/hyprland.conf"

trim() {
    local v="$*"
    v="${v#"${v%%[![:space:]]*}"}"
    v="${v%"${v##*[![:space:]]}"}"
    printf '%s' "$v"
}

pretty_key() {
    case "$1" in
        mouse:272)            echo "LMB" ;;
        mouse:273)            echo "RMB" ;;
        mouse:274)            echo "MMB" ;;
        semicolon)            echo ";" ;;
        XF86AudioRaiseVolume) echo "Vol Up" ;;
        XF86AudioLowerVolume) echo "Vol Down" ;;
        XF86AudioMute)        echo "Mute" ;;
        XF86AudioPlay)        echo "Play/Pause" ;;
        XF86*)                echo "${1#XF86}" ;;
        *)                    echo "$1" ;;
    esac
}

declare -A CMD_OF
ROWS=()
cat="" ; desc=""

while IFS= read -r line || [[ -n $line ]]; do
    # blank line ends the current annotation block
    if [[ -z ${line//[[:space:]]/} ]]; then
        cat="" ; desc="" ; continue
    fi
    # "# [Category] Description" sets the sticky annotation
    if [[ $line =~ ^[[:space:]]*#[[:space:]]*\[([^]]+)\][[:space:]]*(.*) ]]; then
        cat="${BASH_REMATCH[1]}" ; desc="$(trim "${BASH_REMATCH[2]}")" ; continue
    fi
    # any other comment line while an annotation is active = a wrapped
    # continuation of the description; append it
    if [[ $line =~ ^[[:space:]]*# ]]; then
        if [[ -n $cat ]]; then
            extra=$(trim "${line#*#}")
            [[ -n $extra ]] && desc="$desc $extra"
        fi
        continue
    fi
    # bind / binde / bindr / bindm
    if [[ $line =~ ^bind[emr]?[[:space:]]*=[[:space:]]*(.+) ]]; then
        [[ -z $cat ]] && continue
        IFS=',' read -ra P <<< "${BASH_REMATCH[1]}"
        mods=$(trim "${P[0]}")
        mods="${mods//\$mod/Super}"
        mods="${mods//SHIFT/Shift}" ; mods="${mods//CTRL/Ctrl}" ; mods="${mods//ALT/Alt}"
        key=$(pretty_key "$(trim "${P[1]}")")
        action=$(trim "${P[2]}")
        params=""
        for ((j = 3; j < ${#P[@]}; j++)); do params+="${P[$j]},"; done
        params=$(trim "${params%,}")

        # turn "... 1-10" range comments into the real per-key target
        case "$action" in
            workspace | movetoworkspace) rowdesc="${desc//1-10/$params}" ;;
            *)                           rowdesc="$desc" ;;
        esac

        if [[ -n $mods ]]; then combo="$mods + $key"; else combo="$key"; fi
        display="<b>$combo</b>  <span color='cyan'>[$cat]</span> <i>$rowdesc</i>"
        ROWS+=("$cat	$display")
        CMD_OF["$display"]="$action	$params"
        continue
    fi
    # any other statement (submap, exec-once, ...) ends the block
    cat="" ; desc=""
done < "$HYPR_CONF"

# Terminal-local shortcuts (handled by Alacritty, not Hyprland binds)
ROWS+=("Terminal	<b>Ctrl + Shift + C</b>  <span color='cyan'>[Terminal]</span> <i>Copy selection (Alacritty)</i>")
ROWS+=("Terminal	<b>Ctrl + Shift + V</b>  <span color='cyan'>[Terminal]</span> <i>Paste clipboard (Alacritty)</i>")

# sort by category (stable, keeps file order within a category), drop sort key
MENU=$(printf '%s\n' "${ROWS[@]}" | sort -s -t$'\t' -k1,1 | cut -f2- | awk '!seen[$0]++')

CHOICE=$(printf '%s\n' "$MENU" | rofi -dmenu -i -markup-rows -no-custom -p "Keybinds")
[[ -z $CHOICE ]] && exit 0

cmd="${CMD_OF[$CHOICE]}"
action="${cmd%%	*}"
params="${cmd#*	}"
[[ -z $action ]] && exit 0   # e.g. terminal-local rows have nothing to dispatch

if [[ -n $params ]]; then
    hyprctl dispatch "$action" "$params"
else
    hyprctl dispatch "$action"
fi
