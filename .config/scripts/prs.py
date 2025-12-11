#!/usr/bin/env python3
"""
Interactive PR review tool.
Lists PRs awaiting review with details, allows selection via fzf,
and provides options to open in browser or launch Claude Code review.
"""

import json
import subprocess
import sys
from datetime import datetime
from typing import Optional

_repo_cache: Optional[str] = None


def get_repo_from_origin() -> Optional[str]:
    """Get the GitHub repo from the origin remote (preferred over upstream)."""
    global _repo_cache
    if _repo_cache is not None:
        return _repo_cache if _repo_cache else None

    try:
        # Get origin remote URL
        result = subprocess.run(
            ["git", "remote", "get-url", "origin"],
            capture_output=True,
            text=True,
            timeout=5,
        )
        if result.returncode != 0:
            _repo_cache = ""
            return None

        url = result.stdout.strip()
        # Parse GitHub repo from URL
        # Handles: https://github.com/owner/repo.git, git@github.com:owner/repo.git
        if "github.com" in url:
            if url.startswith("git@"):
                # git@github.com:owner/repo.git
                repo = url.split(":")[-1]
            else:
                # https://github.com/owner/repo.git
                repo = "/".join(url.split("/")[-2:])
            repo = repo.removesuffix(".git")
            _repo_cache = repo
            return repo
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass

    _repo_cache = ""
    return None


def run_gh_command(args: list[str], use_repo: bool = True) -> Optional[str]:
    """Run a gh CLI command and return output."""
    try:
        # Add --repo flag if we detected a repo from origin
        cmd_args = args.copy()
        if use_repo:
            repo = get_repo_from_origin()
            if repo and "--repo" not in args and "-R" not in args:
                cmd_args = ["--repo", repo] + cmd_args

        result = subprocess.run(
            ["gh"] + cmd_args,
            capture_output=True,
            text=True,
            timeout=30,
        )
        if result.returncode != 0:
            print(f"Error: {result.stderr}", file=sys.stderr)
            return None
        return result.stdout
    except FileNotFoundError:
        print("Error: gh CLI not found. Install with: brew install gh", file=sys.stderr)
        sys.exit(1)
    except subprocess.TimeoutExpired:
        print("Error: gh command timed out", file=sys.stderr)
        return None


def get_prs(user: str = "@me") -> list[dict]:
    """Fetch PRs awaiting review from the specified user."""
    fields = "number,title,url,author,createdAt,additions,deletions,headRefName,baseRefName,isDraft,reviewDecision"
    output = run_gh_command(
        [
            "pr",
            "list",
            "--search",
            f"review-requested:{user}",
            "--json",
            fields,
        ]
    )
    if not output:
        return []
    try:
        return json.loads(output)
    except json.JSONDecodeError:
        print("Error: Failed to parse PR data", file=sys.stderr)
        return []


def format_date(iso_date: str) -> str:
    """Format ISO date to relative or short format."""
    try:
        dt = datetime.fromisoformat(iso_date.replace("Z", "+00:00"))
        now = datetime.now(dt.tzinfo)
        delta = now - dt

        if delta.days == 0:
            hours = delta.seconds // 3600
            if hours == 0:
                mins = delta.seconds // 60
                return f"{mins}m ago"
            return f"{hours}h ago"
        elif delta.days == 1:
            return "yesterday"
        elif delta.days < 7:
            return f"{delta.days}d ago"
        elif delta.days < 30:
            weeks = delta.days // 7
            return f"{weeks}w ago"
        else:
            return dt.strftime("%b %d")
    except (ValueError, TypeError):
        return "unknown"


def format_diff_stats(additions: int, deletions: int) -> str:
    """Format additions/deletions with color codes for fzf."""
    return f"\033[32m+{additions}\033[0m/\033[31m-{deletions}\033[0m"


def format_pr_for_display(pr: dict, idx: int) -> str:
    """Format a PR for fzf display."""
    number = pr.get("number", "?")
    title = pr.get("title", "No title")[:60]
    if len(pr.get("title", "")) > 60:
        title += "..."
    author = pr.get("author", {}).get("login", "unknown")
    created = format_date(pr.get("createdAt", ""))
    additions = pr.get("additions", 0)
    deletions = pr.get("deletions", 0)
    is_draft = pr.get("isDraft", False)
    review_decision = pr.get("reviewDecision", "")

    # Status indicator
    if is_draft:
        status = "\033[90m[draft]\033[0m"
    elif review_decision == "APPROVED":
        status = "\033[32m[approved]\033[0m"
    elif review_decision == "CHANGES_REQUESTED":
        status = "\033[31m[changes]\033[0m"
    else:
        status = ""

    # Build display line (tab-separated for fzf columns)
    diff_stats = f"\033[32m+{additions}\033[0m/\033[31m-{deletions}\033[0m"

    return f"#{number}\t{title}\t@{author}\t{created}\t{diff_stats}\t{status}"


def select_pr_with_fzf(prs: list[dict], repo: Optional[str] = None) -> Optional[dict]:
    """Use fzf to select a PR from the list."""
    if not prs:
        print("No PRs awaiting review.", file=sys.stderr)
        return None

    # Build fzf input
    lines = []
    for idx, pr in enumerate(prs):
        lines.append(format_pr_for_display(pr, idx))

    fzf_input = "\n".join(lines)

    # fzf header
    header = "PR\tTitle\tAuthor\tCreated\tDiff\tStatus"

    # Build gh commands with repo flag if needed
    repo_flag = f"--repo {repo}" if repo else ""
    preview_cmd = f"gh pr view {repo_flag} {{1}} --comments | head -100"
    open_cmd = f"gh pr view {repo_flag} {{1}} --web"

    try:
        result = subprocess.run(
            [
                "fzf",
                "--ansi",
                "--header",
                header,
                "--header-lines=0",
                "--prompt",
                "Select PR > ",
                "--preview",
                preview_cmd,
                "--preview-window",
                "right:50%:wrap",
                "--bind",
                f"ctrl-o:execute({open_cmd})+abort",
                "--expect",
                "enter,ctrl-r",
                "--tabstop=4",
            ],
            input=fzf_input,
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            return None

        output_lines = result.stdout.strip().split("\n")
        if len(output_lines) < 2:
            return None

        key_pressed = output_lines[0]
        selected_line = output_lines[1]

        # Extract PR number from selection
        pr_number = selected_line.split("\t")[0].lstrip("#")

        # Find matching PR
        for pr in prs:
            if str(pr.get("number")) == pr_number:
                return {"pr": pr, "action": key_pressed}

        return None

    except FileNotFoundError:
        print("Error: fzf not found. Install with: brew install fzf", file=sys.stderr)
        sys.exit(1)


def open_pr_in_browser(pr: dict):
    """Open PR in default browser."""
    url = pr.get("url", "")
    if url:
        subprocess.run(["open", url], check=False)


def review_pr_with_claude(pr: dict, repo: Optional[str] = None):
    """Launch Claude Code to review the PR."""
    number = pr.get("number")
    url = pr.get("url", "")

    print(f"\nLaunching Claude Code to review PR #{number}...")

    # Build repo flag for gh commands
    repo_flag = f"--repo {repo}" if repo else ""

    # Create a prompt for Claude
    prompt = f"""Review this GitHub PR:

PR #{number}: {pr.get("title", "")}
Author: {pr.get("author", {}).get("login", "unknown")}
URL: {url}
Branch: {pr.get("headRefName", "")} -> {pr.get("baseRefName", "")}

Please review this PR and provide:
1. A summary of what the PR does
2. Any potential issues or concerns
3. Suggestions for improvement
4. Overall assessment (approve/request changes/needs discussion)

To see the full diff and files, use: gh pr diff {repo_flag} {number}
To see PR details: gh pr view {repo_flag} {number}
"""

    # Launch Claude Code with the prompt
    try:
        subprocess.run(
            ["claude", "--print", prompt],
            check=False,
        )
    except FileNotFoundError:
        print("Error: claude CLI not found", file=sys.stderr)
        # Fallback: just print the prompt
        print("\n" + "=" * 60)
        print("Claude Code not available. Manual review prompt:")
        print("=" * 60)
        print(prompt)


def main():
    import argparse

    parser = argparse.ArgumentParser(
        description="Interactive PR review tool",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Keybindings in fzf:
  Enter    - Open PR in browser
  Ctrl-R   - Review PR with Claude Code
  Ctrl-O   - Quick open in browser (within fzf)
  Ctrl-C   - Cancel
        """,
    )
    parser.add_argument(
        "user",
        nargs="?",
        default="@me",
        help="GitHub user to check PRs for (default: @me)",
    )
    parser.add_argument(
        "--list",
        "-l",
        action="store_true",
        help="Just list PRs without interactive selection",
    )

    args = parser.parse_args()

    # Fetch PRs
    prs = get_prs(args.user)

    if not prs:
        print(f"No PRs awaiting review from {args.user}")
        return

    # List mode
    if args.list:
        print(f"PRs awaiting review from {args.user}:")
        print("=" * 70)
        for pr in prs:
            number = pr.get("number", "?")
            title = pr.get("title", "No title")
            author = pr.get("author", {}).get("login", "unknown")
            created = format_date(pr.get("createdAt", ""))
            additions = pr.get("additions", 0)
            deletions = pr.get("deletions", 0)
            url = pr.get("url", "")

            print(f"#{number} - {title}")
            print(
                f"  Author: {author} | Created: {created} | +{additions}/-{deletions}"
            )
            print(f"  URL: {url}")
            print()
        return

    # Interactive mode
    repo = get_repo_from_origin()
    result = select_pr_with_fzf(prs, repo)

    if not result:
        return

    pr = result["pr"]
    action = result["action"]

    if action == "ctrl-r":
        review_pr_with_claude(pr, repo)
    else:  # enter or default
        open_pr_in_browser(pr)


if __name__ == "__main__":
    main()
