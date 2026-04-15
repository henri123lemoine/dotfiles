#!/usr/bin/env python3
"""
Wait for PR checks after push/PR-create and feed the outcome back into Claude.

This hook intentionally leans on the official GitHub CLI commands that are
designed for this workflow:

- `gh pr checks --watch` to wait until PR checks settle
- `gh pr checks --json ...` to fetch the final check matrix
- `gh run list --commit <sha>` to find the workflow runs for the pushed commit
- `gh run view <id> --log-failed` to grab failed logs when needed
"""

import json
import logging
import os
import re
import subprocess
import sys
from typing import Any


LOG_PATH = os.path.expanduser("~/.claude/hook_scripts/pr_review_loop.log")
logging.basicConfig(
    filename=LOG_PATH,
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)

TRIGGER_PATTERNS = (
    r"\bgit\b.*\bpush\b",
    r"\bgh\s+pr\s+create\b",
    r"\bhub\s+pull-request\b",
)
SUCCESS_BUCKETS = {"pass", "skipping"}
FAILURE_BUCKETS = {"fail", "cancel"}
PENDING_BUCKETS = {"pending"}


def run(
    cmd: list[str],
    *,
    check: bool = True,
    timeout: int | None = None,
) -> subprocess.CompletedProcess[str]:
    try:
        proc = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout,
        )
    except FileNotFoundError as exc:
        raise RuntimeError(f"Command not found: {cmd[0]}") from exc

    if check and proc.returncode != 0:
        raise RuntimeError(
            f"Command failed: {' '.join(cmd)}\n"
            f"stdout: {proc.stdout.strip()}\n"
            f"stderr: {proc.stderr.strip()}"
        )
    return proc


def gh_json(cmd: list[str], *, default: Any) -> Any:
    proc = run(cmd, check=True)
    output = proc.stdout.strip()
    if not output:
        return default
    try:
        return json.loads(output)
    except json.JSONDecodeError as exc:
        raise RuntimeError(
            f"Expected JSON from {' '.join(cmd)}, got: {truncate(output, 500)}"
        ) from exc


def truncate(text: str, limit: int = 3000) -> str:
    if len(text or "") <= limit:
        return text
    return text[:limit] + "\n...(truncated)..."


def emit_result(
    context: str, *, reason: str | None = None, block: bool = False
) -> None:
    payload: dict[str, Any] = {
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "additionalContext": context,
        }
    }
    if block:
        payload["decision"] = "block"
        payload["reason"] = reason or "PR checks require follow-up."
    sys.stdout.write(json.dumps(payload))
    sys.exit(0)


def load_config() -> dict[str, Any]:
    cfg_path = os.path.expanduser("~/.claude/pr_review_loop.json")
    if os.path.exists(cfg_path):
        try:
            with open(cfg_path) as handle:
                return json.load(handle)
        except Exception:
            log.exception("Failed to load config: %s", cfg_path)
    return {}


def command_triggers_wait(command: str) -> bool:
    return any(re.search(pattern, command) for pattern in TRIGGER_PATTERNS)


def get_pr_info() -> dict[str, Any] | None:
    try:
        pr_info = gh_json(
            ["gh", "pr", "view", "--json", "number,url,headRefOid,title"],
            default={},
        )
    except Exception as exc:
        log.info("No PR context found for current branch: %s", exc)
        return None

    if not pr_info.get("number") or not pr_info.get("url"):
        return None
    return pr_info


def wait_for_checks(pr_number: int, interval: int, max_wait: int) -> dict[str, Any]:
    cmd = ["gh", "pr", "checks", str(pr_number), "--watch", "--interval", str(interval)]
    log.info("Waiting for checks with: %s", " ".join(cmd))
    try:
        proc = run(cmd, check=False, timeout=max_wait)
        return {
            "timed_out": False,
            "returncode": proc.returncode,
            "stdout": proc.stdout.strip(),
            "stderr": proc.stderr.strip(),
        }
    except subprocess.TimeoutExpired as exc:
        stdout = (
            exc.stdout if isinstance(exc.stdout, str) else (exc.stdout or b"").decode()
        )
        stderr = (
            exc.stderr if isinstance(exc.stderr, str) else (exc.stderr or b"").decode()
        )
        log.warning("Timed out waiting for PR checks after %ss", max_wait)
        return {
            "timed_out": True,
            "returncode": None,
            "stdout": stdout.strip(),
            "stderr": stderr.strip(),
        }


def get_check_rows(pr_number: int) -> list[dict[str, Any]]:
    fields = "bucket,completedAt,description,link,name,startedAt,state,workflow"
    rows = gh_json(["gh", "pr", "checks", str(pr_number), "--json", fields], default=[])
    return rows if isinstance(rows, list) else []


def get_runs_for_commit(head_sha: str, limit: int) -> list[dict[str, Any]]:
    if not head_sha:
        return []
    fields = "conclusion,databaseId,displayTitle,name,status,url,workflowName"
    rows = gh_json(
        [
            "gh",
            "run",
            "list",
            "--commit",
            head_sha,
            "--limit",
            str(limit),
            "--json",
            fields,
        ],
        default=[],
    )
    return rows if isinstance(rows, list) else []


def get_failed_run_logs(
    runs: list[dict[str, Any]],
    *,
    max_runs: int,
    max_chars_per_run: int,
) -> list[dict[str, str]]:
    failed_runs = [
        run_info
        for run_info in runs
        if (run_info.get("conclusion") or "").lower()
        not in ("", "success", "neutral", "skipped")
    ]

    out: list[dict[str, str]] = []
    for run_info in failed_runs[:max_runs]:
        run_id = run_info.get("databaseId")
        if not run_id:
            continue
        proc = run(["gh", "run", "view", str(run_id), "--log-failed"], check=False)
        logs = truncate((proc.stdout or proc.stderr or "").strip(), max_chars_per_run)
        if not logs:
            continue
        out.append(
            {
                "name": run_info.get("displayTitle")
                or run_info.get("workflowName")
                or run_info.get("name")
                or str(run_id),
                "logs": logs,
            }
        )
    return out


def check_bucket(check_row: dict[str, Any]) -> str:
    return (check_row.get("bucket") or check_row.get("state") or "unknown").lower()


def summarize_checks(checks: list[dict[str, Any]]) -> tuple[bool, bool, bool]:
    if not checks:
        return False, False, False

    has_failures = any(check_bucket(row) in FAILURE_BUCKETS for row in checks)
    has_pending = any(check_bucket(row) in PENDING_BUCKETS for row in checks)
    all_success = all(check_bucket(row) in SUCCESS_BUCKETS for row in checks)
    return has_failures, has_pending, all_success


def format_check_rows(checks: list[dict[str, Any]]) -> list[str]:
    lines = ["### PR Checks"]
    for row in checks:
        bucket = check_bucket(row)
        workflow = row.get("workflow") or ""
        name = row.get("name") or "unknown"
        description = truncate((row.get("description") or "").strip(), 400)
        link = row.get("link") or ""
        label = name if not workflow or workflow == name else f"{workflow} / {name}"
        lines.append(f"- [{bucket}] {label}")
        if description:
            for item in description.splitlines():
                lines.append(f"  {item}")
        if link:
            lines.append(f"  {link}")
    lines.append("")
    return lines


def format_run_rows(runs: list[dict[str, Any]]) -> list[str]:
    if not runs:
        return []

    lines = ["### Workflow Runs"]
    for run_info in runs:
        status = (
            run_info.get("conclusion") or run_info.get("status") or "unknown"
        ).lower()
        name = (
            run_info.get("displayTitle")
            or run_info.get("workflowName")
            or run_info.get("name")
            or "unknown"
        )
        url = run_info.get("url") or ""
        suffix = f" - {url}" if url else ""
        lines.append(f"- [{status}] {name}{suffix}")
    lines.append("")
    return lines


def format_failed_logs(failed_logs: list[dict[str, str]]) -> list[str]:
    if not failed_logs:
        return []

    lines = ["### Failed Run Logs"]
    for item in failed_logs:
        lines.append(f"- {item['name']}")
        for line in item["logs"].splitlines():
            lines.append(f"  {line}")
    lines.append("")
    return lines


def build_report(
    *,
    pr_url: str,
    head_sha: str,
    wait_result: dict[str, Any],
    checks: list[dict[str, Any]],
    runs: list[dict[str, Any]],
    failed_logs: list[dict[str, str]],
) -> tuple[str, bool]:
    has_failures, has_pending, all_success = summarize_checks(checks)

    lines = [f"PR check outcome for {pr_url}", ""]
    if head_sha:
        lines.append(f"Head commit: `{head_sha[:12]}`")
    if wait_result["timed_out"]:
        lines.append("Timed out waiting for PR checks to finish.")
    elif all_success:
        lines.append("All PR checks finished successfully.")
    elif has_failures:
        lines.append("PR checks finished with failures.")
    elif has_pending:
        lines.append("PR checks are still pending after the watch step.")
    else:
        lines.append("Finished waiting for PR checks.")
    lines.append("")

    if wait_result.get("stdout"):
        lines.append("### gh pr checks --watch")
        lines.append(truncate(wait_result["stdout"], 1200))
        lines.append("")
    elif wait_result.get("stderr"):
        lines.append("### gh pr checks --watch stderr")
        lines.append(truncate(wait_result["stderr"], 1200))
        lines.append("")

    if checks:
        lines.extend(format_check_rows(checks))
    else:
        lines.append("No PR checks were reported by GitHub CLI.")
        lines.append("")

    if runs:
        lines.extend(format_run_rows(runs))

    if failed_logs:
        lines.extend(format_failed_logs(failed_logs))

    if has_failures:
        lines.append("Apply fixes, rerun local verification, and push again.")

    return "\n".join(lines), has_failures


def main() -> None:
    log.info("=" * 60)
    log.info("Hook invoked")

    try:
        event = json.load(sys.stdin)
    except json.JSONDecodeError:
        log.error("Failed to parse stdin JSON")
        sys.exit(0)

    tool = event.get("tool_name")
    command = (event.get("tool_input") or {}).get("command", "")
    log.info("tool=%s command=%s", tool, command[:200])

    if tool != "Bash":
        sys.exit(0)
    if not command_triggers_wait(command):
        sys.exit(0)
    if os.environ.get("CLAUDE_PR_REVIEW_LOOP", "1") == "0":
        sys.exit(0)

    cfg = load_config()
    poll_interval = int(cfg.get("poll_interval_seconds", 10))
    max_wait = int(cfg.get("max_wait_seconds", 1200))
    run_limit = int(cfg.get("workflow_run_limit", 20))
    failed_log_run_limit = int(cfg.get("failed_log_run_limit", 3))
    failed_log_char_limit = int(cfg.get("failed_log_char_limit", 4000))
    log.info(
        "Config: interval=%ss max_wait=%ss run_limit=%s failed_log_run_limit=%s",
        poll_interval,
        max_wait,
        run_limit,
        failed_log_run_limit,
    )

    try:
        auth = run(["gh", "auth", "status"], check=False)
    except Exception as exc:
        log.error("gh auth status failed: %s", exc)
        sys.exit(0)
    if auth.returncode != 0:
        log.info("gh auth is not available in this environment")
        sys.exit(0)

    pr_info = get_pr_info()
    if not pr_info:
        log.info("No PR found for current branch")
        sys.exit(0)

    pr_number = int(pr_info["number"])
    pr_url = pr_info["url"]
    head_sha = (pr_info.get("headRefOid") or "").strip()
    log.info("Watching PR #%s %s", pr_number, pr_url)

    wait_result = wait_for_checks(pr_number, poll_interval, max_wait)

    try:
        checks = get_check_rows(pr_number)
    except Exception as exc:
        log.exception("Failed to fetch final PR checks")
        emit_result(
            f"PR: {pr_url}\nError fetching final check results: {exc}",
            reason="PR checks watcher failed after the watch step.",
            block=True,
        )
        return

    runs: list[dict[str, Any]] = []
    failed_logs: list[dict[str, str]] = []
    try:
        runs = get_runs_for_commit(head_sha, run_limit)
        failed_logs = get_failed_run_logs(
            runs,
            max_runs=failed_log_run_limit,
            max_chars_per_run=failed_log_char_limit,
        )
    except Exception:
        log.exception("Failed to fetch workflow runs/logs")

    report, has_failures = build_report(
        pr_url=pr_url,
        head_sha=head_sha,
        wait_result=wait_result,
        checks=checks,
        runs=runs,
        failed_logs=failed_logs,
    )
    emit_result(
        report,
        reason="PR checks failed. Apply fixes and push again."
        if has_failures
        else None,
        block=has_failures,
    )


if __name__ == "__main__":
    try:
        main()
    except Exception:
        log.exception("Unhandled exception in hook")
        sys.exit(1)
