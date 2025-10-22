# ===============================
# PYENV - Python Version Manager
# ===============================

export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"

_init_pyenv() {
  [[ -n $commands[pyenv] ]] && eval "$(pyenv init - --no-rehash zsh)"
}

# Lazy load pyenv
zdotfiles_lazy_load _init_pyenv pyenv python python3 pip pip3
