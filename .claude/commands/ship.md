---
description: Create a PR (or update existing), push, and iterate on CI/bot feedback until clean
allowed-tools: Bash(gh pr create:*), Bash(gh pr create)
argument-hint: [--draft]
---

# Context

Branch: `$(!git branch --show-current)`

```
$(!git status --short)
```

Existing PR:
```
$(!gh pr view --json number,url,title,state 2>/dev/null || echo "No existing PR")
```

Commits vs main:
```
$(!git log main..HEAD --oneline 2>/dev/null || git log origin/main..HEAD --oneline 2>/dev/null || echo "Could not diff against main")
```

Diff stat vs main:
```
$(!git diff --stat main...HEAD 2>/dev/null || git diff --stat origin/main...HEAD 2>/dev/null || echo "Could not diff against main")
```

# Instructions

You are shipping this branch as a PR. Work through each phase sequentially.

## 1. Pre-checks

- If on `main` or `master`: create a descriptive feature branch from context and switch to it.
- If there are uncommitted changes: stage and commit with a clear conventional-commit message.

## 2. Local validation

Detect the project type and run appropriate checks:
- `package.json` → `npm test`, `npm run lint`
- `pyproject.toml` → `pytest`, `ruff check`
- `Makefile` → `make test`, `make lint`
- `Cargo.toml` → `cargo test`, `cargo clippy`
- Shell scripts → `shellcheck`
- Multiple types → run all that apply
- None detected → skip

Fix any failures before proceeding. Do not skip or disable tests to make them pass.

## 3. Push and create/update PR

- `git push -u origin HEAD`
- **No existing PR**: create one with `gh pr create` using a conventional-commit style title and a body with a summary section and test plan. If the user passed `--draft`, add the `--draft` flag.
- **PR exists**: update with `gh pr edit` only if the description needs material changes.
- Report the PR URL.

## 4. React to hook feedback

After each push, the `pr_review_loop` hook polls CI and bot comments asynchronously. When it injects a `systemMessage` with failures or feedback:

- **CI failures**: read the details, fix the root cause, verify the fix locally, commit, and push.
- **Bot review comments**: fix legitimate issues. Note false positives but don't waste cycles on them.
- Each push re-triggers the hook automatically — just fix and push.

## 5. Guardrails

- **Max 4 fix-push cycles**, then stop and ask the user for guidance.
- **Never force-push.**
- **Never suppress or skip tests** to make CI pass.
- **Pre-existing / unrelated failures**: note them and move on — only fix what this branch introduced.

## 6. Notify

When finished (PR is clean, or you've hit the cycle limit and are stopping), run `notify "ship complete"` to alert the user.

$arguments
