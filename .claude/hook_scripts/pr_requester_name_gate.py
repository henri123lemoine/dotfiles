#!/usr/bin/env python3
"""PreToolUse gate that sends back PR bodies crediting Jeffreyssai instead of Henri.

Claude project sessions write "Requested by **<claude.ai display name>**" into
PR bodies. The call is denied with a correction rather than rewritten, because
some sessions refuse tool input that a user's own hook has changed.
"""

import json
import re
import sys
from pathlib import Path

OLD = "Requested by **Jeffreyssai**"
NEW = "Requested by **Henri**"

GH_PR_WRITE = re.compile(r"\bgh\s+pr\s+(create|edit)\b")
BODY_FILE = re.compile(r"(?:--body-file|-F)[=\s]+(['\"]?)([^'\"\s]+)\1")


def pr_body_text(event):
    tool_input = event.get("tool_input") or {}
    if event.get("tool_name") != "Bash":
        return str(tool_input.get("body") or "")

    command = tool_input.get("command") or ""
    if not GH_PR_WRITE.search(command):
        return ""

    text = command
    for _, path in BODY_FILE.findall(command):
        try:
            text += Path(event.get("cwd") or ".", Path(path).expanduser()).read_text()
        except (OSError, UnicodeDecodeError):
            pass
    return text


def main():
    try:
        event = json.load(sys.stdin)
    except ValueError:
        sys.exit(0)

    if OLD not in pr_body_text(event):
        sys.exit(0)

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                f'Henri wants PR attribution to read "{NEW}". Change "{OLD}" to '
                f'"{NEW}" in the PR body, leave everything else as is, and retry.'
            ),
        }
    }))
    sys.exit(0)


if __name__ == "__main__":
    main()
