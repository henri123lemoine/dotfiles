#!/usr/bin/env bash
# One-time installer for the claude-notify-listener launch agent on macOS.
# Re-run safely after pulling dotfiles updates.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "claude-notify install.sh: macOS only, skipping." >&2
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_SRC="$SCRIPT_DIR/com.henri.claude-notify-listener.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.henri.claude-notify-listener.plist"

if ! command -v terminal-notifier >/dev/null 2>&1; then
  echo "claude-notify install.sh: terminal-notifier not on PATH; install it first (brew bundle)." >&2
  exit 1
fi

mkdir -p "$HOME/Library/LaunchAgents"

ln -sfn "$PLIST_SRC" "$PLIST_DEST"

launchctl unload "$PLIST_DEST" 2>/dev/null || true
launchctl load "$PLIST_DEST"

echo "✓ Installed and loaded com.henri.claude-notify-listener"
echo "  Plist: $PLIST_DEST -> $PLIST_SRC"
echo "  Log:   $HOME/Library/Logs/claude-notify-listener.log"
echo
echo "Quick test (should pop a Mac notification):"
echo "  printf 'Stop|local-test\\n' | nc -w1 127.0.0.1 9876"
