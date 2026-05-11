#!/usr/bin/env bash

if [[ $# -ge 1 && $1 =~ ^[0-9]+$ ]]; then
  if [[ -z "$OG_DEFAULT_REPO" ]]; then
    echo "og: set OG_DEFAULT_REPO=owner/repo to use bare PR numbers" >&2
    exit 1
  fi
  url="https://github.com/${OG_DEFAULT_REPO}/pull/$1"
else
  dir=$(tmux run "echo #{pane_start_path}")
  cd "$dir"
  url=$(git remote get-url origin)

  if [[ $url != *"github.com"* ]]; then
    echo "This repository is not hosted on GitHub"
    exit 1
  fi
fi

if command -v open &>/dev/null; then
  open "$url"
else
  encoded=$(printf '%s' "$url" | base64 -w0)
  seq='\033]1337;SetUserVar=open_url='"$encoded"'\a'
  if [[ -n "$TMUX" ]]; then
    printf '\033Ptmux;\033'"$seq"'\033\\' > /dev/tty
  else
    printf "$seq" > /dev/tty
  fi
fi

# Inspired by https://github.com/SylvanFranklin/.config/blob/main/scripts/open_github.sh

