#!/system/bin/sh
# Traffic Stats daemon — vnstat-lite, pure shell, polls /proc/net/dev every
# 60 s and accumulates per-interface RX/TX bytes into daily files. Survives
# counter resets (boot wipes /proc/net/dev counters back to 0).
#
# DB layout:
#   /data/traffic-stats/.snapshot          last seen counters
#   /data/traffic-stats/<iface>/<YYYY-MM-DD>   "rx=N\ntx=N\nsamples=N"
#   /data/traffic-stats/daemon.log         restart log

DB=/data/traffic-stats
SNAP="$DB/.snapshot"
LOG="$DB/daemon.log"
INTERVAL=60

mkdir -p "$DB"

# Locate bash (provided by bin-utils — needed for ${!var} indirect expansion).
BASH=""
for p in /system/bin/bash \
         /data/adb/modules/bin-utils/system/bin/bash \
         /data/adb/modules_update/bin-utils/system/bin/bash; do
    [ -x "$p" ] && BASH="$p" && break
done
if [ -z "$BASH" ]; then
    echo "[$(date)] FATAL: bash not found, install bin-utils v1.2.0+" >> "$LOG"
    exit 1
fi

# Warm-up: let cellular/wifi come up
sleep 30

# Run poller under bash in a supervised loop
(
    while true; do
        echo "[$(date)] starting traffic-stats poller (interp: $BASH)" >> "$LOG"
        "$BASH" /data/adb/modules/traffic-stats/poller.sh >> "$LOG" 2>&1
        rc=$?
        echo "[$(date)] poller exited rc=$rc, restarting in 10 s" >> "$LOG"
        # Rotate log if huge
        sz=$(stat -c %s "$LOG" 2>/dev/null || echo 0)
        [ "$sz" -gt 524288 ] && mv "$LOG" "$LOG.1"
        sleep 10
    done
) &
