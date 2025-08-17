#!/usr/bin/env python3
"""uv reminder hook for Claude Code."""

import json
import re
import sys


def main():
    try:
        data = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(1)

    if data.get("tool_name") != "Bash":
        sys.exit(0)

    command = data.get("tool_input", {}).get("command", "")

    # Skip if already using
    if re.search(r"\buv\b", command):
        sys.exit(0)

    suggestions = []

    if re.search(r"\bpip install\b", command):
        suggestions.append("💡 Use 'uv add <package>' instead of pip install")
    elif re.search(r"\bpip\b", command):
        suggestions.append("💡 Use 'uv pip' instead of pip")
    elif re.search(r"\b(python3?)\s+[^-].*\.py\b", command):
        # Running a .py script file
        suggestions.append("💡 Use 'uv run script.py' instead of 'python script.py'")
    elif re.search(r"\b(python3?)\s+-[mc]", command):
        # Using -m or -c flags
        suggestions.append(
            "💡 Use 'uv run python -m/-c ...' for modules/code execution"
        )

    if suggestions:
        print(f"Blocked: {command}", file=sys.stderr)
        for s in suggestions:
            print(s, file=sys.stderr)
        print("", file=sys.stderr)
        sys.exit(2)

    sys.exit(0)


if __name__ == "__main__":
    main()
