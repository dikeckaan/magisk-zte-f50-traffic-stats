#!/system/bin/bash
# Traffic stats poller — runs forever, reads /proc/net/dev each INTERVAL,
# diffs against last snapshot, accumulates per-iface daily totals.

DB=/data/traffic-stats
SNAP="$DB/.snapshot"
INTERVAL="${TRAFFIC_INTERVAL:-60}"

mkdir -p "$DB"

# Interfaces to track (skip loopback + virtual)
SKIP_RE='^(lo|sit0|ip6tnl0|gre0|gretap0|erspan0|tunl0|ip_vti0|ip6_vti0|ip6gre0|dummy0|sipa_dummy[0-9]|sipa_eth[1-9])$'

declare -A PREV_RX PREV_TX

# Load previous snapshot if present (one line per iface: "iface rx tx")
if [ -r "$SNAP" ]; then
    while IFS=' ' read -r iface rx tx; do
        [ -z "$iface" ] && continue
        PREV_RX[$iface]="$rx"
        PREV_TX[$iface]="$tx"
    done < "$SNAP"
fi

# Append delta to daily file. $1=iface $2=delta_rx $3=delta_tx
accumulate() {
    local iface="$1" drx="$2" dtx="$3"
    local today
    today=$(date +%Y-%m-%d)
    local idir="$DB/$iface"
    mkdir -p "$idir"
    local f="$idir/$today"
    local cur_rx=0 cur_tx=0 cur_samples=0
    if [ -r "$f" ]; then
        cur_rx=$(awk -F= '/^rx=/{print $2}' "$f")
        cur_tx=$(awk -F= '/^tx=/{print $2}' "$f")
        cur_samples=$(awk -F= '/^samples=/{print $2}' "$f")
        : "${cur_rx:=0}" "${cur_tx:=0}" "${cur_samples:=0}"
    fi
    local new_rx=$(( cur_rx + drx ))
    local new_tx=$(( cur_tx + dtx ))
    local new_samples=$(( cur_samples + 1 ))
    {
        echo "rx=$new_rx"
        echo "tx=$new_tx"
        echo "samples=$new_samples"
        echo "updated=$(date +%s)"
    } > "$f"
}

while true; do
    declare -A CUR_RX CUR_TX
    # /proc/net/dev format (skip 2 header lines):
    # iface: rx_bytes packets errs drop fifo frame compressed multicast tx_bytes packets ...
    while IFS= read -r line; do
        # Strip leading spaces, split on ':'
        case "$line" in
            *Inter*|*face*|"") continue ;;
        esac
        iface="${line%%:*}"
        iface="${iface## }"
        iface="${iface%% }"
        # Skip filtered interfaces
        echo "$iface" | grep -qE "$SKIP_RE" && continue
        # Parse counters
        rest="${line#*:}"
        # shellcheck disable=SC2086
        set -- $rest
        rx_bytes="$1"
        tx_bytes="$9"
        [ -z "$rx_bytes" ] && continue
        CUR_RX[$iface]="$rx_bytes"
        CUR_TX[$iface]="$tx_bytes"
    done < /proc/net/dev

    # Diff and accumulate
    new_snap=""
    for iface in "${!CUR_RX[@]}"; do
        cur_rx="${CUR_RX[$iface]}"
        cur_tx="${CUR_TX[$iface]}"
        prev_rx="${PREV_RX[$iface]:-}"
        prev_tx="${PREV_TX[$iface]:-}"

        if [ -z "$prev_rx" ]; then
            # First sighting — no delta yet, just record
            :
        else
            drx=$(( cur_rx - prev_rx ))
            dtx=$(( cur_tx - prev_tx ))
            # Counter reset detection (kernel counter wrap or interface down/up)
            [ "$drx" -lt 0 ] && drx="$cur_rx"
            [ "$dtx" -lt 0 ] && dtx="$cur_tx"
            # Sanity: ignore absurd jumps (>10 GB/min, almost certainly reset)
            if [ "$drx" -lt 10737418240 ] && [ "$dtx" -lt 10737418240 ]; then
                accumulate "$iface" "$drx" "$dtx"
            fi
        fi
        PREV_RX[$iface]="$cur_rx"
        PREV_TX[$iface]="$cur_tx"
        new_snap="${new_snap}${iface} ${cur_rx} ${cur_tx}
"
    done

    # Write snapshot atomically
    printf '%s' "$new_snap" > "$SNAP.tmp" && mv "$SNAP.tmp" "$SNAP"

    sleep "$INTERVAL"
done
