# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is a dotfiles repository with a transactional setup system for macOS and Linux/Ubuntu environments. The `./setup` script automatically detects the OS, creates symlinks for configuration files, clones external repositories, and installs packages using the appropriate package manager (Homebrew for macOS, apt for Ubuntu) with automatic rollback on failure.

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
- Package files (OS-specific):
  - `Brewfile` - macOS package definitions for Homebrew Bundle (development tools, CLI utilities)
  - `packages.ubuntu` - Ubuntu/Linux package list for apt-get (essential dev tools only)
- `external_repos.txt` - External repositories to clone (format: path|git_url|branch)
- Scripts: `.config/scripts/`
  - `.config/scripts/llm/` - LLM integration CLI script (general purpose OpenAI API tool)
  - `.config/scripts/reload-mpd.sh` - Script to reload MPD
  - private scripts in `.config/scripts/private/`
- Private dotfiles: `dotfiles-private/` (Git submodule for sensitive/personal configurations)
- Testing: `tests/`
  - `tests/validate-setup.sh` - Validation script that checks setup completed successfully
  - `tests/run-tests.sh` - Orchestrates Docker-based tests across different OS
  - `tests/Dockerfile.ubuntu` - Ubuntu test environment
  - `docker-compose.test.yml` - Docker Compose configuration for tests

## Common Commands

- `./setup` - Install/link all dotfiles with transactional behavior
- `SETUP_RELINK_IDENTICAL=1 ./setup` - Replace identical existing files with symlinks
- `SETUP_UPDATE_EXTERNAL=1 ./setup` - Update external repositories during setup
- `.config/scripts/reload-mpd.sh` - Reload MPD music daemon
- `./tests/run-tests.sh` - Run automated tests in Docker containers
- `./tests/validate-setup.sh` - Validate setup completed successfully (can run locally)

## Architecture

The setup script (`setup`) performs preflight checks, creates symlinks for all top-level dotfiles to `$HOME`, handles `.config` directory contents individually, clones external repositories from `external_repos.txt`, and installs packages using the appropriate package manager based on OS detection:
- **macOS** (detected via `$OSTYPE == "darwin*"`): Uses `Brewfile` with Homebrew Bundle
- **Ubuntu/Linux** (detected via `$OSTYPE == "linux-gnu*"` or `/etc/debian_version`): Uses `packages.ubuntu` with apt-get

On any failure, it automatically rolls back changes including removing created symlinks and uninstalling newly installed packages (macOS only for package rollback).

The script uses transactional behavior with comprehensive conflict detection, content comparison for files, and a rollback system that tracks all mutations and reverses them on failure.

Note: Some packages in `packages.ubuntu` may require additional setup (PPAs, cargo installation, or GitHub releases). The setup script will continue with a warning if some packages are unavailable through apt.

## Testing

The repository includes automated tests that run locally and in CI/CD:

### Local Testing
- **macOS**: `./tests/run-macos-tests.sh` (works perfectly - 34/34 tests)
- **Ubuntu**: `./tests/run-tests.sh ubuntu` (Docker-based, see tests/KNOWN_ISSUES.md for M1 Mac issues)
- **Validation**: `./tests/validate-setup.sh` (checks symlinks, commands, configs)

### CI/CD Testing
GitHub Actions automatically tests on every push:
- ✅ macOS latest (on real macOS runners)
- ✅ Ubuntu latest (on real Linux runners)
- ✅ Ubuntu in Docker (containerized testing)

See `.github/workflows/test-dotfiles.yml` for the workflow configuration.

To run tests locally: `./tests/run-macos-tests.sh` or see `tests/README.md` for detailed documentation.

