#!/bin/bash
# Wrapper that monitors spotifyd and restarts it when its Spotify session dies.
# After sleep/wake or network changes, spotifyd's session breaks but the process
# stays alive. This wrapper detects that via log patterns and restarts it.

SPOTIFYD="$HOME/.cargo/bin/spotifyd"
CONFIG="$HOME/.config/spotifyd/spotifyd.conf"
CACHE="$HOME/.cache/spotifyd"
LOG="$CACHE/spotifyd.out.log"
ERRLOG="$CACHE/spotifyd.err.log"

trap 'kill "$SPID" 2>/dev/null; exit 0' SIGTERM SIGINT

while true; do
    : > "$LOG"
    : > "$ERRLOG"

    "$SPOTIFYD" --no-daemon --backend rodio \
        --config-path "$CONFIG" --cache-path "$CACHE" \
        >>"$LOG" 2>>"$ERRLOG" &
    SPID=$!

    sleep 20

    while kill -0 "$SPID" 2>/dev/null; do
        sleep 15
        if grep -q "Connection to server closed" "$LOG" 2>/dev/null; then
            kill "$SPID" 2>/dev/null
            break
        fi
    done

    wait "$SPID" 2>/dev/null
    sleep 5
done
