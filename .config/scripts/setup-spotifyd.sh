#!/bin/bash
# Setup script for spotifyd launch agent
# Run after ./setup to configure spotifyd on a new machine

set -e

PLIST_PATH="$HOME/Library/LaunchAgents/local.spotifyd.plist"
CACHE_DIR="$HOME/.cache/spotifyd"
WRAPPER="$HOME/.config/scripts/spotifyd-wrapper.sh"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Build spotifyd with rodio backend (handles CoreAudio channel negotiation)
if [ ! -f "$HOME/.cargo/bin/spotifyd" ] || ! "$HOME/.cargo/bin/spotifyd" --help 2>&1 | grep -q rodio; then
	echo "Building spotifyd with rodio backend..."
	cargo install spotifyd --locked --no-default-features --features rodio_backend
fi

# Create launch agent — runs the wrapper which monitors health and auto-restarts
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>KeepAlive</key>
	<true/>
	<key>Label</key>
	<string>local.spotifyd</string>
	<key>LimitLoadToSessionType</key>
	<array>
		<string>Aqua</string>
		<string>Background</string>
		<string>LoginWindow</string>
		<string>StandardIO</string>
		<string>System</string>
	</array>
	<key>ProgramArguments</key>
	<array>
		<string>/bin/bash</string>
		<string>$WRAPPER</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
EOF

echo "Created launch agent at $PLIST_PATH"

# Authenticate with Spotify
echo ""
echo "Now authenticating with Spotify..."
echo "A browser will open - log in to your Spotify account."
echo ""
"$HOME/.cargo/bin/spotifyd" authenticate --cache-path "$CACHE_DIR"

# Load the launch agent
launchctl load "$PLIST_PATH"
echo ""
echo "spotifyd is now running!"
echo ""
echo "Next: run 'spotify_player authenticate' to set up the TUI player."
