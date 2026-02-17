#!/bin/bash

if ! pgrep -x spotifyd > /dev/null; then
    ~/.cargo/bin/spotifyd --backend rodio \
        --config-path ~/.config/spotifyd/spotifyd.conf \
        --cache-path ~/.cache/spotifyd
    sleep 3
fi

exec spotify_player "$@"
