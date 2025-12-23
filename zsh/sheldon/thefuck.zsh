# ===============================
# THEFUCK - Command Corrector
# ===============================

# NOTE: Currently broken on Python 3.12 (missing 'imp' module)
# See: https://github.com/nvbn/thefuck/issues/1496
# Will show error message when used until thefuck releases a fix
# Fix: pipx inject thefuck setuptools (partial) or wait for upstream update

# Disabled by default, only works when explicitly called
if zdotfiles_has_command thefuck; then
  _thefuck_init_and_run() {
    # Try to initialize thefuck
    if eval "$(thefuck --alias 2>&1)"; then
      # Success - remove wrapper functions and create aliases
      unfunction fuck fk f _thefuck_init_and_run 2>/dev/null
      alias fk='fuck'
      alias f='fuck'

      # Now call the real thefuck function
      fuck "$@"
    else
      # Initialization failed - show error
      echo "Error: thefuck failed to initialize. It may be incompatible with your Python version." >&2
      echo "Try: pip install --upgrade thefuck" >&2
      return 1
    fi
  }

  # Create wrapper functions for all aliases
  fuck() { _thefuck_init_and_run "$@" }
  f() { _thefuck_init_and_run "$@" }
fi
