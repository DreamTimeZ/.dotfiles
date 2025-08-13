# ===============================
# ALIASES - Clean & Focused
# ===============================

# Security: Proper sudo history exclusion using leading space
alias sudo=' sudo'  # Leading space triggers HIST_IGNORE_SPACE

# ===============================
# VERSION CONTROL (Git)
# ===============================
if zdotfiles_has_command git; then
    # Status and staging
    alias gs='git status'
    alias ga='git add . && git status'
    alias gst='git stash'
    alias gstp='git stash pop'
    alias grmc='git rm --cached'
    
    # Repository management
    alias gi='git init'
    alias gcl='git clone'
    alias grao='git remote add origin'
    
    # Branch management
    alias gb='git branch'
    alias gsw='git switch'
    alias gswc='git switch -c'
    alias gbd='git branch -d'
    alias gbD='git branch -D'
    alias gbrd='git push origin --delete'
    
    # Commits
    alias gc='git commit'
    alias gcm='git commit -m'
    alias gca='git commit --amend'
    alias gundo='git reset --soft HEAD~1'
    
    # Push/Pull with safety
    alias gpl='git pull'
    alias gps='git push'
    alias gpsf='git push --force-with-lease'
    
    # Logs and history
    alias gl='git log --oneline --decorate'
    alias glg='git log --oneline --graph --decorate --all'
    alias ghist='git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'
    alias glast='git log -1 HEAD'
    
    # Diffs and changes
    alias gdf='git diff'
    alias gdc='git diff --cached'
    alias grs='git restore .'
    alias grss='git restore --staged .'
    
    # Advanced operations
    alias grb='git rebase'
    alias grbi='git rebase -i'
    alias gfa='git fetch --all --prune'
    
    # Tags
    alias gtags='git tag -l'
    alias gtagd='git tag -d'
fi

# ===============================
# EDITOR AND DEVELOPMENT TOOLS
# ===============================

# Neovim
if zdotfiles_has_command nvim; then
    alias vi='nvim'
    alias vim='nvim'
fi

# Enhanced search with ripgrep
if zdotfiles_has_command rg; then
    alias rg='rg --smart-case --follow --hidden'
fi

# tldr with proper globbing
if zdotfiles_has_command tldr; then
    alias tldr='noglob tldr'
fi

# ===============================
# TERMINAL MULTIPLEXER
# ===============================
if zdotfiles_has_command tmux; then
    alias tmux-default='tmux attach-session -t default 2>/dev/null || tmux new-session -s default'
    alias t='tmux-default'
    alias tls='tmux list-sessions'
    alias tkill='tmux kill-session -t'
fi

# ===============================
# NAVIGATION AND FILE OPERATIONS
# ===============================

# Directory navigation - safe defaults
alias ..='builtin cd ..'
alias ...='builtin cd ../..'
alias ....='builtin cd ../../..'

# Zoxide integration - enabled by default (non-breaking)
if zdotfiles_has_command zoxide; then
    alias cd='z'
    alias cdi='zi'
    if zdotfiles_has_command fzf; then
        cdf() {
            local dir
            dir=$(zoxide query --interactive) && builtin cd "$dir"
        }
    fi
fi

# Enhanced file listing - enabled by default (mostly non-breaking)
if zdotfiles_has_command eza; then
    alias ls='eza --color=auto --group-directories-first'
    alias ll='eza -l --color=always --group-directories-first --icons'
    alias lla='eza -la --color=always --group-directories-first --icons'
    alias la='eza -a --color=always --group-directories-first --icons'
    alias lh='eza -l --color=always --icons .* 2>/dev/null'
    alias tree='eza --tree --level=2 --icons'
    alias ltree='eza --tree --level=3 --icons'
    
    # Escape hatch for original ls
    alias oldls='command ls'
fi

# Core utilities with safe defaults
alias mkdir='mkdir -pv'
alias df='df -h'
alias du='du -h'

# Safe file operations - explicit interactive variants
alias cpi='cp -iv'      # Interactive copy - asks before overwrite
alias mvi='mv -iv'      # Interactive move - asks before overwrite
alias rmi='rm -Iv'      # Interactive remove - asks before delete

# ===============================
# NETWORKING TOOLS
# ===============================
# Platform-aware ports listing (fallbacks)
if zdotfiles_is_macos; then
    alias ports='lsof -i -P -n | grep LISTEN'
else
    alias ports='ss -tuln || netstat -tuln'
fi
alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'

# IP address queries
alias ipv4='curl -s https://ipv4.icanhazip.com'
alias ipv6='curl -s https://ipv6.icanhazip.com'

# ===============================
# CONTAINERIZATION (Docker)
# ===============================
if zdotfiles_has_command docker; then
    # Essential docker commands
    alias d='docker'
    alias dps='docker ps'
    alias dpsa='docker ps -a'
    alias di='docker images'
    alias dex='docker exec -it'
    alias dlogs='docker logs -f'
    
    # Docker Compose - prefer new syntax
    alias dc='docker compose'
    alias dcup='docker compose up -d'
    alias dcdown='docker compose down'
    alias dclogs='docker compose logs -f'
    
    # Cleanup operations
    alias dprune='docker system prune'
    alias dprune-all='docker system prune -a'
fi

# ===============================
# HTTP CLIENT (HTTPie)
# ===============================
if zdotfiles_has_command http; then
    # HTTP methods
    alias hget='http GET'
    alias hpost='http POST'
    alias hput='http PUT'
    alias hdelete='http DELETE'
    alias hpatch='http PATCH'
    
    # Content types and options
    alias hjson='http --json'
    alias hform='http --form'
    alias hverbose='http --verbose'
    alias hheaders='http --headers'
    alias hdownload='http --download'
fi

# ===============================
# KUBERNETES
# ===============================
if zdotfiles_has_command kubectl; then
    alias k='kubectl'
    alias kgp='kubectl get pods'
    alias kgs='kubectl get services'
    alias kgn='kubectl get nodes'
    alias kgd='kubectl get deployments'
    alias kdesc='kubectl describe'
    alias klogs='kubectl logs -f'
    alias kexec='kubectl exec -it'
fi

# ===============================
# PYTHON PACKAGE MANAGEMENT (Poetry)
# ===============================
if zdotfiles_has_command poetry; then
    # Core dependency management
    alias pi='poetry install'
    alias pu='poetry update'
    alias pl='poetry lock'
    alias pa='poetry add'
    alias padev='poetry add --group dev'
    alias prm='poetry remove'
    
    # Execution
    alias pr='poetry run'
    alias prp='poetry run python'
    alias pshell='poetry shell'
    
    # Testing and code quality
    alias ptest='poetry run pytest'
    alias ptest-cov='poetry run pytest --cov'
    alias pblack='poetry run black .'
    alias pisort='poetry run isort .'
    alias pmypy='poetry run mypy .'
    alias pflake='poetry run flake8'
    
    # Environment management
    alias penv='poetry env info'
    alias penv-list='poetry env list'
    alias penv-use='poetry env use'
    
    # Package information
    alias pshow='poetry show'
    alias ptree='poetry show --tree'
    alias poutdated='poetry show --outdated'
    alias poecheck='poetry check'
    
    # Build and publish
    alias pbuild='poetry build'
    alias ppublish='poetry publish'
fi

# ===============================
# SYSTEM AND UTILITY
# ===============================
alias cls='clear'
alias reload='exec zsh'
alias '?'='echo $?'
alias path='echo $PATH | tr ":" "\n"'
alias env-grep='env | grep -i'

# Process management
alias psg='ps aux | grep -v grep | grep'
alias ports-listening='lsof -i -P -n | grep LISTEN'

# Disk usage helpers
alias ducks='du -cks * | sort -rn | head'
alias biggest='find . -type f -print0 2>/dev/null | xargs -0 stat -f "%z %N" 2>/dev/null | sort -nr | head -5 | awk '\''{size=$1; $1=""; if(size>=1073741824) printf "%.1fG\t%s\n", size/1073741824, $0; else if(size>=1048576) printf "%.1fM\t%s\n", size/1048576, $0; else if(size>=1024) printf "%.1fK\t%s\n", size/1024, $0; else printf "%dB\t%s\n", size, $0}'\'''

# ===============================
# OVERRIDE FUNCTIONS
# ===============================
# These functions allow users to opt-in to command overrides
# Usage: Call these functions in your local configuration

use_interactive_file_ops() {
    alias cp='cp -iv'
    alias mv='mv -iv' 
    alias rm='rm -Iv'
    echo "⚠️  File operations are now interactive by default for the session."
    echo "💡 Use 'command cp/mv/rm' for original behavior in scripts."
}
