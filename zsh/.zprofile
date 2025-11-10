# ===============================
# .ZPROFILE - LOGIN SHELL CONFIG
# ===============================
# Executed for login shells

# ------ Base Configuration ------
export ZDOTFILES_DIR="${ZDOTFILES_DIR:-$HOME/.dotfiles}"
export ZDOTFILES_CONFIG_DIR="${ZDOTFILES_CONFIG_DIR:-$ZDOTFILES_DIR/zsh/config}"

# ------ Path Management ------
# Load helper functions first to use zdotfiles_path_prepend
if [[ -r "$ZDOTFILES_CONFIG_DIR/helpers.zsh" ]]; then
  source "$ZDOTFILES_CONFIG_DIR/helpers.zsh"
fi

# Static path entries (login shell only - avoids duplication in subshells)
[[ -d "/opt/homebrew/bin" ]] && zdotfiles_path_prepend "/opt/homebrew/bin"
[[ -d "$HOME/.local/bin" ]] && zdotfiles_path_prepend "$HOME/.local/bin"
[[ -d "$HOME/.cargo/bin" ]] && zdotfiles_path_prepend "$HOME/.cargo/bin"
[[ -d "/snap/bin" ]] && zdotfiles_path_prepend "/snap/bin"

# PNPM (Node.js package manager) - Platform-aware
if [[ -d "$HOME/.local/share/pnpm" ]] || [[ -d "$HOME/Library/pnpm" ]]; then
  if [[ "$OSTYPE" == "darwin"* ]]; then
    export PNPM_HOME="$HOME/Library/pnpm"
  else
    export PNPM_HOME="$HOME/.local/share/pnpm"
  fi
  [[ -d "$PNPM_HOME" ]] && zdotfiles_path_prepend "$PNPM_HOME"
fi

# ------ Environment Variables ------
export EDITOR="${EDITOR:-nvim}"

# ------ SSH Key Management (Performance-Optimized) ------
: ${SSH_KEY_DIR:="$HOME/.ssh"}
: ${SSH_USE_KEYCHAIN:=1}
: ${SSH_EXCLUDED_PATTERNS:="*.pub config* known_hosts* authorized_keys*"}

# Command availability cache - check once instead of repeatedly
_HAVE_SSH_AGENT=0
_HAVE_SSH_ADD=0
[[ -n $commands[ssh-agent] ]] && _HAVE_SSH_AGENT=1
[[ -n $commands[ssh-add] ]] && _HAVE_SSH_ADD=1

# Only proceed if commands are available
if [[ $_HAVE_SSH_AGENT -eq 1 && $_HAVE_SSH_ADD -eq 1 ]]; then
  # Detect WSL environment
  _IS_WSL=0
  if [[ -f /proc/version ]] && grep -qiE '(microsoft|wsl)' /proc/version 2>/dev/null; then
    _IS_WSL=1
  fi

  # WSL-specific agent socket persistence
  if [[ $_IS_WSL -eq 1 ]]; then
    SSH_AGENT_ENV="$HOME/.ssh/agent-env"

    # Try to reuse existing agent
    if [[ -f "$SSH_AGENT_ENV" ]]; then
      source "$SSH_AGENT_ENV" > /dev/null
      # Verify agent is still running
      if ! kill -0 "$SSH_AGENT_PID" &>/dev/null 2>&1; then
        # Agent died, start new one
        eval "$(ssh-agent -s)" > /dev/null
        echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$SSH_AGENT_ENV"
        echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$SSH_AGENT_ENV"
      fi
    else
      # No existing agent, start new one
      eval "$(ssh-agent -s)" > /dev/null
      echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > "$SSH_AGENT_ENV"
      echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> "$SSH_AGENT_ENV"
    fi
    unset SSH_AGENT_ENV
  else
    # Non-WSL: original behavior
    ssh_agent_running() {
      if [[ -n "$SSH_AGENT_PID" ]]; then
        kill -0 "$SSH_AGENT_PID" &>/dev/null && return 0
      fi
      pgrep -x ssh-agent &>/dev/null
      return $?
    }

    # Start SSH agent if not running
    if ! ssh_agent_running; then
      eval "$(ssh-agent -s)" > /dev/null
    fi

    unset -f ssh_agent_running
  fi
  
  # Simple platform detection for macOS-specific features
  _IS_MACOS=0
  [[ "$OSTYPE" == darwin* ]] && _IS_MACOS=1
  
  # Get currently loaded keys directly from ssh-add
  # The agent status code will help us determine if keys are loaded
  # 0 = keys loaded, 1 = no keys loaded, 2 = agent not running
  ssh-add -l &>/dev/null
  KEYS_STATUS=$?
  
  # Only proceed if agent is running (status code 0 or 1)
  if [[ $KEYS_STATUS -lt 2 ]]; then
    # Get list of currently loaded fingerprints
    loaded_keys=$(ssh-add -l 2>/dev/null | awk '{print $2}')
    
    # Key validation function - reused for each key
    validate_key() {
      local key="$1"
      [[ ! -f "$key" || ! -r "$key" ]] && return 1
      # Content check first, fallback to fingerprint
      grep -q -E "BEGIN .* PRIVATE KEY" "$key" 2>/dev/null && return 0
      ssh-keygen -lf "$key" &>/dev/null
      return $?
    }
    
    # Pattern matching for exclusions using SSH_EXCLUDED_PATTERNS
    should_exclude() {
      local filename="$1"
      local -a patterns
      patterns=(${=SSH_EXCLUDED_PATTERNS})
      for pat in $patterns; do
        case "$filename" in
          $pat) return 0 ;;
        esac
      done
      return 1
    }
    
    # Add keys
    success_count=0
    local -a keys
    keys=("$SSH_KEY_DIR"/*(N))
    for key in $keys; do
      filename="$(basename "$key")"    
      should_exclude "$filename" && continue
      
      # Only validate keys that pass exclusion filter
      validate_key "$key" || continue
      
      # Get fingerprint and check if already loaded
      fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')
      [[ -z "$fingerprint" ]] && continue
      
      # Skip if fingerprint is already in loaded_keys
      [[ -n "$loaded_keys" && "$loaded_keys" == *"$fingerprint"* ]] && continue
      
      # Add key with platform-specific options
      if [[ $_IS_MACOS -eq 1 && $SSH_USE_KEYCHAIN -eq 1 ]]; then
        ssh-add --apple-use-keychain "$key" 2>/dev/null && ((success_count++))
      else
        ssh-add "$key" 2>/dev/null && ((success_count++))
      fi
    done
    
    # Cleanup all temp variables
    unset -f validate_key should_exclude
    unset loaded_keys fingerprint success_count KEYS_STATUS
  fi
  
  unset SSH_KEY_DIR SSH_USE_KEYCHAIN SSH_EXCLUDED_PATTERNS
  unset _HAVE_SSH_AGENT _HAVE_SSH_ADD _IS_MACOS _IS_WSL
fi