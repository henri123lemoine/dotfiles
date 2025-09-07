#!/bin/bash
# Extract tmux pane content for preview

tmux_target="$1"
lines="${2:-}"

if [[ -z "$tmux_target" ]]; then
    echo "Usage: $0 <tmux_target> [lines]"
    exit 1
fi

# Check if target exists
if ! tmux list-panes -a -F "#{session_name}:#{window_index}.#{pane_index}" | grep -q "^$tmux_target$"; then
    echo "Pane $tmux_target not found"
    exit 1
fi

# Capture the pane with ANSI formatting preserved
if [[ -n "$lines" ]]; then
    tmux capture-pane -t "$tmux_target" -e -p | tail -n "$lines"
else
    tmux capture-pane -t "$tmux_target" -e -p
fi