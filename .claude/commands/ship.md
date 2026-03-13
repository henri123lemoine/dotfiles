---
description: Create a PR (or update existing), push, and iterate on CI/bot feedback until clean
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

You are shipping the existing commits on this branch as a PR. Work through each phase sequentially.

**CRITICAL: Do NOT stage, commit, or modify files during pre-checks/local validation. Only do that when fixing CI or review feedback after the PR is up (phase 4).**

## 1. Pre-checks

- If on `main` or `master`: **stop and tell the user** to create a feature branch first. Do not create one.
- If there are uncommitted changes: **leave them be**. Do not stage or commit anything.
- Run `gh auth status -h github.com` and stop with a clear fix message if auth is invalid.

## 2. Local validation

Detect the project type and run appropriate checks. If they fail, report the failures, but do not commit yet.

## 3. Push and create/update PR

- `git push -u origin HEAD`
- **No existing PR**: create one with `gh pr create` using a conventional-commit style title and a body with a summary section and test plan.
- **PR exists**: update with `gh pr edit` only if the description needs material changes.
- Report the PR URL.
- The `pr_review_loop` hook fires asynchronously after each push/create and delivers `additionalContext` on the **next model turn**. After push/create, stop and wait for that feedback before doing phase 4.

## 4. React to hook feedback

When the hook delivers feedback (CI failures, bot review comments):

- **CI failures**: read the details, investigate and fix the root cause, verify the fix locally, commit, and push.
- **Bot review comments**: fix legitimate issues. Note false positives but don't waste cycles on them.
- Each push re-triggers the hook automatically — just fix and push.

## 5. Guardrails

- **Max 6 fix-push cycles**, then stop and ask the user for guidance.
- **You should never have to force-push, and may only if the user explicitly tells you to.**
- **Never suppress or skip tests** to make CI pass.
- **Pre-existing / unrelated failures**: note them and move on — only fix what this branch introduced.

## 6. Notify

When finished (PR is clean, or you've hit the cycle limit and are stopping), run `notify "ship complete"` to alert the user.

## 7. Additional Clarifications, If Any

$arguments
