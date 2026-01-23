# ===============================
# ALIASES - Clean & Focused
# ===============================

# Security: Proper sudo history exclusion using leading space
alias sudo=' sudo'  # Leading space triggers HIST_IGNORE_SPACE

# ===============================
# VERSION CONTROL (Git)
# ===============================
# Aliases follow oh-my-zsh naming conventions
if zdotfiles_has_command git; then
    # Status and staging
    alias gs='git status'
    alias ga='git add'
    alias gapa='git add --patch'
    alias gaa='git add -A && git status'
    alias gsta='git stash push'
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
    alias gcmsg='git commit -m'
    alias gca='git commit --amend'
    alias gundo='git reset --soft HEAD~1'
    
    # Push/Pull with safety
    alias gpl='git pull'
    alias gps='git push'
    alias gpsf='git push --force-with-lease'
    
    # Logs and history
    alias glog='git log'
    alias glo='git log --oneline --decorate'
    alias glg='git log --oneline --graph --decorate --all'
    alias ghist='git log --pretty=format:"%h %ad | %s%d [%an]" --graph --date=short'
    alias glast='git log -1 HEAD'
    alias gsh='git show'
    
    # Diffs and changes
    alias gd='git diff'
    alias gds='git diff --staged'
    alias gdh='git diff HEAD'
    alias gr='git restore'
    alias grs='git restore --staged'

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

# WSL: Git for Windows (faster on /mnt/c paths due to native NTFS access)
if zdotfiles_is_wsl && [[ -x "/mnt/c/Program Files/Git/bin/git.exe" ]]; then
    alias gitw='/mnt/c/Program\ Files/Git/bin/git.exe'
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
    alias t='tmux'
    alias ta='tmux attach'
    alias tls='tmux list-sessions'
    alias tkill='tmux kill-session -t'

    # Dev session shortcuts (requires 'dev' script)
    if zdotfiles_has_command dev; then
        alias devc='dev --cmd claude'
        alias dev4='dev 2x2'
        alias dev4c='dev 2x2 --cmd claude'
    fi

    # Cheatsheet (glow → bat → less)
    tmux-help() {
        local file="${ZDOTFILES_DIR:-$HOME/.dotfiles}/tmux/CHEATSHEET.md"
        [[ -f "$file" ]] || { print -u2 "Cheatsheet not found: $file"; return 1; }
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

# Enhanced file listing - pipe-safe, industry standard
# Uses --color=auto for pipe compatibility (vs --color=always)
if zdotfiles_has_command eza; then
    alias ls='eza --color=auto --group-directories-first'
    alias l='eza -l --color=auto --group-directories-first'
    alias ll='eza -l --color=auto --group-directories-first --icons=auto'
    alias la='eza -lA --color=auto --group-directories-first --icons=auto'
    alias ld='eza -lD --color=auto --icons=auto'
    alias tree='eza --tree --level=2 --color=auto --icons=auto'
    alias ltree='eza --tree --level=3 --color=auto --icons=auto'
    # lh: list hidden files only (function required to handle empty case)
    # - .[^.]*(N) matches hidden files excluding . and ..
    # - (N) = null glob: no error if no matches
    # - Function prevents eza from listing all files when no hidden files exist
    lh() { local f=(.[^.]*(N)); (( ${#f} )) && eza -ld --color=auto --icons=auto "${f[@]}"; }
else
    # Fallback: standard ls with color support
    alias l='ls -lh'
    if zdotfiles_is_macos; then
        alias ls='ls -G'
        alias ll='ls -lhG'
        alias la='ls -lAhG'
        lh() { local f=(.[^.]*(N)); (( ${#f} )) && command ls -lhG "${f[@]}"; }
    else
        alias ls='ls --color=auto'
        alias ll='ls -lh --color=auto'
        alias la='ls -lAh --color=auto'
        lh() { local f=(.[^.]*(N)); (( ${#f} )) && command ls -lh --color=auto "${f[@]}"; }
    fi
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
# Show listening ports - runtime detection with fallbacks
# Note: macOS lsof and /proc fallback show TCP only; Linux ss/netstat show TCP and UDP
ports() {
    if zdotfiles_is_macos; then
        lsof -i -P -n | grep LISTEN
    elif (( $+commands[ss] )); then
        # LISTEN=TCP listening, UNCONN=UDP listening (connectionless)
        ss -tuln | grep -E 'LISTEN|UNCONN'
    elif (( $+commands[netstat] )); then
        netstat -tuln | grep -E 'LISTEN|UNCONN'
    elif (( $+commands[lsof] )); then
        lsof -i -P -n | grep LISTEN
    elif [[ -r /proc/net/tcp ]]; then
        # Fallback: parse /proc directly (TCP only)
        print "Proto\tLocal Address"
        awk 'NR>1 && $4=="0A" {
            split($2,a,":"); printf "tcp\t0.0.0.0:%d\n", strtonum("0x"a[2])
        }' /proc/net/tcp | sort -t: -k2 -nu
    else
        print -u2 "ports: no supported tool found"
        return 1
    fi
}

# Flush DNS cache - runtime detection
flushdns() {
    if zdotfiles_is_macos; then
        sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder
    elif (( $+commands[resolvectl] )); then
        sudo resolvectl flush-caches
    elif (( $+commands[systemd-resolve] )); then
        sudo systemd-resolve --flush-caches
    elif systemctl is-active --quiet nscd 2>/dev/null; then
        sudo nscd -i hosts
    elif systemctl is-active --quiet dnsmasq 2>/dev/null; then
        sudo systemctl restart dnsmasq
    else
        print -u2 "flushdns: no supported DNS cache found"
        return 1
    fi
}

# IP address queries (with timeout to prevent hanging)
alias ipv4='curl -s --connect-timeout 5 --max-time 10 https://ipv4.icanhazip.com'
alias ipv6='curl -s --connect-timeout 5 --max-time 10 https://ipv6.icanhazip.com'

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
    alias pblack='poetry run black'
    alias pisort='poetry run isort'
    alias pmypy='poetry run mypy'
    alias pflake='poetry run flake8'

    # Environment management
    alias penv='poetry env info'
    alias penv-list='poetry env list'
    alias penv-use='poetry env use'

    # Package information
    alias pshow='poetry show'
    alias ptree='poetry show --tree'
    alias poutdated='poetry show --outdated'
    alias pcheck='poetry check'

    # Build and publish
    alias pbuild='poetry build'
    alias ppublish='poetry publish'
fi

# ===============================
# PYTHON PACKAGE MANAGEMENT (uv)
# ===============================
if zdotfiles_has_command uv; then
    # Core commands
    alias uvr='uv run'
    alias uvs='uv sync'

    # Dependency management
    alias uva='uv add'
    alias uvd='uv add --group dev'
    alias uvt='uv add --group test'
    alias uvrm='uv remove'

    # Testing
    alias pyt='uv run pytest'
fi

# ===============================
# SECURITY & MONITORING TOOLS
# ===============================
if zdotfiles_has_command gitleaks; then
    alias gleak='gitleaks detect --verbose'
    alias gleaks='gitleaks protect --staged --verbose'
fi

if zdotfiles_has_command bandwhich; then
    alias bwi='sudo bandwhich'
    alias bwia='sudo bandwhich --addresses'
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
    fac() {
        zdotfiles_has_clipboard || { print -u2 "fac: clipboard not available"; return 1; }
        local output
        output=$(fabric-ai "$@") || return 1
        print -rn -- "$output" | pbcopy
    }
fi

if zdotfiles_has_command claude; then
    claudeh() { claude --model haiku "$@"; }
    claudes() { claude --model sonnet "$@"; }
    claudeo() { claude --model opus "$@"; }
    claudew() { claude --allowedTools "WebFetch,WebSearch" "$@"; }
    claudef() { claude --allowedTools "Glob,Grep,Read" "$@"; }
    claudet() { claude --allowedTools "Edit,Write,Bash,WebFetch,WebSearch" "$@"; }
fi

# ===============================
# SYSTEM AND UTILITY
# ===============================
# his='history' - removed, conflicts with atuin
alias cls='clear'
alias reload='exec zsh'              # Restart shell (fresh state)
alias src='source "${ZDOTFILES_DIR:-$HOME/.dotfiles}/zsh/.zshrc"'  # Reload config
alias '?'='print $?'
alias path='print -l ${(s/:/)PATH}'
alias env-grep='env | grep -i'

# Process management
alias psg='ps aux | grep -v grep | grep'

# Disk usage helpers
# ducks: show directory sizes sorted by size (usage: ducks [count])
# - ./*(N) matches regular files/dirs, ./.[!.]*(N) matches hidden (excluding . and ..)
# - (N) = null glob qualifier: no error if pattern matches nothing
ducks() {
    du -cks ./*(N) ./.[!.]*(N) 2>/dev/null | sort -rn | head -n "${1:-15}"
}

# biggest: find largest files in current directory (usage: biggest [count])
biggest() {
    local count="${1:-5}"
    local awk_fmt='{
        size=$1; $1=""
        if (size >= 1073741824) printf "%.1fG\t%s\n", size/1073741824, $0
        else if (size >= 1048576) printf "%.1fM\t%s\n", size/1048576, $0
        else if (size >= 1024) printf "%.1fK\t%s\n", size/1024, $0
        else printf "%dB\t%s\n", size, $0
    }'
    if zdotfiles_is_macos; then
        find . -type f -print0 2>/dev/null |
            xargs -0 stat -f "%z %N" 2>/dev/null |
            sort -nr | head -n "$count" | awk "$awk_fmt"
    else
        find . -type f -printf "%s %p\n" 2>/dev/null |
            sort -nr | head -n "$count" | awk "$awk_fmt"
    fi
}

# ===============================
# OVERRIDE FUNCTIONS
# ===============================
# These functions allow users to opt-in to command overrides
# Usage: Call these functions in your local configuration

use_interactive_file_ops() {
    alias cp='cp -iv'
    alias mv='mv -iv'
    alias rm='rm -Iv'
    print "File operations are now interactive by default for the session."
    print "Use 'command cp/mv/rm' for original behavior in scripts."
}
