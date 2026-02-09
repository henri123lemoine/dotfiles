#!/usr/bin/env bash
set -euo pipefail

read -rp "Session name: " name
[[ -z "$name" ]] && exit 0

name="${name// /-}"
cwd="$PWD"

zellij pipe -p sessionizer -n sessionizer-new --args "cwd=$cwd,name=$name,layout=compact"
