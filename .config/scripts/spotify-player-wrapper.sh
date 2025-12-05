#!/bin/bash

# Check if spotifyd is running and healthy
# If not, spawn it
if ! pgrep -x spotifyd > /dev/null; then
    launchctl load ~/Library/LaunchAgents/local.spotifyd.plist 2>/dev/null
    sleep 2
else
    last_auth=$(grep -n "Authenticated as" ~/.cache/spotifyd/spotifyd.out.log 2>/dev/null | tail -1 | cut -d: -f1)
    last_error=$(grep -n "No route to host" ~/.cache/spotifyd/spotifyd.out.log 2>/dev/null | tail -1 | cut -d: -f1)

    if [[ -n "$last_error" && -n "$last_auth" && "$last_error" -gt "$last_auth" ]]; then
        if [[ $((last_error - last_auth)) -gt 10 ]]; then
            launchctl unload ~/Library/LaunchAgents/local.spotifyd.plist 2>/dev/null
            launchctl load ~/Library/LaunchAgents/local.spotifyd.plist 2>/dev/null
            sleep 2
        fi
    fi
fi

exec spotify_player "$@"
