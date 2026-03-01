#!/bin/bash
# Dotfiles setup script - symlinks configurations to home directory
# Usage: ./setup.sh [--force]

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
FORCE=false

# Parse arguments
if [[ "$1" == "--force" ]]; then
    FORCE=true
fi

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Dotfiles Setup ===${NC}"
echo "Source: $DOTFILES_DIR"
echo "Target: $HOME"
echo ""

# Function to create symlink with backup
link_file() {
    local src="$1"
    local dest="$2"

    # Skip if source doesn't exist
    if [[ ! -e "$src" ]]; then
        return
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$dest")"

    # Handle existing files
    if [[ -e "$dest" || -L "$dest" ]]; then
        if [[ -L "$dest" ]]; then
            local current_target=$(readlink "$dest")
            if [[ "$current_target" == "$src" ]]; then
                echo -e "${GREEN}✓${NC} Already linked: $dest"
                return
            fi
        fi

        if [[ "$FORCE" == true ]]; then
            mkdir -p "$BACKUP_DIR"
            echo -e "${YELLOW}→${NC} Backing up: $dest"
            mv "$dest" "$BACKUP_DIR/"
        else
            echo -e "${RED}✗${NC} Already exists: $dest (use --force to backup and replace)"
            return
        fi
    fi

    ln -sf "$src" "$dest"
    echo -e "${GREEN}✓${NC} Linked: $dest -> $src"
}

# Config directories to symlink
CONFIG_DIRS=(
    "i3"
    "sway"
    "hypr"
    "waybar"
    "dunst"
    "alacritty"
    "rofi"
    "swaylock"
    "i3status-rust"
    "scripts"
    "systemd"
    "environment.d"
    "sudoers.d"
)

echo -e "${GREEN}Linking config directories...${NC}"
for dir in "${CONFIG_DIRS[@]}"; do
    link_file "$DOTFILES_DIR/.config/$dir" "$HOME/.config/$dir"
done

# Root dotfiles to symlink
ROOT_DOTFILES=(
    ".xprofile"
    ".Xresources"
    ".emacs"
    ".emacs.custom.el"
    ".emacs.local"
    ".emacs.rc"
)

echo ""
echo -e "${GREEN}Linking root dotfiles...${NC}"
for file in "${ROOT_DOTFILES[@]}"; do
    link_file "$DOTFILES_DIR/$file" "$HOME/$file"
done

# Link environment file if it exists (not a dotfile)
if [[ -f "$DOTFILES_DIR/environment" ]]; then
    echo ""
    echo -e "${GREEN}Linking environment file...${NC}"
    link_file "$DOTFILES_DIR/environment" "$HOME/environment"
fi

# Link .local/bin if it exists
if [[ -d "$DOTFILES_DIR/.local/bin" ]]; then
    echo ""
    echo -e "${GREEN}Linking local binaries...${NC}"
    link_file "$DOTFILES_DIR/.local/bin" "$HOME/.local/bin"
fi

echo ""
echo -e "${GREEN}=== Setup Complete ===${NC}"

if [[ -d "$BACKUP_DIR" ]]; then
    echo -e "${YELLOW}Backups saved to: $BACKUP_DIR${NC}"
fi

echo ""
echo "Next steps:"
echo "  1. Install packages: sudo pacman -S --needed - < pkglist.txt"
echo "  2. Install AUR packages: yay -S --needed - < pkglist-aur.txt"
echo "  3. Apply GRUB theme: sudo cp grub/default /etc/default/grub && sudo grub-mkconfig -o /boot/grub/grub.cfg"
echo "  4. Reload your window manager or log out/in"
