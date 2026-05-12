#!/usr/bin/env bash
# Claude Code Stop/Notification hook.
#
# On macOS (terminal-notifier present): show a native banner whose click jumps
# to the originating tmux pane via tmux switch-client/select-window/select-pane.
#
# On Linux (e.g. EC2 over SSH) or anywhere terminal-notifier is missing: forward
# EVENT|TARGET to 127.0.0.1:$CLAUDE_NOTIFY_PORT (default 9876), where the Mac's
# claude-notify-listener picks it up via a reverse SSH tunnel and shows the
# banner locally.
#
# In both modes, skipped when the originating tmux pane is already the focused
# pane of an attached client. First arg is the hook event name.
set -u

cat >/dev/null 2>&1 || true

EVENT="${1:-Stop}"
PORT="${CLAUDE_NOTIFY_PORT:-9876}"

target=""
if [ -n "${TMUX_PANE:-}" ] && TMUX_BIN=$(command -v tmux); then
  info=$("$TMUX_BIN" display-message -p -t "$TMUX_PANE" \
    '#{session_name}:#{window_index}.#{pane_index}|#{pane_active}|#{window_active}|#{session_attached}' 2>/dev/null) || info=""
  if [ -n "$info" ]; then
    IFS='|' read -r target pane_active window_active session_attached <<<"$info"
    if [ "$pane_active" = "1" ] && [ "$window_active" = "1" ] && [ "${session_attached:-0}" != "0" ]; then
      exit 0
    fi
  fi
fi

if NOTIFIER=$(command -v terminal-notifier); then
  [ -n "$target" ] || exit 0
  TMUX_BIN=${TMUX_BIN:-$(command -v tmux)} || exit 0
  case "$EVENT" in
    Notification) title="Claude needs input" ;;
    *)            title="Claude done" ;;
  esac
  safe_target=${target//\'/\'\\\'\'}
  execute="'$TMUX_BIN' switch-client -t '$safe_target' && '$TMUX_BIN' select-window -t '$safe_target' && '$TMUX_BIN' select-pane -t '$safe_target'"
  "$NOTIFIER" \
    -title "$title" \
    -message "$target" \
    -group "claude-${TMUX_PANE:-local}" \
    -execute "$execute" >/dev/null 2>&1 || true
  exit 0
fi

command -v nc >/dev/null 2>&1 || exit 0
host=$(hostname -s 2>/dev/null || hostname || echo remote)
label="$host"
[ -n "$target" ] && label="$host:$target"
printf '%s|%s\n' "$EVENT" "$label" | nc -w1 -q0 127.0.0.1 "$PORT" >/dev/null 2>&1 || \
  printf '%s|%s\n' "$EVENT" "$label" | nc -w1 127.0.0.1 "$PORT" >/dev/null 2>&1 || true

exit 0
