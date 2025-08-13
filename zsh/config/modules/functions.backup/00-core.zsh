# ===============================
# CORE UTILITY FUNCTIONS
# ===============================

# Only define notify if we have a notification method available
# Enable in macos notification settings for it to work
if zdotfiles_has_command terminal-notifier; then
    # Send desktop notification using terminal-notifier (preferred)
    notify() {
        [[ $# -eq 0 ]] && { echo "Usage: notify <message> [title]" >&2; return 1; }
        terminal-notifier -title "${2:-Terminal}" -message "$1"
    }
elif zdotfiles_has_command osascript; then
    # Send desktop notification using AppleScript (fallback)
    notify() {
        [[ $# -eq 0 ]] && { echo "Usage: notify <message> [title]" >&2; return 1; }
        local _msg="$1"
        local _title="${2:-Terminal}"
        # Escape embedded quotes for AppleScript
        _msg="${_msg//\"/\\\"}"
        _title="${_title//\"/\\\"}"
        osascript -e "display notification \"$_msg\" with title \"$_title\""
    }
fi

# Retry a command until it succeeds
retry() {
  if [[ $# -eq 0 ]]; then
    zdotfiles_error "Usage: retry <command> [args...]"
    return 1
  fi
  
  local max_attempts=5
  local delay=2
  local attempt=1
  
  # Parse options
  while [[ $1 == -* ]]; do
    case $1 in
      --max-attempts=*) max_attempts="${1#*=}"; shift ;;
      --delay=*) delay="${1#*=}"; shift ;;
      *) zdotfiles_error "Unknown option: $1"; return 1 ;;
    esac
  done
  
  local cmd=("$@")
  
  while (( attempt <= max_attempts )); do
    if "${cmd[@]}"; then
      return 0
    fi
    
    if (( attempt < max_attempts )); then
      echo "Attempt $attempt failed. Retrying in ${delay}s..."
      sleep "$delay"
    fi
    
    ((attempt++))
  done
  
  zdotfiles_error "Command failed after $max_attempts attempts: ${cmd[*]}"
  return 1
}

# mkdir with verbose output and parent creation
mkdirp() {
  if [[ $# -eq 0 ]]; then
    zdotfiles_error "Usage: mkdirp <directory> [directories...]"
    return 1
  fi
  
  mkdir -pv "$@"
}

# Safe file operations with confirmation
confirm() {
  local prompt="${1:-Are you sure?}"
  echo -n "$prompt [y/N]: "
  read -r response
  [[ "$response" =~ ^[Yy]$ ]]
} 