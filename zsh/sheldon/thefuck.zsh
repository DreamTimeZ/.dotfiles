# ===============================
# THE FUCK
# ===============================

# Check if helper function is available
if ! typeset -f zdotfiles_lazy_load > /dev/null; then
  # If helper isn't available, use inline implementation
  function f() {
    unfunction f
    if command -v thefuck >/dev/null 2>&1; then
      eval "$(thefuck --alias f)" >/dev/null 2>&1
      f "$@"
    else
      echo "Error: thefuck not found. Please install thefuck." >&2
      return 1
    fi
  }
else
  # Use the central helper function
  zdotfiles_lazy_load f 'eval "$(thefuck --alias f)" >/dev/null 2>&1'
fi