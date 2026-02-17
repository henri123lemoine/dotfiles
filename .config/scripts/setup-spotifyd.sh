#!/bin/bash
# Setup script for spotifyd on a new machine
# Run after ./setup to build, authenticate, and verify spotifyd

set -e

CACHE_DIR="$HOME/.cache/spotifyd"
PLIST_PATH="$HOME/Library/LaunchAgents/local.spotifyd.plist"

mkdir -p "$CACHE_DIR"

# Build spotifyd with rodio backend (handles CoreAudio channel negotiation)
if [ ! -f "$HOME/.cargo/bin/spotifyd" ] || ! "$HOME/.cargo/bin/spotifyd" --help 2>&1 | grep -q rodio; then
	echo "Building spotifyd with rodio backend..."
	cargo install spotifyd --locked --no-default-features --features rodio_backend
fi

# Remove legacy LaunchAgent if present (spotifyd is now started on-demand by spotify-player-wrapper.sh)
if [ -f "$PLIST_PATH" ]; then
	launchctl bootout "gui/$(id -u)/local.spotifyd" 2>/dev/null || true
	rm -f "$PLIST_PATH"
	echo "Removed legacy LaunchAgent."
fi

# Authenticate with Spotify
echo ""
echo "Authenticating with Spotify..."
echo "A browser will open - log in to your Spotify account."
echo ""
"$HOME/.cargo/bin/spotifyd" authenticate --cache-path "$CACHE_DIR"

echo ""
echo "spotifyd is ready! It will start automatically when you open spotify_player (tmux prefix+m)."
echo ""
echo "Next: run 'spotify_player authenticate' to set up the TUI player."
