#!/system/bin/sh
ui_print " "
ui_print "  Traffic Stats (vnstat-lite)"
ui_print "  ==========================="
ui_print " "
ui_print "  Per-interface RX/TX daily accumulator."
ui_print "  Polls /proc/net/dev every 60 s."
ui_print "  DB at /data/traffic-stats/"
ui_print " "
ui_print "  Requires bin-utils v1.3.0+ (provides static bash + lib/common.sh)."
ui_print " "

# Hard dependency: bin-utils v1.3.0+ (lib/common.sh + static bash).
if [ ! -r /data/adb/modules/bin-utils/lib/common.sh ] \
   && [ ! -r /data/adb/modules_update/bin-utils/lib/common.sh ]; then
    ui_print " "
    ui_print "  ❌ bin-utils v1.3.0+ is required (provides lib/common.sh)."
    ui_print "     Install it first:  /install_module bin-utils"
    ui_print " "
    abort "  Missing dependency: bin-utils v1.3.0+"
fi

mkdir -p /data/traffic-stats
chmod 755 /data/traffic-stats

set_perm "$MODPATH/service.sh"  0 0 0755
set_perm "$MODPATH/poller.sh"   0 0 0755

ui_print "  [OK] Installed."
ui_print "  Daemon starts at late_start (boot)."
ui_print "  Bot reads it via /traffic_history (statusbot v2.12+)."
ui_print " "
