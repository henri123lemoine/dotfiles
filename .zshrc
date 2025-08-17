# Prompt
ZSH_THEME="af-magic"
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# Remove right side prompt (hostname and exit codes)
RPROMPT=""

# Enable vim kiey bindings in terminal
bindkey -v

# Tool Initialization
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
source $HOME/.config/broot/launcher/bash/br  # Broot things, idk
eval "$(direnv hook zsh)"  # direnv things, idk
eval $(thefuck --alias) # allow "fuck" to correct typos
source <(fzf --zsh) # fzf integration
eval "$(zoxide init zsh)" # better cd

# Aliases
## General
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cd='z'
alias c='clear'
alias mkdir='mkdir -p'
alias gl='git log --pretty=format:"%h --- %ae --- %s"' # git log but short
alias glf='git log --name-status --pretty=format:"%h --- %ae --- %s"' # git log but short but with file names
alias rgf='rg --files | rg'  # Lets you search files with ripgrep, e.g. "rpf test.txt" will search all files under current path which path contains "test.txt"
alias pomodoro='porsmo'  # Opens a pomodoro menu
alias find='fd'  # better and faster find to replace default (fd)
alias speedtest="speedtest-rs"
alias godot="/Applications/Godot.app/Contents/MacOS/Godot"
alias sz='source ~/.zshrc'
alias ls='eza'
alias la='eza -a'
alias ll='eza -lah'
alias l='eza -lah'
alias cawa="cargo watch -q -c -w src/ -x 'run -q'"
alias run-life-logging='$HOME/Documents/Programming/PersonalProjects/life-logging/run_background.sh'
alias synopsis="$HOME/Documents/Programming/ExternalRepos/synopsis/synopsis.py"
## Paths
alias nnotes='nvim "$HOME/Documents/notes.md"'
alias ndiary='nvim "$HOME/Documents/diary.md"'
alias nprojects='nvim "$HOME/Documents/projects.md"'
***REMOVED***
alias ntmp='nvim "$HOME/Documents/tmp/tmp.md"'
alias python='python3'
alias claude='~/.claude/local/claude'

# General Functions

mkcd() { mkdir $1 ; cd $1 } # mkdir and cd in one

h() { # go to tmux session home directory
  if [[ -n "$TMUX" ]]; then
    local session_name="$(tmux display-message -p '#{session_name}')"
    local session_path="$(tmux display-message -p '#{session_path}')"
    
    # If session_path is empty, use a fallback based on session name
    if [[ -z "$session_path" ]]; then
      case "$session_name" in
        dotfiles) session_path="/Users/henrilemoine/dotfiles" ;;
        generic) session_path="/Users/henrilemoine" ;;
        *) session_path="$HOME" ;;
      esac
    fi
    
    if [[ "$PWD" != "$session_path" ]]; then
      z "$session_path"
    fi
  else
    echo "Not in a tmux session"
  fi
}

bettertree() {  # better `tree` function
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git ls-files | tree --fromfile "$@"
  else
    tree "$@"
  fi
}

teecopy() {
  local cmd=$(fc -ln -1 | sed 's/^ *//;s/ *$//')  # Store the original command
  cmd=${cmd% | teecopy}
  local output=$(eval "$cmd")  # Run the command and capture its output
  {  # Copy the command and output to clipboard
    echo "➜ $(basename $PWD) $cmd"
    echo "$output"
  } | pbcopy
  return ${pipestatus[1]}  # Return the original exit status
}

crc() {  # `cargo run` copy: Function to run cargo and copy output to clipboard
  tmp_file=$(mktemp /tmp/cargo_output.XXXXXX)
  current_dir=$(pwd)
  echo "$current_dir cargo run $@" > "$tmp_file"
  cargo run "$@" 2>&1 | tee -a "$tmp_file"
  cat "$tmp_file" | pbcopy
  rm "$tmp_file"
}

# wt <new-branch> [base]
# Creates a linked worktree at <repo>/worktrees/<safe-branch-dir> and cd's into it.
# Examples:
#   wt feature/login           # base = HEAD
#   wt hotfix-404 origin/main  # base = origin/main
wt() {
  emulate -L zsh -o pipefail

  # Args
  if (( $# < 1 )); then
    print -u2 "usage: wt <new-branch> [base]"
    return 2
  fi
  local branch="$1"
  local base="${2:-HEAD}"

  # Preflight
  command -v git >/dev/null 2>&1 || { print -u2 "error: git not found in PATH"; return 127; }

  # Must be in a *working tree* (non-bare)
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 "error: not inside a Git working tree"
    return 1
  fi

  # Main repo root (works from any linked worktree)
  local common_git_dir repo_root
  if ! common_git_dir="$(git rev-parse --git-common-dir 2>/dev/null)"; then
    print -u2 "error: failed to resolve common git dir"
    return 1
  fi
  repo_root="$(cd "$common_git_dir/.." 2>/dev/null && pwd -P)" || {
    print -u2 "error: failed to resolve repository root"
    return 1
  }

  # Paths
  # Keep the Git branch name as-is (so feature/foo is allowed),
  # but make a safe directory name for the filesystem.
  local safe="${branch// /-}"
  safe="${safe//\//__}"
  local wt_root="$repo_root/worktrees"
  local wt_dir="$wt_root/$safe"

  # Create container dir
  mkdir -p "$wt_root" 2>/dev/null || { print -u2 "error: cannot create $wt_root"; return 1; }

  # Refuse if destination exists
  if [[ -e "$wt_dir" ]]; then
    print -u2 "error: worktree path already exists: $wt_dir"
    return 1
  fi

  # Debug (opt-in)
  if [[ -n "${WT_DEBUG:-}" ]]; then
    print -u2 "-- wt debug --"
    print -u2 "CWD:      $PWD"
    print -u2 "ROOT:     $repo_root"
    print -u2 "BRANCH:   $branch"
    print -u2 "BASE:     $base"
    print -u2 "WT_DIR:   $wt_dir"
    print -u2 "----------"
  fi

  # Add worktree
  # If the branch already exists locally, just add the worktree at that branch.
  if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
    if git -C "$repo_root" worktree add "$wt_dir" "$branch"; then
      builtin cd "$wt_dir" || return 1
      pwd
      return 0
    else
      print -u2 "error: failed to add worktree for existing branch '$branch' at $wt_dir"
      return 1
    fi
  fi

  # If branch doesn't exist, try to ensure base is resolvable; fetch if it's a remote ref shape.
  if ! git -C "$repo_root" rev-parse --verify --quiet "$base" >/dev/null; then
    if [[ "$base" == */* ]]; then
      git -C "$repo_root" fetch --all --prune --quiet || true
    fi
  fi

  # Create the branch and worktree atomically.
  if git -C "$repo_root" worktree add -b "$branch" "$wt_dir" "$base"; then
    builtin cd "$wt_dir" || return 1
    pwd
    return 0
  else
    print -u2 "error: failed to create branch '$branch' from '$base' and add worktree at $wt_dir"
    return 1
  fi
}

# dwt <branch> [--force] [--keep-branch]
# Removes the linked worktree at <repo>/worktrees/<safe-branch-dir>, verifies cleanliness unless --force,
# and by default deletes the branch if it's safe (fully merged, not checked out in other worktrees).
# Use --keep-branch to preserve the branch. Use --force to override safety checks and -D the branch.
dwt() {
  emulate -L zsh -o pipefail

  # Parse args
  local force=0 keep_branch=0 branch=""
  for arg in "$@"; do
    case "$arg" in
      --force|-f) force=1 ;;
      --keep-branch|--keep|-k) keep_branch=1 ;;
      --) shift; break ;;
      -*)
        print -u2 "error: unknown option: $arg"
        print -u2 "usage: dwt <branch> [--force] [--keep-branch]"
        return 2
        ;;
      *) branch="$arg" ;;
    esac
  done

  if [[ -z "$branch" ]]; then
    print -u2 "usage: dwt <branch> [--force] [--keep-branch]"
    return 2
  fi

  # Preflight
  command -v git >/dev/null 2>&1 || { print -u2 "error: git not found in PATH"; return 127; }
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print -u2 "error: not inside a Git working tree (cd into the repo and retry)"
    return 1
  fi

  # Main repo root (works from any linked worktree)
  local common_git_dir repo_root
  if ! common_git_dir="$(git rev-parse --git-common-dir 2>/dev/null)"; then
    print -u2 "error: failed to resolve common git dir"
    return 1
  fi
  repo_root="$(cd "$common_git_dir/.." 2>/dev/null && pwd -P)" || {
    print -u2 "error: failed to resolve repository root"
    return 1
  }

  # Resolve target worktree
  local safe="${branch// /-}"; safe="${safe//\//__}"
  local wt_root="$repo_root/worktrees"
  local candidate="$wt_root/$safe"
  local wt_dir=""

  if [[ -d "$candidate" ]]; then
    wt_dir="$candidate"
  else
    local current_path="" found_path=""
    while IFS= read -r line; do
      if [[ "$line" == worktree\ * ]]; then
        current_path="${line#worktree }"
      elif [[ "$line" == branch\ refs/heads/* ]]; then
        local b="${line#branch refs/heads/}"
        [[ "$b" == "$branch" ]] && found_path="$current_path"
      fi
    done < <(git -C "$repo_root" worktree list --porcelain)
    [[ -n "$found_path" ]] && wt_dir="$found_path"
  fi

  if [[ -z "$wt_dir" || ! -d "$wt_dir" ]]; then
    print -u2 "error: worktree for branch '$branch' not found (looked for $candidate and via branch lookup)"
    return 1
  fi

  # Safety checks unless --force
  if (( ! force )); then
    if ! git -C "$wt_dir" diff --quiet --no-ext-diff; then
      print -u2 "error: unstaged changes present in $wt_dir (use --force to override)"
      return 1
    fi
    if ! git -C "$wt_dir" diff --cached --quiet --no-ext-diff; then
      print -u2 "error: staged changes present in $wt_dir (use --force to override)"
      return 1
    fi
    if [[ -n "$(git -C "$wt_dir" status --porcelain --untracked-files=normal)" ]]; then
      print -u2 "error: untracked files present in $wt_dir (use --force to override)"
      return 1
    fi
    if git -C "$wt_dir" rev-parse -q --verify MERGE_HEAD >/dev/null 2>&1; then
      print -u2 "error: merge in progress in $wt_dir (use --force to override)"
      return 1
    fi
    if [[ -d "$wt_dir/.git/rebase-apply" || -d "$wt_dir/.git/rebase-merge" ]]; then
      print -u2 "error: rebase in progress in $wt_dir (use --force to override)"
      return 1
    fi
  fi

  # If we're inside the target worktree, hop out FIRST (canonical paths)
  local abs_pwd abs_wt
  abs_pwd="$(cd "$PWD" 2>/dev/null && pwd -P)"
  abs_wt="$(cd "$wt_dir" 2>/dev/null && pwd -P)"
  if [[ -n "$abs_pwd" && -n "$abs_wt" ]]; then
    if [[ "$abs_pwd" == "$abs_wt" || "$abs_pwd" == "$abs_wt"/* ]]; then
      builtin cd "$repo_root" || return 1
    fi
  fi

  # Remove worktree (anchor all git commands at the repo root)
  if (( force )); then
    git -C "$repo_root" worktree remove --force "$wt_dir" \
      || { print -u2 "error: failed to remove worktree (forced)"; return 1; }
  else
    git -C "$repo_root" worktree remove "$wt_dir" \
      || { print -u2 "error: failed to remove worktree"; return 1; }
  fi

  # Branch deletion: default = delete if safe, unless --keep-branch
  if (( ! keep_branch )); then
    # Is the branch checked out in another worktree?
    local count=0
    while IFS= read -r line; do
      [[ "$line" == branch\ refs/heads/"$branch" ]] && ((count++))
    done < <(git -C "$repo_root" worktree list --porcelain)

    if (( count > 0 && ! force )); then
      print -u2 "note: branch '$branch' is checked out in another worktree; keeping branch (use --force to delete anyway)"
    else
      if (( force )); then
        git -C "$repo_root" branch -D "$branch" >/dev/null 2>&1 \
          || print -u2 "note: could not force-delete branch '$branch' (it may not exist)"
      else
        if ! git -C "$repo_root" branch -d "$branch" >/dev/null 2>&1; then
          print -u2 "note: branch '$branch' not fully merged; keeping it (use --force to delete anyway)"
        fi
      fi
    fi
  fi

  builtin cd "$repo_root" || return 1
  print "$PWD"
}

# Auto (programs that automatically add things to .zshrc will automatically add them below)

