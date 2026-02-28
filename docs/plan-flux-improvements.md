# plan-flux-improvements (Wayland span + stability testing)

## Goal
- Prefer a **single, continuous Flux animation across 2 monitors** (like “one big desktop” on X11/i3/Windows).
- Keep priority on **stability debugging** (stress tests + logs).

## Reality (Wayland constraint)
A *single* Wayland surface that spans multiple physical outputs is generally **not a supported/portable concept**. Compositors manage outputs; clients typically get one toplevel surface that is placed on **one** output at a time.

So a “true one-window 3840x1080 across 2 monitors” is usually not achievable on Wayland without compositor-specific hacks.

## Practical ways to get a continuous-looking span
### Option 1 (best visual result, not truly one window): 2 surfaces, 1 timeline
- Create **two layer-shell surfaces** (one per output) but drive them from a **shared render clock** and deterministic RNG seed.
- Render two viewports from a single virtual canvas (e.g. left = x:[0..1920), right = x:[1920..3840)).
- Pros: looks like a perfect span; works with Wayland.
- Cons: technically 2 surfaces (but visually seamless).

### Option 2: render a single wide video, then split to outputs
- Add a “render-to-video” mode (offscreen wgpu) producing a 3840x1080 loop.
- Play it with mpvpaper/other wallpaper layer tool with per-output cropping.
- Pros: very stable runtime; easy to autostart; minimal compositor interaction.
- Cons: pre-render step; not interactive.

### Option 3: compositor-specific experiment (not recommended)
- Try gamescope or Hyprland-specific tricks to place one window across outputs.
- Expect unreliable behavior; likely impossible with standard protocols.

## Suggested Flux code improvements (if touching sources)
1) Add explicit concept of **virtual render size** vs per-output viewport.
2) Add CLI args:
   - `--virtual-size 3840x1080`
   - `--viewport 0,0,1920,1080` and `--viewport 1920,0,1920,1080`
   - `--seed` to guarantee deterministic continuity.
3) Add layer-shell backend (wlroots) or output selection (if not already).
4) Make “two outputs” launch script that starts both instances with shared seed + shared start time.

## Priority: stability tooling (stress tests)
- Continue using `dotfiles/scripts/btrfs-nvme-stress.sh` and extend logging as needed.
- If hangs occur: capture SysRq `w/t` dumps + kernel log around hung tasks.

