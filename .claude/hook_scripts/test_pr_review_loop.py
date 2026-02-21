"""Tests for pr_review_loop.py hook."""

import io
import json
import os
import sys
from unittest.mock import MagicMock, patch

import pytest

sys.path.insert(0, os.path.dirname(__file__))
import pr_review_loop


# ---------------------------------------------------------------------------
# 1. Pure function unit tests
# ---------------------------------------------------------------------------


class TestShouldWatch:
    def test_bot_suffix_default(self):
        assert pr_review_loop.should_watch("renovate[bot]", []) is True

    def test_non_bot_default(self):
        assert pr_review_loop.should_watch("alice", []) is False

    def test_explicit_login(self):
        assert pr_review_loop.should_watch("alice", ["alice", "bob"]) is True

    def test_explicit_login_miss(self):
        assert pr_review_loop.should_watch("charlie", ["alice"]) is False

    def test_wildcard(self):
        assert pr_review_loop.should_watch("anyone", ["*"]) is True

    def test_empty_author(self):
        assert pr_review_loop.should_watch("", []) is False

    def test_empty_author_with_wildcard(self):
        assert pr_review_loop.should_watch("", ["*"]) is False


class TestTruncate:
    def test_under_limit(self):
        assert pr_review_loop.truncate("short", 10) == "short"

    def test_exact_limit(self):
        assert pr_review_loop.truncate("12345", 5) == "12345"

    def test_over_limit(self):
        result = pr_review_loop.truncate("123456", 5)
        assert result.startswith("12345")
        assert "truncated" in result

    def test_none_input(self):
        assert pr_review_loop.truncate(None, 10) is None


class TestMaxId:
    def test_normal_list(self):
        assert pr_review_loop.max_id([{"id": 3}, {"id": 7}, {"id": 1}]) == 7

    def test_empty_list(self):
        assert pr_review_loop.max_id([]) == 0

    def test_missing_id_key(self):
        assert pr_review_loop.max_id([{"foo": "bar"}]) == 0

    def test_string_ids(self):
        assert pr_review_loop.max_id([{"id": "5"}, {"id": "12"}]) == 12


class TestLogin:
    def test_nested_user(self):
        assert pr_review_loop.login({"user": {"login": "alice"}}) == "alice"

    def test_missing_user(self):
        assert pr_review_loop.login({}) == ""

    def test_missing_login(self):
        assert pr_review_loop.login({"user": {}}) == ""

    def test_none_user(self):
        assert pr_review_loop.login({"user": None}) == ""


class TestAsList:
    def test_list_passthrough(self):
        data = [1, 2, 3]
        assert pr_review_loop.as_list(data) is data

    def test_dict_returns_empty(self):
        assert pr_review_loop.as_list({"key": "val"}) == []


class TestChecksCompleted:
    def test_all_completed(self):
        runs = [{"status": "completed"}, {"status": "completed"}]
        assert pr_review_loop.checks_completed(runs) is True

    def test_some_pending(self):
        runs = [{"status": "completed"}, {"status": "in_progress"}]
        assert pr_review_loop.checks_completed(runs) is False

    def test_empty_list(self):
        assert pr_review_loop.checks_completed([]) is False


class TestFormatFailedChecks:
    def test_mixed_results(self):
        runs = [
            {"name": "lint", "conclusion": "success"},
            {"name": "test", "conclusion": "failure", "html_url": "https://ci/1",
             "output": {"summary": "2 tests failed"}},
            {"name": "build", "conclusion": "skipped"},
        ]
        lines = pr_review_loop.format_failed_checks(runs)
        joined = "\n".join(lines)
        assert "Failed CI/CD Checks" in joined
        assert "**test**: failure" in joined
        assert "2 tests failed" in joined
        assert "lint" not in joined
        assert "build" not in joined

    def test_all_success(self):
        runs = [
            {"name": "lint", "conclusion": "success"},
            {"name": "build", "conclusion": "neutral"},
        ]
        assert pr_review_loop.format_failed_checks(runs) == []

    def test_empty_output_fields(self):
        runs = [{"name": "ci", "conclusion": "failure"}]
        lines = pr_review_loop.format_failed_checks(runs)
        assert any("**ci**" in line for line in lines)


class TestCollectComments:
    def test_filters_by_base_id(self):
        items = [
            {"id": 1, "user": {"login": "bot[bot]"}, "body": "old"},
            {"id": 5, "user": {"login": "bot[bot]"}, "body": "new"},
        ]
        result = pr_review_loop.collect_comments(items, 3, "issue_comment", [])
        assert len(result) == 1
        assert result[0]["body"] == "new"

    def test_filters_by_watch_logins(self):
        items = [
            {"id": 10, "user": {"login": "alice"}, "body": "hi"},
            {"id": 11, "user": {"login": "bob"}, "body": "yo"},
        ]
        result = pr_review_loop.collect_comments(items, 0, "review", ["alice"])
        assert len(result) == 1
        assert result[0]["_author"] == "alice"

    def test_mutates_author_and_kind(self):
        items = [{"id": 5, "user": {"login": "ci[bot]"}, "body": "x"}]
        result = pr_review_loop.collect_comments(items, 0, "inline_comment", [])
        assert result[0]["_author"] == "ci[bot]"
        assert result[0]["_kind"] == "inline_comment"

    def test_non_dict_items_skipped(self):
        items = [None, "string", 42, {"id": 5, "user": {"login": "b[bot]"}}]
        result = pr_review_loop.collect_comments(items, 0, "issue_comment", [])
        assert len(result) == 1


# ---------------------------------------------------------------------------
# 2. Command detection (regex) tests
# ---------------------------------------------------------------------------


class TestCommandDetection:
    @pytest.mark.parametrize(
        "cmd",
        [
            "git push",
            "git push origin main",
            "git push -u origin feat/my-branch",
            "git push --force origin main",
            "git -c push.default=current push",
        ],
    )
    def test_push_matches(self, cmd):
        assert pr_review_loop.PUSH_RE.search(cmd)

    @pytest.mark.parametrize(
        "cmd",
        [
            "gh pr create",
            "gh pr create --title \"fix: something\"",
            "gh pr create --fill",
            "gh pr create --draft --title 'WIP'",
        ],
    )
    def test_pr_create_matches(self, cmd):
        assert pr_review_loop.PR_CREATE_RE.search(cmd)

    @pytest.mark.parametrize(
        "cmd",
        [
            "git pull",
            "git status",
            "git log",
            "gh pr view",
            "gh pr list",
            "ls -la",
        ],
    )
    def test_negative_push(self, cmd):
        assert not pr_review_loop.PUSH_RE.search(cmd)

    @pytest.mark.parametrize(
        "cmd",
        [
            "git pull",
            "gh pr view",
            "gh pr merge",
        ],
    )
    def test_negative_pr_create(self, cmd):
        assert not pr_review_loop.PR_CREATE_RE.search(cmd)


# ---------------------------------------------------------------------------
# 3. Integration tests for main()
# ---------------------------------------------------------------------------


def _make_router(
    check_runs_seq=None,
    issue_comments_seq=None,
    review_comments_seq=None,
    reviews_seq=None,
):
    """Build a subprocess command router.

    Each *_seq parameter is a list of JSON-serializable values returned
    sequentially on successive gh-api calls to that endpoint. The last
    element repeats for any additional calls.
    """
    check_runs_seq = check_runs_seq or [{"check_runs": []}]
    issue_comments_seq = issue_comments_seq or [[]]
    review_comments_seq = review_comments_seq or [[]]
    reviews_seq = reviews_seq or [[]]

    counters = {
        "check_runs": 0,
        "issue_comments": 0,
        "review_comments": 0,
        "reviews": 0,
    }

    def _next(key, seq):
        idx = min(counters[key], len(seq) - 1)
        counters[key] += 1
        return seq[idx]

    def router(cmd, **kwargs):
        r = MagicMock()
        r.returncode = 0
        r.stderr = ""
        r.stdout = ""

        if cmd[0] == "gh" and cmd[1] == "auth":
            r.stdout = "Logged in\n"
        elif cmd[0] == "git" and "rev-parse" in cmd:
            r.stdout = "abc123def\n"
        elif cmd[:3] == ["gh", "pr", "view"]:
            r.stdout = json.dumps({
                "number": 42,
                "url": "https://github.com/owner/repo/pull/42",
            })
        elif cmd[0] == "gh" and cmd[1] == "api":
            path = cmd[2] if len(cmd) > 2 else ""
            if "-f" in cmd:
                r.stdout = "{}"
            elif "check-runs" in path:
                r.stdout = json.dumps(_next("check_runs", check_runs_seq))
            elif "issues/" in path:
                r.stdout = json.dumps(_next("issue_comments", issue_comments_seq))
            elif "pulls/" in path and "comments" in path:
                r.stdout = json.dumps(_next("review_comments", review_comments_seq))
            elif "reviews" in path:
                r.stdout = json.dumps(_next("reviews", reviews_seq))
            else:
                r.stdout = "[]"
        return r

    return router


def _run_main(event, router=None, config=None):
    """Run main() with all external boundaries mocked.

    Returns (exit_code, parsed_payload_or_None).
    """
    if router is None:
        router = lambda cmd, **kw: MagicMock(stdout="", stderr="", returncode=0)

    stdout_buf = io.StringIO()
    exit_code = [None]
    clock = [1_000_000.0]

    def fake_exit(code=0):
        exit_code[0] = code
        raise SystemExit(code)

    def fake_time():
        return clock[0]

    def fake_sleep(secs):
        clock[0] += secs

    with patch("sys.stdin", io.StringIO(json.dumps(event))), \
         patch("sys.stdout", stdout_buf), \
         patch("sys.exit", side_effect=fake_exit), \
         patch("subprocess.run", side_effect=router), \
         patch("time.time", side_effect=fake_time), \
         patch("time.sleep", side_effect=fake_sleep), \
         patch.object(pr_review_loop, "load_config", return_value=config or {}):
        try:
            pr_review_loop.main()
        except SystemExit:
            pass

    raw = stdout_buf.getvalue()
    payload = json.loads(raw) if raw.strip() else None
    return exit_code[0], payload


class TestMainEarlyExits:
    def test_non_bash_tool(self):
        code, payload = _run_main({"tool_name": "Read", "tool_input": {}})
        assert code == 0
        assert payload is None

    def test_irrelevant_command(self):
        code, payload = _run_main(
            {"tool_name": "Bash", "tool_input": {"command": "ls -la"}}
        )
        assert code == 0
        assert payload is None

    def test_disabled_via_env(self):
        os.environ["CLAUDE_PR_REVIEW_LOOP"] = "0"
        code, payload = _run_main(
            {"tool_name": "Bash", "tool_input": {"command": "git push"}}
        )
        assert code == 0
        assert payload is None


class TestMainAllChecksPass:
    def test_no_output_when_all_green(self):
        checks_pending = {"check_runs": [
            {"name": "test", "status": "in_progress", "conclusion": None},
        ]}
        checks_done = {"check_runs": [
            {"name": "test", "status": "completed", "conclusion": "success"},
        ]}
        router = _make_router(
            check_runs_seq=[checks_pending, checks_done],
        )
        event = {"tool_name": "Bash", "tool_input": {"command": "git push origin main"}}
        code, payload = _run_main(event, router)
        assert code == 0
        assert payload is None


class TestMainCIFailure:
    def test_emits_failure_details(self):
        checks = {"check_runs": [
            {"name": "lint", "status": "completed", "conclusion": "success"},
            {"name": "test", "status": "completed", "conclusion": "failure",
             "html_url": "https://ci/run/1",
             "output": {"summary": "3 tests failed"}},
        ]}
        router = _make_router(check_runs_seq=[checks])
        event = {"tool_name": "Bash", "tool_input": {"command": "git push"}}
        code, payload = _run_main(event, router)
        assert code == 0
        msg = payload["systemMessage"]
        assert "Failed CI/CD Checks" in msg
        assert "**test**: failure" in msg
        assert "3 tests failed" in msg


class TestMainBotComments:
    def test_collects_issue_comments(self):
        checks = {"check_runs": [
            {"name": "ci", "status": "completed", "conclusion": "success"},
        ]}
        bot_comment = [
            {"id": 100, "user": {"login": "coderabbit[bot]"}, "body": "Looks risky"},
        ]
        router = _make_router(
            check_runs_seq=[checks],
            issue_comments_seq=[[], [], bot_comment],
        )
        event = {"tool_name": "Bash", "tool_input": {"command": "gh pr create --fill"}}
        code, payload = _run_main(event, router)
        assert code == 0
        msg = payload["systemMessage"]
        assert "PR Comments" in msg
        assert "coderabbit[bot]" in msg
        assert "Looks risky" in msg


class TestMainMixed:
    def test_ci_failure_and_inline_comments(self):
        checks = {"check_runs": [
            {"name": "build", "status": "completed", "conclusion": "failure",
             "html_url": "https://ci/2",
             "output": {"summary": "compile error"}},
        ]}
        inline = [
            {"id": 200, "user": {"login": "reviewer[bot]"}, "body": "Fix types",
             "path": "src/main.py", "line": 42},
        ]
        router = _make_router(
            check_runs_seq=[checks],
            review_comments_seq=[[], [], inline],
        )
        event = {"tool_name": "Bash", "tool_input": {"command": "git push"}}
        code, payload = _run_main(event, router)
        assert code == 0
        msg = payload["systemMessage"]
        assert "Failed CI/CD Checks" in msg
        assert "**build**: failure" in msg
        assert "Inline Comments" in msg
        assert "reviewer[bot]" in msg
        assert "src/main.py:42" in msg


class TestMainNoChecks:
    def test_still_collects_comments(self):
        no_checks = {"check_runs": []}
        bot_comment = [
            {"id": 50, "user": {"login": "sweep[bot]"}, "body": "Suggestion here"},
        ]
        router = _make_router(
            check_runs_seq=[no_checks],
            issue_comments_seq=[[], [], bot_comment],
        )
        event = {"tool_name": "Bash", "tool_input": {"command": "git push"}}
        code, payload = _run_main(event, router)
        assert code == 0
        msg = payload["systemMessage"]
        assert "sweep[bot]" in msg
        assert "Suggestion here" in msg


class TestMainTimeout:
    def test_reports_partial_on_timeout(self):
        checks_pending = {"check_runs": [
            {"name": "slow-test", "status": "in_progress", "conclusion": None},
        ]}
        bot_comment = [
            {"id": 75, "user": {"login": "linter[bot]"}, "body": "Style issue"},
        ]
        router = _make_router(
            check_runs_seq=[checks_pending],
            issue_comments_seq=[[], [], bot_comment],
        )
        event = {"tool_name": "Bash", "tool_input": {"command": "git push"}}
        code, payload = _run_main(event, router)
        assert code == 0
        msg = payload["systemMessage"]
        assert "linter[bot]" in msg
        assert "Style issue" in msg
