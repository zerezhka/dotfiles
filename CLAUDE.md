# CLAUDE.md

Personal Arch Linux dotfiles for i3 (X11) and Sway (Wayland) — configs are symlinked to `~`.

## Structure

| Path | Purpose |
|------|---------|
| `.config/i3/config` | i3 window manager |
| `.config/sway/config` | Sway compositor |
| `.config/i3status-rust/` | Status bar (TOML, separate configs per WM) |
| `.config/environment.d/wayland.conf` | Wayland session env vars |
| `environment` | X11 session env vars |
| `.xprofile` | X11 session startup |
| `pkglist.txt` / `pkglist-aur.txt` | Installed packages |
| `grub/default` | GRUB config (Vimix theme) |

## Key Design Decisions

- **Both WMs use Mod4** (Super) as `$mod`, `pango:Iosevka` fonts
- **Sway uses `--to-code`** on bindsym for layout-independent keybindings
- **Keep i3/Sway keybindings in sync** where possible
- **Env vars**: Wayland → `environment.d/wayland.conf`, X11 → `environment` or `.xprofile`
- **`~/.local/bin/xdg-open`**: custom replacement launching Chromium directly (avoids slow D-Bus in i3)

## Keyboard Layout (Critical)

US/RU layout with Alt+Shift toggle — breaks after upgrades. Redundant fallbacks:
1. Sway: `input type:keyboard` in `.config/sway/config:9-12`
2. i3: `setxkbmap` calls in config + `.xprofile`
3. Systemd user service: `.config/systemd/user/keyboard-layout.service`
4. Script: `.local/bin/setup-keyboard-layout`

## Screensaver Stack

- **Screensaver**: `.local/bin/flux-desktop` (custom binary, exits on any key/click)
- **i3**: `xidlehook` → flux at 5min, `betterlockscreen` at 10min
- **Sway**: `swayidle` → flux at 5min, `swaylock` at 10min, DPMS off at 15min
- Manual lock: `Mod+Shift+L`

## Notifications

`.config/{i3,sway}/scripts/show_notification.sh` — brightness/volume/battery/wifi via `dunstify -r 9999`.
