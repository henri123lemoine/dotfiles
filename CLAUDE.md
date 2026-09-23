# CLAUDE.md

This is a dotfiles repository with a transactional setup system for macOS and Linux/Ubuntu environments. The `./setup` script automatically detects the OS, creates symlinks for configuration files, clones external repositories, and installs packages using the appropriate package manager (Homebrew for macOS, apt for Ubuntu) with automatic rollback on failure.

The sister repo and submodule, `dotfiles-private/`, contains all the content from this `dotfiles/` setup that is private.

## Gotchas

- `.zshenv` sets `ZDOTDIR` to `.config/zsh`, so the rest of the zsh config lives there rather than in `$HOME`.
- `external_repos.txt` format is `path|git_url|branch`.
- Some packages in `packages.ubuntu` need setup apt cannot provide (PPAs, cargo, GitHub releases). Setup warns and continues rather than failing.

## Common Commands

- `./setup` - Install/link all dotfiles with transactional behavior
- `SETUP_RELINK_IDENTICAL=1 ./setup` - Replace identical existing files with symlinks
- `SETUP_UPDATE_EXTERNAL=1 ./setup` - Update external repositories during setup
- `.config/scripts/reload-mpd.sh` - Reload MPD music daemon
- `./tests/run-tests.sh [ubuntu]` - Run automated tests in Docker containers
- `./tests/validate-setup.sh` - Validate setup completed successfully (can run locally)
- `./tests/test-fresh-mac.sh` - Simulate fresh Mac setup with isolated HOME (catches .zshrc issues)
