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
    alias ga='git add'
    alias gaa='git add -A && git status'
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
    alias gl='git log'
    alias glo='git log --oneline --decorate'
    alias glg='git log --oneline --graph --decorate --all'
    alias ghist='git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'
    alias glast='git log -1 HEAD'
    alias gsh='git show'
    
    # Diffs and changes
    alias gdf='git diff'
    alias gdc='git diff --cached'
    alias gds='git diff --staged'  # Alias for gdc (modern naming)
    alias gr='git restore'
    alias grs='git restore .'
    alias grss='git restore --staged .'

    # Advanced operations
    alias gm='git merge'
    alias gcp='git cherry-pick'
    alias grb='git rebase'
    alias grbi='git rebase -i'
    alias grbc='git rebase --continue'
    alias grba='git rebase --abort'
    alias gfa='git fetch --all --prune'
    
    # Tags
    alias gtags='git tag -l'
    alias gtagd='git tag -d'
fi

# LazyGit
if zdotfiles_has_command lazygit; then
    alias lg='lazygit'
fi

# ===============================
# EDITOR AND DEVELOPMENT TOOLS
# ===============================

# Neovim
if zdotfiles_has_command nvim; then
    alias vi='nvim'
    alias vim='nvim'
fi

# Cursor
if zdotfiles_has_command cursor; then
    alias c='cursor'
fi

# Enhanced search with ripgrep
# Note: Keeping rg as standard command (no default flags) for predictable behavior
# Use 'rg -S --follow --hidden' manually when needed

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

    # Dev session shortcuts (see: dev -h)
    alias devc='dev --cmd claude'
    alias dev4='dev 2x2'
    alias dev4c='dev 2x2 --cmd claude'

    # Cheatsheet (glow → bat → less)
    tmux-help() {
        local file="$HOME/.dotfiles/tmux/CHEATSHEET.md"
        if (( ${+commands[glow]} )); then glow "$file"
        elif (( ${+commands[bat]} )); then bat "$file"
        else ${PAGER:-less} "$file"; fi
    }
    alias tsh='tmux-help'
fi

# ===============================
# NAVIGATION AND FILE OPERATIONS
# ===============================

# Directory navigation
alias ..='builtin cd ..'
alias ...='builtin cd ../..'
alias ....='builtin cd ../../..'
alias .....='builtin cd ../../../..'
alias ......='builtin cd ../../../../..'
alias .......='builtin cd ../../../../../..'
alias ........='builtin cd ../../../../../../..'

# Zoxide integration - enabled by default (non-breaking)
if zdotfiles_has_command zoxide; then
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
    alias l='eza -l --icons=auto'
    alias ls='eza --color=auto --group-directories-first'
    alias ll='eza -la --color=always --sort=name --group-directories-first --icons'
    alias la='eza -a --color=always --sort=name --group-directories-first --icons'
    alias lh='eza -l --color=always --sort=name --icons .* 2>/dev/null'
    alias ld='eza -lD --icons=auto' # List directories only
    alias tree='eza --tree --level=2 --icons'
    alias ltree='eza --tree --level=3 --icons'
    
    # Escape hatch for original ls
    alias oldls='command ls'
fi

# Core utilities - keeping standard behavior for predictable output
# Use 'mkdir -pv', 'df -h', 'du -h' manually when needed

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

# Platform-aware DNS cache flush
if zdotfiles_is_macos; then
    alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
else
    # Linux/Ubuntu - systemd-resolved
    alias flushdns='sudo resolvectl flush-caches || sudo systemd-resolve --flush-caches'
fi

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
    alias dcupb='docker compose up -d --build'
    alias dcdown='docker compose down'
    alias dcdownrm='docker compose down --remove-orphans'
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
# SECURITY & MONITORING TOOLS
# ===============================
if zdotfiles_has_command gitleaks; then
    alias gls='gitleaks detect --verbose'
    alias glspre='gitleaks protect --staged --verbose'
fi

if zdotfiles_has_command bandwhich; then
    alias bw='sudo bandwhich'
    alias bwp='sudo bandwhich --addresses'
fi

# ===============================
# AI TOOLS
# ===============================
if zdotfiles_has_command fabric-ai; then
    alias fa='fabric-ai'

    # fabric-ai with glow rendering
    fag() {
        if (( ${+commands[glow]} )); then
            fabric-ai "$@" | glow
        else
            fabric-ai "$@"
        fi
    }

    # fabric-ai with clipboard output
    fac() { fabric-ai "$@" | pbcopy; }
fi

# ===============================
# SYSTEM AND UTILITY
# ===============================
# his='history' - removed, conflicts with atuin
alias cls='clear'
alias reload='exec zsh'              # Restart shell (fresh state)
alias src='source ~/.zshrc'          # Reload config (preserve state)
alias '?'='echo $?'
alias path='echo $PATH | tr ":" "\n"'
alias env-grep='env | grep -i'

# Process management
alias psg='ps aux | grep -v grep | grep'

# Disk usage helpers
alias ducks='du -cks * | sort -rn | head'
if zdotfiles_is_macos; then
    alias biggest='find . -type f -print0 2>/dev/null | xargs -0 stat -f "%z %N" 2>/dev/null | sort -nr | head -5 | awk '\''{size=$1; $1=""; if(size>=1073741824) printf "%.1fG\t%s\n", size/1073741824, $0; else if(size>=1048576) printf "%.1fM\t%s\n", size/1048576, $0; else if(size>=1024) printf "%.1fK\t%s\n", size/1024, $0; else printf "%dB\t%s\n", size, $0}'\'''
else
    alias biggest='find . -type f -printf "%s %p\n" 2>/dev/null | sort -nr | head -5 | awk '\''{size=$1; $1=""; if(size>=1073741824) printf "%.1fG\t%s\n", size/1073741824, $0; else if(size>=1048576) printf "%.1fM\t%s\n", size/1048576, $0; else if(size>=1024) printf "%.1fK\t%s\n", size/1024, $0; else printf "%dB\t%s\n", size, $0}'\'''
fi

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
