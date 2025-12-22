# ===============================
# .ZPROFILE - LOGIN SHELL CONFIG
# ===============================
# Executed for login shells

# ------ Base Configuration ------
export ZDOTFILES_DIR="${ZDOTFILES_DIR:-$HOME/.dotfiles}"
export ZDOTFILES_CONFIG_DIR="${ZDOTFILES_CONFIG_DIR:-$ZDOTFILES_DIR/zsh/config}"

# Silent mode for login shells (non-interactive shells should not produce output)
export ZDOTFILES_LOG_LEVEL=0

# ------ Path Management ------
# Load helper functions first to use zdotfiles_path_prepend
if [[ -r "$ZDOTFILES_CONFIG_DIR/helpers.zsh" ]]; then
  source "$ZDOTFILES_CONFIG_DIR/helpers.zsh"
fi

# Static path entries (login shell only - avoids duplication in subshells)
[[ -d "/home/linuxbrew/.linuxbrew/bin" ]] && zdotfiles_path_prepend "/home/linuxbrew/.linuxbrew/bin"
[[ -d "/opt/homebrew/bin" ]] && zdotfiles_path_prepend "/opt/homebrew/bin"
[[ -d "$HOME/.local/bin" ]] && zdotfiles_path_prepend "$HOME/.local/bin"
[[ -d "$HOME/.cargo/bin" ]] && zdotfiles_path_prepend "$HOME/.cargo/bin"
[[ -d "/snap/bin" ]] && zdotfiles_path_prepend "/snap/bin"

# JetBrains Toolbox CLI scripts (idea, pycharm, webstorm, etc.)
[[ -d "$HOME/.local/share/JetBrains/Toolbox/scripts" ]] && zdotfiles_path_prepend "$HOME/.local/share/JetBrains/Toolbox/scripts"
[[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]] && zdotfiles_path_prepend "$HOME/Library/Application Support/JetBrains/Toolbox/scripts"

# PNPM (Node.js package manager) - Platform-aware
# Always export PNPM_HOME and ensure directory exists for seamless first use
if [[ "$OSTYPE" == "darwin"* ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
else
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi
[[ -d "$PNPM_HOME" ]] || mkdir -p "$PNPM_HOME"
zdotfiles_path_prepend "$PNPM_HOME"

# Pyenv (Python version manager)
export PYENV_ROOT="$HOME/.pyenv"
[[ -d "$PYENV_ROOT/bin" ]] && zdotfiles_path_prepend "$PYENV_ROOT/bin"

# NVM (Node version manager) - Add default node to PATH
# Check multiple possible NVM locations (user install, Homebrew Linux, Homebrew macOS)
for _nvm_dir in "$HOME/.nvm" "/home/linuxbrew/.linuxbrew/opt/nvm" "/opt/homebrew/opt/nvm" "/usr/local/opt/nvm"; do
  [[ -d "$_nvm_dir/versions/node" ]] || continue
  export NVM_DIR="$_nvm_dir"

  _node_version=""
  # Try to resolve default alias (handles 2-level nesting: default -> lts/* -> lts/krypton)
  if [[ -f "$NVM_DIR/alias/default" ]]; then
    _alias=$(cat "$NVM_DIR/alias/default")
    # If alias points to another alias file, resolve once more
    [[ -f "$NVM_DIR/alias/$_alias" ]] && _alias=$(cat "$NVM_DIR/alias/$_alias")
    # Check if resolved value is a valid version directory
    [[ -d "$NVM_DIR/versions/node/$_alias" ]] && _node_version="$_alias"
  fi

  # Fallback to latest installed version (using semantic version sort)
  if [[ -z "$_node_version" ]]; then
    # (N) = null_glob, (On) = reverse order + numeric sort, (/) = directories only
    _versions=("$NVM_DIR/versions/node"/v*(NOn/))
    [[ ${#_versions[@]} -gt 0 ]] && _node_version="${_versions[1]:t}"
  fi

  # Add to PATH if node binary exists
  if [[ -n "$_node_version" ]]; then
    _node_bin="$NVM_DIR/versions/node/$_node_version/bin"
    [[ -x "$_node_bin/node" ]] && zdotfiles_path_prepend "$_node_bin"
  fi

  unset _node_version _alias _versions _node_bin
  break  # Found a valid NVM installation, stop searching
done
unset _nvm_dir

# ------ Environment Variables ------
export EDITOR="${EDITOR:-nvim}"
[[ -d "/usr/lib/jvm/temurin-25-jdk-amd64" ]] && export JAVA_HOME="/usr/lib/jvm/temurin-25-jdk-amd64"

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