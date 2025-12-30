# Session Desktop Entries

Custom session desktop entries for display managers (SDDM/LightDM/GDM).

## Installation

```bash
# X11 sessions
sudo cp sessions/xsessions/*.desktop /usr/share/xsessions/

# Wayland sessions
sudo cp sessions/wayland-sessions/*.desktop /usr/share/wayland-sessions/
```

## Files

### xsessions/kodi-x11.desktop

Kodi session configured to use X11 windowing explicitly (`--windowing=x11`).

**Why needed:** With Nvidia proprietary drivers, Kodi's auto-detection may choose GBM/Wayland which fails. This forces X11 mode for compatibility.

## Notes

- Sway and i3 desktop entries are managed by their respective packages
- These are reference/override configs for systems with Nvidia proprietary drivers
