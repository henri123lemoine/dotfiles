# Git

## Add

Generally do not run `git add` unless the user explicitly requests it.

## Commits

Match the standard commit messages from the codebase. Typically, `<type e.g. feat / docs>(<project-specific type e.g. tooling / env-specific>): <thing that is done>`, including more detail in the commit details if need be. E.g., `feat(model-registry): implement delete_model side task`.

## Push

*NEVER* use `git push` or any externally-impacting commands unless explicitly requested by the user.

## GitHub Actions

Never submit GitHub PR reviews, comments, approvals, or any other actions that post publicly without explicit user confirmation. Always present analysis first and ask before executing.
