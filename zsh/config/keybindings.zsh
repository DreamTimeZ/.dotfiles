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
