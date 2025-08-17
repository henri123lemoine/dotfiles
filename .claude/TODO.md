# Claude Code + TMUX Session Switcher - TODO

## Phase 1: Hook Research & Testing

### Research Stop/Notification hooks

- [ ] Check Claude Code docs for hook event data format
- [ ] Test what information is passed to hooks (working directory, session ID, etc.)
- [ ] Verify if Stop hooks fire reliably vs Notification hooks
- [ ] Create test hook script to see what JSON data we receive

### Analyze existing Claude session logs

- [ ] Analyze existing Claude session logs in ~/.claude/projects/\*/
- [ ] Look for session start/end markers and working directory info in logs
- [ ] Confirm how session IDs correlate between hooks and log files

## Phase 2: TMUX-Claude Correlation Strategy

### Directory-based correlation

- [ ] Create script that maps TMUX sessions to their working directories
- [ ] Test correlation accuracy between Claude working dir and TMUX sessions
- [ ] Handle edge cases (multiple sessions in same directory, subdirectories, etc.)

### Session info caching

- [ ] Design cache file format (JSON with timestamp, claude_session_id, tmux_session_name, working_dir)
- [ ] Implement cache cleanup (remove old entries, handle multiple Claude sessions)

## Phase 3: Hook Implementation

### Create Claude hook script

- [ ] Create Claude hook script that receives session data via stdin
- [ ] Extract working directory and session info from hook data
- [ ] Find matching TMUX session by directory correlation
- [ ] Update cache file with latest session mapping

### Configure hook in settings

- [ ] Configure hook in Claude settings (Stop or Notification events)
- [ ] Test hook firing reliability across different conversation end scenarios

## Phase 4: Hotkey & Switching Logic

### Create session switcher script

- [ ] Create session switcher script that reads from cache
- [ ] Validate TMUX session still exists before switching
- [ ] Implement TMUX switching logic (switch-client vs attach-session)
- [ ] Handle cases where session is already active, doesn't exist, etc.

### Global hotkey setup

- [ ] Create Hammerspoon/BetterTouchTool configuration for hotkey binding
- [ ] Add visual/audio feedback for successful switches

## Phase 5: Edge Cases & Polish

### Handle multiple scenarios

- [ ] Handle multiple Claude sessions in same directory
- [ ] Handle Claude running outside TMUX
- [ ] Handle TMUX sessions that don't correspond to Claude sessions
- [ ] Handle cache corruption or missing cache file

### Performance optimization

- [ ] Ensure hook script runs quickly (async cache updates)
- [ ] Optimize TMUX session discovery
- [ ] Add debug mode for troubleshooting

## Research Questions to Answer

- **Stop vs Notification hooks**: Which fires more reliably? What's the timing difference?
- **Hook data format**: Exactly what JSON structure do we receive? Does it include working directory?
- **TMUX path correlation**: How accurate is `pane_current_path` for directory matching?
- **Cache persistence**: Where to store cache file? How to handle concurrent access?

## Key Advantages of This Approach

- Real-time capture when conversation ends (no log parsing delays)
- Exact session correlation (no guessing from timestamps)
- Working directory correlation (more reliable than process matching)
- Hotkey-triggered switching (user control over when to switch)

---

## Original TODO item to fix:

Fix this:

```
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "$HOME/.claude/uv_reminder_hook.py"
    }
  ]
}
```
