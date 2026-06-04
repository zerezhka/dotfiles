# Flux (Drift-like screensaver) on Wayland/Hyprland — dual-monitor span

**Status: implemented natively.** Flux now renders **one continuous fluid
simulation across both monitors** via `wlr-layer-shell`. The streams flow
seamlessly across the seam — it is *not* two independent instances anymore.

Sources/build:
- `~/Projects/flux/` (Rust + wgpu) — the runner lives in `flux-desktop/src/wayland.rs`
- Deployed binary: `~/Projects/dotfiles/.local/bin/flux-desktop`
  (symlinked to `~/.local/bin/flux-desktop`)

## How it works

`flux-desktop` detects a Wayland session (`WAYLAND_DISPLAY`) and runs a
Wayland-native layer-shell runner (falls back to a winit window on X11/macOS/Windows):

1. Enumerates all outputs and computes the **union bounding box** of every monitor
   (e.g. two 1920×1080 side-by-side → one 3840×1080 virtual canvas).
2. Creates one `Layer::Overlay` surface **per output**, each covering its whole screen.
3. Builds a single `Flux` simulation sized to the union. Each frame it does one
   `compute()` step, then renders each output with its own `ScreenViewport` slice
   (its physical rect within the union). Because every output samples the *same*
   simulation, the fluid is continuous across the gap.
4. Exits on **any keyboard or pointer input** (screensaver behaviour), and on
   `SIGTERM`/`SIGINT` (so `pkill` / hypridle always kill it instantly).

No Hyprland `windowrule` placement is needed — layer-shell binds each surface to
its output directly.

> Why the old "two independent instances / blur the inactive screen" workaround is
> gone: that existed because a single winit window can't span outputs on Wayland.
> The layer-shell runner sidesteps it by drawing one surface per output from a
> shared simulation. `~/.local/bin/flux-with-blur` is now obsolete.

## Run it manually

```bash
flux-desktop          # spans all monitors; press any key / move mouse to exit
```

## Screensaver wiring (hypridle)

`~/.config/hypr/hypridle.conf` chains it as a pre-lock screensaver and kills it on
every lock path so it never runs hidden behind hyprlock:

```ini
general {
    lock_cmd = pkill -9 flux-desktop; hyprlock
    before_sleep_cmd = pkill -9 flux-desktop; hyprlock
}

listener {            # 5 min: flux screensaver
    timeout = 300
    on-timeout = ~/.local/bin/flux-desktop
    on-resume = pkill -9 flux-desktop
}
listener {            # 15 min: lock (flux killed first)
    timeout = 900
    on-timeout = pkill -9 flux-desktop; hyprlock
}
listener {            # 45 min: screens off
    timeout = 2700
    on-timeout = hyprctl dispatch dpms off
    on-resume = hyprctl dispatch dpms on
}
```

Apply changes: `systemctl --user restart hypridle` (or `pkill hypridle; hypridle &`).

## Lock-screen / SDDM note

Flux **cannot** draw on top of hyprlock or the SDDM greeter — both deliberately
suppress all other surfaces (`ext-session-lock-v1` / a separate greeter compositor).
So flux is a *pre-lock* screensaver only. To animate *behind* a password prompt you'd
have to build a dedicated `ext-session-lock-v1` locker (flux background + PAM auth),
which is a separate project.

## Updating the deployed binary

After rebuilding flux:
```bash
cargo build --release -p flux-desktop          # in ~/Projects/flux
cp ~/Projects/flux/target/release/flux-desktop ~/Projects/dotfiles/.local/bin/flux-desktop
```

## Troubleshooting

- Stuck process: `pkill -9 flux-desktop` (or `SIGTERM` — it handles both).
- Mixed per-monitor scale factors are approximate; matched-resolution pairs are exact.
- One monitor black: check `hyprctl monitors`; the log prints the per-output viewport
  mapping (`Output N: ... vp=ScreenViewport { ... }`).
