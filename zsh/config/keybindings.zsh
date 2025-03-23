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