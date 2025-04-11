# ===============================
# FZF-TAB CONFIGURATION
# ===============================
# Enhanced tab completion with fzf integration

# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Force zsh not to show the completion menu, allowing fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no

# Lazy-load preview commands only when needed
function _fzf_tab_get_preview_cmds() {
  # Only set these variables if they're not already set
  if [[ -z "$_FILE_PREVIEW_CMD" ]]; then
    if command -v bat &>/dev/null; then
      _FILE_PREVIEW_CMD="bat --color=always --style=plain --line-range :100"
    else
      _FILE_PREVIEW_CMD="cat"
    fi
  fi

  if [[ -z "$_DIR_PREVIEW_CMD" ]]; then
    if command -v eza &>/dev/null; then
      _DIR_PREVIEW_CMD="eza -1 --color=always"
    else
      _DIR_PREVIEW_CMD="ls -1 --color=always"
    fi
  fi
}

# Preview directory's content when completing 'cd'
zstyle ':fzf-tab:complete:cd:*' fzf-preview '_fzf_tab_get_preview_cmds && $_DIR_PREVIEW_CMD $realpath'

# Preview file content when completing vim/nvim/vi
zstyle ':fzf-tab:complete:(nvim|vim|vi|nano|emacs):*' fzf-preview '_fzf_tab_get_preview_cmds && $_FILE_PREVIEW_CMD $realpath'

# General file preview
zstyle ':fzf-tab:complete:*:*' fzf-preview '_fzf_tab_get_preview_cmds && ([[ -f $realpath ]] && ($_FILE_PREVIEW_CMD $realpath)) || ([[ -d $realpath ]] && ($_DIR_PREVIEW_CMD $realpath)) || echo $realpath 2> /dev/null | head -200'

# Switch group using '<' and '>'
zstyle ':fzf-tab:*' switch-group '<' '>'

# Keybindings for multi-selection
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-space:toggle+down'

# Only show the group name when there are multiple groups
zstyle ':fzf-tab:*' single-group color header

# Set a reasonable limit for max completions and continuous trigger
zstyle ':fzf-tab:*' continuous-trigger '/'

# Limit the number of candidates for better performance
# zstyle ':fzf-tab:*' max-candidates 200

# Reduce FZF overhead
# zstyle ':fzf-tab:*' fzf-command fzf
# zstyle ':fzf-tab:*' fzf-min-height 10
# zstyle ':fzf-tab:*' fzf-pad 4