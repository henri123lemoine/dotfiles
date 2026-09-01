#!/usr/bin/env bash
# One-time installer for the pin-builtin-mic launch agent on macOS.
# Re-run safely after pulling dotfiles updates.
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "pin-builtin-mic install.sh: macOS only, skipping." >&2
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_SRC="$SCRIPT_DIR/com.henri.pin-builtin-mic.plist"
PLIST_DEST="$HOME/Library/LaunchAgents/com.henri.pin-builtin-mic.plist"

swiftc -O -o "$SCRIPT_DIR/pin-builtin-mic" "$SCRIPT_DIR/pin-builtin-mic.swift"

mkdir -p "$HOME/Library/LaunchAgents"

ln -sfn "$PLIST_SRC" "$PLIST_DEST"

launchctl unload "$PLIST_DEST" 2>/dev/null || true
launchctl load "$PLIST_DEST"

echo "✓ Installed and loaded com.henri.pin-builtin-mic"
echo "  Plist: $PLIST_DEST -> $PLIST_SRC"
echo "  Log:   $HOME/Library/Logs/pin-builtin-mic.log"
