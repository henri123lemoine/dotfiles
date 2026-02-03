#!/usr/bin/env python3
"""
Restore session state on SessionStart to maintain context.
"""

import json
import os
import sys
from datetime import datetime, timedelta


def main():
    try:
        evt = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    cwd = evt.get("cwd", os.getcwd())

    state_dir = os.path.expanduser("~/.claude/session_states")
    safe_cwd = cwd.replace("/", "_").replace(" ", "_")
    state_file = os.path.join(state_dir, f"{safe_cwd}.json")

    if not os.path.exists(state_file):
        sys.exit(0)

    try:
        with open(state_file) as f:
            state = json.load(f)
    except Exception:
        sys.exit(0)

    saved_at = state.get("saved_at")
    if saved_at:
        try:
            saved_time = datetime.fromisoformat(saved_at)
            if datetime.now() - saved_time > timedelta(hours=24):
                os.remove(state_file)
                sys.exit(0)
        except Exception:
            pass

    context_parts = []

    if state.get("branch"):
        context_parts.append(f"Branch: {state['branch']}")

    if state.get("has_uncommitted_changes"):
        context_parts.append("Note: There were uncommitted changes in the last session")

    if context_parts:
        payload = {
            "hookSpecificOutput": {
                "additionalContext": "Previous session context:\n" + "\n".join(context_parts)
            }
        }
        sys.stdout.write(json.dumps(payload))

    sys.exit(0)


if __name__ == "__main__":
    main()
