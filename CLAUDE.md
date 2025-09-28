# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is a dotfiles repository with a transactional setup system for macOS environments. The `./setup` script creates symlinks for configuration files, clones external repositories, and installs packages with automatic rollback on failure.

The sister repo and submodule, `dotfiles-private/`, contains all the content from this `dotfiles/` setup that is private.

## Configuration Files by Category

- Zsh Shell:
  - `.zshenv` - Zsh environment variables (sets ZDOTDIR to .config/zsh)
  - `.config/zsh/` - Zsh configuration directory
    - `.config/zsh/.zshrc` - Main zsh configuration
    - `.config/zsh/.zprofile` - Zsh profile settings
    - `.config/zsh/functions.zsh` - Custom Zsh functions
- Git:
  - `.config/git/config` - Git global configuration
  - `.config/git/ignore` - Global gitignore file
  - `.gitignore` - Repository gitignore
  - `.ignore` - Search tool ignore patterns (ripgrep, etc.)
- Wezterm: `.config/wezterm/wezterm.lua`
- Tmux
  - `.config/tmux/tmux.conf` - Tmux configuration file
- Neovim: `.config/nvim/init.lua`
- Hammerspoon: `.config/hammerspoon/`
- Music/Media:
  - `.config/mpd/mpd.conf` - Music Player Daemon configuration
  - `.config/rmpc/config.ron` - rmpc (Rust MPD client) configuration
  - `.config/beets/config.yaml` - Beets music library manager configuration
- Claude Code: `.claude/`
  - `.claude/settings.json`
  - `.claude/hook_scripts/` - Hook scripts including tmux integration and instance management
    - `claude_popup.sh` - Tmux popup interface for Claude instances with fzf
    - `claude_instances.py` - Claude instance detection and management
- `Brewfile` - Homebrew Bundle package definitions (development tools, CLI utilities)
- `external_repos.txt` - External repositories to clone (format: path|git_url|branch)
- Scripts: `.config/scripts/`
  - `.config/scripts/llm/` - LLM integration CLI script (general purpose OpenAI API tool)
  - `.config/scripts/reload-mpd.sh` - Script to reload MPD
  - private scripts in `.config/scripts/private/`
- Private dotfiles: `dotfiles-private/` (Git submodule for sensitive/personal configurations)

## Common Commands

- `./setup` - Install/link all dotfiles with transactional behavior
- `SETUP_RELINK_IDENTICAL=1 ./setup` - Replace identical existing files with symlinks
- `SETUP_UPDATE_EXTERNAL=1 ./setup` - Update external repositories during setup
- `.config/scripts/reload-mpd.sh` - Reload MPD music daemon

## Architecture

The setup script (`setup`) performs preflight checks, creates symlinks for all top-level dotfiles to `$HOME`, handles `.config` directory contents individually, clones external repositories from `external_repos.txt`, and installs packages from `Brewfile`. On any failure, it automatically rolls back changes including removing created symlinks and uninstalling newly installed packages.

The script uses transactional behavior with comprehensive conflict detection, content comparison for files, and a rollback system that tracks all mutations and reverses them on failure.

