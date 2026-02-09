# Dotfiles

Personal Arch Linux dotfiles for i3, Sway, and Hyprland window managers.

## Features

- **Multi-DE support**: Shared scripts auto-detect i3 (X11), Sway (Wayland), or Hyprland
- **Unified notifications**: Volume, brightness, battery, WiFi with Nerd Font icons
- **Dual screensaver**: Custom flux-desktop for both X11 and Wayland
- **Status bars**: i3status-rust configurations for all environments
- **Keyboard layouts**: US/RU with Alt+Shift toggle, persistent across reboots

## Quick Setup

```bash
# Clone the repository
git clone https://github.com/zerezhka/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles

# Run setup script to symlink configs
./setup.sh

# Install packages
sudo pacman -S --needed - < pkglist.txt
yay -S --needed - < pkglist-aur.txt

# Apply GRUB theme (optional)
sudo cp grub/default /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Reload your window manager or log out/in
```

## Setup Script Options

```bash
./setup.sh          # Safe mode - won't overwrite existing files
./setup.sh --force  # Backup and replace existing files
```

## What Gets Symlinked

### Config directories
- `.config/i3/` - i3 window manager (X11)
- `.config/sway/` - Sway compositor (Wayland)
- `.config/hypr/` - Hyprland compositor (Wayland)
- `.config/waybar/` - Status bar for Wayland
- `.config/scripts/` - Shared scripts for all DEs
- `.config/alacritty/` - Terminal emulator
- `.config/rofi/` - Application launcher
- `.config/dunst/` - Notification daemon
- `.config/i3status-rust/` - Status bar configs
- `.config/systemd/` - User services
- And more...

### Root dotfiles
- `.xprofile` - X11 session startup
- `.Xresources` - X11 resources
- `environment` - Global environment variables
- `.local/bin/` - Custom scripts and binaries

## Manual Setup Notes

See [CLAUDE.md](CLAUDE.md) for detailed architecture notes and manual setup instructions.

## Key Bindings (All DEs)

- `Mod+Return` - Terminal (alacritty)
- `Mod+d` - Application launcher
- `Mod+Shift+E` - Logout menu
- `Mod+Shift+L` - Lock screen
- `Mod+Shift+R` - Reload config

## Shared Scripts

All three DEs share the same polished implementations:

- **`dmenu-logout.sh`** - Power menu with auto-detection
- **`show_notification.sh`** - Rich notifications with progress bars
- **`keyboard-layout-notify.sh`** - Layout switching notifications
- **`lock-key-notify.sh`** - CapsLock/NumLock indicators
