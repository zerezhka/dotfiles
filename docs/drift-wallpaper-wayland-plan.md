# Drift-like wallpaper across 2 monitors on Wayland (Hyprland) — plan

Goal: run an animated “drift”/screensaver-style wallpaper on a dual-monitor setup.

**Key Wayland reality:** a single surface spanning *two physical outputs* is not reliably supported across apps/compositors. The pragmatic solution is **one fullscreen layer per monitor** (two instances), or a compositor/virtual-output trick (gamescope).

## Option A (recommended): run 2 fullscreen layer surfaces (one per monitor)
This is how most Wayland video-wallpaper setups do multi-monitor.

### Tool choices
- **mpvpaper** (Wayland layer-shell, supports per-output): best for video/animated content
- Alternative: **swww** for animated transitions (not continuous “drift video”)

### Steps
1) Identify output names:
   ```bash
   hyprctl monitors
   ```
   Example outputs: `HDMI-A-1`, `HDMI-A-2`.

2) Install mpvpaper (package name may vary):
   ```bash
   sudo pacman -S --needed mpv
   yay -S --needed mpvpaper
   ```

3) Create a small launcher script (two mpvpaper instances):
   - one instance per output, fullscreen background layer
   - use `--loop` and optionally limit fps/vo for stability

4) Hook it into Hyprland autostart (exec-once) *or* systemd user service.

### Example launcher (pseudo)
```bash
#!/usr/bin/env bash
pkill -x mpvpaper 2>/dev/null || true

# left monitor
mpvpaper -o "--loop --no-audio --profile=gpu-hq" HDMI-A-2 ~/Videos/drift.mp4 &

# right monitor
mpvpaper -o "--loop --no-audio --profile=gpu-hq" HDMI-A-1 ~/Videos/drift.mp4 &

wait
```

### Notes
- This is not a single stretched surface, but visually it can look like “one wide wallpaper” if you render/crop the content consistently.
- To make it truly continuous across both monitors, you need a **3840x1080** source (or render) and pass different crop options per monitor.

## Option B: “true span” via virtual output (harder / less reliable)
Possible approach: run the wallpaper inside **gamescope** with a virtual resolution `3840x1080`, then try to place that single window across both monitors.

Caveat: on Wayland, placing one window across 2 outputs is compositor-specific; may still end up constrained to one output.

## Option C: accept single-monitor fullscreen (simple)
If you just want a nice drift-like effect on the primary monitor, run one instance.

## Implementation checklist for this repo
- [ ] Add `scripts/start-drift-wallpaper.sh`
- [ ] Add `systemd --user` service: `drift-wallpaper.service` (WantedBy=graphical-session.target)
- [ ] Add docs: this file
- [ ] Decide on output names (keep configurable via env vars)

## Next questions
- What is the source format? (video mp4/webm vs shader vs custom binary)
- Do you want it running **always** or only when idle (screensaver behavior)?
- Exact monitor arrangement: left/right order and which output name maps to which.
