#!/bin/bash

set -e

EMMC_EFI="/mnt/efi_emmc"
BOOT_DIR="${EMMC_EFI}/EFI/Microsoft/Boot"
GRUB_EFI="/tmp/grub_minimal/bootx64.efi"

echo "Installing minimal GRUB to eMMC..."
echo "This will replace Windows bootloader with GRUB (original backed up as bootmgfw_original.efi)"
echo ""

if [ ! -d "${EMMC_EFI}" ]; then
    echo "Creating mount point ${EMMC_EFI}..."
    sudo mkdir -p "${EMMC_EFI}"
fi

if ! mountpoint -q "${EMMC_EFI}"; then
    echo "Mounting eMMC EFI partition..."
    sudo mount /dev/mmcblk1p1 "${EMMC_EFI}"
fi

if [ ! -f "${BOOT_DIR}/bootmgfw_original.efi" ]; then
    echo "ERROR: bootmgfw_original.efi not found!"
    echo "This backup should exist. Something is wrong."
    exit 1
fi

if [ ! -f "${GRUB_EFI}" ]; then
    echo "ERROR: GRUB bootloader not found at ${GRUB_EFI}"
    exit 1
fi

if [ ! -d "${EMMC_EFI}" ] || [ ! -d "${BOOT_DIR}" ]; then
    echo "ERROR: eMMC EFI partition not mounted at ${EMMC_EFI}"
    exit 1
fi

echo "Backing up current bootmgfw.efi to bootmgfw.efi.backup..."
cp -v "${BOOT_DIR}/bootmgfw.efi" "${BOOT_DIR}/bootmgfw.efi.backup"

echo ""
echo "Installing GRUB as bootmgfw.efi..."
cp -v "${GRUB_EFI}" "${BOOT_DIR}/bootmgfw.efi"

echo ""
echo "Syncing filesystems..."
sync

echo ""
echo "Installation complete!"
echo ""
echo "Your boot menu will now show:"
echo "  1. SSD GRUB - chainloads to your full GRUB on SSD"
echo "  2. Windows 10 - boots Windows from bootmgfw_original.efi"
echo "  3. UEFI Firmware Settings"
echo "  4. Reboot"
echo "  5. Shutdown"
echo ""
echo "The SSD GRUB option will fail gracefully if SSD is removed."
echo "You can remove/reinstall the SSD at any time."
echo ""
echo "To revert: sudo cp ${BOOT_DIR}/bootmgfw_original.efi ${BOOT_DIR}/bootmgfw.efi"

