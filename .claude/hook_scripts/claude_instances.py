#!/usr/bin/env python3
"""Claude Code instance detector for tmux."""

import json
import subprocess
import sys


def get_claude_instances(waiting_only=False):
    """Get Claude instances from tmux panes."""
    try:
        # Get all tmux panes with node processes (Claude runs on node)
        result = subprocess.run(
            [
                "tmux",
                "list-panes",
                "-a",
                "-F",
                "#{session_name}:#{window_index}.#{pane_index}|#{pane_current_command}|#{pane_current_path}",
            ],
            capture_output=True,
            text=True,
            timeout=3,
        )

        if result.returncode != 0:
            return []

        instances = []
        for line in result.stdout.strip().split("\n"):
            if not line or "|" not in line:
                continue

            target, command, path = line.split("|", 2)

            # Skip non-Claude processes
            if command not in ["node", "claude-code"]:
                continue

            # Get pane content to determine status
            content_result = subprocess.run(
                ["tmux", "capture-pane", "-t", target, "-p"],
                capture_output=True,
                text=True,
                timeout=2,
            )

            if content_result.returncode != 0:
                continue

            content = content_result.stdout.strip()
            last_lines = "\n".join(content.split("\n")[-8:])

            # Determine status from content
            if "⎿  Running…" in last_lines:
                status = "processing"
            elif any(p in last_lines for p in ["│ > ", "│ >", "-- INSERT --"]):
                status = "waiting_for_input"
            else:
                status = "active"

            # Skip if we only want waiting instances
            if waiting_only and status != "waiting_for_input":
                continue

            instances.append(
                {
                    "tmux_target": target,
                    "session_name": target.split(":")[0],
                    "working_directory": path,
                    "status": status,
                }
            )

        # Sort: waiting first, then processing, then active
        priority = {"waiting_for_input": 1, "processing": 2, "active": 3}
        instances.sort(key=lambda x: priority.get(x["status"], 4))

        return instances

    except Exception:
        return []


def main():
    waiting_only = "--waiting" in sys.argv
    output_json = "--json" in sys.argv

    instances = get_claude_instances(waiting_only)

    if output_json:
        print(json.dumps(instances, indent=2))
    else:
        if not instances:
            print("No Claude Code instances found.")
            return

        emojis = {"waiting_for_input": "⏳", "processing": "⚡", "active": "💻"}
        for i, inst in enumerate(instances, 1):
            emoji = emojis.get(inst["status"], "❓")
            print(
                f"{emoji} {inst['tmux_target']} ({inst['session_name']}) | {inst['working_directory']}"
            )


if __name__ == "__main__":
    main()
