#!/bin/bash

ln -sf ~/dotfiles/git/.gitconfig ~/.gitconfig
ln -sf ~/dotfiles/shell/.zshrc ~/.zshrc
ln -sf ~/dotfiles/shell/.aliases ~/.aliases

ln -sf ~/dotfiles/shell/starship.toml ~/.config/starship.toml

ln -sf ~/dotfiles/zed/keymap.json ~/.config/zed/keymap.json
ln -sf ~/dotfiles/zed/settings.json ~/.config/zed/settings.json
ln -sf ~/dotfiles/zed/tasks.json ~/.config/zed/tasks.json

# Claude stuff
ln -sf ~/dotfiles/claude/skills ~/.claude/skills
ln -sf ~/dotfiles/claude/agents ~/.claude/agents
ln -sf ~/dotfiles/claude/commands ~/.claude/commands
