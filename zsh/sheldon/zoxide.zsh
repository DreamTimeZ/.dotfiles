# ===============================
# ZOXIDE
# ===============================

# Define the zoxide initialization command
_init_zoxide() {
  if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh --hook prompt)"
  else
    echo "Error: zoxide not found. Please install zoxide." >&2
    return 1
  fi
}

# Check if helper function is available
if ! typeset -f zdotfiles_lazy_load > /dev/null; then
  # If helper isn't available, use inline implementation for both z and zi
  function z() {
    unfunction z zi 2>/dev/null
    _init_zoxide
    z "$@"
  }
  
  function zi() {
    unfunction z zi 2>/dev/null
    _init_zoxide
    zi "$@"
  }
else
  # Use the central helper function for both commands
  zdotfiles_lazy_load z '_init_zoxide'
  zdotfiles_lazy_load zi '_init_zoxide'
fi