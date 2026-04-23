# Emacs mode keybindings (use bindkey -l to list all available keymaps)
bindkey -e

# Redo (not bound by default in zsh; undo is already ^Xu / ^X^U)
bindkey '^[r' redo                    # Alt+r

# Edit command line in $EDITOR (not bound by default in zsh; matches bash C-x C-e)
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line      # Ctrl+X Ctrl+E

# Line navigation: Home/End (all three common escape forms for portability)
bindkey '^[[H'  beginning-of-line     # Home (xterm normal)
bindkey '^[[F'  end-of-line           # End  (xterm normal)
bindkey '^[OH'  beginning-of-line     # Home (xterm application cursor)
bindkey '^[OF'  end-of-line           # End  (xterm application cursor)
bindkey '^[[1~' beginning-of-line     # Home (VT220)
bindkey '^[[4~' end-of-line           # End  (VT220)

# Word navigation: Ctrl/Alt + Arrow
bindkey '^[[1;5C' forward-word        # Ctrl+Right
bindkey '^[[1;5D' backward-word       # Ctrl+Left
bindkey '^[[1;3C' forward-word        # Alt+Right
bindkey '^[[1;3D' backward-word       # Alt+Left

# Delete character forward
bindkey '^[[3~' delete-char           # Delete

# Word deletion: forward
bindkey '^[[3;5~' kill-word           # Ctrl+Delete
bindkey '^[[3;3~' kill-word           # Alt+Delete

# Word deletion: backward
bindkey '^H' backward-kill-word       # Ctrl+Backspace
bindkey '^[^?' backward-kill-word     # Alt+Backspace
bindkey '^[[127;5u' backward-kill-word  # Ctrl+Backspace (kitty)
bindkey '^[[127;3u' backward-kill-word  # Alt+Backspace (kitty)

# Line deletion: backward. Override zsh default (kill-whole-line) to match macOS Cocoa.
bindkey '^U' backward-kill-line       # Ctrl+U / Cmd+Backspace via Ghostty

# macOS: xterm Meta modifier (standard, works across terminals)
bindkey '^[[3;9~' kill-line           # Fn+Cmd+Delete
# iTerm2 proprietary sequence
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
  bindkey '^[[99~' kill-line          # Fn+Cmd+Delete (iTerm2)
fi

# Clear screen + scrollback (Ctrl+X l = extended clear)
_clear_screen_and_scrollback() {
    [[ -n "$TMUX" ]] && tmux clear-history
    printf '\e[H\e[2J\e[3J'  # Cursor home + clear screen + clear scrollback
    zle reset-prompt
}
zle -N _clear_screen_and_scrollback
bindkey '^Xl' _clear_screen_and_scrollback

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
