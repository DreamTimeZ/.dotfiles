# ===============================
# GIT FUNCTIONS
# ===============================

# Fuzzy Git branch switcher
fbr() {
    git branch --all | fzf --preview "git log --oneline --decorate --graph --color=always {}" | sed 's/^[* ]*//;s#remotes/[^/]*/##' | xargs git checkout
}

# Fuzzy Git file opener
fgf() {
    git ls-files | fzf --preview "bat --style=numbers --color=always {}" | xargs -r ${EDITOR:-vim}
} 