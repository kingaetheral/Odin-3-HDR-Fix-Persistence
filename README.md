# Odin 3 HDR Fix & Persistence

Magisk module · v1.1.0 · Odin 3

HDR content on the Odin 3 renders dim and washed out. This module fixes it — systemlessly — and keeps the fix applied across reboots.

Based on the original fix by **Antigravity**. This version adds persistence, a watchdog, configuration toggles, and recovery-flash support.

## What it does

Three things, all reversible by removing the module:

1. **Overlays the panel display config** (`/vendor/etc/displayconfig/display_id_4630946441858561683.xml`) with a corrected brightness curve spanning 0.23–782.4 nits and an enabled High Brightness Mode with an SDR→HDR ratio map. Stock lacks this file for the active panel ID, so the framework falls back to conservative defaults.
2. **Sets display properties** at boot: `vendor.display.disable_sdr_dimming=1` and `vendor.display.disable_3d_adaptive_tm=0`.
3. **Disables hardware overlays** (`service call SurfaceFlinger 1008 i32 1`), forcing GPU composition so HDR layers go through the corrected tone-mapping path. Optional — see configuration.

A watchdog re-applies the properties and the SurfaceFlinger setting if anything resets them (SurfaceFlinger restarts silently undo #3; the service detects the restart by PID change and re-asserts).

## Companion: DTBO peak brightness patch

For the full effect, the boot device tree should report the panel's real peak brightness. Stock DTBO declares `qcom,mdss-dsi-panel-peak-brightness = 4200000` (420.0 nits); the panel is capable of 782.4 nits (`7824283`). With the DTBO patched, Android reports `mMaxLuminance=782.4283` and this module's brightness curve maps onto the true range.

This module works without the DTBO patch (and is safe to run either way), but the reported panel ceiling stays at stock 420 nits until the DTBO is patched. The DTBO patch requires flashing the `dtbo` partition — see the companion repository for the method and the guard module that keeps it in place across OTAs.

## Install

1. Download the zip from [Releases](../../releases)
2. Magisk → Modules → Install from storage
3. Reboot

If you previously installed the original `fix_hdr` module, remove it first — the module IDs differ and both would apply.

## Configuration

`/data/adb/odin3_hdr_fix/config.conf`:

| Setting | Default | Meaning |
|---|---|---|
| `DISABLE_SDR_DIMMING` | `1` | Stops SDR content from dimming while HDR is on screen |
| `DISABLE_3D_ADAPTIVE_TM` | `0` | Adaptive tone mapping prop value used by the fix |
| `DISABLE_HW_OVERLAYS` | `1` | Forces GPU composition. Fixes HDR paths that bypass tone mapping, at some battery/GPU cost. Set `0` to test whether the XML + props alone are enough on your unit |
| `WATCHDOG_INTERVAL` | `60` | Seconds between re-checks; `0` = apply once at boot |

Edit, then reboot. Actions are logged to `/data/adb/odin3_hdr_fix/hdr.log`.

### About the GPU composition tradeoff

Disabling hardware overlays means the GPU composites every frame instead of the display hardware. The cost is highest on static screens (where the GPU could otherwise idle) and smallest in games (where it is already active). If HDR looks correct on your unit with `DISABLE_HW_OVERLAYS=0`, keep it there.

## Verifying

```
su -c 'cat /data/adb/odin3_hdr_fix/hdr.log'
su -c 'getprop vendor.display.disable_sdr_dimming'
```

Expect `set disable_sdr_dimming=1` in the log and `1` from getprop, then judge with real HDR content.

## Uninstall

Remove the module in Magisk and reboot. The overlay and properties revert to stock. Optionally delete `/data/adb/odin3_hdr_fix/`.

## Credits

- **Antigravity** — original fix: display config calibration, properties, and composition workaround
- Powered by [Magisk](https://github.com/topjohnwu/Magisk)
