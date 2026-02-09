#!/bin/bash

# === Package Installation ===

# Install Homebrew if not present
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Install oh-my-zsh if not present
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# Homebrew packages from .zshrc
BREW_PACKAGES=(
    atuin
    fzf
    rbenv
    volta
    starship
    zoxide
    eza
)

for package in "${BREW_PACKAGES[@]}"; do
    if ! brew list "$package" &> /dev/null; then
        echo "Installing $package..."
        brew install "$package"
    else
        echo "$package already installed"
    fi
done

# === Symlinks ===

ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/shell/.zshenv ~/.zshenv
ln -sf ~/dotfiles/shell/.zshrc ~/.zshrc
ln -sf ~/dotfiles/shell/.aliases.sh ~/.aliases.sh
ln -sf ~/dotfiles/shell/.functions.sh ~/.functions.sh

ln -sf ~/dotfiles/shell/starship.toml ~/.config/starship.toml

ln -sf ~/dotfiles/zed/keymap.json ~/.config/zed/keymap.json
ln -sf ~/dotfiles/zed/settings.json ~/.config/zed/settings.json
ln -sf ~/dotfiles/zed/tasks.json ~/.config/zed/tasks.json

# Claude stuff
ln -sf ~/dotfiles/claude/agents ~/.claude/agents
ln -sf ~/dotfiles/claude/commands ~/.claude/commands
ln -sf ~/dotfiles/claude/hooks ~/.claude/hooks
ln -sf ~/dotfiles/claude/skills ~/.claude/skills

# Ghostty stuff
ln -sf ~/dotfiles/ghostty/config ~/.config/ghostty/config
