# bindkey -l to list all keybindings; -e to use emacs keybindings
bindkey -e

# WSL-specific key bindings for Ctrl + Arrow keys and word deletion
if [[ "$(uname -r)" == *microsoft* ]] || [[ "$(uname -r)" == *WSL* ]]; then
    # Word navigation with Ctrl modifier (Windows Terminal / WSL)
    bindkey '^[[1;5C' forward-word      # Ctrl + Right
    bindkey '^[[1;5D' backward-word     # Ctrl + Left

    # Word deletion
    bindkey '^[[3;5~' kill-word         # Ctrl + Delete (forward delete word)

    # Alternative sequences some WSL terminals might use
    bindkey '^[OC' forward-word         # Ctrl + Right (alternative)
    bindkey '^[OD' backward-word        # Ctrl + Left (alternative)
fi

# Custom widget: Delete line to left of cursor (Cmd + Delete)
backward-kill-to-beginning-of-line() {
  zle set-mark-command       # Mark at current cursor position
  zle beginning-of-line      # Move to start of line
  zle kill-region            # Kill everything from start to original position
}
zle -N backward-kill-to-beginning-of-line
bindkey '\e[79~' backward-kill-to-beginning-of-line

# iTerm2/Cursor fallback bindings
bindkey '^[[3~' delete-char             # Fn+Delete fallback
bindkey '^[[3;9~' kill-line             # Fn+Cmd+Delete (iterm in Cursor)
bindkey '^[[99~' kill-line              # iTerm2: Fn + Cmd + Delete

# Atuin replaces history substring search

# Only define keybindings function if documentation file exists
if [[ -f "${ZDOTDIR:-$HOME}/.dotfiles/zsh/docs/keybindings.md" ]]; then
    # Function to display keybindings using best available viewer
    kb() {
        local keybindings_file="${ZDOTDIR:-$HOME}/.dotfiles/zsh/docs/keybindings.md"
        
        # Use best available markdown viewer
        if zdotfiles_has_command glow; then
            glow "$keybindings_file"
        elif zdotfiles_has_command bat; then
            bat --style=plain --language=markdown "$keybindings_file"
        elif zdotfiles_has_command less && less -V 2>/dev/null | grep -q "color"; then
            less -R "$keybindings_file"
        else
            cat "$keybindings_file"
        fi
    }
fi