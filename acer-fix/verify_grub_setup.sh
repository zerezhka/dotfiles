#!/bin/bash

EMMC_EFI="/mnt/efi_emmc"
BOOT_DIR="${EMMC_EFI}/EFI/Microsoft/Boot"
GRUB_EFI="/tmp/grub_minimal/bootx64.efi"

echo "=== Pre-installation verification ==="
echo ""

if [ ! -d "${EMMC_EFI}" ]; then
    echo "Creating mount point ${EMMC_EFI}..."
    sudo mkdir -p "${EMMC_EFI}"
fi

if ! mountpoint -q "${EMMC_EFI}"; then
    echo "Mounting eMMC EFI partition..."
    sudo mount /dev/mmcblk1p1 "${EMMC_EFI}"
fi

echo "1. Checking eMMC EFI partition..."
if [ -d "${EMMC_EFI}" ]; then
    df -h "${EMMC_EFI}" | tail -1
    echo "✓ eMMC EFI partition is mounted"
else
    echo "✗ eMMC EFI partition not mounted"
    exit 1
fi

echo ""
echo "2. Checking Windows boot files..."
if [ -f "${BOOT_DIR}/bootmgfw_original.efi" ]; then
    ls -lh "${BOOT_DIR}/bootmgfw_original.efi"
    echo "✓ Original Windows bootloader backup exists"
else
    echo "✗ bootmgfw_original.efi not found"
    exit 1
fi

echo ""
echo "3. Checking current bootmgfw.efi..."
if [ -f "${BOOT_DIR}/bootmgfw.efi" ]; then
    ls -lh "${BOOT_DIR}/bootmgfw.efi"
    CURRENT_SIZE=$(stat -c%s "${BOOT_DIR}/bootmgfw.efi")
    ORIGINAL_SIZE=$(stat -c%s "${BOOT_DIR}/bootmgfw_original.efi")
    if [ "$CURRENT_SIZE" -eq "$ORIGINAL_SIZE" ]; then
        echo "✓ Current bootmgfw.efi appears to be Windows bootloader"
    else
        echo "⚠ Current bootmgfw.efi differs from original (might already be GRUB)"
    fi
else
    echo "✗ bootmgfw.efi not found"
    exit 1
fi

echo ""
echo "4. Checking GRUB bootloader..."
if [ -f "${GRUB_EFI}" ]; then
    ls -lh "${GRUB_EFI}"
    file "${GRUB_EFI}"
    echo "✓ Minimal GRUB bootloader ready"
else
    echo "✗ GRUB bootloader not found"
    exit 1
fi

echo ""
echo "5. Checking SSD..."
if [ -d "/boot/grub" ]; then
    echo "✓ SSD GRUB installation found at /boot/grub"
    SSD_UUID=$(lsblk -no UUID /dev/sda1 2>/dev/null || echo "unknown")
    echo "  SSD EFI partition UUID: ${SSD_UUID}"
else
    echo "⚠ SSD GRUB not found (this is OK if SSD is removed)"
fi

echo ""
echo "6. Checking available space..."
AVAILABLE=$(df -BM "${EMMC_EFI}" | tail -1 | awk '{print $4}' | sed 's/M//')
NEEDED=5
if [ "$AVAILABLE" -gt "$NEEDED" ]; then
    echo "✓ Sufficient space available (${AVAILABLE}M > ${NEEDED}M needed)"
else
    echo "✗ Insufficient space (${AVAILABLE}M available, ${NEEDED}M needed)"
    exit 1
fi

echo ""
echo "=== All checks passed! ==="
echo ""
echo "You can now run: sudo /tmp/install_grub_emmc.sh"

