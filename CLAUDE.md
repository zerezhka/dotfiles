# CLAUDE.md

Personal Arch Linux dotfiles — configs are symlinked to `~`. **Hyprland is the daily driver**; i3 (X11) and Sway (Wayland) are kept working as fallbacks.

## Structure

| Path | Purpose |
|------|---------|
| `.config/hypr/hyprland.conf` | Hyprland compositor (current setup) |
| `.config/hypr/hypridle.conf` / `hyprlock.conf` / `hyprpaper.conf` | Idle, lock, wallpaper |
| `.config/hypr/local.conf.example` | Machine-specific monitors/workspaces (copy to `~/.config/hypr/local.conf`, not in repo) |
| `.config/i3/config` | i3 window manager (fallback) |
| `.config/i3/config-crd` | i3 variant for Chrome Remote Desktop (Mod1, DUMMY0 output, win+space toggle) |
| `.config/sway/config` | Sway compositor (fallback) |
| `.config/waybar/` | Hyprland bars (3 bars: left-top, right-top, right-vertical) |
| `.config/i3status-rust/` | i3/Sway status bars (TOML, separate configs per WM) |
| `.config/scripts/` | Shared WM scripts (notifications, logout menu, layout notify) |
| `.config/environment.d/wayland.conf` | Wayland session env vars |
| `environment` | X11 session env vars |
| `.xprofile` | X11 session startup |
| `pkglist.txt` / `pkglist-aur.txt` | Installed packages |
| `grub/default` | GRUB config (Vimix theme) |

## Key Design Decisions

- **All WMs use Mod4** (Super) as `$mod` (except `config-crd`: Mod1), `pango:Iosevka` fonts
- **Sway uses `--to-code`** on bindsym for layout-independent keybindings
- **Keep i3/Sway/Hyprland keybindings in sync** where possible (`Mod+Shift+H` = Hyprland cheatsheet; `Mod+H` = split on i3/Sway)
- **Env vars**: Wayland → `environment.d/wayland.conf`, X11 → `environment` or `.xprofile`
- **`~/.local/bin/xdg-open`**: custom replacement launching Chromium directly (avoids slow D-Bus in i3)

## Keyboard Layout (Critical)

US/RU layout with Alt+Shift toggle — breaks after upgrades. Redundant fallbacks:
1. Hyprland: `input { kb_layout }` in `.config/hypr/hyprland.conf`
2. Sway: `input type:keyboard` in `.config/sway/config:9-12`
3. i3: `setxkbmap` calls in config + `.xprofile`
4. Systemd user service: `.config/systemd/user/keyboard-layout.service`
5. Script: `.local/bin/setup-keyboard-layout`

Layout-change OSD: status bars poll `scripts/get_keyboard_layout.sh` (per-WM wrapper around `.config/scripts/keyboard-layout-notify.sh`), which fires `dunstify` on change — no separate watcher process.

## Screensaver / Idle Stack

Unified timings across WMs: flux screensaver at 5 min, lock at 15 min, screens off at 45 min.

- **Screensaver**: `.local/bin/flux-desktop` (custom binary, spans monitors, exits on any key/click)
- **Hyprland**: `hypridle` → `hyprlock`; manual `Mod+Shift+L` runs `.local/bin/flux-screensaver` (5s flux grace, then hyprlock)
- **Sway**: `swayidle` → `swaylock-smooth`; manual `Mod+Shift+L`
- **i3**: `xidlehook` (timers are *relative* to each other) → `betterlockscreen`; manual `Mod+Shift+L`; `config-crd` skips DPMS (virtual display)

## Notifications

`.config/scripts/show_notification.sh` — brightness/volume/battery/wifi OSD via `dunstify -r 9999`, shared by all WMs.
