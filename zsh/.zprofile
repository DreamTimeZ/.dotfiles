export ZDOTFILES_DIR="${ZDOTFILES_DIR:-$HOME/.dotfiles}"
export ZDOTFILES_CONFIG_DIR="${ZDOTFILES_CONFIG_DIR:-$ZDOTFILES_DIR/zsh/config}"

[[ -r "$ZDOTFILES_CONFIG_DIR/local/zprofile.pre.zsh" ]] && source "$ZDOTFILES_CONFIG_DIR/local/zprofile.pre.zsh"

# Silent mode for login shells (non-interactive shells should not produce output)
export ZDOTFILES_LOG_LEVEL=0

if [[ -r "$ZDOTFILES_CONFIG_DIR/helpers.zsh" ]]; then
  source "$ZDOTFILES_CONFIG_DIR/helpers.zsh"
fi

# /home is an autofs automount on macOS: every stat under it goes to automountd,
# is never cached, and costs 12-33ms per login shell (measured 2026-11-23).
# Linuxbrew is Linux-only.
if ! zdotfiles_is_macos; then
  [[ -d "/home/linuxbrew/.linuxbrew/sbin" ]] && zdotfiles_path_prepend "/home/linuxbrew/.linuxbrew/sbin"
  [[ -d "/home/linuxbrew/.linuxbrew/bin" ]] && zdotfiles_path_prepend "/home/linuxbrew/.linuxbrew/bin"
fi
# sbin is prepended first so bin lands ahead of it, matching brew shellenv.
[[ -d "/opt/homebrew/sbin" ]] && zdotfiles_path_prepend "/opt/homebrew/sbin"
[[ -d "/opt/homebrew/bin" ]] && zdotfiles_path_prepend "/opt/homebrew/bin"
[[ -d "$HOME/.local/bin" ]] && zdotfiles_path_prepend "$HOME/.local/bin"
[[ -d "$HOME/.cargo/bin" ]] && zdotfiles_path_prepend "$HOME/.cargo/bin"

export EDITOR="${EDITOR:-nvim}"

# Start ssh-agent if needed. Key loading is deferred to first use (see sheldon/ssh-keys.zsh)
if [[ -n $commands[ssh-agent] && -n $commands[ssh-add] ]]; then
  # Check if ANY working agent exists (ssh-agent, gpg-agent, 1Password, forwarded)
  ssh-add -l &>/dev/null
  if [[ $? -eq 2 ]]; then
    _ssh_env=$HOME/.ssh/agent-env
    if [[ -f $_ssh_env ]]; then
      source "$_ssh_env" >/dev/null
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
    # Publish the verdict so interactive shells (sheldon/ssh-keys.zsh) skip the
    # ~3.5ms probe. Re-probe rather than trusting SSH_AUTH_SOCK: a restored
    # agent-env leaves a stale socket set even when its agent is long dead.
    # Left unset on failure, so those shells re-probe and can still recover.
    ssh-add -l &>/dev/null
    [[ $? -ne 2 ]] && export ZDOTFILES_SSH_AGENT_UP=1
  else
    export ZDOTFILES_SSH_AGENT_UP=1
  fi
fi
