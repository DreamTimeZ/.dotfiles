# bindkey -l to list all keybindings; -e to use emacs keybindings
bindkey -e

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

# History substring search
bindkey '^K' history-substring-search-up
bindkey '^J' history-substring-search-down

# Function to display keybindings using glow
function kb() {
    local keybindings_file="${ZDOTDIR:-$HOME}/.dotfiles/zsh/docs/keybindings.md"
    
    # Check if glow is installed
    if command -v glow &> /dev/null; then
        # Display the keybindings using glow
        glow "$keybindings_file"
    else
        # Fallback to less with color if glow is not available
        echo "Note: Install glow for better formatting: brew install glow"
        echo "Displaying with basic formatting...\n"
        
        # Check if bat is available (better fallback with syntax highlighting)
        if command -v bat &> /dev/null; then
            bat --style=plain --language=markdown "$keybindings_file"
        # Check if less is available with color support
        elif command -v less &> /dev/null && less -V | grep -q "color"; then
            less -R "$keybindings_file"
        # Last resort, use cat
        else
            cat "$keybindings_file"
        fi
    fi
}