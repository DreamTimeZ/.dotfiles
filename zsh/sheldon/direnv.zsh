# ===============================
# DIRENV
# ===============================

# Always initialize direnv during shell startup
if command -v direnv >/dev/null 2>&1; then
  eval "$(command direnv hook zsh)"
else
  # Create a placeholder function that will show error when used
  function direnv() {
    echo "Error: direnv not found. Please install direnv." >&2
    return 1
  }
fi