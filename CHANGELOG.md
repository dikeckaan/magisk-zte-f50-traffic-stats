# Changelog

## v1.0.0
- Initial public release
- Pure-shell vnstat-lite: polls /proc/net/dev every 60 s, accumulates per-iface daily RX/TX
- Survives kernel counter resets across reboots
- Requires bin-utils v1.2.0+ (static bash for assoc arrays + indirect expansion)
