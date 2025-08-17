#!/bin/bash

# MPD/RMPC Reload Script
# This script restarts MPD and updates the music database

set -e

echo "🎵 Reloading MPD and RMPC..."

# Stop MPD if running
echo "📡 Stopping MPD..."
brew services stop mpd 2>/dev/null || true

# Wait a moment for clean shutdown
sleep 2

# Start MPD
echo "🚀 Starting MPD..."
brew services start mpd

# Wait for MPD to fully start
echo "⏳ Waiting for MPD to start..."
sleep 3

# Test connection and update database
echo "🔄 Updating music database..."
mpc update

# Show status
echo "✅ MPD Status:"
mpc status

echo ""
echo "🎶 MPD/RMPC reload complete!"
echo "💡 You can now use rmpc with YouTube URLs:"
echo "   - Open rmpc (Ctrl+V in tmux)"
echo "   - Press ':' for command mode"
echo "   - Type: add yt <YouTube_URL>"
echo ""