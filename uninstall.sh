#!/system/bin/sh
# Stop the poller if running, keep the DB (user may want to inspect/back up)
pkill -f /data/adb/modules/traffic-stats/poller.sh 2>/dev/null
pkill -f /data/adb/modules/traffic-stats/service.sh 2>/dev/null
# DB stays at /data/traffic-stats — remove manually if desired:
#   rm -rf /data/traffic-stats
