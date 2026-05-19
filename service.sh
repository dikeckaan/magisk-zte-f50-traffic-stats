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
LOG="$DB/daemon.log"

mkdir -p "$DB"

# bin-utils v1.3.0+ provides bash + common.sh (hard requirement).
. /data/adb/modules/bin-utils/lib/common.sh

BASH=$(find_bash) || {
    log_line "FATAL: bash not found via find_bash, install bin-utils v1.3.0+"
    exit 1
}

# Warm-up: let cellular/wifi come up before the first poll.
sleep 30

# Supervisor loop. log_rotate runs each iteration to cap log growth.
(
    while true; do
        log_rotate 524288
        log_line "starting traffic-stats poller (interp: $BASH)"
        "$BASH" /data/adb/modules/traffic-stats/poller.sh >> "$LOG" 2>&1
        log_line "poller exited rc=$?, restarting in 10 s"
        sleep 10
    done
) &
