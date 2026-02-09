#!/usr/bin/env bash
# Zellij sessionizer — meant to be called from the zj shell function.
# Inside Zellij, use the session-manager plugin (Ctrl-a f) instead.
set -euo pipefail

sessions=$(zellij ls -s 2>/dev/null || true)
selected=$(
  {
    [[ -n "$sessions" ]] && echo "$sessions"
    zoxide query -l 2>/dev/null | head -40
  } | fzf --prompt=" " --scheme=path
) || exit 0

if [[ -n "$sessions" ]] && echo "$sessions" | grep -qxF "$selected"; then
  exec zellij attach "$selected"
fi

dir="$selected"
name="$(basename "$dir")"
name="${name// /-}"
name="${name//./-}"
cd "$dir" && exec zellij attach -c "$name"
