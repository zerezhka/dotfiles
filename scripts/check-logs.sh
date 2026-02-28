#!/bin/bash
# check-logs.sh — system crash/hang investigation tool
# Usage:
#   sudo check-logs.sh          # summarize previous boot
#   sudo check-logs.sh -b -2    # specific boot index
#   sudo check-logs.sh --list   # list all boots
#   sudo check-logs.sh --all    # scan all boots for crashes
#   sudo check-logs.sh --cores  # show coredumps

RED='\033[0;31m'
YEL='\033[1;33m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BLD='\033[1m'
RST='\033[0m'

BOOT=-1

list_boots() {
    echo -e "${BLD}=== Boot History ===${RST}"
    journalctl --list-boots --no-pager | while read idx id first last; do
        # check if ended cleanly: look for systemd shutdown/poweroff in last 30 lines
        clean=$(journalctl -b "$idx" --no-pager 2>/dev/null | tail -30 \
            | grep -c "Reached target.*Shutdown\|Unmounted /home\|Deactivated swap\|systemd-poweroff\|systemd-halt\|systemd-reboot")
        if [ "$clean" -gt 0 ]; then
            status="${GRN}clean${RST}"
        else
            status="${RED}UNCLEAN${RST}"
        fi
        printf "  %4s  %s  →  %s  [%b]\n" "$idx" "$first $first_time" "$last" "$status"
    done
}

scan_boot() {
    local b=$1
    local info
    info=$(journalctl --list-boots --no-pager 2>/dev/null | awk -v b="$b" '$1==b')
    local first last
    first=$(echo "$info" | awk '{print $3, $4}')
    last=$(echo "$info" | awk '{print $5, $6}')

    echo -e "\n${BLD}${CYN}=== Boot $b  |  $first → $last ===${RST}"

    # --- shutdown type ---
    local clean
    clean=$(journalctl -b "$b" --no-pager 2>/dev/null | tail -30 \
        | grep -c "Reached target.*Shutdown\|Unmounted /home\|Deactivated swap\|systemd-poweroff\|systemd-halt\|systemd-reboot")
    if [ "$clean" -gt 0 ]; then
        echo -e "  Shutdown: ${GRN}clean${RST}"
    else
        echo -e "  Shutdown: ${RED}UNCLEAN (hard reboot / hang)${RST}"
    fi

    # --- kernel crashes ---
    local crashes
    crashes=$(journalctl -b "$b" --no-pager 2>/dev/null \
        | grep -E "BUG: kernel|Oops:|kernel NULL pointer|irqs disabled|hard LOCKUP|soft lockup|NMI: IOCK|Kernel panic")
    if [ -n "$crashes" ]; then
        echo -e "\n  ${RED}${BLD}[KERNEL CRASH]${RST}"
        echo "$crashes" | while IFS= read -r line; do
            echo -e "  ${RED}$line${RST}"
        done
    fi

    # --- OOM kills ---
    local ooms
    ooms=$(journalctl -b "$b" --no-pager 2>/dev/null \
        | grep -E "oom_kill|Out of memory:|Killed process" | head -5)
    if [ -n "$ooms" ]; then
        echo -e "\n  ${YEL}[OOM KILLS]${RST}"
        echo "$ooms" | while IFS= read -r line; do
            echo -e "  ${YEL}$line${RST}"
        done
    fi

    # --- hung tasks ---
    local hung
    hung=$(journalctl -b "$b" --no-pager 2>/dev/null \
        | grep "hung_task_timeout\|task.*blocked.*more than" | head -5)
    if [ -n "$hung" ]; then
        echo -e "\n  ${YEL}[HUNG TASKS]${RST}"
        echo "$hung" | head -3 | while IFS= read -r line; do
            echo -e "  ${YEL}$line${RST}"
        done
    fi

    # --- btrfs errors ---
    local btrfs
    btrfs=$(journalctl -b "$b" --no-pager 2>/dev/null \
        | grep -i "btrfs.*error\|btrfs.*corruption\|btrfs.*bad\|list_del corruption" | head -5)
    if [ -n "$btrfs" ]; then
        echo -e "\n  ${RED}[BTRFS ERRORS]${RST}"
        echo "$btrfs" | while IFS= read -r line; do
            echo -e "  ${RED}$line${RST}"
        done
    fi

    # --- nvidia / gpu ---
    local gpu
    gpu=$(journalctl -b "$b" --no-pager 2>/dev/null \
        | grep -iE "nvidia.*error|gpu.*hang|Xid.*error" | head -5)
    if [ -n "$gpu" ]; then
        echo -e "\n  ${YEL}[GPU ERRORS]${RST}"
        echo "$gpu" | while IFS= read -r line; do
            echo -e "  ${YEL}$line${RST}"
        done
    fi

    # --- failed services ---
    local failed
    failed=$(journalctl -b "$b" --no-pager 2>/dev/null \
        | grep "Failed to start\|failed with result" \
        | grep -v "clawdbot\|reverse-ssh\|xdg-desktop-portal" | head -5)
    if [ -n "$failed" ]; then
        echo -e "\n  ${YEL}[FAILED SERVICES]${RST}"
        echo "$failed" | while IFS= read -r line; do
            echo -e "  ${YEL}$line${RST}"
        done
    fi

    # --- last 5 lines ---
    echo -e "\n  ${BLD}[Last journal entries]${RST}"
    journalctl -b "$b" --no-pager 2>/dev/null | tail -5 | while IFS= read -r line; do
        echo "  $line"
    done
}

scan_all() {
    echo -e "${BLD}=== Scanning all boots for issues ===${RST}\n"
    journalctl --list-boots --no-pager 2>/dev/null | awk '{print $1}' | while read idx; do
        issues=""
        log=$(journalctl -b "$idx" --no-pager 2>/dev/null)

        echo "$log" | grep -qE "BUG: kernel|Oops:|kernel NULL pointer|Kernel panic" && issues+="CRASH "
        echo "$log" | grep -qE "oom_kill|Killed process" && issues+="OOM "
        echo "$log" | grep -qi "btrfs.*error\|list_del corruption" && issues+="BTRFS "
        echo "$log" | grep -qE "hung_task_timeout|task.*blocked.*more than" && issues+="HUNG "

        clean=$(echo "$log" | tail -30 \
            | grep -c "Reached target.*Shutdown\|Unmounted /home\|systemd-poweroff\|systemd-halt\|systemd-reboot")
        [ "$clean" -eq 0 ] && issues+="UNCLEAN "

        if [ -n "$issues" ]; then
            info=$(journalctl --list-boots --no-pager 2>/dev/null | awk -v b="$idx" '$1==b')
            first=$(echo "$info" | awk '{print $3, $4}')
            last=$(echo "$info" | awk '{print $5, $6}')
            printf "  %4s  %-35s  ${RED}%s${RST}\n" "$idx" "$first → $last" "$issues"
        fi
    done
}

show_cores() {
    echo -e "${BLD}=== Coredumps ===${RST}"
    coredumpctl list 2>/dev/null || echo "  coredumpctl not available or no dumps"
}

# --- main ---
case "${1:-}" in
    --list)   list_boots ;;
    --all)    scan_all ;;
    --cores)  show_cores ;;
    -b)       BOOT="${2:--1}"; scan_boot "$BOOT" ;;
    *)        scan_boot "$BOOT" ;;
esac
