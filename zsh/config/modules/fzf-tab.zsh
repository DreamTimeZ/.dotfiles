# ===============================
# FZF-TAB CONFIGURATION
# ===============================

# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Set descriptions format to enable group support
# NOTE: do not use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'

# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Force zsh not to show the completion menu, allowing fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no

# --- Determine Preview Commands Once ---

# File preview command: use bat if available, otherwise cat
if command -v bat &>/dev/null; then
  FILE_PREVIEW="bat --color=always --style=plain --line-range :100"
else
  FILE_PREVIEW="cat"
fi

# Directory preview command: use eza if available, otherwise ls
if command -v eza &>/dev/null; then
  DIR_PREVIEW="eza -1 --color=always"
else
  DIR_PREVIEW="ls -1 --color=always"
fi

# --- fzf-tab Specific Configuration ---

# Preview directory's content when completing 'cd'
zstyle ':fzf-tab:complete:cd:*' fzf-preview '$DIR_PREVIEW $realpath'

# Preview file content when completing vim/nvim/vi
zstyle ':fzf-tab:complete:(nvim|vim|vi):*' fzf-preview '$FILE_PREVIEW $realpath'

# General file preview: check file or directory, and fall back to a basic output
zstyle ':fzf-tab:complete:*:*' fzf-preview '([[ -f $realpath ]] && ($FILE_PREVIEW $realpath)) || ([[ -d $realpath ]] && ($DIR_PREVIEW $realpath)) || echo $realpath 2> /dev/null | head -200'

# Switch group using '<' and '>'
zstyle ':fzf-tab:*' switch-group '<' '>'

# Keybindings for multi-selection (toggle selection with ctrl-space)
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-space:toggle+down'

# Only show the group name when there are multiple groups
zstyle ':fzf-tab:*' single-group color header

# Set a reasonable limit for max completions by triggering continuous search with '/'
zstyle ':fzf-tab:*' continuous-trigger '/'

# (Optional) Uncomment the following line if you prefer to use FZF_DEFAULT_OPTS for consistency
# zstyle ':fzf-tab:*' use-fzf-default-opts yes