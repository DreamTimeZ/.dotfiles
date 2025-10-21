# ===============================
# PYENV - Python Version Manager
# ===============================

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

_init_pyenv() {
  [[ -n $commands[pyenv] ]] && eval "$(pyenv init - --no-rehash zsh)"
}

# Skip if asdf is managing Python (check happens instantly via file test)
if [[ ! (-n $ASDF_DIR && -f $ASDF_DIR/shims/python) && \
      ! -f $HOME/.asdf/shims/python && \
      ! -f /opt/homebrew/opt/asdf/shims/python && \
      ! -f /usr/local/opt/asdf/shims/python ]]; then
  zdotfiles_lazy_load _init_pyenv pyenv python python3 pip pip3
fi
