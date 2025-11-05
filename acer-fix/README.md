# Acer Laptop Boot Fix

## Problem

This laptop has a buggy UEFI firmware that:
- Doesn't save boot order changes made with `efibootmgr`
- Hangs when entering UEFI setup with SATA SSD installed
- Requires pressing F12 on every boot to select boot device

## Solution

Replace the Windows bootloader on eMMC with a minimal GRUB that provides a boot menu, allowing:
- Default boot to Linux (via SSD GRUB chainload)
- Boot to Windows when needed
- Portable SSD that can be removed and used in other machines
- No firmware modifications needed

## Files

- `bootx64.efi` - Minimal GRUB bootloader (4.2M, with embedded config)
- `grub.cfg` - Source GRUB configuration (for reference)
- `install_grub_emmc_from_repo.sh` - Installation script (use this)
- `install_grub_emmc.sh` - Installation script (legacy /tmp version)
- `verify_grub_setup.sh` - Pre-installation verification
- `GRUB_EMMC_SETUP_README.md` - Detailed documentation

## Quick Start

### 1. Verify Prerequisites

```bash
cd ~/Projects/dotfiles/acer-fix
./verify_grub_setup.sh
```

### 2. Install

```bash
sudo ./install_grub_emmc_from_repo.sh
```

### 3. Reboot

You should see a GRUB menu with:
- SSD GRUB - Default
- Windows 10
- UEFI Firmware Settings
- Reboot / Shutdown

## Boot Behavior

### With SSD Installed
1. GRUB menu appears
2. Default: SSD GRUB chainloads
3. Your full GRUB with themes loads
4. Boot Arch Linux normally

### Without SSD
1. GRUB menu appears
2. SSD option shows error if selected
3. Select Windows to boot
4. System works normally

## Revert

If you need to restore Windows-only boot:

```bash
sudo cp /mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw_original.efi \
       /mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw.efi
```

## Technical Details

See `GRUB_EMMC_SETUP_README.md` for complete documentation.

### What Gets Modified

- `/mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw.efi` - Replaced with GRUB
- Backups created:
  - `bootmgfw.efi.backup` - Current file before installation
  - `bootmgfw_original.efi` - Original Windows bootloader (already exists)

### Space Usage

- eMMC EFI partition: 96M total
- GRUB bootloader: 4.2M
- Plenty of space remaining

## Rebuild (if needed)

If you need to regenerate the bootloader with different settings:

```bash
cd /tmp
mkdir -p grub_minimal/boot/grub

# Edit configuration
nano grub_minimal/boot/grub/grub.cfg

# Build standalone GRUB
grub-mkstandalone \
  -d /usr/lib/grub/x86_64-efi \
  -O x86_64-efi \
  --modules="part_gpt part_msdos fat ext2 ntfs chain boot linux configfile normal search search_fs_uuid" \
  --fonts="" \
  --locales="" \
  --themes="" \
  -o bootx64.efi \
  boot/grub/grub.cfg

# Copy to repo
cp bootx64.efi ~/Projects/dotfiles/acer-fix/
```

## Status

✅ Minimal GRUB created (4.2M)  
✅ Configuration tested  
✅ Scripts ready  
✅ Documentation complete  
⏳ **Ready to install** - Run `sudo ./install_grub_emmc_from_repo.sh`  
⏳ **Needs testing** - Reboot after installation to verify


