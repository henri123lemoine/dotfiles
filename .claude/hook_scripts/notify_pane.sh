#!/usr/bin/env bash
# Shim kept so settings.json hook paths stay stable; the real logic lives in
# dotfiles: ~/.config/scripts/notify/notify (generic notifier, on PATH as `notify`)
exec "$HOME/.config/scripts/notify/notify" claude-hook "${1:-Stop}"
