# ===============================
# .ZPROFILE - LOGIN SHELL CONFIG
# ===============================
# Executed for login shells

# ------ Base Configuration ------
export ZDOTFILES_DIR="${ZDOTFILES_DIR:-$HOME/.dotfiles}"
export ZDOTFILES_CONFIG_DIR="${ZDOTFILES_CONFIG_DIR:-$ZDOTFILES_DIR/zsh/config}"

# ------ Local Pre-hook ------
[[ -r "$ZDOTFILES_CONFIG_DIR/local/zprofile.pre.zsh" ]] && source "$ZDOTFILES_CONFIG_DIR/local/zprofile.pre.zsh"

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
if zdotfiles_is_macos; then
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

# ------ SSH Agent Setup ------
# Start ssh-agent if needed. Key loading is deferred to first use (see sheldon/ssh-keys.zsh)
# Respects existing agents: gpg-agent, 1Password, forwarded agents, etc.
if [[ -n $commands[ssh-agent] && -n $commands[ssh-add] ]]; then
  # Check if ANY working agent exists (ssh-agent, gpg-agent, 1Password, forwarded)
  ssh-add -l &>/dev/null
  if [[ $? -eq 2 ]]; then
    # No working agent - start/restore one
    # Persist agent across sessions on all platforms. System-managed agents
    # (macOS Keychain, GNOME Keyring, 1Password) are detected above and
    # skip this block entirely, so persistence never conflicts with them.
    _ssh_env=$HOME/.ssh/agent-env
    if [[ -f $_ssh_env ]]; then
      source "$_ssh_env" >/dev/null
      # Verify restored agent actually works
      ssh-add -l &>/dev/null
      [[ $? -eq 2 ]] && {
        eval "$(ssh-agent -s)" >/dev/null
        print -r "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >$_ssh_env
        print -r "export SSH_AGENT_PID=$SSH_AGENT_PID" >>$_ssh_env
      }
    else
      eval "$(ssh-agent -s)" >/dev/null
      print -r "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >$_ssh_env
      print -r "export SSH_AGENT_PID=$SSH_AGENT_PID" >>$_ssh_env
    fi
    unset _ssh_env
  fi
fi
