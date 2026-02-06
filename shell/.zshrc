export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

export EDITOR="zed --wait"

source $ZSH/oh-my-zsh.sh

if [ -f ~/.aliases ]; then
    source ~/.aliases
fi

if [ -f ~/.functions ]; then
    source ~/.functions
fi

source /opt/homebrew/share/zsh/site-functions

# Shell history search
eval "$(atuin init zsh)"

# fzf
source <(fzf --zsh)

# Ruby (rbenv)
eval "$(rbenv init - zsh)"

# Node.js (Volta)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Starship
eval "$(starship init zsh)"

# Zoxide
eval "$(zoxide init --cmd cd zsh)"

# Claude project artifacts directory
export CLAUDE_PROJECTS_DIR="${CLAUDE_PROJECTS_DIR:-$HOME/brain/dev/projects}"

# Load user-installed binaries
export PATH="$HOME/.local/bin:$PATH"
