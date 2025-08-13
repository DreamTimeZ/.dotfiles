# ===============================
# GIT FUNCTIONS
# ===============================

# Only define git fuzzy functions if both git and fzf are available
if zdotfiles_has_command git && zdotfiles_has_command fzf; then
    # Fuzzy Git branch switcher
    fbr() {
        # Check if we're in a git repository
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
            zdotfiles_error "Not in a git repository"
            return 1
        fi
        
        local branch
        branch=$(git branch --all | fzf --preview "git log --oneline --decorate --graph --color=always {}" | sed 's/^[* ]*//;s#remotes/[^/]*/##')
        
        if [[ -n "$branch" ]]; then
            git checkout "$branch"
        fi
    }

    # Fuzzy Git file opener
    fgf() {
        # Check if we're in a git repository
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
            zdotfiles_error "Not in a git repository"
            return 1
        fi
        
        local preview_cmd='cat {}'
        if zdotfiles_has_command bat; then
            preview_cmd='bat --style=numbers --color=always {}'
        fi
        
        local files
        files=$(git ls-files | fzf --multi --preview "$preview_cmd")
        
        if [[ -n "$files" ]]; then
            echo "$files" | xargs -r "${EDITOR:-vim}"
        fi
    }
fi 