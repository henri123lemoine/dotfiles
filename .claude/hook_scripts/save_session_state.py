#!/usr/bin/env python3
"""
Save session state on Stop for context persistence across sessions.
"""

import json
import os
import sys
from datetime import datetime


def main():
    try:
        evt = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    cwd = evt.get("cwd", os.getcwd())
    session_id = evt.get("session_id", "unknown")

    state_dir = os.path.expanduser("~/.claude/session_states")
    os.makedirs(state_dir, exist_ok=True)

    safe_cwd = cwd.replace("/", "_").replace(" ", "_")
    state_file = os.path.join(state_dir, f"{safe_cwd}.json")

    try:
        result = os.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null").read().strip()
        branch = result if result else None
    except Exception:
        branch = None

    try:
        result = os.popen("git status --porcelain 2>/dev/null").read().strip()
        has_changes = bool(result)
    except Exception:
        has_changes = False

    state = {
        "session_id": session_id,
        "cwd": cwd,
        "branch": branch,
        "has_uncommitted_changes": has_changes,
        "saved_at": datetime.now().isoformat()
    }

    try:
        with open(state_file, "w") as f:
            json.dump(state, f, indent=2)
    except Exception:
        pass

    sys.exit(0)


if __name__ == "__main__":
    main()
