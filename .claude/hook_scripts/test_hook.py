#!/usr/bin/env python3
"""
Test hook script to log JSON data received from Claude Code hooks.
This will help us understand exactly what data is passed to hooks.
"""

import json
import os
import sys
from datetime import datetime


def main():
    try:
        # Read JSON data from stdin
        hook_data = json.load(sys.stdin)

        # Create log entry with timestamp
        log_entry = {"timestamp": datetime.now().isoformat(), "hook_data": hook_data}

        # Log to file for analysis
        log_file = os.path.expanduser("~/.claude/hook_test.log")
        with open(log_file, "a") as f:
            f.write(json.dumps(log_entry, indent=2) + "\n---\n")

        # Also print to stderr for debugging (won't interfere with Claude)
        print(
            f"Hook fired: {hook_data.get('hook_event_name', 'unknown')}",
            file=sys.stderr,
        )
        print(f"CWD: {hook_data.get('cwd', 'unknown')}", file=sys.stderr)
        print(f"Session ID: {hook_data.get('session_id', 'unknown')}", file=sys.stderr)

    except Exception as e:
        # Log errors to separate file
        error_log = os.path.expanduser("~/.claude/hook_error.log")
        with open(error_log, "a") as f:
            f.write(f"{datetime.now().isoformat()}: {str(e)}\n")


if __name__ == "__main__":
    main()
