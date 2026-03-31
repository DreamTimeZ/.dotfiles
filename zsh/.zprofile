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

# ------ Environment Variables ------
export EDITOR="${EDITOR:-nvim}"

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
