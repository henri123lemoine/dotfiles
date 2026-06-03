#!/usr/bin/env python3
"""PreToolUse gate that auto-approves lone `gh pr create --draft` commands.

Draft PRs are cheap and reversible; everything else exits silently and defers
to the normal permission rules, so ready-for-review still prompts.
"""

import json
import shlex
import sys

PUNCTUATION = set("();<>|&")


def is_lone_draft_create(command):
    if "create" not in command:
        return False

    # Command substitution runs even inside double quotes, so reject it before
    # shlex would hide it inside a single token.
    if "$(" in command or "`" in command:
        return False

    try:
        lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
        lexer.whitespace_split = True
        tokens = list(lexer)
    except ValueError:
        return False

    if tokens[:3] != ["gh", "pr", "create"]:
        return False

    for token in tokens:
        if token and all(char in PUNCTUATION for char in token):
            return False

    # An unquoted newline is whitespace to shlex and could hide a second command.
    if command.count("\n") != sum(token.count("\n") for token in tokens):
        return False

    args = tokens[3:]
    return "--draft" in args or "-d" in args


def main():
    try:
        event = json.load(sys.stdin)
    except ValueError:
        sys.exit(0)

    if event.get("tool_name") != "Bash":
        sys.exit(0)

    command = event.get("tool_input", {}).get("command", "")
    if not isinstance(command, str) or not is_lone_draft_create(command):
        sys.exit(0)

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "permissionDecisionReason": "Draft PR creation is auto-approved; ready-for-review still prompts.",
        }
    }))
    sys.exit(0)


if __name__ == "__main__":
    main()
