# ===============================
# DIRENV
# ===============================

# Check if helper function is available
if ! typeset -f zdotfiles_lazy_load > /dev/null; then
  # If helper isn't available, use inline implementation
  function direnv() {
    unfunction direnv
    if command -v direnv >/dev/null 2>&1; then
      eval "$(command direnv hook zsh)"
      command direnv "$@"
    else
      echo "Error: direnv not found. Please install direnv." >&2
      return 1
    fi
  }
else
  # Use the central helper function
  zdotfiles_lazy_load direnv 'eval "$(command direnv hook zsh)"'
fi

# That's it - no other code executed during startup 