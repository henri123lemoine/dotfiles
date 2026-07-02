# notify

Generic desktop notifier for terminal agents/tools running in tmux inside
WezTerm. Not tied to any one assistant — Claude Code and Codex plug in via
adapter subcommands; anything else can call `notify send`/`notify blocker`.

## Pieces

- `notify` — the single entry point, on PATH via `~/.config/scripts/bin`.
  Posts macOS banners via `terminal-notifier` whose click jumps to the
  originating tmux pane (`notify focus <target>`: `tmux switch-client` +
  `select-window` + `select-pane`, then activates WezTerm). Plays a sound for
  blockers. Run with no args for full usage.
- `notify claude-hook <event>` — Claude Code adapter; the Stop and Notification
  hooks in `.claude/settings.json` point at the `~/.claude/hook_scripts/notify_pane.sh`
  shim, which execs this.
- `notify codex-hook` — Codex CLI adapter; enable with
  `notify = ["/Users/henrilemoine/.config/scripts/notify/notify", "codex-hook"]`
  in `~/.codex/config.toml`.
- `.claude/skills/notify-user/SKILL.md` — Claude Code skill; agents run
  `notify blocker "<what they need>"` when hard-blocked.
- Hammerspoon `⌘⌃C` (`.config/hammerspoon/init.lua`) — runs `notify focus-last`
  to jump to the most recently notified pane without touching the mouse.
- `listener.sh` + `com.henri.notify-listener.plist` — launchd agent on the Mac
  receiving `EVENT|TARGET` lines on 127.0.0.1:9876 from remote (Linux) machines
  over a reverse SSH tunnel; `notify` forwards automatically when no local
  notifier exists. Install with `./install.sh`.

## Behavior notes

- Banners are suppressed when the target pane is active in an attached session
  AND WezTerm is the frontmost app (you're already looking at it). Blockers
  (`notify blocker`, `--force`) bypass the check and always alert.
- Claude stop-hook continuations (`stop_hook_active`) and subagent events are
  skipped by the claude-hook adapter.
- Processes without `$TMUX_PANE` (background jobs) get their pane found by
  matching panes' cwd against the project dir (worktrees resolve to the repo),
  preferring panes running a matching agent CLI.
- Banners auto-dismiss by default; for click-to-jump to be useful when away,
  set terminal-notifier's notification style to **Alerts** in
  System Settings → Notifications (alerts persist until dismissed).
- Do not add `-sender` to terminal-notifier calls — it silently breaks
  `-execute`/`-activate` click handling.

## Env knobs

`NOTIFY_APP` (label used in titles, e.g. "Claude blocked"), `NOTIFY_TARGET`
(explicit tmux target), `NOTIFY_PORT` (default 9876), `NOTIFY_VOLUME` (default
0.8), `NOTIFY_SOUND_STOP` / `_INPUT` / `_BLOCKER` (system sound name or `none`;
defaults none/none/Basso), `NOTIFY_DEBUG=1` (log to
`~/.local/state/notify/debug.log`).
