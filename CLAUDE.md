# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal Arch Linux dotfiles repository managing configurations for i3/Sway window managers, system services, and environment setup. The repository tracks configuration files that are typically symlinked to their proper locations in the home directory.

## Architecture

### Window Manager Setup (Dual Environment)

The repository supports **both X11 (i3) and Wayland (Sway)** environments with parallel configurations:

- **i3 (X11)**: `.config/i3/config` - X11-based tiling window manager
- **Sway (Wayland)**: `.config/sway/config` - Wayland compositor (i3-compatible)

Both environments share similar keybindings and workflow but have environment-specific configurations:
- Screenshot tools: `xfce4-screenshooter` (i3) vs `grim + slurp` (Sway)
- Lock screen: `light-locker` (i3) vs `swaylock` (Sway)
- Background: `feh` (i3) vs `swaybg` (Sway)
- Status bar: Both use `i3status-rust` with separate config files

### Environment Configuration

Environment variables are managed in multiple locations for different session types:

1. **`.config/environment.d/wayland.conf`**: Wayland/Sway session variables
   - Sets Electron apps to use Wayland (`ELECTRON_OZONE_PLATFORM_HINT=wayland`)
   - Configures Qt, Firefox for native Wayland
   - Uses Vulkan renderer for Sway

2. **`environment`**: Global X11/i3 environment variables
   - Sets `BROWSER=chromium`, desktop session variables
   - Adds `~/.local/bin` to PATH

3. **`.xprofile`**: X11 session startup (loaded by display managers)
   - Conditional i3-specific setup
   - Keyboard layout initialization

### Keyboard Layout Management

Persistent keyboard layout (US/RU with Alt+Shift toggle) is a **critical issue** that breaks after system upgrades. Multiple fallback mechanisms:

1. Sway: Built-in `input type:keyboard` config (`.config/sway/config:9-12`)
2. i3: Multiple redundant calls to `setxkbmap` in config and `.xprofile`
3. Systemd service: `.config/systemd/user/keyboard-layout.service` (i3 only)
4. Helper script: `.local/bin/setup-keyboard-layout`

### Helper Scripts

**`.config/{i3,sway}/scripts/show_notification.sh`**: Unified notification system for brightness, volume, battery, wifi status. Uses `dunstify` with replacement ID 9999 to avoid notification spam.

**`.config/{i3,sway}/scripts/dmenu-logout.sh`**: Session logout menu

**`.local/bin/xdg-open`**: Custom xdg-open replacement that directly launches Chromium for URLs, avoiding slow D-Bus lookups in i3 (performance optimization)

### Package Management

- **`pkglist.txt`**: Official Arch packages (128 packages)
- **`pkglist-aur.txt`**: AUR packages (70 packages, heavily includes GRUB themes)

To restore packages on a new system:
```bash
sudo pacman -S --needed - < pkglist.txt
yay -S --needed - < pkglist-aur.txt
```

### GRUB Configuration

**`grub/default`**: GRUB bootloader config with Vimix theme

To apply on new system:
```bash
yay -S grub-theme-vimix-whitesur-1080p-git
sudo cp grub/default /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Key Commands

### Window Manager Operations

**Reload i3 config:**
```bash
i3-msg reload  # or Mod4+Shift+c
```

**Reload Sway config:**
```bash
swaymsg reload  # or Mod4+Shift+c
```

**Test notification system:**
```bash
~/.config/i3/scripts/show_notification.sh volume +5%
~/.config/sway/scripts/show_notification.sh brightness +10%
```

### Git Operations

This repository uses standard git workflow. Current status shows:
- Modified: `.config/sway/config`
- Deleted: `.local/share/applications/cursor.desktop`
- Untracked: `.config/environment.d/`

### Package List Updates

When updating package lists after installing/removing software:
```bash
pacman -Qqe | grep -v "$(pacman -Qqm)" > pkglist.txt
pacman -Qqm > pkglist-aur.txt
```

## Important Implementation Notes

### When Editing Window Manager Configs

1. **Keybindings**: i3 and Sway configs should be kept in sync for keybindings where possible
2. **--to-code flag**: Used in Sway for layout-independent keybindings (`.config/sway/config`)
3. **Both configs use Mod4** (Super/Windows key) as `$mod`
4. **Font**: Both use `pango:Iosevka` family fonts

### When Editing Helper Scripts

1. Scripts in `.config/i3/scripts/` and `.config/sway/scripts/` are **environment-specific**
2. The `show_notification.sh` script uses different commands:
   - Brightness: `brightnessctl`
   - Volume: `pactl` (PipeWire/PulseAudio)
   - Uses `dunstify -r 9999` to replace previous notifications

### When Working with Environment Variables

1. Wayland variables go in `.config/environment.d/wayland.conf`
2. X11 variables go in `environment` or `.xprofile`
3. PATH modifications should be added to `.xprofile` to ensure `~/.local/bin` scripts are available

### System Integration

- Status bar uses `i3status-rust` with TOML configs in `.config/i3status-rust/`
- Notification daemon: `dunst` (launched by both i3 and Sway configs)
- Terminal: `alacritty` (Mod4+Return in both WMs)
- Application launcher: `i3-dmenu-desktop` (Mod4+d in both WMs)

## Personal Notes

### Desktop Background

The Sway background (`/usr/share/backgrounds/xfce/red_moon_penger.jpg`) features **Penger** - a pixel art penguin character on red/orange sand dunes with a moon. Despite the filename containing "red_moon", the image is NOT solid red - it's a beautiful desert landscape scene with blue sky, moon, and the beloved Penger character.

**Source**: https://penger.city/wallpapers/redmoon_penger.jpg
