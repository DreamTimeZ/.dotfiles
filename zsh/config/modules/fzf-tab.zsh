# ===============================
# FZF-TAB CONFIGURATION
# ===============================

# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'

# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no

# Preview directory's content with eza/ls when completing cd
if command -v eza &>/dev/null; then
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
else
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls -1 --color=always $realpath'
fi

# Preview file content using bat/cat when completing vim/nvim
if command -v bat &>/dev/null; then
  zstyle ':fzf-tab:complete:(nvim|vim|vi):*' fzf-preview 'bat --color=always --style=plain --line-range :100 $realpath'
else
  zstyle ':fzf-tab:complete:(nvim|vim|vi):*' fzf-preview 'cat $realpath'
fi

# Switch group using '<' and '>'
zstyle ':fzf-tab:*' switch-group '<' '>'

# Keybindings for multi-selection
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-space:toggle+down'

# Only show the group name when there are multiple groups
zstyle ':fzf-tab:*' single-group color header

# Show file preview for certain commands
zstyle ':fzf-tab:complete:*:*' fzf-preview '([[ -f $realpath ]] && (bat --style=plain --color=always $realpath || cat $realpath)) || ([[ -d $realpath ]] && (eza -1 --color=always $realpath || ls -1 --color=always $realpath)) || echo $realpath 2> /dev/null | head -200'

# Set a reasonable limit for max completions
zstyle ':fzf-tab:*' continuous-trigger '/'

# Use FZF_DEFAULT_OPTS for a consistent experience (be cautious with this option)
# zstyle ':fzf-tab:*' use-fzf-default-opts yes 