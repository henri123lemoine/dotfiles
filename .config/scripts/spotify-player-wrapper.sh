#!/bin/bash

spotifyd_healthy() {
    local pid=$(pgrep -x spotifyd)
    [ -z "$pid" ] && return 1

    local start_epoch wake_epoch
    start_epoch=$(date -j -f "%a %d %b %T %Y" "$(ps -o lstart= -p "$pid" | xargs)" "+%s" 2>/dev/null)
    wake_epoch=$(sysctl -n kern.waketime 2>/dev/null | sed 's/{ sec = \([0-9]*\).*/\1/')
    [ -n "$wake_epoch" ] && [ -n "$start_epoch" ] && [ "$wake_epoch" -gt "$start_epoch" ] && return 1

    lsof -p "$pid" -i TCP -n -P 2>/dev/null | grep ESTABLISHED | grep -qv ":4444"
}

if ! spotifyd_healthy; then
    pkill -x spotifyd 2>/dev/null && sleep 1
    ~/.cargo/bin/spotifyd --backend rodio \
        --config-path ~/.config/spotifyd/spotifyd.conf \
        --cache-path ~/.cache/spotifyd
    sleep 3
fi

exec spotify_player "$@"
