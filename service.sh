#!/system/bin/sh
# Odin 3 HDR Fix - boot service

CONF=/data/adb/odin3_hdr_fix/config.conf
LOG=/data/adb/odin3_hdr_fix/hdr.log

log() { echo "$(date '+%m-%d %H:%M:%S') $1" >> "$LOG"; }

until [ "$(getprop sys.boot_completed)" = "1" ]; do sleep 5; done
sleep 5

[ -f "$CONF" ] && . "$CONF"
DISABLE_SDR_DIMMING=${DISABLE_SDR_DIMMING:-1}
DISABLE_3D_ADAPTIVE_TM=${DISABLE_3D_ADAPTIVE_TM:-0}
DISABLE_HW_OVERLAYS=${DISABLE_HW_OVERLAYS:-1}
WATCHDOG_INTERVAL=${WATCHDOG_INTERVAL:-60}

: > "$LOG"
log "service started (sdr_dimming=$DISABLE_SDR_DIMMING tm=$DISABLE_3D_ADAPTIVE_TM hw_overlays_off=$DISABLE_HW_OVERLAYS watchdog=${WATCHDOG_INTERVAL}s)"

apply() {
  if [ "$(getprop vendor.display.disable_sdr_dimming)" != "$DISABLE_SDR_DIMMING" ]; then
    setprop vendor.display.disable_sdr_dimming "$DISABLE_SDR_DIMMING" && log "set disable_sdr_dimming=$DISABLE_SDR_DIMMING"
  fi
  if [ "$(getprop vendor.display.disable_3d_adaptive_tm)" != "$DISABLE_3D_ADAPTIVE_TM" ]; then
    setprop vendor.display.disable_3d_adaptive_tm "$DISABLE_3D_ADAPTIVE_TM" && log "set disable_3d_adaptive_tm=$DISABLE_3D_ADAPTIVE_TM"
  fi
  if [ "$DISABLE_HW_OVERLAYS" = "1" ]; then
    # No readback for this setting; re-assert it. Cheap call, idempotent.
    /system/bin/service call SurfaceFlinger 1008 i32 1 > /dev/null 2>&1 && log "asserted HW overlays off (SF 1008)"
  fi
}

apply

if [ "$WATCHDOG_INTERVAL" -gt 0 ] 2>/dev/null; then
  # Track SurfaceFlinger PID; a change means it restarted and overlay
  # setting was reset, so re-apply immediately.
  SF_PID=$(pidof surfaceflinger)
  while true; do
    sleep "$WATCHDOG_INTERVAL"
    NEW_PID=$(pidof surfaceflinger)
    if [ "$NEW_PID" != "$SF_PID" ]; then
      log "SurfaceFlinger restarted ($SF_PID -> $NEW_PID), re-applying"
      SF_PID=$NEW_PID
    fi
    apply
  done
fi
