#!/system/bin/sh
ui_print " "
ui_print "  Traffic Stats (vnstat-lite)"
ui_print "  ==========================="
ui_print " "
ui_print "  Per-interface RX/TX daily accumulator."
ui_print "  Polls /proc/net/dev every 60 s."
ui_print "  DB at /data/traffic-stats/"
ui_print " "
ui_print "  Requires bin-utils v1.2.0+ (for static bash)."
ui_print " "

mkdir -p /data/traffic-stats
chmod 755 /data/traffic-stats

set_perm "$MODPATH/service.sh"  0 0 0755
set_perm "$MODPATH/poller.sh"   0 0 0755

ui_print "  [OK] Installed."
ui_print "  Daemon starts at late_start (boot)."
ui_print "  Bot reads it via /traffic_history (statusbot v2.12+)."
ui_print " "
