# ===============================
# PYENV CONFIGURATION
# ===============================
# Lazy-loading implementation for pyenv

# Set up environment variables for pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Cache expensive operations for better performance
function _pyenv_init_cmd() {
  # Cache the init command
  if [[ -z "$_PYENV_INIT_CMD_CACHE" ]]; then
    _PYENV_INIT_CMD_CACHE="$(command pyenv init - --no-rehash 2>/dev/null)"
  fi
  echo "$_PYENV_INIT_CMD_CACHE"
}

# Define a wrapper function for pyenv that will load pyenv only when needed
function pyenv() {
  # Remove this wrapper function
  unfunction pyenv
  
  # Add pyenv to the path if it exists
  if command -v pyenv >/dev/null 2>&1; then
    # Initialize pyenv - use --no-rehash for faster loading
    local init_cmd="$(_pyenv_init_cmd)"
    [[ -n "$init_cmd" ]] && eval "${init_cmd}" >/dev/null 2>&1
    
    # Execute the command that was passed to this function
    command pyenv "$@"
  else
    echo "pyenv not found. Please install pyenv." >&2
    return 1
  fi
}

# Add lazy loading for python and pip commands (only if not managed by asdf)
# First, check if asdf is managing python
if ! (( $+functions[asdf] )) || ! { asdf which python &>/dev/null || asdf which python3 &>/dev/null }; then
  for cmd in python python3 pip pip3; do
    # Only create wrapper if command doesn't exist or is not managed by asdf
    if ! command -v $cmd >/dev/null 2>&1; then
      eval "function $cmd() { unfunction $cmd; pyenv; command $cmd \"\$@\"; }"
    fi
  done
fi

# Cache variable for init command
typeset -g _PYENV_INIT_CMD_CACHE="" 