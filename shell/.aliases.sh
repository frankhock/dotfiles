# Navigation commands
alias bits='cd ~/bits'
alias l='eza -lah --group-directories-first'
alias ll='eza -lh --group-directories-first'

# Dangerous operations - use with caution!
alias fuckit='git reset --hard HEAD && git clean -fd'

# Bundle commands
alias bi='bundle install'

# Git commands
alias gs='git status'

# Shortcut commands
alias cc='claude --model opus --dangerously-skip-permissions'
alias ccd='claude --model opus --dangerously-skip-permissions'
alias cch='claude --model haiku'

# Consider moving these to project-specific shell configs or .envrc files
alias bsetup='bi && yarn && bin/db-migrate'
alias db_reset='bin/rails db:drop db:create db:migrate:with_data db:seed db:staging:seed log:clear tmp:clear && bundle exec rake elasticsearch:development_reindex'
alias ui='cd ~/bits/user-interviews/rails-server'
