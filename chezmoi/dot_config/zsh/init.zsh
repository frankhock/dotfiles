export EDITOR="zed --wait"
export GPG_TTY="${GPG_TTY:-$TTY}"

_dotfiles_zsh_dir="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"
if [[ -r "$_dotfiles_zsh_dir/aliases.zsh" ]]; then
    source "$_dotfiles_zsh_dir/aliases.zsh"
fi
unset _dotfiles_zsh_dir

if [[ -r "$HOME/.env" ]]; then
    source "$HOME/.env"
fi

if command -v brew >/dev/null 2>&1; then
    brew_prefix="$(brew --prefix)"
    fpath=("$brew_prefix/share/zsh/site-functions" $fpath)
    unset brew_prefix
fi

if [[ -r "$HOME/.oh-my-zsh/oh-my-zsh.sh" ]]; then
    export ZSH="$HOME/.oh-my-zsh"
    ZSH_THEME=""
    plugins=(git)
    source "$ZSH/oh-my-zsh.sh"
else
    autoload -Uz compinit
    compinit
fi

if command -v atuin >/dev/null 2>&1; then
    eval "$(atuin init zsh)"
fi

if command -v fzf >/dev/null 2>&1; then
    source <(fzf --zsh)
fi

if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate zsh)"
fi

if command -v rbenv >/dev/null 2>&1; then
    eval "$(rbenv init - zsh)"
fi

if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init --cmd cd zsh)"
fi

export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
esac

if command -v wt >/dev/null 2>&1; then
    eval "$(wt config shell init zsh)"
fi
