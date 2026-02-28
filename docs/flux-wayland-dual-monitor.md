# Flux (Drift-like screensaver) on Wayland/Hyprland — dual monitor “span”

You have Flux sources/builds in:
- `~/Projects/flux/` (Rust + wgpu)
- In dotfiles there are helper binaries:
  - `~/Projects/dotfiles/.local/bin/flux-desktop`
  - `~/Projects/dotfiles/.local/bin/flux-with-blur`

## Reality check: Wayland doesn’t do “one window across 2 monitors” reliably
On X11 you can treat multi-monitor as one big coordinate space and just make a 3840x1080 window.
On Wayland the compositor owns outputs; most apps can’t request “span both outputs” in a portable way.

**Pragmatic approach:** run **two fullscreen instances**, one per output.
Visually it’s “stretched”, even though technically it’s two surfaces.

## Recommended: two instances (one per monitor)
### 1) Get output names
```bash
hyprctl monitors
```
You’ll see names like `HDMI-A-1`, `HDMI-A-2`.

### 2) Start Flux twice
Flux needs a display session (Wayland). Run from a Hyprland terminal.

Example (replace paths/output mapping with your real ones):

```bash
# Stop previous runs
pkill -x flux-desktop 2>/dev/null || true

# Left monitor
env WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
  WLR_DRM_DEVICES="$WLR_DRM_DEVICES" \
  flux-desktop --fullscreen --output HDMI-A-2 &

# Right monitor
env WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
  WLR_DRM_DEVICES="$WLR_DRM_DEVICES" \
  flux-desktop --fullscreen --output HDMI-A-1 &
```

Notes:
- The actual flags depend on how your `flux-desktop` wrapper is built. If it doesn’t support `--output`, you can still do it by using Hyprland window rules (see below).

## If Flux cannot target outputs: use Hyprland window rules
If Flux is “just a normal window”, you can force placement/fullscreen per monitor.

In `~/.config/hypr/hyprland.conf` add rules (example):
```ini
# Put Flux on left monitor
windowrule = monitor HDMI-A-2, class:^(flux)$
# or title match if class differs
# windowrule = monitor HDMI-A-2, title:^(Flux)$

# Make it fullscreen (or maximize)
windowrule = fullscreen, class:^(flux)$
```

Then run two instances and Hyprland will place them.

## Making it look like one continuous wide animation
If you want a *true continuous* look across both screens:
- Render Flux at 3840x1080 (or your combined resolution)
- Split/crop into two views (left/right) and feed each instance a different viewport

This requires Flux to support viewport/camera offsets. If it doesn’t, easiest is to accept “two identical but independent” instances.

## Troubleshooting
- If one monitor stays black: check the output name from `hyprctl monitors`.
- If it launches on the wrong monitor: add explicit Hyprland `windowrule = monitor ...`.
- For testing stability: running Flux + NVMe IO can increase chance of reproducing hangs.
