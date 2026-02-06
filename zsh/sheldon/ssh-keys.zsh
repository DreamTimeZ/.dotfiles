# ===============================
# SSH KEY LAZY LOADING
# ===============================
# SSH agent is started in .zprofile, but key loading is deferred
# until first use of ssh/scp/sftp/git-remote operations.
# Saves ~10-15ms on shell startup.

# Guard: only set up if ssh-add exists and agent is running
[[ -z $commands[ssh-add] ]] && return
ssh-add -l &>/dev/null
[[ $? -eq 2 ]] && return  # 2 = agent not running; 0/1 = running (with/without keys)

# Configuration (can be overridden before this file loads)
: ${ZDOTFILES_SSH_KEY_DIR:=$HOME/.ssh}
: ${ZDOTFILES_SSH_USE_KEYCHAIN:=1}
: ${ZDOTFILES_SSH_EXCLUDED:="*.pub config* known_hosts* authorized_keys* agent-env*"}

# State tracking
typeset -g _ZDOTFILES_SSH_KEYS_LOADED=0

# Load SSH keys into agent
_zdotfiles_load_ssh_keys() {
  # Only run once
  (( _ZDOTFILES_SSH_KEYS_LOADED )) && return 0
  _ZDOTFILES_SSH_KEYS_LOADED=1

  local key filename fingerprint
  local -a loaded_fps exclude_pats keys

  # Get already-loaded key fingerprints
  loaded_fps=( ${(f)"$(ssh-add -l 2>/dev/null | awk '{print $2}')"} )

  # Parse exclusion patterns
  exclude_pats=( ${=ZDOTFILES_SSH_EXCLUDED} )

  # Platform detection for keychain
  local use_keychain=0
  zdotfiles_is_macos && [[ $ZDOTFILES_SSH_USE_KEYCHAIN -eq 1 ]] && use_keychain=1

  # Iterate over key files
  keys=( "$ZDOTFILES_SSH_KEY_DIR"/*(N) )
  for key in $keys; do
    filename=${key:t}

    # Check exclusion patterns
    local excluded=0
    for pat in $exclude_pats; do
      [[ $filename == $~pat ]] && { excluded=1; break; }
    done
    (( excluded )) && continue

    # Validate: must be readable file with private key header
    [[ -f $key && -r $key ]] || continue
    grep -qE '^-----BEGIN .*PRIVATE KEY-----' "$key" 2>/dev/null || continue

    # Get fingerprint
    fingerprint=$(ssh-keygen -lf "$key" 2>/dev/null | awk '{print $2}')
    [[ -n $fingerprint ]] || continue

    # Skip if already loaded
    (( ${loaded_fps[(I)$fingerprint]} )) && continue

    # Add key
    if (( use_keychain )); then
      ssh-add --apple-use-keychain "$key" &>/dev/null
    else
      ssh-add "$key" &>/dev/null
    fi
  done
}

# Wrapper generator for commands that need SSH keys
_zdotfiles_ssh_wrap() {
  local cmd=$1
  eval "
    $cmd() {
      (( _ZDOTFILES_SSH_KEYS_LOADED )) || _zdotfiles_load_ssh_keys
      command $cmd \"\$@\"
    }
  "
}

# Wrap direct SSH commands
_zdotfiles_ssh_wrap ssh
_zdotfiles_ssh_wrap scp
_zdotfiles_ssh_wrap sftp
_zdotfiles_ssh_wrap rsync

# Git wrapper: only load keys for remote operations
git() {
  if (( ! _ZDOTFILES_SSH_KEYS_LOADED )); then
    case ${1:-} in
      push|pull|fetch|clone|remote|ls-remote|submodule|lfs)
        _zdotfiles_load_ssh_keys
        ;;
    esac
  fi
  command git "$@"
}

unfunction _zdotfiles_ssh_wrap
