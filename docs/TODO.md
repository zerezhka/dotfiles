# TODO

## Tomorrow — Clean Arch Install from EndeavourOS ISO

Try fresh Arch install to rule out accumulated config/package debt as hang cause.

### Plan
- Boot EndeavourOS ISO
- Install Arch (not EndeavourOS) manually or via archinstall
- Filesystem: btrfs (keep, but without discard=async) or try ext4
- Kernel: stable `linux` (not zen)
- Driver: nvidia-open-dkms
- Restore dotfiles via setup.sh

### Current hang investigation status
See `~/.claude/projects/-home-sergey-Projects-dotfiles/memory/system-hangs.md`

**Already done on current system:**
- Switched default kernel: linux-zen → stable linux
- Added `nodiscard` to all btrfs fstab entries (fstrim.timer handles TRIM)
- nvidia-open-dkms 590.48.01 confirmed correct for RTX 3080

**Root cause clue:** btrfs list_del corruption in add_delayed_ref (CVE-2024-50273 related), triggered under heavy NVMe COW load on linux-zen 6.18.9
