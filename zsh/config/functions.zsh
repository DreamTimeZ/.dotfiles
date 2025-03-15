# ===============================
# FUNCTIONS
# ===============================

# Serve files with Node.js (using nodemon) or Python
serve() {
    local port="${1:-8000}"
    if command -v nodemon &>/dev/null; then
        echo "Serving with Node.js (nodemon) on http://localhost:$port"
        nodemon --watch . -e js,html,css --exec "npx serve -l $port"
    elif command -v python3 &>/dev/null; then
        echo "Serving with Python on http://localhost:$port"
        python3 -m http.server "$port"
    else
        echo "Neither Node.js nor Python is available for serving."
    fi
}

# Create a directory and navigate to it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Show disk usage for top 10 largest directories/files
dusage() {
    du -ah . | sort -rh | head -n 10
}

# ===============================
# FZF FUNCTIONS & ALIASES
# ===============================

# Fuzzy file finder with preview (using bat if available)
ffind() {
    find . -type f | fzf --preview 'bat --style=numbers --color=always {} 2>/dev/null || cat {}'
}

# Fuzzy directory finder
fd() {
    local dir
    dir=$(find . -type d 2>/dev/null | fzf +m) && cd "$dir"
}

# Fuzzy process finder and killer
fp() {
    local pid
    pid=$(ps aux | fzf --preview 'echo {}' | awk '{print $2}')
    if [ -n "$pid" ]; then
        kill -9 "$pid"
        echo "Killed process $pid"
    fi
}

# Fuzzy Git branch switcher
fbr() {
    git branch --all | fzf --preview "git log --oneline --decorate --graph --color=always {}" | sed 's/^[* ]*//;s#remotes/[^/]*/##' | xargs git checkout
}

# Fuzzy Git file opener
fgf() {
    git ls-files | fzf --preview "bat --style=numbers --color=always {}" | xargs -r ${EDITOR:-vim}
}

# Fuzzy search through shell history
fh() {
    fc -l 1 | fzf | sed 's/^[ \t]*//' | while read -r cmd; do
        print -z "$cmd"
    done
}
