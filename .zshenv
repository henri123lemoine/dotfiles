export ZDOTDIR="${ZDOTDIR:-$HOME/.config/zsh}"

export VISUAL="nvim"
export EDITOR="nvim"

# Cargo (Rust) - conditional, for manual installs (Homebrew Rust doesn't need this)
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# User-local binaries
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.pixi/bin:$PATH"

# App-specific paths (only if installed)
[[ -d "/Applications/MATLAB_R2024b.app/bin" ]] && export PATH="/Applications/MATLAB_R2024b.app/bin:$PATH"
[[ -d "/Applications/Docker.app/Contents/Resources/bin" ]] && export PATH="/Applications/Docker.app/Contents/Resources/bin:$PATH"
[[ -d "/Applications/WezTerm.app/Contents/MacOS" ]] && export PATH="/Applications/WezTerm.app/Contents/MacOS:$PATH"
[[ -d "/Library/TeX/texbin" ]] && export PATH="$PATH:/Library/TeX/texbin"

# Java (only if installed)
if [[ -d "/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home" ]]; then
    export JAVA_HOME="/Library/Java/JavaVirtualMachines/jdk-21.jdk/Contents/Home"
fi

# Apache Ant (only if installed)
if [[ -d "$HOME/devtools/apache-ant-1.10.14" ]]; then
    export ANT_HOME="$HOME/devtools/apache-ant-1.10.14"
    export PATH="$PATH:$ANT_HOME/bin"
fi
