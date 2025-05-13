# ===============================
# PYENV CONFIGURATION
# ===============================

# Set up environment variables for pyenv (required for shims to work)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Define the pyenv initialization function
_init_pyenv() {
  # Initialize pyenv - use --no-rehash for faster loading
  if command -v pyenv >/dev/null 2>&1; then
    eval "$(pyenv init - --no-rehash)" >/dev/null 2>&1
  else
    echo "pyenv not found. Please install pyenv." >&2
    return 1
  fi
}

# Check if asdf might be managing Python without invoking 'asdf' function
function _is_python_managed_by_asdf() {
  # Check if ASDF_DIR is set and Python shims exist
  if [[ -n "$ASDF_DIR" && -f "$ASDF_DIR/shims/python" ]]; then
    return 0
  fi
  
  # Check common asdf shim locations if ASDF_DIR isn't set
  if [[ -f "$HOME/.asdf/shims/python" || -f "$HOME/.asdf/shims/python3" ]]; then
    return 0
  fi
  
  # Check brew-installed asdf location (without invoking brew)
  local brew_prefix="/opt/homebrew"
  [[ -d "/usr/local/opt/asdf" ]] && brew_prefix="/usr/local"
  if [[ -f "$brew_prefix/opt/asdf/shims/python" || -f "$brew_prefix/opt/asdf/shims/python3" ]]; then
    return 0
  fi
  
  return 1
}

# Set up lazy loading for pyenv
if typeset -f zdotfiles_lazy_load > /dev/null; then
  # Use the central helper function
  zdotfiles_lazy_load pyenv '_init_pyenv'
  
  # Add lazy loading for python commands (only if not managed by asdf)
  if ! _is_python_managed_by_asdf; then
    for cmd in python python3 pip pip3; do
      # Only create wrapper if the command doesn't already exist in PATH
      if ! command -v $cmd >/dev/null 2>&1; then
        zdotfiles_lazy_load $cmd '_init_pyenv'
      fi
    done
  fi
else
  # Fallback to original implementation if helper isn't available
  function pyenv() {
    unfunction pyenv
    _init_pyenv
    command pyenv "$@"
  }
  
  # Add lazy loading for python and pip commands (only if not managed by asdf)
  if ! _is_python_managed_by_asdf; then
    for cmd in python python3 pip pip3; do
      # Only create wrapper if the command doesn't already exist in PATH
      if ! command -v $cmd >/dev/null 2>&1; then
        eval "function $cmd() { unfunction $cmd; _init_pyenv; command $cmd \"\$@\"; }"
      fi
    done
  fi
fi 