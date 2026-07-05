# Odin 3 HDR Fix

Magisk module for improving HDR behavior on the AYN Odin 3.

This module is meant to fix the Android-side HDR configuration that makes HDR content look dim, dull, or incorrectly tone-mapped on affected Odin 3 units. It does not flash partitions. Everything it changes is systemless and can be removed by uninstalling the module and rebooting.

## What It Does

This module handles three separate parts of the HDR fix:

1. **Adds the correct display config for the Odin 3 panel**

   Android looks for a per-display XML file matching the physical display ID. On affected devices, that file is missing, so Android falls back to a generic display config. This module overlays:

   `/vendor/etc/displayconfig/display_id_4630946441858561683.xml`

   The included config gives Android the Odin 3 panel brightness curve, topping out at about `782.4283` nits, and enables the High Brightness Mode policy used for HDR.

2. **Applies the HDR-related display properties**

   At boot, the module sets:

   ```sh
   vendor.display.disable_sdr_dimming=1
   vendor.display.disable_3d_adaptive_tm=0
   ```

   These are used by the Qualcomm display stack and help avoid the dull or dim HDR presentation seen on the stock configuration.

3. **Optionally disables hardware overlays**

   The module can run:

   ```sh
   service call SurfaceFlinger 1008 i32 1
   ```

   This forces GPU/client composition. On the Odin 3, this can make HDR layers go through the correct composition path instead of the broken hardware-overlay path. This is enabled by default because it matches the known working fix, but it can be disabled in the config file for testing.

## Watchdog

SurfaceFlinger can restart during normal use. When that happens, the hardware-overlay setting is lost. This module includes a lightweight watchdog that periodically checks the SurfaceFlinger process and re-applies the fix if needed.

The watchdog does not do heavy work. The main battery or performance tradeoff comes from forcing GPU composition, not from the watchdog itself.

## DTBO Peak Brightness Patch

This module is designed to pair with the Odin 3 HDR DTBO Peak Brightness Patcher:

https://github.com/WhiteEagle-12/Odin-3-HDR-DTBO-Patcher

Stock DTBO reports the panel peak brightness as `4200000`, which Android interprets as `420.0` nits. The Odin 3 panel config contains measured brightness data up to about `782.4283` nits. With the DTBO patched to `7824283`, Android reports the display HDR max luminance as `782.4283` instead of `420.0`.

In plain terms:

- The DTBO patcher tells Android what the panel can report as its HDR peak.
- This Magisk module tells Android how to map and drive that brightness range, and keeps the runtime HDR settings applied.
- The SurfaceFlinger workaround fixes the composition path that can make HDR look wrong.

The module is safe to install without the DTBO patcher, but a stock DTBO may still report the panel as a 420-nit HDR display. For the intended fix, use both pieces together.

## Installation

1. Download the module zip from Releases.
2. Open Magisk.
3. Install from storage.
4. Reboot.

This module can be installed before or after running the DTBO patcher. Order does not matter, but both pieces are recommended for the full HDR fix.

If you already have another Odin HDR or display-config module installed, remove it first to avoid applying the same fixes twice.

## Configuration

The config file is created at:

```sh
/data/adb/odin3_hdr_fix/config.conf
```

Available settings:

| Setting | Default | Meaning |
|---|---:|---|
| `DISABLE_SDR_DIMMING` | `1` | Prevents SDR content from being dimmed incorrectly when HDR is active. |
| `DISABLE_3D_ADAPTIVE_TM` | `0` | Qualcomm tone-mapping property used by the fix. |
| `DISABLE_HW_OVERLAYS` | `1` | Forces GPU composition using the SurfaceFlinger call. Set to `0` to test with hardware overlays enabled. |
| `WATCHDOG_INTERVAL` | `60` | Seconds between watchdog checks. Set to `0` to apply once at boot only. |

After editing the config, reboot.

## GPU Composition Tradeoff

When `DISABLE_HW_OVERLAYS=1`, Android uses the GPU to composite display layers instead of letting display hardware handle overlays. This can slightly increase power use and heat, especially in GPU-heavy apps or games.

For normal HDR video and UI use, the cost is usually small. For demanding games or emulators, test both modes:

- If HDR still looks correct with `DISABLE_HW_OVERLAYS=0`, leave it off for better efficiency.
- If HDR becomes dim, washed out, or incorrectly mapped, keep `DISABLE_HW_OVERLAYS=1`.

## Verification

Check the module log:

```sh
su -c 'cat /data/adb/odin3_hdr_fix/hdr.log'
```

Check the SDR dimming property:

```sh
su -c 'getprop vendor.display.disable_sdr_dimming'
```

Expected result:

```sh
1
```

With the DTBO patch applied, Android should report HDR max luminance around `782.4283` nits.

## Uninstall

Remove the module in Magisk and reboot. The overlay and runtime properties will revert to stock behavior.

You can optionally remove the config/log directory:

```sh
su -c 'rm -rf /data/adb/odin3_hdr_fix'
```

## Credits

- kingaetheral
- WhiteEagle-12
- Zurce
- Magisk by topjohnwu
