#!/usr/bin/env python3
"""
PR Review Loop Hook for Claude Code.

After `git push`, polls GitHub for new review bot feedback.
When feedback arrives, blocks Claude and injects it so Claude can apply fixes.
"""

import json
import os
import re
import subprocess
import sys
import time
from urllib.parse import urlparse


def run(cmd: list[str], check=True) -> str:
    p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if check and p.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(cmd)}\n{p.stderr.strip()}")
    return p.stdout


def gh_api(path: str) -> list | dict:
    out = run(["gh", "api", path], check=True)
    return json.loads(out) if out.strip() else []


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


def emit_block(reason: str, context: str) -> None:
    payload = {
        "decision": "block",
        "reason": reason,
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


def main():
    try:
        evt = json.load(sys.stdin)
    except json.JSONDecodeError:
        sys.exit(0)

    tool = evt.get("tool_name")
    cmd = (evt.get("tool_input") or {}).get("command", "")

    if tool != "Bash":
        sys.exit(0)

    if not re.match(r"^\s*git\s+push(\s|$)", cmd):
        sys.exit(0)

    if os.environ.get("CLAUDE_PR_REVIEW_LOOP", "1") == "0":
        sys.exit(0)

    cfg = load_config()
    watch_logins = cfg.get("watch_logins", [])
    trigger_comment = cfg.get("trigger_comment", "")
    poll_interval = int(cfg.get("poll_interval_seconds", 20))
    max_wait = int(cfg.get("max_wait_seconds", 1200))
    quiet_period = int(cfg.get("quiet_period_seconds", 45))

    try:
        run(["gh", "auth", "status"], check=False)
    except Exception:
        sys.exit(0)

    try:
        pr_info = json.loads(run(["gh", "pr", "view", "--json", "number,url"], check=True))
    except Exception:
        sys.exit(0)

    pr_number = pr_info.get("number")
    pr_url = pr_info.get("url", "")
    if not pr_number or not pr_url:
        sys.exit(0)

    path = urlparse(pr_url).path.strip("/").split("/")
    if len(path) < 4:
        sys.exit(0)
    owner, repo = path[0], path[1]

    issue_comments_path = f"repos/{owner}/{repo}/issues/{pr_number}/comments?per_page=100"
    review_comments_path = f"repos/{owner}/{repo}/pulls/{pr_number}/comments?per_page=100"
    reviews_path = f"repos/{owner}/{repo}/pulls/{pr_number}/reviews?per_page=100"

    try:
        base_issue = max_id(gh_api(issue_comments_path))
        base_review_comments = max_id(gh_api(review_comments_path))
        base_reviews = max_id(gh_api(reviews_path))
    except Exception as e:
        emit_block(
            f"PR review loop couldn't read PR feedback via GitHub API.",
            f"PR: {pr_url}\nError: {str(e)}"
        )

    if trigger_comment:
        try:
            run(["gh", "api", f"repos/{owner}/{repo}/issues/{pr_number}/comments",
                 "-f", f"body={trigger_comment}"], check=False)
        except Exception:
            pass

    deadline = time.time() + max_wait
    first_seen_at = None
    last_new_at = None

    new_issue = []
    new_inline = []
    new_reviews = []

    while time.time() < deadline:
        try:
            issue_now = gh_api(issue_comments_path)
            inline_now = gh_api(review_comments_path)
            reviews_now = gh_api(reviews_path)
        except Exception:
            time.sleep(poll_interval)
            continue

        def collect(items, base, kind):
            out = []
            for it in items:
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

        got_issue = collect(issue_now, base_issue, "issue_comment")
        got_inline = collect(inline_now, base_review_comments, "inline_comment")
        got_reviews = collect(reviews_now, base_reviews, "review")

        any_new = bool(got_issue or got_inline or got_reviews)
        if any_new:
            now = time.time()
            if first_seen_at is None:
                first_seen_at = now
            last_new_at = now

            new_issue.extend(got_issue)
            new_inline.extend(got_inline)
            new_reviews.extend(got_reviews)

            base_issue = max(base_issue, max_id(issue_now))
            base_review_comments = max(base_review_comments, max_id(inline_now))
            base_reviews = max(base_reviews, max_id(reviews_now))

        if first_seen_at is not None and last_new_at is not None:
            if (time.time() - last_new_at) >= quiet_period:
                break

        time.sleep(poll_interval)

    if not (new_issue or new_inline or new_reviews):
        sys.exit(0)

    lines = [
        f"PR feedback detected: {pr_url}",
        "",
        "Apply these fixes, run tests, and push again.",
        ""
    ]

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
            path = c.get("path", "")
            line_no = c.get("line") or c.get("original_line") or ""
            body = truncate(c.get("body", "") or "", 2000).strip()
            loc = f"{path}:{line_no}" if path else ""
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

    emit_block(
        f"New PR review feedback on {pr_url}. Apply fixes and push again.",
        "\n".join(lines)
    )


if __name__ == "__main__":
    main()
