export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source $ZSH/oh-my-zsh.sh

if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

# Autosuggestions (install: brew install zsh-autosuggestions)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Shell history search
eval "$(mcfly init zsh)"

# Ruby (rbenv)
eval "$(rbenv init - zsh)"

# Node.js (Volta)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"