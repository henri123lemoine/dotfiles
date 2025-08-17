# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is a dotfiles repository with a transactional setup system for macOS environments. The key architecture ensures all-or-nothing installation with automatic rollback on failure.

Some settings for:

- zsh
- wezterm
- claude
- git (global `.gitignore`, `.gitconfig`)
- brew
- hammerspoon
- nvim

## Common Commands

### Setup and Installation

- `./setup` - Main setup script with transactional behavior (runs preflight, creates symlinks, clones external repos, installs packages)
- `SETUP_RELINK_IDENTICAL=1 ./setup` - Replace identical existing files with symlinks

## Architecture

### Core Components

1. **Transactional Setup Script (`./setup`)**

   - Performs comprehensive preflight checks before making any changes
   - Creates symlinks for dotfiles (`.zshrc`, `.gitconfig`, `.tmux.conf`, etc.)
   - Clones external repositories defined in `external_repos.txt`
   - Installs Homebrew packages from `Brewfile`
   - Automatic rollback on any failure (removes created symlinks/dirs, uninstalls packages)

2. **External Repository Management (`external_repos.txt`)**

   - Format: `relative/path|git_url|optional_branch`
   - Currently manages: nvim config and tmux plugin manager
   - Reuses existing git repos if remote URLs match

3. **Package Management (`Brewfile`)**
   - Declarative package installation using Homebrew Bundle
   - Includes development tools (neovim, git, docker, rust-analyzer, etc.)
   - Transactional behavior: newly installed packages are uninstalled on script failure

### Key Files Structure

- **Dotfiles**: All top-level hidden files/dirs are automatically symlinked to `$HOME`
- **Configuration**: Shell configs (`.zshrc`, `.zshenv`), Git config (`.gitconfig`), tmux config (`.tmux.conf`)
- **Gitignore**: Single `.gitignore` serves as both repo ignore and global Git exclude file

### Safety Mechanisms

- **Conflict Detection**: Script scans for existing files/directories before proceeding
- **Content Comparison**: Differentiates between identical and different file conflicts
- **Rollback System**: Tracks all mutations and reverses them on failure
- **Git Integration**: Honors `.gitignore` rules when selecting files to symlink

## Development Notes

- The setup script uses bash with strict error handling (`set -euo pipefail`)
- Git URL normalization handles both HTTPS and SSH formats
- External repos support optional branch specification
- Homebrew rollback is best-effort (dependencies may remain)
- `RELINK_IDENTICAL=1` flag allows replacing identical files with symlinks for future synchronization
