#!/bin/bash
set -euo pipefail

# NVMe Boot Fix Script
# Moves Docker + containerd data to ext4 on /dev/sda3 to eliminate btrfs COW churn,
# starts scrub, and disables COW on /boot for future dracut.

DEVICE="/dev/sda3"
TMP_MNT="/mnt/docker-migrate-$(date +%s)"
DATE_SUFFIX=$(date +%Y%m%d_%H%M%S)

echo "=== NVMe Boot Fix Script ==="
echo "Target: $DEVICE -> /var/lib/docker (ext4) + bind mount /var/lib/containerd"
echo ""

# --- Checks ---
if [ "$EUID" -ne 0 ]; then
    echo "ERROR: Run as root (sudo bash $0)"
    exit 1
fi

if [ ! -b "$DEVICE" ]; then
    echo "ERROR: $DEVICE does not exist"
    exit 1
fi

if findmnt -n -S "$DEVICE" >/dev/null 2>&1; then
    echo "ERROR: $DEVICE is already mounted. Aborting."
    exit 1
fi

# --- Stop services ---
echo "[1/8] Stopping Docker and containerd..."
systemctl stop docker.socket docker.service containerd.service 2>/dev/null || true

# --- Check space ---
echo "[2/8] Checking data sizes..."
DOCKER_SIZE=$(du -sb /var/lib/docker 2>/dev/null | awk '{print $1}' || echo 0)
CONTAINERD_SIZE=$(du -sb /var/lib/containerd 2>/dev/null | awk '{print $1}' || echo 0)
TOTAL_SIZE=$((DOCKER_SIZE + CONTAINERD_SIZE))
DEV_SIZE=$(blockdev --getsize64 "$DEVICE")

echo "  Docker data:     $(numfmt --to=iec "$DOCKER_SIZE")"
echo "  Containerd data: $(numfmt --to=iec "$CONTAINERD_SIZE")"
echo "  Total to move:   $(numfmt --to=iec "$TOTAL_SIZE")"
echo "  $DEVICE size:    $(numfmt --to=iec "$DEV_SIZE")"

if [ "$TOTAL_SIZE" -gt "$DEV_SIZE" ]; then
    echo "ERROR: Not enough space on $DEVICE"
    exit 1
fi

# --- Format ---
echo "[3/8] Formatting $DEVICE as ext4 (label: docker-root)..."
mkfs.ext4 -F -L docker-root -E nodiscard "$DEVICE"

# --- Mount and migrate ---
echo "[4/8] Migrating data (this may take a while)..."
mkdir -p "$TMP_MNT"
mount "$DEVICE" "$TMP_MNT"

# containerd goes into a subdirectory; docker data goes to device root
# so that mounting the device at /var/lib/docker exposes data directly
mkdir -p "$TMP_MNT/containerd"

echo "  Copying /var/lib/docker..."
rsync -aHAX --info=progress2 /var/lib/docker/ "$TMP_MNT/"

echo "  Copying /var/lib/containerd..."
rsync -aHAX --info=progress2 /var/lib/containerd/ "$TMP_MNT/containerd/"

sync
umount "$TMP_MNT"
rmdir "$TMP_MNT"

# --- Swap directories ---
echo "[5/8] Replacing old directories with mount..."
mv /var/lib/docker "/var/lib/docker.bak.$DATE_SUFFIX"
mv /var/lib/containerd "/var/lib/containerd.bak.$DATE_SUFFIX"
mkdir -p /var/lib/docker
mkdir -p /var/lib/containerd

mount "$DEVICE" /var/lib/docker
mount --bind /var/lib/docker/containerd /var/lib/containerd

# --- Update fstab ---
echo "[6/8] Updating /etc/fstab..."
cp /etc/fstab "/etc/fstab.bak.$DATE_SUFFIX"

# Remove stale entries
sed -i '\|/var/lib/docker|d' /etc/fstab
sed -i '\|/var/lib/containerd|d' /etc/fstab

UUID=$(blkid -s UUID -o value "$DEVICE")
echo "UUID=$UUID /var/lib/docker ext4 defaults,noatime 0 2" >> /etc/fstab
echo "/var/lib/docker/containerd /var/lib/containerd none bind 0 0" >> /etc/fstab

# --- Btrfs scrub ---
echo "[7/8] Starting btrfs scrub on / (runs in background)..."
btrfs scrub start /

# --- Disable COW on /boot for future dracut writes ---
echo "[8/8] Disabling COW on /boot..."
chattr +C /boot 2>/dev/null || true

# --- Start services ---
echo "Starting containerd and Docker..."
systemctl start containerd.service docker.service docker.socket

echo ""
echo "=== Done ==="
echo "Docker and containerd are now on ext4 at $DEVICE."
echo "Old data kept at:"
echo "  /var/lib/docker.bak.$DATE_SUFFIX"
echo "  /var/lib/containerd.bak.$DATE_SUFFIX"
echo ""
echo "Post-script checks:"
echo "  1. docker ps"
echo "  2. systemctl status docker containerd"
echo "  3. btrfs scrub status /"
echo ""
echo "After you confirm everything works, remove the .bak directories to free NVMe space:"
echo "  sudo rm -rf /var/lib/docker.bak.$DATE_SUFFIX /var/lib/containerd.bak.$DATE_SUFFIX"
echo ""
echo "NOTE: Before next reboot, run:"
echo "  sudo btrfs rescue zero-log /dev/nvme0n1p2"
echo "(zero-log is only safe on unmounted FS — do it right before shutdown/reboot)"
echo ""
echo "WARNING: Do NOT run 'dracut --force --regenerate-all' right now."
echo "         Existing /boot initramfs files still have COW enabled."
echo "         If you need to regenerate initramfs, do it when the system is idle"
echo "         and be ready to REISUB if it hangs."
