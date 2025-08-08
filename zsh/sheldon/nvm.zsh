# nvm lazy loader with Homebrew support
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

# Sentinel for wrapper state
typeset -g _NVM_WRAPPER_ACTIVE=1

# Core initialization function
_nvm_do_init() {
  emulate -L zsh
  
  # Exit early if real nvm is already loaded
  if typeset -f nvm >/dev/null 2>&1 && [[ -z "${_NVM_WRAPPER_ACTIVE-}" ]]; then
    return 0
  fi

  # Determine Homebrew prefix efficiently
  local brew_prefix="${HOMEBREW_PREFIX:-}"
  if [[ -z "$brew_prefix" ]]; then
    if [[ -d /opt/homebrew ]]; then
      brew_prefix=/opt/homebrew
    elif [[ -d /usr/local/Homebrew || -d /usr/local/opt ]]; then
      brew_prefix=/usr/local
    elif command -v brew >/dev/null 2>&1; then
      brew_prefix="$(brew --prefix 2>/dev/null)"
    fi
  fi

  # Load nvm.sh from first available location
  local nvm_sh
  for nvm_sh in "${brew_prefix:+$brew_prefix/opt/nvm/nvm.sh}" "$NVM_DIR/nvm.sh"; do
    [[ -r "$nvm_sh" ]] && { . "$nvm_sh"; break; } || continue
  done

  # Check if nvm loaded successfully
  if ! typeset -f nvm >/dev/null 2>&1; then
    return 1
  fi

  # Load completion if available
  local nvm_comp
  for nvm_comp in "${brew_prefix:+$brew_prefix/opt/nvm/etc/bash_completion.d/nvm}" "$NVM_DIR/bash_completion"; do
    if [[ -r "$nvm_comp" ]]; then
      autoload -Uz bashcompinit 2>/dev/null && bashcompinit 2>/dev/null
      . "$nvm_comp"
      break
    fi
  done

  # Auto-use default version if node isn't available
  if ! command -v node >/dev/null 2>&1 && [[ -r "$NVM_DIR/alias/default" ]]; then
    nvm use default >/dev/null 2>&1 || true
  fi

  unset -g _NVM_WRAPPER_ACTIVE
  return 0
}

# Wrapper functions with unified error handling
_nvm_lazy_wrap() {
  local cmd="$1"
  if _nvm_do_init && unfunction "$cmd" 2>/dev/null; then
    command "$cmd" "$@"
  else
    echo "$cmd: requires Node.js. Install with 'nvm install --lts'" >&2
    return 127
  fi
}

nvm() {
  if _nvm_do_init; then
    nvm "$@"
  else
    echo "nvm: not found. Install via 'brew install nvm' or official installer" >&2
    return 127
  fi
}

node() { _nvm_lazy_wrap node "$@"; }
npm() { _nvm_lazy_wrap npm "$@"; }
npx() { _nvm_lazy_wrap npx "$@"; }
yarn() { _nvm_lazy_wrap yarn "$@"; }
pnpm() { _nvm_lazy_wrap pnpm "$@"; }
corepack() { _nvm_lazy_wrap corepack "$@"; }