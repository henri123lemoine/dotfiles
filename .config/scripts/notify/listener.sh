#!/usr/bin/env bash
# Listens on 127.0.0.1:$NOTIFY_PORT for notification triggers forwarded from
# remote machines over a reverse SSH tunnel (see Host work in ~/.ssh/config,
# RemoteForward 9876 127.0.0.1:9876).
#
# Wire format: one line per notification, EVENT|TARGET
#   EVENT  = "Stop" | "Notification" | "Blocker"
#   TARGET = free-form label, typically "host:session:window.pane"
set -u

PORT="${NOTIFY_PORT:-9876}"
VOLUME="${NOTIFY_VOLUME:-0.8}"
NOTIFIER=$(command -v terminal-notifier) || {
  echo "notify-listener: terminal-notifier not found on PATH" >&2
  exit 1
}

while IFS= read -r line; do
  [ -z "$line" ] && continue
  event="${line%%|*}"
  target="${line#*|}"
  [ "$target" = "$event" ] && target="remote"
  sound=""
  case "$event" in
    Notification) title="Needs input" ;;
    Blocker)      title="Blocked"; sound="/System/Library/Sounds/Basso.aiff" ;;
    *)            title="Done" ;;
  esac
  [ -n "$sound" ] && (afplay -v "$VOLUME" "$sound" >/dev/null 2>&1 &)
  "$NOTIFIER" \
    -title "$title" \
    -message "$target" \
    -group "notify-remote-$target" \
    >/dev/null 2>&1 || true
done < <(nc -kl 127.0.0.1 "$PORT" 2>/dev/null)
