# Dual Monitor Status Bar Configuration

**DELETE AFTER IMPLEMENTATION**

## Plan

Configure dual-monitor setup for PC with different status bar positioning:

### Left Monitor (HDMI-A-2, workspaces 1-5)
- Standard horizontal status bar at **top** position
- Uses `i3status-rust` with toolbar/block features
- Config: `~/.config/i3status-rust/config-sway.toml`

### Right Monitor (HDMI-A-1, workspaces 6-10)
- **Vertical status bar** positioned on the **right side**
- Uses `i3status-rust` with toolbar/block features
- May need separate config file for vertical layout
- Inspiration from waybar config (battery/keyboard-state with `rotate: 270`)

## Implementation Steps

1. Test current dual-monitor setup with both bars
2. Configure right monitor bar with vertical positioning
3. Adjust i3status-rust config for vertical layout if needed
4. Test workspace switching and tray behavior
5. Update `.config/sway/config` with final configuration
6. Commit changes
7. **Delete this TODO file**

## Notes

- i3status-rust preferred over waybar for toolbar features
- Solarized Dark theme (#073642 background)
- Font: Iosevka Nerd Font 14
