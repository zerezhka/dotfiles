# Xorg Configuration

This directory contains Xorg configuration files that should be copied to `/etc/X11/xorg.conf.d/`.

## Installation

```bash
sudo cp xorg.conf.d/20-nvidia.conf /etc/X11/xorg.conf.d/
```

## Files

### 20-nvidia.conf

Nvidia GPU configuration for dual 1920x1080 monitors with:
- `ForceFullCompositionPipeline` on both displays to prevent flickering/tearing
- `TripleBuffer` enabled for better performance
- Explicit metamode for HDMI-A-2 (left) and HDMI-A-1 (right) at positions 0,0 and 1920,0

Required for RTX 3080 with proprietary Nvidia drivers to eliminate screen flickering.
