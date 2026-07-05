#!/system/bin/sh
CONF_DIR=/data/adb/odin3_hdr_fix

ui_print "*******************************"
ui_print " Odin 3 HDR Fix"
ui_print " v1.1.0"
ui_print "*******************************"

mkdir -p "$CONF_DIR"
if [ -f "$CONF_DIR/config.conf" ]; then
  ui_print "- Kept existing config."
else
  cp -f "$MODPATH/config.conf" "$CONF_DIR/config.conf"
  ui_print "- Default config installed."
fi

ui_print "- Overlays panel display config:"
ui_print "  782-nit brightness curve + High Brightness Mode"
ui_print "- NOTE: full effect requires the DTBO peak"
ui_print "  brightness patch (782 nits). Without it, the"
ui_print "  reported panel ceiling stays at stock 420."
ui_print "- Config: $CONF_DIR/config.conf"
ui_print "- Log:    $CONF_DIR/hdr.log"
ui_print "- Reboot to activate."

chmod 755 "$MODPATH/service.sh"
