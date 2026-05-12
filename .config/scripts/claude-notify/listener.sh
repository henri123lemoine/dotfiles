#!/usr/bin/env bash
# Listens on 127.0.0.1:$CLAUDE_NOTIFY_PORT for Claude Code notification triggers
# forwarded from remote machines over a reverse SSH tunnel (see Host work in
# ~/.ssh/config, RemoteForward 9876 127.0.0.1:9876).
#
# Wire format: one line per notification, EVENT|TARGET
#   EVENT  = "Stop" | "Notification"
#   TARGET = free-form label, typically "host:session:window.pane"
set -u

PORT="${CLAUDE_NOTIFY_PORT:-9876}"
NOTIFIER=$(command -v terminal-notifier) || {
  echo "claude-notify-listener: terminal-notifier not found on PATH" >&2
  exit 1
}

while IFS= read -r line; do
  [ -z "$line" ] && continue
  event="${line%%|*}"
  target="${line#*|}"
  [ "$target" = "$event" ] && target="remote"
  case "$event" in
    Notification) title="Claude needs input" ;;
    *)            title="Claude done" ;;
  esac
  "$NOTIFIER" \
    -title "$title" \
    -message "$target" \
    -group "claude-remote-$target" \
    >/dev/null 2>&1 || true
done < <(nc -kl 127.0.0.1 "$PORT" 2>/dev/null)
