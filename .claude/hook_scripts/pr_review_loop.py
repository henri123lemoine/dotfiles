#!/usr/bin/env python3
"""
PR Review Loop Hook for Claude Code.

After `git push` or `gh pr create`, polls GitHub for CI/CD check results
and new review bot feedback. When checks fail or feedback arrives, blocks
Claude and injects the details so Claude can apply fixes.
"""

import json
import logging
import os
import re
import subprocess
import sys
import time
from urllib.parse import urlparse

LOG_PATH = os.path.expanduser("~/.claude/hook_scripts/pr_review_loop.log")
logging.basicConfig(
    filename=LOG_PATH,
    level=logging.DEBUG,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%H:%M:%S",
)
log = logging.getLogger(__name__)


def run(cmd: list[str], check=True) -> str:
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if check and p.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{p.stderr.strip()}")
    return p.stdout


def gh_api(path: str) -> list | dict:
    out = run(["gh", "api", path], check=True)
    return json.loads(out) if out.strip() else {}


def as_list(data: list | dict) -> list:
    return data if isinstance(data, list) else []


def max_id(items: list) -> int:
    return max((int(it.get("id", 0)) for it in items), default=0)


def login(it: dict) -> str:
    return (it.get("user") or {}).get("login", "")


def should_watch(author: str, watch_logins: list[str]) -> bool:
    if not author:
        return False
    if watch_logins:
        return "*" in watch_logins or author in watch_logins
    return author.endswith("[bot]")


def truncate(s: str, n: int = 3000) -> str:
    return s if len(s or "") <= n else s[:n] + "\n…(truncated)…"


def emit_context(context: str) -> None:
    payload = {
        "hookSpecificOutput": {
            "additionalContext": context
        }
    }
    sys.stdout.write(json.dumps(payload))
    sys.exit(0)


def load_config() -> dict:
    cfg_path = os.path.expanduser("~/.claude/pr_review_loop.json")
    if os.path.exists(cfg_path):
        try:
            with open(cfg_path) as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def get_head_sha() -> str:
    return run(["git", "rev-parse", "HEAD"], check=True).strip()


def get_check_runs(owner: str, repo: str, sha: str) -> list[dict]:
    data = gh_api(f"repos/{owner}/{repo}/commits/{sha}/check-runs")
    return as_list(data.get("check_runs", []) if isinstance(data, dict) else [])


def checks_completed(runs: list[dict]) -> bool:
    if not runs:
        return False
    return all(r.get("status") == "completed" for r in runs)


def format_failed_checks(runs: list[dict]) -> list[str]:
    lines = []
    failed = [r for r in runs if r.get("conclusion") not in ("success", "skipped", "neutral")]
    if not failed:
        return lines
    lines.append("### Failed CI/CD Checks")
    for r in failed:
        name = r.get("name", "unknown")
        conclusion = r.get("conclusion", "unknown")
        url = r.get("html_url", "")
        lines.append(f"- **{name}**: {conclusion} — {url}")
        output = r.get("output") or {}
        summary = truncate(output.get("summary", "") or "", 1500).strip()
        if summary:
            for line in summary.split("\n"):
                lines.append(f"  {line}")
    lines.append("")
    return lines


def collect_comments(items: list, base: int, kind: str, watch_logins: list[str]) -> list[dict]:
    out = []
    for it in items:
        if not isinstance(it, dict):
            continue
        try:
            if int(it.get("id", 0)) <= base:
                continue
        except Exception:
            continue
        author = login(it)
        if not should_watch(author, watch_logins):
            continue
        it["_author"] = author
        it["_kind"] = kind
        out.append(it)
    return out


def main():
    log.info("=" * 60)
    log.info("Hook invoked")

    try:
        evt = json.load(sys.stdin)
    except json.JSONDecodeError:
        log.error("Failed to parse stdin JSON")
        sys.exit(0)

    tool = evt.get("tool_name")
    cmd = (evt.get("tool_input") or {}).get("command", "")
    log.info("tool=%s cmd=%s", tool, cmd[:200])

    if tool != "Bash":
        log.debug("Not Bash, skipping")
        sys.exit(0)

    is_push = re.search(r"\bgit\b.*\bpush\b", cmd)
    is_pr_create = re.search(r"\bgh\s+pr\s+create\b", cmd)
    if not (is_push or is_pr_create):
        log.debug("Not a push/pr-create command, skipping")
        sys.exit(0)

    if os.environ.get("CLAUDE_PR_REVIEW_LOOP", "1") == "0":
        log.info("Disabled via env var")
        sys.exit(0)

    log.info("Triggered (push=%s, pr_create=%s)", bool(is_push), bool(is_pr_create))

    cfg = load_config()
    watch_logins = cfg.get("watch_logins", [])
    trigger_comment = cfg.get("trigger_comment", "")
    poll_interval = int(cfg.get("poll_interval_seconds", 20))
    max_wait = int(cfg.get("max_wait_seconds", 1200))
    quiet_period = int(cfg.get("quiet_period_seconds", 45))
    log.info("Config: poll=%ds, max_wait=%ds, quiet=%ds, watch=%s",
             poll_interval, max_wait, quiet_period, watch_logins)

    try:
        run(["gh", "auth", "status"], check=False)
    except Exception as e:
        log.error("gh auth failed: %s", e)
        sys.exit(0)

    try:
        pr_info = json.loads(run(["gh", "pr", "view", "--json", "number,url"], check=True))
    except Exception as e:
        log.error("No PR found: %s", e)
        sys.exit(0)

    pr_number = pr_info.get("number")
    pr_url = pr_info.get("url", "")
    log.info("PR #%s: %s", pr_number, pr_url)
    if not pr_number or not pr_url:
        log.error("Missing PR number or URL")
        sys.exit(0)

    parsed = urlparse(pr_url).path.strip("/").split("/")
    if len(parsed) < 4:
        log.error("Bad PR URL parse: %s", parsed)
        sys.exit(0)
    owner, repo = parsed[0], parsed[1]

    try:
        head_sha = get_head_sha()
    except Exception as e:
        log.error("Can't get HEAD sha: %s", e)
        sys.exit(0)
    log.info("HEAD sha: %s", head_sha)

    issue_comments_path = f"repos/{owner}/{repo}/issues/{pr_number}/comments?per_page=100"
    review_comments_path = f"repos/{owner}/{repo}/pulls/{pr_number}/comments?per_page=100"
    reviews_path = f"repos/{owner}/{repo}/pulls/{pr_number}/reviews?per_page=100"

    try:
        base_issue = max_id(as_list(gh_api(issue_comments_path)))
        base_review_comments = max_id(as_list(gh_api(review_comments_path)))
        base_reviews = max_id(as_list(gh_api(reviews_path)))
        log.info("Baselines: issue=%d, review_comments=%d, reviews=%d",
                 base_issue, base_review_comments, base_reviews)
    except Exception as e:
        log.error("Failed to snapshot baselines: %s", e)
        emit_context(f"PR review loop couldn't read PR feedback via GitHub API.\nPR: {pr_url}\nError: {str(e)}")
        return

    if trigger_comment:
        try:
            run(["gh", "api", f"repos/{owner}/{repo}/issues/{pr_number}/comments",
                 "-f", f"body={trigger_comment}"], check=False)
        except Exception:
            pass

    deadline = time.time() + max_wait
    last_new_comment_at = None
    ci_done = False
    poll_count = 0

    new_issue: list[dict] = []
    new_inline: list[dict] = []
    new_reviews: list[dict] = []
    failed_check_lines: list[str] = []

    log.info("Starting poll loop (max %ds)", max_wait)

    while time.time() < deadline:
        poll_count += 1

        if not ci_done:
            try:
                runs = get_check_runs(owner, repo, head_sha)
                statuses = [(r.get("name"), r.get("status"), r.get("conclusion")) for r in runs]
                log.debug("Poll #%d checks: %s", poll_count, statuses)
                if runs and checks_completed(runs):
                    ci_done = True
                    failed_check_lines = format_failed_checks(runs)
                    log.info("CI done! %d runs, %d failed", len(runs), len(failed_check_lines))
            except Exception as e:
                log.warning("Check runs poll error: %s", e)

        try:
            issue_now = as_list(gh_api(issue_comments_path))
            inline_now = as_list(gh_api(review_comments_path))
            reviews_now = as_list(gh_api(reviews_path))
        except Exception as e:
            log.warning("Comments poll error: %s", e)
            time.sleep(poll_interval)
            continue

        got_issue = collect_comments(issue_now, base_issue, "issue_comment", watch_logins)
        got_inline = collect_comments(inline_now, base_review_comments, "inline_comment", watch_logins)
        got_reviews = collect_comments(reviews_now, base_reviews, "review", watch_logins)

        if got_issue or got_inline or got_reviews:
            log.info("New comments: issue=%d, inline=%d, reviews=%d",
                     len(got_issue), len(got_inline), len(got_reviews))
            last_new_comment_at = time.time()
            new_issue.extend(got_issue)
            new_inline.extend(got_inline)
            new_reviews.extend(got_reviews)
            base_issue = max(base_issue, max_id(issue_now))
            base_review_comments = max(base_review_comments, max_id(inline_now))
            base_reviews = max(base_reviews, max_id(reviews_now))

        comments_settled = (
            last_new_comment_at is not None
            and (time.time() - last_new_comment_at) >= quiet_period
        )

        if ci_done and comments_settled:
            log.info("CI done + comments settled, breaking")
            break
        if not ci_done and comments_settled:
            log.info("No CI checks found but comments settled, breaking")
            break

        time.sleep(poll_interval)

    has_failures = bool(failed_check_lines)
    has_comments = bool(new_issue or new_inline or new_reviews)
    log.info("Loop ended: ci_done=%s, has_failures=%s, has_comments=%s, polls=%d",
             ci_done, has_failures, has_comments, poll_count)

    if not has_failures and not has_comments:
        log.info("Nothing to report, exiting cleanly")
        sys.exit(0)

    lines = [f"CI/CD results for {pr_url}", ""]

    if has_failures:
        lines.append("Apply these fixes, run tests, and push again.")
        lines.append("")
        lines.extend(failed_check_lines)
    elif ci_done:
        lines.append("All checks passed.")
        lines.append("")

    if new_reviews:
        lines.append("### Reviews")
        for r in new_reviews:
            state = r.get("state", "")
            body = truncate(r.get("body", "") or "", 2000).strip()
            author = r.get("_author", "")
            lines.append(f"- **{state}** by `{author}`")
            if body:
                for line in body.split("\n"):
                    lines.append(f"  {line}")
        lines.append("")

    if new_inline:
        lines.append("### Inline Comments")
        for c in new_inline:
            author = c.get("_author", "")
            fpath = c.get("path", "")
            line_no = c.get("line") or c.get("original_line") or ""
            body = truncate(c.get("body", "") or "", 2000).strip()
            loc = f"{fpath}:{line_no}" if fpath else ""
            lines.append(f"- `{loc}` by `{author}`")
            if body:
                for line in body.split("\n"):
                    lines.append(f"  {line}")
        lines.append("")

    if new_issue:
        lines.append("### PR Comments")
        for c in new_issue:
            author = c.get("_author", "")
            body = truncate(c.get("body", "") or "", 2000).strip()
            lines.append(f"- by `{author}`")
            if body:
                for line in body.split("\n"):
                    lines.append(f"  {line}")
        lines.append("")

    reason = "CI/CD checks failed" if has_failures else "New PR review feedback"
    log.info("Emitting context: %s", reason)
    output = "\n".join(lines)
    log.debug("Output:\n%s", output)
    emit_context(output)


if __name__ == "__main__":
    try:
        main()
    except Exception:
        log.exception("Unhandled exception in hook")
        sys.exit(1)
