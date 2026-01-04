#!/bin/bash
# Dotfiles installation script
# Creates symlinks from ~/Projects/dotfiles to home directory

set -e

DOTFILES_DIR="$HOME/Projects/dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Dotfiles Installation ===${NC}"
echo "Dotfiles directory: $DOTFILES_DIR"
echo "Backup directory: $BACKUP_DIR"
echo ""

# Function to create symlink with backup
link_file() {
    local src="$1"
    local dest="$2"

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    # Backup existing file/symlink if it exists
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ ! -L "$dest" ] || [ "$(readlink -f "$dest")" != "$(readlink -f "$src")" ]; then
            echo -e "${YELLOW}Backing up:${NC} $dest"
            mkdir -p "$BACKUP_DIR"
            cp -rL "$dest" "$BACKUP_DIR/" 2>/dev/null || true
            rm -rf "$dest"
        else
            echo -e "${GREEN}Already linked:${NC} $dest"
            return
        fi
    fi

    # Create symlink
    ln -sf "$src" "$dest"
    echo -e "${GREEN}Linked:${NC} $dest -> $src"
}

# Function to link entire directory
link_directory() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        echo -e "${YELLOW}Backing up directory:${NC} $dest"
        mkdir -p "$BACKUP_DIR"
        cp -r "$dest" "$BACKUP_DIR/" 2>/dev/null || true
        rm -rf "$dest"
    fi

    ln -sf "$src" "$dest"
    echo -e "${GREEN}Linked directory:${NC} $dest -> $src"
}

echo -e "${GREEN}[1/7] Linking .local/bin scripts...${NC}"
mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES_DIR/.local/bin/"*; do
    [ -f "$script" ] && link_file "$script" "$HOME/.local/bin/$(basename "$script")"
done

echo ""
echo -e "${GREEN}[2/7] Linking .local/share files...${NC}"
link_file "$DOTFILES_DIR/.local/share/applications/mimeapps.list" "$HOME/.local/share/applications/mimeapps.list"
link_file "$DOTFILES_DIR/.local/share/applications/discord.desktop" "$HOME/.local/share/applications/discord.desktop"
link_file "$DOTFILES_DIR/.local/share/applications/emacs.desktop" "$HOME/.local/share/applications/emacs.desktop"
link_file "$DOTFILES_DIR/.local/share/xsessions/i3-custom.desktop" "$HOME/.local/share/xsessions/i3-custom.desktop"
link_file "$DOTFILES_DIR/.local/share/wayland-sessions/sway-custom.desktop" "$HOME/.local/share/wayland-sessions/sway-custom.desktop"

echo ""
echo -e "${GREEN}[3/7] Linking i3 configuration...${NC}"
link_file "$DOTFILES_DIR/.config/i3/config" "$HOME/.config/i3/config"
link_directory "$DOTFILES_DIR/.config/i3/scripts" "$HOME/.config/i3/scripts"

echo ""
echo -e "${GREEN}[4/7] Linking Sway configuration...${NC}"
link_file "$DOTFILES_DIR/.config/sway/config" "$HOME/.config/sway/config"
link_directory "$DOTFILES_DIR/.config/sway/scripts" "$HOME/.config/sway/scripts"

echo ""
echo -e "${GREEN}[5/7] Linking status bar and waybar...${NC}"
link_file "$DOTFILES_DIR/.config/i3status-rust/config.toml" "$HOME/.config/i3status-rust/config.toml"
link_file "$DOTFILES_DIR/.config/i3status-rust/config-sway.toml" "$HOME/.config/i3status-rust/config-sway.toml"
link_file "$DOTFILES_DIR/.config/waybar/config" "$HOME/.config/waybar/config"
link_file "$DOTFILES_DIR/.config/waybar/style.css" "$HOME/.config/waybar/style.css"

echo ""
echo -e "${GREEN}[6/7] Linking environment and systemd...${NC}"
link_file "$DOTFILES_DIR/.config/environment.d/wayland.conf" "$HOME/.config/environment.d/wayland.conf"
link_file "$DOTFILES_DIR/.config/systemd/user/keyboard-layout.service" "$HOME/.config/systemd/user/keyboard-layout.service"
link_file "$DOTFILES_DIR/.config/chromium-flags.conf" "$HOME/.config/chromium-flags.conf"
link_file "$DOTFILES_DIR/.xprofile" "$HOME/.xprofile"
link_file "$DOTFILES_DIR/environment" "$HOME/environment"

echo ""
echo -e "${GREEN}[7/7] Linking i3status-rust binary...${NC}"
if [ -f "$DOTFILES_DIR/.config/bin/i3status-rs" ]; then
    link_file "$DOTFILES_DIR/.config/bin/i3status-rs" "$HOME/.config/bin/i3status-rs"
    chmod +x "$HOME/.config/bin/i3status-rs" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo ""
echo -e "${YELLOW}Additional manual steps:${NC}"
echo "1. For GRUB theme (requires sudo):"
echo "   sudo cp $DOTFILES_DIR/grub/default /etc/default/grub"
echo "   sudo grub-mkconfig -o /boot/grub/grub.cfg"
echo ""
echo "2. Enable keyboard layout service (i3 only):"
echo "   systemctl --user enable keyboard-layout.service"
echo ""
echo "3. Set up ZRAM (after reboot to newer kernel):"
echo "   sudo cp /tmp/zram.service /etc/systemd/system/zram.service"
echo "   sudo systemctl enable --now zram.service"
echo ""
echo "4. Apply swappiness tuning:"
echo "   sudo cp /tmp/99-swappiness.conf /etc/sysctl.d/99-swappiness.conf"
echo "   sudo sysctl -p /etc/sysctl.d/99-swappiness.conf"
echo ""

if [ -d "$BACKUP_DIR" ]; then
    echo -e "${YELLOW}Backups saved to:${NC} $BACKUP_DIR"
else
    echo -e "${GREEN}No backups needed - all files were already linked or didn't exist${NC}"
fi
