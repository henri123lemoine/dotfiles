#!/usr/bin/env python3
"""
Local regression tests for the GH-CLI-based PR review hook.
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path


HOOK = Path(__file__).with_name("pr_review_loop.py")


def write_file(path: Path, content: str, executable: bool = False) -> None:
    path.write_text(content)
    if executable:
        path.chmod(0o755)


def make_stub_bin(root: Path, state_path: Path) -> Path:
    bin_dir = root / "bin"
    bin_dir.mkdir()

    gh_stub = """#!/usr/bin/env python3
import json
import sys
from pathlib import Path

state_path = Path("__STATE_PATH__")
state = json.loads(state_path.read_text())
args = sys.argv[1:]

if args[:2] == ["auth", "status"]:
    raise SystemExit(state.get("auth_status_rc", 0))

if args[:2] == ["pr", "view"]:
    print(json.dumps(state["pr_view"]))
    raise SystemExit(0)

if args[:3] == ["pr", "checks", str(state["pr_view"]["number"])]:
    if "--watch" in args:
        if state.get("watch_stdout"):
            print(state["watch_stdout"])
        if state.get("watch_stderr"):
            print(state["watch_stderr"], file=sys.stderr)
        raise SystemExit(state.get("watch_rc", 0))
    if "--json" in args:
        print(json.dumps(state.get("checks", [])))
        raise SystemExit(0)

if args[:2] == ["run", "list"]:
    print(json.dumps(state.get("runs", [])))
    raise SystemExit(0)

if args[:2] == ["run", "view"]:
    run_id = args[2]
    print(state.get("run_logs", {}).get(run_id, ""))
    raise SystemExit(0)

raise SystemExit(1)
"""

    gh_stub = gh_stub.replace("__STATE_PATH__", str(state_path))
    write_file(bin_dir / "gh", gh_stub, executable=True)
    return bin_dir


def run_hook(state: dict, command: str) -> dict:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        home = root / "home"
        repo = root / "repo"
        claude_dir = home / ".claude"
        hook_dir = claude_dir / "hook_scripts"
        hook_dir.mkdir(parents=True)
        repo.mkdir()

        state_path = root / "state.json"
        state_path.write_text(json.dumps(state))
        bin_dir = make_stub_bin(root, state_path)

        config = {
            "poll_interval_seconds": 1,
            "max_wait_seconds": 5,
            "workflow_run_limit": 10,
            "failed_log_run_limit": 2,
            "failed_log_char_limit": 1000,
        }
        write_file(claude_dir / "pr_review_loop.json", json.dumps(config))

        env = os.environ.copy()
        env["HOME"] = str(home)
        env["PATH"] = f"{bin_dir}:{env['PATH']}"

        event = {
            "tool_name": "Bash",
            "tool_input": {"command": command},
        }
        proc = subprocess.run(
            [sys.executable, str(HOOK)],
            cwd=repo,
            input=json.dumps(event),
            text=True,
            capture_output=True,
            env=env,
            check=True,
        )
        if not proc.stdout.strip():
            raise AssertionError(f"Expected hook output, got stderr:\n{proc.stderr}")
        return json.loads(proc.stdout)


def test_success_is_informational() -> None:
    payload = run_hook(
        {
            "pr_view": {
                "number": 12,
                "url": "https://github.com/acme/dotfiles/pull/12",
                "headRefOid": "abc123abc123abc123",
                "title": "Test PR",
            },
            "watch_stdout": "Refreshing checks status every 1 seconds. Press Ctrl+C to quit.\nAll checks were successful",
            "checks": [
                {
                    "bucket": "pass",
                    "name": "test-dotfiles",
                    "workflow": "CI",
                    "description": "completed",
                    "link": "https://example.com/check/1",
                }
            ],
            "runs": [
                {
                    "databaseId": 101,
                    "displayTitle": "CI",
                    "status": "completed",
                    "conclusion": "success",
                    "url": "https://example.com/run/101",
                }
            ],
            "run_logs": {},
        },
        "gh pr create --fill",
    )

    assert payload.get("decision") is None, payload
    context = payload["hookSpecificOutput"]["additionalContext"]
    assert "All PR checks finished successfully." in context, context
    assert "[pass] CI / test-dotfiles" in context, context
    assert "[success] CI" in context, context


def test_failures_block_and_include_logs() -> None:
    payload = run_hook(
        {
            "pr_view": {
                "number": 34,
                "url": "https://github.com/acme/dotfiles/pull/34",
                "headRefOid": "def456def456def456",
                "title": "Broken PR",
            },
            "watch_stdout": "Some checks failed",
            "checks": [
                {
                    "bucket": "fail",
                    "name": "lint",
                    "workflow": "CI",
                    "description": "1 failing job",
                    "link": "https://example.com/check/2",
                }
            ],
            "runs": [
                {
                    "databaseId": 202,
                    "displayTitle": "CI",
                    "status": "completed",
                    "conclusion": "failure",
                    "url": "https://example.com/run/202",
                }
            ],
            "run_logs": {"202": "flake8 reported one error"},
        },
        "git push origin HEAD",
    )

    assert payload["decision"] == "block", payload
    assert "PR checks failed" in payload["reason"], payload
    context = payload["hookSpecificOutput"]["additionalContext"]
    assert "PR checks finished with failures." in context, context
    assert "flake8 reported one error" in context, context


def main() -> int:
    tests = [
        ("success is informational", test_success_is_informational),
        ("failures block and include logs", test_failures_block_and_include_logs),
    ]

    for name, test in tests:
        test()
        print(f"PASS: {name}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
