# Dotfiles

These dotfiles are managed by [chezmoi](https://www.chezmoi.io/) from
`~/dotfiles`. The first setup asks whether the Mac is a `work` or `personal`
machine and stores the selected profile, Git identity, and optional GPG signing
settings in the machine-local chezmoi config.

## Set up a new Mac

Install chezmoi without applying any files yet:

```sh
sh -c "$(curl -fsLS https://get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
```

Clone and initialize the source checkout:

```sh
chezmoi init \
  --source "$HOME/dotfiles" \
  https://github.com/frankhock/dotfiles.git
```

Review and apply the changes:

```sh
chezmoi diff
chezmoi apply --verbose
chezmoi status
```

The first apply installs Homebrew if necessary, then installs the curated
formulae and casks declared in `chezmoi/.chezmoidata/packages.toml`. It does not
remove unrelated packages or upgrade the full machine.

Git push credentials and `~/.env` are deliberately machine-local and are not
managed by chezmoi.

## Daily use

```sh
chezmoi status                 # Show pending changes
chezmoi diff                   # Review pending changes
chezmoi edit ~/.zshrc          # Edit a managed source file
chezmoi edit --apply ~/.zshrc  # Edit and apply one file
chezmoi apply                  # Apply local source changes
chezmoi update                 # Pull and apply remote changes
chezmoi cd                     # Open a shell in ~/dotfiles
```

Commit and push source changes with normal Git commands from `~/dotfiles`.

## Profiles and packages

Shared, work-only, and personal-only Homebrew lists live in
`chezmoi/.chezmoidata/packages.toml`. Machine-local profile and Git identity data
live in `~/.config/chezmoi/chezmoi.toml`.

mise manages the global Node.js LTS and latest Bun releases declared in
`chezmoi/dot_config/mise/config.toml`; project-level mise configuration can
override them. Run the Claude hook specs from the repository root with
`bun test claude/hooks`.

To recreate the local config and answer the prompts again:

```sh
chezmoi init --source "$HOME/dotfiles" --prompt
```
