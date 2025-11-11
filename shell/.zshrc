export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh

if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

# Shell history search
. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"

# Ruby (rbenv)
eval "$(rbenv init - zsh)"

# Node.js (Volta)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Starship
eval "$(starship init zsh)"