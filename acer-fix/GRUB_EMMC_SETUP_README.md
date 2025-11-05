# Minimal GRUB Installation for eMMC Boot

## Problem Solved
- efibootmgr doesn't save boot order changes
- UEFI setup hangs when SSD is installed
- Need to press F12 every boot to select boot device

## Solution
Replace Windows bootloader (bootmgfw.efi) with a minimal GRUB that:
1. Boots to GRUB menu by default (no F12 needed)
2. Can chainload to SSD GRUB (your full Arch Linux GRUB)
3. Can boot Windows from backed-up bootmgfw_original.efi
4. Works whether SSD is installed or not

## What Was Created

### 1. Minimal GRUB Bootloader (4.2M)
- Location: `/tmp/grub_minimal/bootx64.efi`
- No themes, minimal modules only
- Embedded configuration (no separate grub.cfg needed)

### 2. Boot Menu Options
1. **SSD GRUB** - Default option
   - Searches for SSD by UUID (EC46-6293)
   - Chainloads to your full GRUB on /dev/sda1
   - Shows error message if SSD is not found
   - Falls back to menu on error

2. **Windows 10**
   - Boots Windows from bootmgfw_original.efi

3. **UEFI Firmware Settings**
4. **Reboot**
5. **Shutdown**

### 3. Installation Scripts

#### Verification Script
- Location: `/tmp/verify_grub_setup.sh`
- Checks all prerequisites before installation
- Already run and passed all checks

#### Installation Script
- Location: `/tmp/install_grub_emmc.sh`
- Backs up current bootmgfw.efi
- Installs GRUB as bootmgfw.efi
- Preserves bootmgfw_original.efi

## Installation

### Option 1: From dotfiles repo (recommended)

```bash
cd ~/Projects/dotfiles/acer-fix
sudo ./install_grub_emmc_from_repo.sh
```

### Option 2: From /tmp

```bash
sudo /tmp/install_grub_emmc.sh
```

Both scripts do the same thing, but the repo version uses the bootloader from this directory.

## What Happens After Installation

1. **Normal boot (SSD installed)**:
   - BIOS loads bootmgfw.efi (which is now GRUB)
   - GRUB menu appears with 10 second timeout
   - Default: SSD GRUB is chainloaded
   - Your full GRUB on SSD takes over
   - You get your normal Arch Linux boot with themes

2. **SSD removed**:
   - BIOS loads bootmgfw.efi (GRUB)
   - GRUB menu appears
   - SSD GRUB option shows "SSD not found" error
   - Press any key to return to menu
   - Select Windows to boot
   - Laptop still works perfectly

3. **Windows boot**:
   - Select "Windows 10" from GRUB menu
   - GRUB chainloads bootmgfw_original.efi
   - Windows boots normally

## Benefits

✓ No more F12 spam on every boot
✓ Default boot to Linux (via GRUB chainload)
✓ Works with or without SSD
✓ Can move SSD to another PC
✓ Windows still bootable from menu
✓ Only 4.2M space used on eMMC
✓ No UEFI firmware changes needed

## Safety

- Original Windows bootloader backed up as `bootmgfw_original.efi`
- Current bootmgfw.efi backed up as `bootmgfw.efi.backup`
- To revert to Windows-only boot:
  ```bash
  sudo cp /mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw_original.efi \
         /mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw.efi
  ```

## Technical Details

### Files Created
- `/tmp/grub_minimal/bootx64.efi` - Standalone GRUB bootloader (4.2M)
- `/tmp/grub_minimal/boot/grub/grub.cfg` - Embedded configuration

### Installation Location
- Target: `/mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw.efi`
- Backup: `/mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw.efi.backup`
- Original: `/mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw_original.efi` (already exists)

### GRUB Modules Included
- part_gpt, part_msdos - Partition table support
- fat, ext2, ntfs - Filesystem support
- chain - Chainloading support
- boot, linux - Boot support
- configfile, normal - GRUB core
- search, search_fs_uuid - Device search

### Space Usage
- eMMC EFI partition: 96M total, 70M available
- GRUB bootloader: 4.2M
- After installation: ~66M available

## Troubleshooting

### If boot fails
1. System should still show GRUB menu
2. Try "Windows 10" option
3. If GRUB doesn't load, use F12 to select "Windows Boot Manager"

### If SSD GRUB fails
- Normal if SSD is removed
- Menu will show error and return to menu
- Select Windows or other option

### To reinstall
```bash
sudo /tmp/install_grub_emmc.sh
```

### To revert completely
```bash
sudo cp /mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw_original.efi \
       /mnt/efi_emmc/EFI/Microsoft/Boot/bootmgfw.efi
```

## Testing Plan

After installation, test these scenarios:

1. **With SSD installed**:
   - Reboot
   - Should see GRUB menu
   - Wait for timeout or press Enter
   - Should chainload to SSD GRUB
   - Boot Arch Linux

2. **Test Windows boot**:
   - Reboot
   - Select "Windows 10" from GRUB menu
   - Windows should boot

3. **Without SSD** (optional, test later):
   - Shutdown
   - Remove SSD
   - Boot
   - GRUB menu appears
   - Try SSD GRUB option (will fail gracefully)
   - Boot Windows

4. **SSD portability** (optional):
   - Remove SSD
   - Install in another PC
   - Should boot Arch Linux normally
   - Return SSD to laptop
   - Should still work

## Files Summary

Created files (safe to delete after installation):
- `/tmp/grub_minimal/` - Build directory
- `/tmp/install_grub_emmc.sh` - Installation script
- `/tmp/verify_grub_setup.sh` - Verification script
- `/tmp/GRUB_EMMC_SETUP_README.md` - This file

Keep these for reference or delete after confirming everything works.

