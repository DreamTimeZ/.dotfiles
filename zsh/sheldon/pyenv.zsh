# ===============================
# PYENV - Python Version Manager
# ===============================
# PATH setup is handled in .zprofile

export PYENV_ROOT="$HOME/.pyenv"

_init_pyenv() {
  [[ -n $commands[pyenv] ]] && eval "$(pyenv init - --no-rehash zsh)"
}

# Lazy load pyenv
zdotfiles_lazy_load _init_pyenv pyenv python python3 pip pip3
