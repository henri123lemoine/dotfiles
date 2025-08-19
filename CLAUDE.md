# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is a dotfiles repository with a transactional setup system for macOS environments. The `./setup` script creates symlinks for configuration files, clones external repositories, and installs packages with automatic rollback on failure.

## Configuration Files by Category

- Zsh Shell:
  - `.zshrc` - Main zsh configuration
  - `.zshenv` - Zsh environment variables
  - `.zprofile` - Zsh profile settings
- Git:
  - `.gitconfig` - Git global configuration
  - `.gitignore_global` - Global gitignore file
  - `.gitignore` - Repository gitignore
- Wezterm: `.config/wezterm/wezterm.lua`
- Tmux
  - `.config/tmux/tmux.conf` - Tmux configuration file
  - `.tmux/scripts/llm/` - LLM integration script for tmux
- Neovim: `.config/nvim/`
- Hammerspoon: `.hammerspoon/`
- Music/Media:
  - `.config/mpd/mpd.conf` - Music Player Daemon configuration
  - `.config/rmpc/config.ron` - rmpc (Rust MPD client) configuration
  - `.config/beets/config.yaml` - Beets music library manager configuration
  - `reload-mpd.sh` - Script to reload MPD
- Claude Code: `.claude/`
  - `.claude/settings.json`
  - `.claude/hook_scripts/`
- `Brewfile` - Homebrew Bundle package definitions (development tools, CLI utilities)
- `external_repos.txt` - External repositories to clone (format: path|git_url|branch)

## Common Commands

- `./setup` - Install/link all dotfiles with transactional behavior
- `SETUP_RELINK_IDENTICAL=1 ./setup` - Replace identical existing files with symlinks
- `SETUP_UPDATE_EXTERNAL=1 ./setup` - Update external repositories during setup
- `reload-mpd.sh` - Reload MPD music daemon

## Architecture

The setup script (`setup`) performs preflight checks, creates symlinks for all top-level dotfiles to `$HOME`, handles `.config` directory contents individually, clones external repositories from `external_repos.txt`, and installs packages from `Brewfile`. On any failure, it automatically rolls back changes including removing created symlinks and uninstalling newly installed packages.

The script uses transactional behavior with comprehensive conflict detection, content comparison for files, and a rollback system that tracks all mutations and reverses them on failure.
