# Emacs mode keybindings (use bindkey -l to list all available keymaps)
bindkey -e

# Redo (not bound by default in zsh; undo is already ^Xu / ^X^U)
bindkey '^[r' redo                    # Alt+r

# Word navigation: Ctrl/Alt + Arrow
bindkey '^[[1;5C' forward-word        # Ctrl+Right
bindkey '^[[1;5D' backward-word       # Ctrl+Left
bindkey '^[[1;3C' forward-word        # Alt+Right
bindkey '^[[1;3D' backward-word       # Alt+Left

# Word deletion: forward
bindkey '^[[3;5~' kill-word           # Ctrl+Delete
bindkey '^[[3;3~' kill-word           # Alt+Delete

# Word deletion: backward
bindkey '^H' backward-kill-word       # Ctrl+Backspace
bindkey '^[^?' backward-kill-word     # Alt+Backspace
bindkey '^[[127;5u' backward-kill-word  # Ctrl+Backspace (kitty)
bindkey '^[[127;3u' backward-kill-word  # Alt+Backspace (kitty)

# macOS/iTerm2 specific
bindkey '^[[3;9~' kill-line           # Fn+Cmd+Delete (Cursor IDE)
bindkey '^[[99~' kill-line            # Fn+Cmd+Delete (iTerm2)

# Display keybindings documentation
if [[ -f "${ZDOTDIR:-$HOME}/.dotfiles/zsh/docs/keybindings.md" ]]; then
    kb() {
        local file="${ZDOTDIR:-$HOME}/.dotfiles/zsh/docs/keybindings.md"
        if zdotfiles_has_command glow; then glow "$file"
        elif zdotfiles_has_command bat; then bat --style=plain --language=markdown "$file"
        else less "$file"
        fi
    }
fi
