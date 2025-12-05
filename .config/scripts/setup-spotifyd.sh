#!/bin/bash
# Setup script for spotifyd launch agent
# Run after ./setup to configure spotifyd on a new machine

set -e

PLIST_PATH="$HOME/Library/LaunchAgents/local.spotifyd.plist"
CACHE_DIR="$HOME/.cache/spotifyd"

# Create cache directory
mkdir -p "$CACHE_DIR"

# Create launch agent with correct paths
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
		<string>/opt/homebrew/opt/spotifyd/bin/spotifyd</string>
		<string>--no-daemon</string>
		<string>--config-path</string>
		<string>$HOME/.config/spotifyd/spotifyd.conf</string>
		<string>--cache-path</string>
		<string>$CACHE_DIR</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StandardErrorPath</key>
	<string>$CACHE_DIR/spotifyd.err.log</string>
	<key>StandardOutPath</key>
	<string>$CACHE_DIR/spotifyd.out.log</string>
</dict>
</plist>
EOF

echo "Created launch agent at $PLIST_PATH"

# Authenticate with Spotify
echo ""
echo "Now authenticating with Spotify..."
echo "A browser will open - log in to your Spotify account."
echo ""
spotifyd authenticate --cache-path "$CACHE_DIR"

# Load the launch agent
launchctl load "$PLIST_PATH"
echo ""
echo "spotifyd is now running!"
echo ""
echo "Next: run 'spotify_player authenticate' to set up the TUI player."
