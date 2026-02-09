export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

export EDITOR="zed --wait"

source $ZSH/oh-my-zsh.sh

if [ -f ~/.aliases.sh ]; then
    source ~/.aliases.sh
fi

if [ -f ~/.functions.sh ]; then
    source ~/.functions.sh
fi

source /opt/homebrew/share/zsh/site-functions

# Shell history search
eval "$(atuin init zsh)"

# fzf
source <(fzf --zsh)

# Ruby (rbenv)
eval "$(rbenv init - zsh)"

# Node.js (Volta)
export PATH="$VOLTA_HOME/bin:$PATH"

# Starship
eval "$(starship init zsh)"

# Zoxide
eval "$(zoxide init --cmd cd zsh)"

# Load user-installed binaries
export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/Users/frankhock/.bun/_bun" ] && source "/Users/frankhock/.bun/_bun"
