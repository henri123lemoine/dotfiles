#!/bin/bash

start_spotifyd() {
    spotifyd --config-path ~/.config/spotifyd/spotifyd.conf --cache-path ~/.cache/spotifyd
    sleep 2
}

if ! pgrep -x spotifyd > /dev/null; then
    start_spotifyd
else
    last_auth=$(grep -n "Authenticated as" ~/.cache/spotifyd/spotifyd.out.log 2>/dev/null | tail -1 | cut -d: -f1)
    last_error=$(grep -n "No route to host" ~/.cache/spotifyd/spotifyd.out.log 2>/dev/null | tail -1 | cut -d: -f1)

    if [[ -n "$last_error" && -n "$last_auth" && "$last_error" -gt "$last_auth" ]]; then
        if [[ $((last_error - last_auth)) -gt 10 ]]; then
            pkill -x spotifyd
            sleep 1
            start_spotifyd
        fi
    fi
fi

exec spotify_player "$@"
