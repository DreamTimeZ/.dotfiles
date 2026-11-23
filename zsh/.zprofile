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

# Keys are added on first use by ssh/config (AddKeysToAgent, UseKeychain on macOS)
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
  fi
fi
