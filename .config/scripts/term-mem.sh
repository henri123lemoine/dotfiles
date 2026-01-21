#!/usr/bin/env bash
# Analyze memory usage of processes running in terminal sessions

set -euo pipefail

echo "=== Terminal Memory Analysis ==="
echo ""

# Build TTY → tmux pane mapping
declare -A tty_to_pane
if command -v tmux &>/dev/null && tmux list-sessions &>/dev/null; then
    while IFS= read -r line; do
        tty=$(echo "$line" | awk '{print $1}' | sed 's|/dev/tty||')
        pane=$(echo "$line" | awk '{print $2}')
        tty_to_pane["$tty"]="$pane"
    done < <(tmux list-panes -a -F "#{pane_tty} #{session_name}:#{window_name}.#{pane_index}")
fi

tty_to_location() {
    local tty="$1"
    if [[ -n "${tty_to_pane[$tty]:-}" ]]; then
        echo "${tty_to_pane[$tty]}"
    else
        echo "$tty"
    fi
}

# Get all processes with a tty (terminal)
mapfile -t procs < <(ps aux | awk '$7 ~ /s[0-9]+/ && $7 != "??" {print}' | sort -k6 -rn)

if [[ ${#procs[@]} -eq 0 ]]; then
    echo "No terminal processes found."
    exit 0
fi

# Categorize processes
declare -A category_mem
declare -A category_count

for proc in "${procs[@]}"; do
    cmd=$(echo "$proc" | awk '{for(i=11;i<=NF;i++) printf $i" "; print ""}' | sed 's/^ *//;s/ *$//')
    mem_kb=$(echo "$proc" | awk '{print $6}')

    category=""
    if [[ "$cmd" =~ claude ]]; then
        category="claude"
    elif [[ "$cmd" =~ pyright|typescript-language-server|tailwindcss|eslint.*server ]]; then
        category="lsp"
    elif [[ "$cmd" =~ node|npm|npx|bun ]]; then
        category="node"
    elif [[ "$cmd" =~ ^-?zsh$ ]] || [[ "$cmd" =~ ^-?bash$ ]]; then
        category="shell"
    elif [[ "$cmd" =~ nvim|vim ]]; then
        category="editor"
    elif [[ "$cmd" =~ python|python3 ]]; then
        category="python"
    else
        category="other"
    fi

    category_mem[$category]=$(( ${category_mem[$category]:-0} + mem_kb ))
    category_count[$category]=$(( ${category_count[$category]:-0} + 1 ))
done

# Summary by category
printf "%-10s | %6s | %s\n" "Category" "Memory" "Count"
printf "%s\n" "-----------|--------|------"

total_mem=0
for cat in claude lsp node editor python shell other; do
    if [[ -n "${category_mem[$cat]:-}" ]]; then
        mem_mb=$(( ${category_mem[$cat]} / 1024 ))
        total_mem=$(( total_mem + ${category_mem[$cat]} ))
        printf "%-10s | %5d MB | %d\n" "$cat" "$mem_mb" "${category_count[$cat]}"
    fi
done
echo ""
echo "Total: $((total_mem / 1024)) MB across ${#procs[@]} processes"

# Top processes by memory
echo ""
echo "=== Top 15 processes by memory ==="
printf "%-8s | %-25s | %-10s | %s\n" "Memory" "Location" "Started" "Command"
printf "%s\n" "---------|---------------------------|------------|--------"

count=0
for proc in "${procs[@]}"; do
    [[ $count -ge 15 ]] && break
    mem_kb=$(echo "$proc" | awk '{print $6}')
    mem_mb=$((mem_kb / 1024))
    tty=$(echo "$proc" | awk '{print $7}')
    started=$(echo "$proc" | awk '{print $9}')
    location=$(tty_to_location "$tty")
    cmd=$(echo "$proc" | awk '{for(i=11;i<=NF;i++) printf $i" "}' | cut -c1-40 | sed 's/ *$//')

    printf "%-8s | %-25s | %-10s | %s\n" "${mem_mb} MB" "$location" "$started" "$cmd"
    count=$((count + 1))
done

# Claude-specific section (if any running)
claude_procs=$(ps aux | grep -E 'claude.*--dangerously-skip-permissions$' | grep -v grep | sort -k6 -rn || true)
if [[ -n "$claude_procs" ]]; then
    echo ""
    echo "=== Claude Code instances ==="
    printf "%-8s | %-25s | %-10s | %s\n" "Memory" "Location" "Started" "Project"
    printf "%s\n" "---------|---------------------------|------------|--------"

    declare -A dir_count
    while IFS= read -r proc; do
        pid=$(echo "$proc" | awk '{print $2}')
        mem_kb=$(echo "$proc" | awk '{print $6}')
        mem_mb=$((mem_kb / 1024))
        tty=$(echo "$proc" | awk '{print $7}')
        started=$(echo "$proc" | awk '{print $9}')
        location=$(tty_to_location "$tty")
        cwd=$(lsof -p "$pid" 2>/dev/null | grep cwd | awk '{print $NF}' | sed "s|$HOME|~|")

        [[ -n "$cwd" ]] && dir_count["$cwd"]=$((${dir_count["$cwd"]:-0} + 1))
        printf "%-8s | %-25s | %-10s | %s\n" "${mem_mb} MB" "$location" "$started" "$cwd"
    done <<< "$claude_procs"

    # Duplicates
    for dir in "${!dir_count[@]}"; do
        if [[ ${dir_count[$dir]} -gt 1 ]]; then
            echo "  ⚠ ${dir_count[$dir]} instances in: $dir"
        fi
    done
fi
