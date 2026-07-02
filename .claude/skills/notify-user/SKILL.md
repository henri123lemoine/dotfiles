---
name: notify-user
description: Alert the user on their Mac when hitting a BIG BLOCKER — stuck needing user input, auth, a decision, or hitting a hard failure that stops progress. Distinct from normal end-of-turn. Use proactively the moment a turn is about to end in "needs input:", "failed:", or an equivalent blocked state, especially in background sessions where the user may be away.
---

# Notify User (Blocker Alert)

When you hit a big blocker — you cannot make further progress without the user — send an urgent alert: it plays a sound and shows a macOS banner that, when clicked, jumps straight to this session's tmux window in WezTerm.

## When to trigger

- Ending a turn with `needs input:` or `failed:`
- Stuck waiting on something only the user can do (auth, GUI interaction, a decision, access)
- A long-running task died in a way that needs human attention

Do NOT trigger for normal task completion (the Stop hook already handles that), questions asked mid-conversation while the user is clearly active, or minor recoverable errors.

## How

Run (unsandboxed so audio and notifications work; never let it fail the turn):

```bash
NOTIFY_APP=Claude notify blocker "<one short line: what you need>" || true
```

`notify` is the generic notifier on PATH (`~/.config/scripts/bin`); if it's not found, use the full path `~/.config/scripts/notify/notify`.

The message should say what unblocks you, e.g. `"Need: gcloud auth login"` or `"Decision: drop or migrate the legacy table?"`. Keep it under ~70 chars — it's a banner.

The script resolves the tmux pane automatically (via `$TMUX_PANE`, or by matching the project directory when running as a background job) and wires the banner click to `tmux switch-client` + WezTerm activation. No target setup needed.

## Rules

- Alert once per distinct blocker — do not repeat it every turn while still blocked on the same thing.
- If the script is missing or errors, fall back to `afplay /System/Library/Sounds/Basso.aiff` and continue.
