# Zellij Migration from tmux

This document explains the differences between your tmux setup and this Zellij config.

## Quick Start

```bash
# Run zellij (it will use .config/zellij/config.kdl automatically)
zellij

# Attach to existing session
zellij attach <session-name>

# List sessions (shows running and resurrectable)
zellij list-sessions

# Create named session
zellij -s my-session

# Attach OR resurrect (same command)
zellij attach my-old-session  # works even if session was quit
```

## Session Management

### Multiple Sessions (Like tmux)
Sessions run in the background when you detach. Multiple sessions can run simultaneously.

### Session Switching
Two options:

1. **Built-in session-manager** (`Ctrl-a s`): Shows all sessions, switch by selecting one
2. **Sessionizer plugin** (`Ctrl-a f`): Fuzzy-find projects, creates/switches sessions (like your git-session-script)

### Session Resurrection
Sessions are auto-saved every 1 second. Even after `Ctrl-q` (quit), you can resurrect:
```bash
zellij list-sessions          # shows "foo (EXITED)"
zellij attach foo             # resurrects it
```

Commands show "Press ENTER to run..." on resurrection for safety.

## Keybinding Comparison

| Action | tmux | Zellij |
|--------|------|--------|
| Prefix | `Ctrl-a` | `Ctrl-a` (enters "tmux" mode) |
| Exit prefix mode | automatic after command | `Esc` or `Enter` |
| New window/tab | `prefix c` | `prefix c` |
| Kill pane | `prefix x` | `prefix x` |
| Split vertical | `prefix -` | `prefix -` |
| Split horizontal | `prefix \|` | `prefix \|` |
| Navigate panes | `prefix hjkl` | `prefix hjkl` |
| Resize panes | `prefix HJKL` (repeat) | `prefix H` → resize mode, then `hjkl` |
| Session picker | `prefix s` | `prefix s` → `w` for session manager |
| Copy mode | `prefix [` | `prefix [` |
| Toggle status | `prefix b` | `prefix b` (toggles pane frames) |
| Lazygit | `prefix g` | `prefix g` |
| Grove | `prefix w` | `prefix w` |
| Lazydocker | `prefix d` | `prefix Ctrl-d` (d is detach) |
| GitHub dash | `prefix Ctrl-g` | `prefix Ctrl-g` |
| rmpc | `prefix Ctrl-v` | `prefix Ctrl-v` |
| Spotify | `prefix m` | `prefix m` |
| Git session picker | `prefix f` | `prefix f` (needs script adaptation) |
| Toggle floating | (N/A) | `prefix Space` or `Alt-f` |
| Fullscreen pane | (N/A) | `prefix z` or `Alt-z` |

### Vim-style Navigation (vim-tmux-navigator replacement)

In **normal mode** (not prefix mode):
- `Ctrl-h/j/k/l` moves between panes

For seamless vim integration, install one of:
- [zellij-nav.nvim](https://github.com/swaits/zellij-nav.nvim) + zellij-autolock
- [smart-splits.nvim](https://github.com/mrjones2014/smart-splits.nvim) (works with both tmux and zellij)

## What's Different

### 1. Prefix Mode vs Instant Commands

**tmux**: `Ctrl-a x` kills pane immediately, then you're back to normal.

**Zellij**: `Ctrl-a` enters a mode, you press `x`, then `Enter` or `Esc` returns to normal. Most commands auto-return, but it's a different mental model.

### 2. Floating Panes vs Popups

**tmux `display-popup`**:
- Ephemeral overlay
- Closes completely when command exits
- No trace left behind

**Zellij floating panes**:
- Persistent pane that can be toggled
- When command exits, pane closes (same behavior for your use case)
- Can toggle all floating panes with `Alt-f`
- Can "pin" floating panes (always on top)

**Verdict**: For lazygit/lazydocker/etc, behavior is effectively the same since you close the app and the pane goes away.

### 3. Session Management

**tmux (sessionx + git-session-script)**:
- fzf-based fuzzy session picker
- Git repo discovery with caching
- Seamless switch between sessions

**Zellij**:
- Built-in session manager (`Ctrl-a s`)
- **Sessionizer plugin** (`Ctrl-a f`) - fuzzy-find projects like git-session-script
- Both support instant session switching via plugin API

**Verdict**: Comparable. The sessionizer plugin provides the fuzzy-find workflow you're used to.

### 4. Session Persistence

**tmux (resurrect + continuum)**:
- Auto-save every 15 minutes
- Restore nvim sessions with strategy
- Captures pane contents

**Zellij (built-in)**:
- Auto-save every 1 second to `~/.cache/zellij/`
- Survives reboots/crashes
- Commands require "Press ENTER to run" on restoration
- Pane viewport optionally saved (enabled in config)
- **Does NOT** restore nvim sessions (handle this in nvim config)

**To persist nvim sessions**: Use a plugin like `auto-session` or `persistence.nvim` in Neovim itself.

### 5. Resize Mode

**tmux**: `prefix H` is repeatable - hold prefix, tap H multiple times.

**Zellij**: `prefix H` enters resize mode, then `hjkl` to resize, `Esc` to exit.

**Arguably better**: Zellij lets you resize in all directions without re-pressing prefix.

### 6. Status Bar

**tmux**: Highly customizable format strings with icons, colors, etc.

**Zellij**: Uses plugins (`compact-bar`, `tab-bar`). Less customizable for one-off tweaks, but themes work.

The config uses `compact-bar` at the top. You can switch to `tab-bar` in the layout file.

## What's Missing (Needs Work)

### 1. Claude Integration Scripts

Your tmux Claude integration (`claude_popup.sh`, `claude_instances.py`, etc.) uses:
- `tmux list-panes`
- `tmux capture-pane`
- `tmux send-keys`

Zellij equivalents:
- `zellij action dump-screen`
- `zellij action write` / `zellij action write-chars`
- `zellij action list-clients`

**Status**: Not ported. Would need rewrite of ~500 lines.

### 2. git-session-script

Original uses `tmux new-session` / `tmux switch-client`.

Zellij equivalent:
```bash
# Create or attach to session
zellij attach -c "$session_name" options --default-cwd "$path"
```

**Status**: See `git-session-script-zellij` for a basic adaptation.

### 3. Create Named Session Popup

**tmux**: `prefix C` opens a popup to create named session.

**Zellij**: No direct equivalent. You'd run `zellij -s name` from a terminal.

### 4. Hot Reload Config

**tmux**: `prefix r` reloads `tmux.conf`.

**Zellij**: No hot reload. You must restart zellij. The `prefix r` binding is a placeholder.

## What's Better in Zellij

### 1. Stacked Panes
Native support for stacked layouts. Use `Alt [` and `Alt ]` to switch between stacked panes.

### 2. Floating Pane Toggle
`Alt-f` toggles all floating panes - useful for hiding/showing your "popup" tools.

### 3. Session Resurrection
Built-in, no plugins needed, saves every second.

### 4. Layouts
Define complex layouts in KDL files, share them across machines.

### 5. Edit Scrollback in Editor
In scroll mode, press `e` to open scrollback in `$EDITOR`.

## Recommended Neovim Plugins

For seamless navigation, add to your Neovim config:

```lua
-- Option 1: zellij-nav.nvim (zellij-specific)
{
  "swaits/zellij-nav.nvim",
  lazy = true,
  event = "VeryLazy",
  keys = {
    { "<c-h>", "<cmd>ZellijNavigateLeft<cr>",  { silent = true, desc = "navigate left"  } },
    { "<c-j>", "<cmd>ZellijNavigateDown<cr>",  { silent = true, desc = "navigate down"  } },
    { "<c-k>", "<cmd>ZellijNavigateUp<cr>",    { silent = true, desc = "navigate up"    } },
    { "<c-l>", "<cmd>ZellijNavigateRight<cr>", { silent = true, desc = "navigate right" } },
  },
}

-- Option 2: smart-splits.nvim (works with tmux AND zellij)
{
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  config = function()
    require("smart-splits").setup({})
  end,
  keys = {
    { "<C-h>", function() require("smart-splits").move_cursor_left() end },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end },
  },
}
```

Also install `zellij-autolock` for automatic lock mode when in vim:
```bash
# Add to plugins in config.kdl, or install manually
# See: https://github.com/fresh2dev/zellij-autolock
```

## Running Both (Transition Period)

You can run both tmux and zellij during your transition:
- Keep your tmux config as-is
- Use `zellij` when you want to test
- Gradually migrate scripts as you validate workflows

Zellij won't interfere with tmux - they're completely separate.

## Common Issues

### 1. Keybindings conflict with shell/vim
Zellij has an "autolock" mode. Make sure `zellij-autolock` is installed to auto-lock when in vim.

### 2. Floating pane doesn't close
Some apps don't properly exit. The pane persists. Close it with `prefix x`.

### 3. Session not found
Zellij sessions use different paths than tmux. Use `zellij list-sessions` to see available sessions.

### 4. Copy doesn't work
Make sure `copy_command "pbcopy"` is set (it is in the config). On Linux, use `wl-copy` or `xclip`.
