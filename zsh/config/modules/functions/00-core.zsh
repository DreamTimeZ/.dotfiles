# ===============================
# CORE UTILITY FUNCTIONS
# ===============================

# Cross-platform desktop notification
# Priority: terminal-notifier (macOS) > osascript (macOS) > notify-send (Linux) > terminal bell
if zdotfiles_has_command terminal-notifier; then
    notify() {
        [[ $# -eq 0 ]] && { echo "Usage: notify <message> [title]" >&2; return 1; }
        terminal-notifier -title "${2:-Terminal}" -message "$1"
    }
elif zdotfiles_has_command osascript; then
    notify() {
        [[ $# -eq 0 ]] && { echo "Usage: notify <message> [title]" >&2; return 1; }
        local _msg="$1"
        local _title="${2:-Terminal}"
        _msg="${_msg//\"/\\\"}"
        _title="${_title//\"/\\\"}"
        osascript -e "display notification \"$_msg\" with title \"$_title\""
    }
elif zdotfiles_has_command notify-send && [[ -n "$DISPLAY" || -n "$WAYLAND_DISPLAY" ]]; then
    # Linux desktop (GNOME, KDE, XFCE) and WSLg
    notify() {
        [[ $# -eq 0 ]] && { echo "Usage: notify <message> [title]" >&2; return 1; }
        notify-send "${2:-Terminal}" "$1"
    }
else
    # Fallback: terminal bell + formatted print
    notify() {
        [[ $# -eq 0 ]] && { echo "Usage: notify <message> [title]" >&2; return 1; }
        echo -e "\a\033[1;33m==> ${2:-Terminal}:\033[0m $1"
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