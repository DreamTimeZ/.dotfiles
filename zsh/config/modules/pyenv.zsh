# ===============================
# PYENV CONFIGURATION
# ===============================

# Set the pyenv root directory
export PYENV_ROOT="$HOME/.pyenv"

# Add pyenv bin directory to PATH if it exists
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

# Initialize pyenv for zsh
if command -v pyenv &>/dev/null; then
  eval "$(pyenv init - zsh)"
fi 