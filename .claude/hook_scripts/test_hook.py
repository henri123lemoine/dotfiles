#!/usr/bin/env python3
import json
import sys

evt = json.load(sys.stdin)
cmd = (evt.get("tool_input") or {}).get("command", "")

if "HOOKTEST" not in cmd:
    sys.exit(0)

payload = {"decision": "block", "reason": "TEST HOOK SAYS HELLO"}
sys.stdout.write(json.dumps(payload))
sys.stdout.flush()
