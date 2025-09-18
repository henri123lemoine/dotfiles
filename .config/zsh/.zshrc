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

# Plugins - simple and clean
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting

# Prompt
zinit ice depth=1; zinit light romkatv/powerlevel10k
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Configure autosuggestions
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

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

# Accept autosuggestion with right arrow
bindkey '^[[C' forward-char

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
alias .....='cd ../../../..'
alias ......='cd ../../../../..'
alias c='clear'
alias sz='source ~/.config/zsh/.zshrc'

## File operations
alias l='eza -lah'

## Git
alias gl='git log --pretty=format:"%h --- %ae --- %s"'
alias glf='git log --name-status --pretty=format:"%h --- %ae --- %s"'

## Development tools
alias synopsis="$HOME/Documents/Programming/ExternalRepos/synopsis/synopsis.py"
alias og='bash ~/.config/scripts/open_github.sh'
alias godot="/Applications/Godot.app/Contents/MacOS/Godot"

## Search & productivity  
alias rgf='rg --files | rg'
alias pomodoro='porsmo'

## Tools
alias python='python3'
alias tm='tmux new-session -A -s main'

# Load custom functions
source "$HOME/.config/zsh/functions.zsh"
source "$HOME/.config/scripts/private/lb_functions.zsh"

# macOS specific
if [[ "$OSTYPE" == "darwin"* ]]; then
    [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi
export PATH="$HOME/.claude/local:$PATH"

# Local customizations
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

