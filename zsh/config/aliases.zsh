# ===============================
# ALIASES
# ===============================

# VCS (Git)
alias ga='git add . && git status'
alias gs='git status'
alias gsw='git switch'                         # Switch to another branch
alias gswc='git switch -c'                     # Create and switch to new branch
alias gb='git branch'                         # List branches
alias gbd='git branch -d'                      # Safe delete (warns if not merged)
alias gbD='git branch -D'                      # Force delete (even if not merged)
alias gbrd='git push origin --delete'          # Delete remote branch
alias gc='git commit'                         # Commit
alias gcm='git commit -m'                      # Commit with message
alias gca='git commit --amend'                 # Amend last commit
alias gundo='git reset --soft HEAD~1'
alias gpl='git pull'
alias gps='git push'
alias gpsf='git push --force-with-lease'       # Safe force push
alias glg='git log --oneline --graph --decorate --all'
alias gl='git log --oneline --decorate'
alias ghist='git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'
alias gdf='git diff'
alias gdc='git diff --cached'                  # Show staged changes
alias grs='git restore .'                      # Restore working directory changes
alias grss='git restore --staged .'            # Unstage staged files
alias grb='git rebase'
alias grbi='git rebase -i'
alias gcl='git clone'
alias gfa='git fetch --all --prune'
alias glast='git log -1 HEAD'
alias gtags='git tag -l'
alias gtagd='git tag -d'

# tldr (tealdealer)
alias tldr="noglob tldr"

# Editor tools
alias vi='nvim'

## Cursor with Profiles
alias cu="cursor --profile 'Default'"
alias cpy="cursor --profile 'Python'"
alias ctr="cursor --profile 'TypeScript React'"
alias cs="cursor --profile 'Spring Boot'"
alias cxx="cursor --profile 'Cpp'"

# Tmux
alias t="tmux attach-session -t default 2>/dev/null || tmux new-session -s default"

# Search and Replace
alias grep='rg'
alias find='fd'

# Navigation using zoxide
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias cd='z'
alias cdf='cd "$(zoxide query --interactive)" || return'
alias cdi='zoxide query --interactive' # Consider switching to 'z --interactive'

# File listing using eza (if installed)
alias ls='eza --color=auto --group-directories-first'
alias ll='eza -l --group-directories-first --color=always --icons'
alias lla='eza -la --group-directories-first --color=always --icons'
alias la='eza -a --group-directories-first --color=always --icons'
alias lh='eza -l --group-directories-first --color=always --icons .* 2>/dev/null'
alias tree='eza --tree --level=2 --icons'

# Core utilities with safe defaults
alias mkdir='mkdir -pv'
alias rm='rm -Iv'
alias rd='rmdir'
alias cp='cp -iv'
alias mv='mv -iv'
alias df='df -h'
alias du='du -h'

# Networking tools
alias ports='netstat -tuln'
alias sniff='sudo tcpdump -i any port'
alias nscan='sudo nmap -sS -Pn'
alias flushdns='sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder'‚
alias ip='grc ip a'
alias ip4='curl -s https://ipv4.icanhazip.com'
alias ipv6='curl -s https://ipv6.icanhazip.com'

# Miscellaneous
alias cls='clear'
alias reload='source ~/.zshrc' # Reload this configuration
alias '?'='echo $?' # Print the exit code of the last command

# Kubernetes shortcuts (if kubectl is installed)
if command -v kubectl &>/dev/null; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get svc'
    alias kgn='kubectl get nodes'
fi
