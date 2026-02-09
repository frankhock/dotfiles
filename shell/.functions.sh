# Shell functions

# Ralph Wiggum Loop - parallel Claude task runner
ralph() {
  local project_dir="$CLAUDE_PROJECTS_DIR"
  local tasks_file="ralph-tasks.json"
  local prompt_file="ralph-prompt.md"
  local args=("$@")

  # If first arg exists and doesn't start with -, try project resolution
  if [[ $# -gt 0 && "$1" != -* ]]; then
    local pattern="$1"
    # Use nullglob so missing matches don't error (zsh)
    setopt localoptions nullglob 2>/dev/null
    local matches=("$project_dir"/*"$pattern"*)

    if [[ ${#matches[@]} -eq 1 ]]; then
      # Single match - use it (zsh arrays are 1-indexed)
      local project_path="${matches[1]}"
      if [[ -f "$project_path/$tasks_file" ]]; then
        echo "Using project: $(basename "$project_path")"
        shift
        # Build args: tasks file, prompt file (if exists), then remaining args
        args=("-p" "$project_path/$tasks_file")
        if [[ -f "$project_path/$prompt_file" ]]; then
          args+=("-m" "$project_path/$prompt_file")
        fi
        args+=("$@")
      else
        echo "No $tasks_file found in $project_path"
        return 1
      fi
    elif [[ ${#matches[@]} -gt 1 ]]; then
      # Multiple matches - show them
      echo "Multiple projects match '$pattern':"
      for m in "${matches[@]}"; do
        echo "  $(basename "$m")"
      done
      echo "Be more specific."
      return 1
    fi
    # No matches - fall through to Ruby script (might be other usage)
  fi

  ruby ~/dotfiles/claude/scripts/ralph-loop.rb "${args[@]}"
}

# List projects for quick selection and clipboard copy
lsp() {
  local project_dir="$CLAUDE_PROJECTS_DIR"
  local selection

  selection=$(ls -1 "$project_dir" | grep -v '^\.' | sort -r | fzf --height=40% --reverse)
  [[ -n "$selection" ]] && echo "$selection" | pbcopy && echo "Copied: $selection"
}
