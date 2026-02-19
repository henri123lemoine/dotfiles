#!/bin/bash
set -euo pipefail

REPO="https://github.com/henri123lemoine/dotfiles.git"
DEST="${DOTFILES_DIR:-$HOME/dotfiles}"

if ! command -v git >/dev/null 2>&1; then
  echo "git not found, installing..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -qq && sudo apt-get install -y git
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y git
  elif command -v brew >/dev/null 2>&1; then
    brew install git
  else
    echo "Cannot install git automatically. Install git and re-run."
    exit 1
  fi
fi

if [[ -d "$DEST" ]]; then
  echo "dotfiles already exist at $DEST, pulling latest..."
  git -C "$DEST" pull --ff-only
else
  git clone "$REPO" "$DEST"
fi

exec "$DEST/setup"
