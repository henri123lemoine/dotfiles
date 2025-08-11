# Prompt
ZSH_THEME="af-magic"
export ZSH="$HOME/.oh-my-zsh"
source $ZSH/oh-my-zsh.sh

# Enable vim kiey bindings in terminal
bindkey -v

# Aliases (inspired by Fraser)
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ll='ls -aAlFG'
alias 777='chmod -R 777'
alias 755='chmod -R 755'
alias e='nvim'
alias crago='cargo' # inside joke
alias krago='cargo'
alias mkdir='mkdir -p'
alias python='python3'
alias py='python3'
alias pip='python3 -m pip'
alias gl='git log --pretty=format:"%h --- %ae --- %s"' # git log but short
alias glf='git log --name-status --pretty=format:"%h --- %ae --- %s"' # git log but short but with file names
eval $(thefuck --alias) # allow "fuck" to correct typos
source <(fzf --zsh) # fzf integration
eval "$(zoxide init zsh)" # better cd
alias cd='z'

# SPECIFIC

# Node Version Manager (NVM)
## Environment Variables
export NVM_DIR="$HOME/.nvm"
## Configuration
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Java
## Environment Variables
export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home"

# Apache Ant
## Environment Variables
export ANT_HOME="$HOME/devtools/apache-ant-1.10.14"
export PATH="$PATH:$ANT_HOME/bin"
# Bun
## Environment Variables
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
## Configuration
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Python: None -- Just use uv

# Go
## Environment Variables
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin:$(go env GOPATH)/bin"
## Aliases
alias air='$(go env GOPATH)/bin/air'
# export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
# export PATH=$PATH:$(go env GOPATH)/bin

# Rust
## Cargo
crc() {  # `cargo run` copy: Function to run cargo and copy output to clipboard
  tmp_file=$(mktemp /tmp/cargo_output.XXXXXX)
  current_dir=$(pwd)
  echo "$current_dir cargo run $@" > "$tmp_file"
  cargo run "$@" 2>&1 | tee -a "$tmp_file"
  cat "$tmp_file" | pbcopy
  rm "$tmp_file"
}
alias cawa="cargo watch -q -c -w src/ -x 'run -q'"

# LaTeX
export PATH="$PATH:/Library/TeX/texbin"

# Todo.txt
export TODO_DIR="$HOME/.todo"

# Bat (cat replacement) https://github.com/sharkdp/bat
batdiff() {
    git diff --name-only --relative --diff-filter=d | xargs bat --diff
}

# Other
source $HOME/.config/broot/launcher/bash/br  # Broot things, idk
eval "$(direnv hook zsh)"  # direnv things, idk

# Aliases
## General
# alias rgrep='rg'  # better and faster grep to replace the default (ripgrep)
alias rgf='rg --files | rg'  # Lets you search files with ripgrep, e.g. "rpf test.txt" will search all files under current path which are called test.txt
alias pomodoro='porsmo'  # Opens a pomodoro menu
# alias find='fd'  # better and faster find to replace default (fd)
alias t="todo.sh"
alias speedtest="speedtest-rs"
alias run-life-logging='$HOME/Documents/Programming/PersonalProjects/life-logging/run_background.sh'
## Zshrc
alias sz='source ~/.zshrc'  # quick source .zshrc file
alias nzshrc='nvim ~/.zshrc'
## Git
alias gitundo="git reset HEAD~1"
## Eza
alias ls='eza'
alias la='eza -a'
alias ll='eza -lah'
alias l='eza -lah'
## School
alias cds='cd "$HOME/Documents/School/McGill/7-F2024"'
alias nns='nvim "$HOME/Documents/School/McGill/7-F2024/general.md"'  # nns for general school notes
alias nnm='nvim "$HOME/Documents/School/McGill/7-F2024/MATH524/Notes/general.md"'  # nnm for neovim notes math
alias nnr='nvim "$HOME/Documents/School/McGill/7-F2024/COMP400/Notes/general.md"'  # nnp for neovim notes research
alias nnai='nvim "$HOME/Documents/School/McGill/7-F2024/COMP424/Notes/general.md"'  # nnai for neovim notes AI (now ambiguous)
alias nnc='nvim "$HOME/Documents/School/McGill/7-F2024/COMP558/Notes/general.md"'  # nnc for neovim notes comp
## Programming
alias cdp='cd "$HOME/Documents/Programming"'
alias cdpp='cd "$HOME/Documents/Programming/PersonalProjects"'
alias cdi='cd "$HOME/Documents/Programming/PersonalProjects/InfiniteMinesweeperProject"'
## Work
alias cdw='cd "$HOME/Documents/Work"'
# alias cdg='cd "$HOME/Documents/Work/Zeroth/Marmott\_\&\_Olameter/geothermal"'
alias cdg='cd "$HOME/Documents/Work/Zeroth/Marmott_&_Olameter/geothermal"'
## Files
alias nnotes='nvim "$HOME/Documents/notes.md"'
alias ndiary='nvim "$HOME/Documents/diary.md"'
alias nprojects='nvim "$HOME/Documents/projects.md"'
***REMOVED***
alias ntmp='nvim "$HOME/Documents/tmp/tmp.md"'

# General Functions

context() {
    HELPERS_DIR="$HOME/Documents/Programming/PersonalProjects/Helpers"
    CURRENT_DIR="$(pwd)"
    (cd "$HELPERS_DIR" && uv run python main.py prompt_maker get_prompt_context "$CURRENT_DIR" --file_types="${1:-.go,.templ}" --exclude_paths="${2:-tmp/,static/,internal/hash/,internal/middleware/}")
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

mkcd() { mkdir $1 ; cd $1 } # mkdir and cd in one
# wt <new-branch> [base]  → create a branch, add a linked worktree at <repo>/worktrees/<branch>, cd into it
# Examples:
#   wt feature-login           # base = current HEAD
#   wt hotfix-404 origin/main  # base = origin/main
wt() {
  local branch base root path slug

  if [[ -z "$1" ]]; then
    echo "usage: wt <new-branch> [base]" >&2
    return 2
  fi

  # Normalize branch name a bit (spaces → dashes)
  branch="$1"
  slug="${branch// /-}"
  base="${2:-HEAD}"

  # Must be in a git repo
  if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "error: not inside a git repository" >&2
    return 1
  fi

  path="$root/worktrees/$slug"
  mkdir -p "$root/worktrees"

  # Refuse if a worktree dir already exists
  if [[ -e "$path" ]]; then
    echo "error: worktree path already exists: $path" >&2
    return 1
  fi

  # Create branch if it doesn't exist yet
  if git show-ref --verify --quiet "refs/heads/$slug"; then
    echo "branch '$slug' already exists locally; reusing it"
  else
    if ! git branch "$slug" "$base"; then
      echo "error: failed to create branch '$slug' from '$base'" >&2
      return 1
    fi
  fi

  # Add worktree and jump in
  if git worktree add "$path" "$slug"; then
    cd "$path" || return 1
    pwd
  else
    echo "error: failed to add worktree at $path" >&2
    # Optional cleanup if branch was just created and worktree failed:
    # git branch -D "$slug" >/dev/null 2>&1
    return 1
  fi
}

# Auto (programs that automatically add things to .zshrc will automatically add them below)
export PATH="$HOME/.pixi/bin:$PATH"
export PATH="/Applications/MATLAB_R2024b.app/bin:$PATH"
export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
