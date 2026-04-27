#!/usr/bin/env bash
# Claude Code Stop/Notification hook: macOS notification, click jumps to the
# originating tmux pane. Skipped when that pane is already the focused pane
# of an attached client. First arg is the hook event name ("Stop" or
# "Notification").
set -u

cat >/dev/null 2>&1 || true

[ -n "${TMUX_PANE:-}" ] || exit 0
TMUX_BIN=$(command -v tmux) || exit 0
NOTIFIER=$(command -v terminal-notifier) || exit 0

info=$("$TMUX_BIN" display-message -p -t "$TMUX_PANE" \
  '#{session_name}:#{window_index}.#{pane_index}|#{pane_active}|#{window_active}|#{session_attached}' 2>/dev/null) || exit 0

IFS='|' read -r target pane_active window_active session_attached <<<"$info"
[ -n "$target" ] || exit 0

if [ "$pane_active" = "1" ] && [ "$window_active" = "1" ] && [ "${session_attached:-0}" != "0" ]; then
  exit 0
fi

case "${1:-Stop}" in
  Notification) title="Claude needs input" ;;
  *)            title="Claude done" ;;
esac

safe_target=${target//\'/\'\\\'\'}
execute="'$TMUX_BIN' switch-client -t '$safe_target' && '$TMUX_BIN' select-window -t '$safe_target' && '$TMUX_BIN' select-pane -t '$safe_target'"

"$NOTIFIER" \
  -title "$title" \
  -message "$target" \
  -group "claude-$TMUX_PANE" \
  -execute "$execute" >/dev/null 2>&1 || true

exit 0
