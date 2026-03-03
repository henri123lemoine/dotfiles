#!/usr/bin/env python3
import json
import sys

if __name__ == "__main__":
    evt = json.load(sys.stdin)
    cmd = (evt.get("tool_input") or {}).get("command", "")

    import time, os

    logpath = os.path.expanduser("~/.claude/hook_scripts/logs/test_hook.log")
    with open(logpath, "a") as f:
        f.write(f"{time.strftime('%H:%M:%S')} cmd={cmd[:100]}\n")

    if "HOOKTEST" not in cmd and "git" not in cmd:
        sys.exit(0)

    payload = {"decision": "block", "reason": f"TEST HOOK fired for: {cmd[:80]}"}
    sys.stdout.write(json.dumps(payload))
    sys.stdout.flush()
