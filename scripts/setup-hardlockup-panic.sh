#!/bin/bash
# setup-hardlockup-panic.sh — auto-reboot on hard lockup (kernel freeze)
# Solves: USB keyboard can't trigger REISUB during a hard lockup
# Run with: sudo setup-hardlockup-panic

CONF=/etc/sysctl.d/99-hardlockup.conf

cat > "$CONF" << 'EOF'
# Auto-reboot on hard lockup (NMI watchdog detects frozen CPU)
# Needed because USB keyboards can't trigger SysRq during a hard lockup
kernel.hardlockup_panic=1
kernel.panic=10
EOF

sysctl -p "$CONF"

echo ""
echo "Applied:"
echo "  hardlockup_panic = $(cat /proc/sys/kernel/hardlockup_panic)"
echo "  panic (reboot delay) = $(cat /proc/sys/kernel/panic)s"
echo ""
echo "On next hard lockup: NMI watchdog fires → kernel panic → reboot in 10s"
