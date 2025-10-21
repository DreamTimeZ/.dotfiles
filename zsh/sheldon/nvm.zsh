# ===============================
# NVM - Node Version Manager
# ===============================

_init_nvm() {
  local nvm_script
  for nvm_script in \
    "$HOME/.nvm/nvm.sh" \
    "/opt/homebrew/opt/nvm/nvm.sh" \
    "/usr/local/opt/nvm/nvm.sh"
  do
    [[ -s $nvm_script ]] || continue
    export NVM_DIR=${nvm_script%/nvm.sh}

    # Now load NVM
    \. "$nvm_script"
    [[ -s $NVM_DIR/bash_completion ]] && \. "$NVM_DIR/bash_completion"

    # Activate default version (this sets NVM_BIN and other vars NVM needs)
    nvm use default --silent 2>/dev/null || nvm use node --silent 2>/dev/null || true

    return 0
  done
}

zdotfiles_lazy_load _init_nvm nvm node npm npx pnpm yarn
