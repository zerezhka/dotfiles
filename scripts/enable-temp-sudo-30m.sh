#!/usr/bin/env bash
# Enable temporary (30m) passwordless sudo for a small allowlist.
# This is useful for agent-assisted setup (e.g., installing ollama).
#
# What it does:
#  - writes /etc/sudoers.d/openclaw-temp (NOPASSWD for pacman+systemctl)
#  - validates it with visudo
#  - schedules auto-removal in 30 minutes via systemd-run
#
# Usage:
#   ./enable-temp-sudo-30m.sh
#   ./enable-temp-sudo-30m.sh 45m   # optional custom TTL

set -euo pipefail

TTL="${1:-30m}"
SUDOERS_FILE="/etc/sudoers.d/openclaw-temp"

if [[ $EUID -ne 0 ]]; then
  echo "This script needs to run with sudo/root." >&2
  echo "Run: sudo $0 $TTL" >&2
  exit 1
fi

echo "[1/3] Writing $SUDOERS_FILE"
cat >"$SUDOERS_FILE" <<'EOF'
# TEMP: allow passwordless sudo for a small allowlist (auto-removed).
sergey ALL=(root) NOPASSWD: /usr/bin/pacman, /usr/bin/systemctl
EOF
chmod 440 "$SUDOERS_FILE"

echo "[2/3] Validating sudoers include"
visudo -cf "$SUDOERS_FILE"

echo "[3/3] Scheduling auto-removal in $TTL"
# transient unit that will delete the sudoers file after TTL
systemd-run --on-active="$TTL" --unit revoke-openclaw-temp-sudo \
  /usr/bin/rm -f "$SUDOERS_FILE"

echo
echo "OK. Temporary sudo allowlist is active until ~${TTL}."
echo "Check timer: systemctl list-timers | grep revoke-openclaw-temp-sudo"
echo "Revoke now:  sudo rm -f $SUDOERS_FILE"
