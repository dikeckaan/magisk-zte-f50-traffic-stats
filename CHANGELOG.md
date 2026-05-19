# Changelog

## v1.0.1 — 2026-05-19
- **Service migration to `bin-utils/lib/common.sh`** (now a hard dep,
  v1.3.0+ required). `service.sh` calls `find_bash`, `log_line`, and
  `log_rotate` from the shared library instead of duplicating them.
  Net: 45 → 36 lines.
- `customize.sh` now hard-requires bin-utils v1.3.0+ at install time.
- Behaviour unchanged.

## v1.0.0
- Initial public release
- Pure-shell vnstat-lite: polls /proc/net/dev every 60 s, accumulates per-iface daily RX/TX
- Survives kernel counter resets across reboots
- Requires bin-utils v1.2.0+ (static bash for assoc arrays + indirect expansion)
