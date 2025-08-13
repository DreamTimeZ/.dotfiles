# ===============================
# FILE & DIRECTORY NAVIGATION FUNCTIONS
# ===============================

# Create a directory and navigate to it (use z for zoxide tracking)
mkcd() {
    mkdir -p "$1" || return 1
    if zdotfiles_has_command zoxide; then
        z "$1"
    else
        builtin cd "$1"
    fi
}

# Show disk usage for top 10 largest directories/files
dusage() {
    du -ah . | sort -rh | head -n 10
}

# Only define fuzzy finder functions if fzf is available
if zdotfiles_has_command fzf; then
    # Fuzzy file finder with preview (using bat if available)
    ffind() {
        local preview_cmd='cat {}'
        if zdotfiles_has_command bat; then
            preview_cmd='bat --style=numbers --color=always {} 2>/dev/null || cat {}'
        fi
        
        find . -type f 2>/dev/null | fzf --preview "$preview_cmd"
    }

    # Fuzzy directory finder
    fdir() {
        local dir
        dir=$(find . -type d 2>/dev/null | fzf +m) && builtin cd "$dir"
    }
fi 