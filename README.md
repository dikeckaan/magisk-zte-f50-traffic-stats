# traffic-stats (vnstat-lite)

A tiny pure-shell traffic accounting daemon for rooted Android. Polls
`/proc/net/dev` every 60 s, diffs counters, and accumulates per-interface
RX/TX bytes into daily files. Survives kernel counter resets (boot wipes
`/proc/net/dev` back to zero — we detect that and restart the day's
accumulation from the new baseline).

## Why not real vnstat?

Real vnstat is a great tool but on Android it has to fight Bionic/musl
mismatch and SQLite linkage. This module reimplements its core in ~80 lines
of bash, with zero binary dependencies (other than `bin-utils`'s static
bash, which `statusbot` already requires).

Trade-off: no live monitor mode, no fancy graphs, no SQLite. We get monthly
totals, per-day breakdowns, and per-interface separation — which is what a
MiFi user actually needs (track cellular usage vs. monthly cap).

## Use case

Track how much cellular data you used today / this month, without trusting
the operator's portal. Particularly useful when the device is a hotspot
serving multiple clients and you want to know whether you're approaching
a data cap.

## DB layout

```
/data/traffic-stats/
├── .snapshot                    # last seen counters (iface rx tx)
├── daemon.log                   # restart / supervisor log
├── sipa_eth0/                   # cellular WAN
│   ├── 2026-05-19               # rx=N\ntx=N\nsamples=N\nupdated=epoch
│   ├── 2026-05-20
│   └── …
├── wlan0/                       # WiFi STA (if used)
└── br0/                         # hotspot bridge
```

Each daily file contains:
```
rx=104857600
tx=20971520
samples=1440
updated=1779228000
```

## How it survives counter resets

On boot, `/proc/net/dev` counters reset to 0. The poller detects that the
current read is *less* than the previous snapshot and treats the current
value as a fresh delta (i.e. counts the post-reset bytes from zero). The
day's accumulation continues across reboots without losing or
double-counting bytes.

## Requirements

- Magisk 20.4+
- Android arm64
- **`bin-utils` v1.2.0+** (for the static `bash` binary — `${!var}` indirect
  expansion and associative arrays aren't in toybox sh)

## Installation

1. Make sure `bin-utils` is installed.
2. Flash this module.
3. Reboot (or wait for `late_start service` to spawn the daemon at next boot).

The daemon's pid is implicit (supervisor loop in `service.sh`); to stop it
manually:

```
pkill -f /data/adb/modules/traffic-stats/poller.sh
```

It will be auto-restarted by the supervisor within ~10 s.

## Bot integration

[statusbot](https://github.com/dikeckaan/magisk-zte-f50-statusbot) v2.12+
adds a `/traffic_history` command that reads this DB and reports:

```
📊 Traffic — sipa_eth0 (cellular)
Today:     1.4 GB ↓ / 280 MB ↑
This week: 8.2 GB total
This month: 23.4 GB total
Avg/day:   1.1 GB
```

## Uninstall

Removing the module via Magisk Manager runs `uninstall.sh` which stops the
daemon. The DB at `/data/traffic-stats/` is **preserved** — delete manually
if you want to wipe history:

```
rm -rf /data/traffic-stats
```

## License

GPL-3.0
