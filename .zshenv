export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

export VISUAL="nvim"
export EDITOR="nvim"

[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

if [[ -d "$HOME/.bun" ]]; then
    export BUN_INSTALL="$HOME/.bun"
    export PATH="$BUN_INSTALL/bin:$PATH"
fi

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.pixi/bin:$PATH"

[[ -d "/Applications/MATLAB_R2024b.app/bin" ]] && export PATH="/Applications/MATLAB_R2024b.app/bin:$PATH"
[[ -d "/Applications/Docker.app/Contents/Resources/bin" ]] && export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
[[ -d "/Applications/WezTerm.app/Contents/MacOS" ]] && export PATH="/Applications/WezTerm.app/Contents/MacOS:$PATH"
[[ -d "/Library/TeX/texbin" ]] && export PATH="$PATH:/Library/TeX/texbin"

if [[ -d "/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home" ]]; then
    export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home"
fi

if [[ -d "$HOME/devtools/apache-ant-1.10.14" ]]; then
    export ANT_HOME="$HOME/devtools/apache-ant-1.10.14"
    export PATH="$PATH:$ANT_HOME/bin"
fi
