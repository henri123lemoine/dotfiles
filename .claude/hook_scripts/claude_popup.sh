#!/bin/bash
# Claude Code tmux popup with fzf selection

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WAITING_ONLY=${1:-""}

# Get instances (--waiting flag if first arg is "waiting")
if [[ "$WAITING_ONLY" == "waiting" ]]; then
    instances=$(python3 "$SCRIPT_DIR/claude_instances.py" --waiting --json 2>/dev/null)
    header="Select waiting Claude instance:"
    prompt="Waiting > "
else
    instances=$(python3 "$SCRIPT_DIR/claude_instances.py" --json 2>/dev/null)
    header="Select Claude instance:"
    prompt="Claude > "
fi

# Check if we have instances
if [[ -z "$instances" ]] || ! echo "$instances" | python3 -m json.tool >/dev/null 2>&1; then
    echo "No Claude Code instances found."
    read -p "Press Enter to continue..."
    exit 0
fi

# Convert JSON to fzf format with colors
fzf_input=$(echo "$instances" | python3 -c "
import json, sys
try:
    for inst in json.load(sys.stdin):
        status, target, session, path = inst['status'], inst['tmux_target'], inst['session_name'], inst['working_directory']
        emoji = {'waiting_for_input': '⏳', 'processing': '⚡', 'active': '💻'}[status]
        color = '\033[1;33m' if status == 'waiting_for_input' else ('\033[1;32m' if status == 'processing' else '')
        reset = '\033[0m' if color else ''
        print(f'{color}{emoji} {status.replace(\"_\", \" \").title()} | {target} ({session}) | {path}{reset}')
except: pass
")

# Exit if no instances
[[ -z "$fzf_input" ]] && exit 0

# Show fzf selection
selected=$(echo "$fzf_input" | fzf \
    --height=100% --layout=reverse --header="$header" --prompt="$prompt" \
    --border --ansi --no-sort --tiebreak=begin)

# Exit if nothing selected
[[ -z "$selected" ]] && exit 0

# Extract tmux target and switch
tmux_target=$(echo "$selected" | awk -F' \\| ' '{print $2}' | awk '{print $1}')
[[ -n "$tmux_target" ]] && tmux switch-client -t "$tmux_target"
