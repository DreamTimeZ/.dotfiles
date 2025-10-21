# ===============================
# NVM - Node Version Manager
# ===============================

# Add node to PATH without loading NVM (fast startup)
if [[ -d "$HOME/.nvm/versions/node" ]]; then
  export NVM_DIR="$HOME/.nvm"
  # Find the node binary path
  _node_path=""
  if [[ -s "$NVM_DIR/alias/default" ]]; then
    _nvm_default=$(cat "$NVM_DIR/alias/default")
    # Try with 'v' prefix first (e.g., v22.21.0), then exact match, then glob
    for _try in "v${_nvm_default}" "${_nvm_default}" $(command ls -1d "$NVM_DIR/versions/node"/v${_nvm_default}.* 2>/dev/null | tail -1 | xargs basename 2>/dev/null); do
      if [[ -d "$NVM_DIR/versions/node/$_try/bin" ]]; then
        _node_path="$NVM_DIR/versions/node/$_try/bin"
        break
      fi
    done
  fi
  # Fallback to latest version
  if [[ -z "$_node_path" ]]; then
    _latest=$(command ls -1 "$NVM_DIR/versions/node" 2>/dev/null | tail -1)
    [[ -n "$_latest" ]] && _node_path="$NVM_DIR/versions/node/$_latest/bin"
  fi
  # Add to PATH if found
  [[ -n "$_node_path" && -d "$_node_path" ]] && export PATH="$_node_path:$PATH"
  unset _nvm_default _node_path _try _latest
fi

# Lazy load NVM itself (for version switching)
_init_nvm() {
  local nvm_script
  for nvm_script in \
    "$HOME/.nvm/nvm.sh" \
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
