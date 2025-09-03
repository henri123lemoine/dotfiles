# Credit to https://github.com/dreamsofautonomy/zensh/blob/main/.zshrc for some of this
# To Fraser Ross Lee for some

# Enable Powerlevel10k instant prompt
# Should stay at the top of ~/.zshrc
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Options
setopt AUTO_CD CORRECT INTERACTIVECOMMENTS NO_BEEP PROMPT_SUBST IGNORE_EOF
setopt HIST_EXPIRE_DUPS_FIRST HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_VERIFY SHARE_HISTORY
setopt NO_BANG_HIST

# History
HISTFILE=~/.zsh_history
HISTSIZE=5000
SAVEHIST=5000

# Initialize zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

# Plugins
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab

# Prompt
zinit ice depth=1; zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Initialize completions
autoload -Uz compinit
compinit
zinit cdreplay -q

# Remove right side prompt
RPROMPT=""

# Vim key bindings
bindkey -v

# Key bindings
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[3~' delete-char
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^ ' autosuggest-accept

# Autosuggestion settings
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#666666"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Tool initialization
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
[ -s "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"
command -v direnv >/dev/null && eval "$(direnv hook zsh)"
command -v thefuck >/dev/null && eval "$(thefuck --alias)"
command -v fzf >/dev/null && source <(fzf --zsh)
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# Aliases
## Navigation & basics
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias c='clear'
alias sz='source ~/.config/zsh/.zshrc'

## File operations
alias mkdir='mkdir -p'
alias ls='eza'
alias la='eza -a'
alias ll='eza -lah'
alias l='eza -lah'

## Git
alias gl='git log --pretty=format:"%h --- %ae --- %s"'
alias glf='git log --name-status --pretty=format:"%h --- %ae --- %s"'

## Development tools
alias cawa="cargo watch -q -c -w src/ -x 'run -q'"
alias synopsis="$HOME/Documents/Programming/ExternalRepos/synopsis/synopsis.py"
alias run-life-logging='$HOME/Documents/Programming/PersonalProjects/life-logging/run_background.sh'
alias og='bash ~/.config/scripts/open_github.sh'
alias godot="/Applications/Godot.app/Contents/MacOS/Godot"
alias speedtest="speedtest-rs"

## Search & productivity  
alias rgf='rg --files | rg'
alias pomodoro='porsmo'

## Quick file editing
alias nnotes='nvim "$HOME/Documents/notes.md"'
alias ndiary='nvim "$HOME/Documents/diary.md"'
alias nprojects='nvim "$HOME/Documents/projects.md"'
alias ntmp='nvim "$HOME/Documents/tmp/tmp.md"'

## Tools
alias python='python3'
alias claude='~/.claude/local/claude'
alias claud='claude'
alias cc='claude'
alias tm='tmux new-session -A -s main'

# Load custom functions
source "$HOME/.config/zsh/functions.zsh"

# macOS specific
if [[ "$OSTYPE" == "darwin"* ]]; then
    [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Local customizations
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

