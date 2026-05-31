#!/usr/bin/env bash
# crash-forensics-setup.sh — maximize what survives a hard crash/hang.
#
# The telemetry in crash-hunt.sh is fsync'd to disk so it survives, but the final
# KERNEL oops/panic usually does NOT (journald dies with the system). This wires up
# three independent capture paths so the next crash is actually diagnosable:
#
#   1. pstore-on-oops  — kernel dumps dmesg to EFI/ramoops pstore on oops; survives reboot.
#   2. netconsole      — streams the kernel log over UDP to another box (your Proxmox),
#                        catching messages emitted in the instant before a freeze.
#   3. rasdaemon       — persistently logs MCE / PCIe-AER hardware errors (else invisible).
#
# Run with sudo. NON-persistent across reboot unless you pass --persist (writes sysctl
# drop-in + systemd units). Netconsole needs your Proxmox IP + a listener there.
#
# Usage:
#   sudo bash crash-forensics-setup.sh                         # pstore-on-oops only (this boot)
#   sudo bash crash-forensics-setup.sh --netconsole 192.168.1.X
#   sudo bash crash-forensics-setup.sh --netconsole 192.168.1.X --persist
#   sudo bash crash-forensics-setup.sh --collect               # gather pstore after a crash
#
# On the Proxmox box, listen with:   nc -u -l -p 6666 | tee netconsole-$(date +%F).log

set -uo pipefail
[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }

NETCON_IP=""; PERSIST=0; COLLECT=0; PORT=6666
while [ $# -gt 0 ]; do
    case "$1" in
        --netconsole) NETCON_IP="$2"; shift 2 ;;
        --persist)    PERSIST=1; shift ;;
        --collect)    COLLECT=1; shift ;;
        *) echo "unknown arg: $1" >&2; exit 2 ;;
    esac
done

# ---- collect previously captured crash data ----
if (( COLLECT )); then
    DEST="/home/${SUDO_USER:-$USER}/crash-hunt-logs/pstore-$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$DEST"
    if compgen -G "/sys/fs/pstore/*" >/dev/null; then
        cp -a /sys/fs/pstore/* "$DEST"/ && echo "pstore -> $DEST"
        echo "(clear with: rm /sys/fs/pstore/*  — frees the limited backend)"
    else
        echo "pstore empty — no kernel crash dump captured."
    fi
    command -v ras-mc-ctl >/dev/null && { echo "=== rasdaemon errors ==="; ras-mc-ctl --errors; }
    chown -R "${SUDO_USER:-$USER}" "$DEST" 2>/dev/null || true
    exit 0
fi

# ---- 1. pstore-on-oops: capture an oops to persistent store, then reboot ----
echo "[pstore] backend:"; mount | grep -i pstore || echo "  (no pstore mounted — check efi_pstore/ramoops)"
sysctl -w kernel.panic_on_oops=1
sysctl -w kernel.panic=10           # reboot 10s after panic (so pstore is written)
echo "[pstore] panic_on_oops=1, panic=10 (this boot)"

# ---- 2. netconsole -> remote listener ----
if [ -n "$NETCON_IP" ]; then
    GW_IF=$(ip route show default | awk '{print $5; exit}')
    SRC_IP=$(ip -4 addr show "$GW_IF" | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
    GW_MAC=$(ip neigh show "$NETCON_IP" | awk '{print $5; exit}')
    [ -z "$GW_MAC" ] && { ping -c1 -W1 "$NETCON_IP" >/dev/null 2>&1; GW_MAC=$(ip neigh show "$NETCON_IP" | awk '{print $5; exit}'); }
    if [ -z "$GW_MAC" ]; then
        echo "[netconsole] could not resolve MAC for $NETCON_IP — is it up/on-LAN?" >&2
    else
        modprobe netconsole "netconsole=@${SRC_IP}/${GW_IF},${PORT}@${NETCON_IP}/${GW_MAC}" 2>/dev/null \
            && echo "[netconsole] streaming kernel log: ${SRC_IP}:${GW_IF} -> ${NETCON_IP}:${PORT} (${GW_MAC})" \
            || echo "[netconsole] modprobe failed (already loaded? rmmod netconsole first)" >&2
        echo "[netconsole] on $NETCON_IP run:  nc -u -l -p $PORT | tee netconsole-\$(date +%F).log"
    fi
fi

# ---- 3. rasdaemon for MCE/AER ----
if pacman -Qq rasdaemon >/dev/null 2>&1; then
    systemctl enable --now rasdaemon 2>/dev/null && echo "[rasdaemon] enabled (ras-mc-ctl --errors to read)"
else
    echo "[rasdaemon] not installed — install for MCE/AER logging:  sudo pacman -S rasdaemon"
fi

# ---- persist across reboots ----
if (( PERSIST )); then
    cat >/etc/sysctl.d/99-crash-forensics.conf <<EOF
kernel.panic_on_oops=1
kernel.panic=10
EOF
    echo "[persist] wrote /etc/sysctl.d/99-crash-forensics.conf"
    if [ -n "$NETCON_IP" ] && [ -n "${GW_MAC:-}" ]; then
        echo "options netconsole netconsole=@${SRC_IP}/${GW_IF},${PORT}@${NETCON_IP}/${GW_MAC}" \
            >/etc/modprobe.d/netconsole.conf
        echo "netconsole" >/etc/modules-load.d/netconsole.conf
        echo "[persist] netconsole will auto-load (note: src IP is static here; update if DHCP changes it)"
    fi
fi

echo "done. After a crash:  sudo bash $0 --collect"
