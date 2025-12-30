# SDDM Theme Configuration

Custom theme configurations for SDDM themes.

## Installation

```bash
# Sugar Candy theme (dual monitor setup)
sudo cp sddm/themes/sugar-candy-theme.conf /usr/share/sddm/themes/sugar-candy/theme.conf
```

## Files

### sugar-candy-theme.conf

Sugar Candy theme configured for dual 1920x1080 monitors (3840x1080 total).

**Changes from default:**
- `ScreenWidth="3840"` (was 1440)
- `ScreenHeight="1080"` (was 900)

This ensures the login background spans both monitors correctly instead of only displaying on the primary monitor.
