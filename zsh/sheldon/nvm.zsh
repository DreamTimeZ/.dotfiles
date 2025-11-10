# ===============================
# NVM - Node Version Manager
# ===============================
# PATH setup is handled in .zprofile

export NVM_DIR="$HOME/.nvm"

# Lazy load NVM itself (for version switching)
_init_nvm() {
  local nvm_script
  for nvm_script in \
    "$NVM_DIR/nvm.sh" \
    "/opt/homebrew/opt/nvm/nvm.sh" \
    "/usr/local/opt/nvm/nvm.sh"
  do
    [[ -s $nvm_script ]] || continue
    export NVM_DIR=${nvm_script%/nvm.sh}
    \. "$nvm_script"
    [[ -s $NVM_DIR/bash_completion ]] && \. "$NVM_DIR/bash_completion"
    return 0
  done
}

zdotfiles_lazy_load _init_nvm nvm
