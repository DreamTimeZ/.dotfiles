# ===============================
# ZSH CONFIGURATION HELPERS
# ===============================
# Central place for helper functions used throughout the zsh configuration system

# ----- Constants and Defaults -----
# Cache for frequently used values
typeset -g ZDOTFILES_PLATFORM=""  # Will be set on first use
typeset -gA ZDOTFILES_CMD_CACHE   # Command existence cache
ZDOTFILES_CMD_CACHE=()            # Clear on re-source to detect newly installed tools

# ----- Logging Helpers -----

# Print informational message (blue) - only if log level is info or higher
zdotfiles_info() {
  [[ $ZDOTFILES_LOG_LEVEL -ge 3 ]] && echo -e "\033[1;34m==>\033[0m \033[1m$*\033[0m"
  return 0
}

# Print warning message (yellow) - only if log level is warn or higher
zdotfiles_warn() {
  [[ $ZDOTFILES_LOG_LEVEL -ge 2 ]] && echo -e "\033[1;33m==>\033[0m \033[1m$*\033[0m"
  return 0
}

# Print error message (red) - only if log level is error or higher
zdotfiles_error() {
  [[ $ZDOTFILES_LOG_LEVEL -ge 1 ]] && echo -e "\033[1;31m==>\033[0m \033[1m$*\033[0m"
  return 0
}

# ----- Path Management Helpers -----

# Add directory to end of PATH without duplicates
# Usage: zdotfiles_path_append /path/to/directory
# Returns: 0 on success, 1 if directory doesn't exist
zdotfiles_path_append() {
  [[ ! -d "$1" ]] && zdotfiles_error "Cannot add non-existent directory to PATH: $1" && return 1
  
  local dir="$1"
  # Remove existing occurrence first (prevent duplicates)
  PATH=":$PATH:"; PATH="${PATH//:$dir:/:}"; PATH="${PATH#:}"; PATH="${PATH%:}"
  
  export PATH="$PATH:$dir"
  zdotfiles_info "Added to PATH: $dir"
  return 0
}

# Add directory to beginning of PATH without duplicates
# Usage: zdotfiles_path_prepend /path/to/directory
# Returns: 0 on success, 1 if directory doesn't exist
zdotfiles_path_prepend() {
  [[ ! -d "$1" ]] && zdotfiles_error "Cannot add non-existent directory to PATH: $1" && return 1
  
  local dir="$1"
  # Remove existing occurrence first (prevent duplicates)
  PATH=":$PATH:"; PATH="${PATH//:$dir:/:}"; PATH="${PATH#:}"; PATH="${PATH%:}"
  
  export PATH="$dir:$PATH"
  zdotfiles_info "Prepended to PATH: $dir"
  return 0
}

# ----- System Detection Helpers -----

# Check if a command exists in PATH with caching
# Usage: if zdotfiles_has_command git; then ...; fi
# Returns: 0 if command exists, 1 otherwise
zdotfiles_has_command() {
  [[ -z "$1" ]] && return 1

  local cmd="$1"

  # Ensure cache is associative (guards against loss of type in subshells,
  # re-source edge cases, or emulation mode changes by plugins)
  if [[ ${(t)ZDOTFILES_CMD_CACHE} != association* ]]; then
    zdotfiles_warn "ZDOTFILES_CMD_CACHE lost associative type (was: ${(t)ZDOTFILES_CMD_CACHE:-unset}), re-initializing"
    typeset -gA ZDOTFILES_CMD_CACHE=()
  fi

  # Check cache first
  if [[ -n "${ZDOTFILES_CMD_CACHE[$cmd]:-}" ]]; then
    return "${ZDOTFILES_CMD_CACHE[$cmd]}"
  fi

  # Use native zsh $commands hash table (9x faster than command -v)
  if [[ -n $commands[$cmd] ]]; then
    ZDOTFILES_CMD_CACHE[$cmd]=0
    return 0
  else
    ZDOTFILES_CMD_CACHE[$cmd]=1
    return 1
  fi
}

# Detect operating system platform - with caching
# Usage: platform=$(zdotfiles_detect_platform)
# Returns: String with platform name (macos, linux, wsl, bsd, windows, unknown)
zdotfiles_detect_platform() {
  # Use cached value if available
  [[ -n "$ZDOTFILES_PLATFORM" ]] && echo "$ZDOTFILES_PLATFORM" && return 0

  # Detect platform and cache it
  local platform
  case "$OSTYPE" in
    darwin*)  platform="macos" ;;
    linux*)
      # Distinguish WSL from native Linux
      if [[ -n "$WSL_DISTRO_NAME" || -n "$WSL_INTEROP" ]]; then
        platform="wsl"
      else
        platform="linux"
      fi
      ;;
    bsd*)     platform="bsd" ;;
    msys*|cygwin*)  platform="windows" ;;
    *)        platform="unknown" ;;
  esac

  # Cache the result
  ZDOTFILES_PLATFORM="$platform"
  echo "$platform"
  return 0
}

# Check if running on macOS (uses cached platform value)
# Usage: if zdotfiles_is_macos; then ...; fi
# Returns: 0 if on macOS, 1 otherwise
zdotfiles_is_macos() {
  [[ -z "$ZDOTFILES_PLATFORM" ]] && zdotfiles_detect_platform >/dev/null
  [[ "$ZDOTFILES_PLATFORM" == "macos" ]]
  return $?
}

# Check if running on Linux (uses cached platform value)
# Usage: if zdotfiles_is_linux; then ...; fi
# Returns: 0 if on Linux, 1 otherwise
zdotfiles_is_linux() {
  [[ -z "$ZDOTFILES_PLATFORM" ]] && zdotfiles_detect_platform >/dev/null
  [[ "$ZDOTFILES_PLATFORM" == "linux" ]]
  return $?
}

# Check if running on WSL (Windows Subsystem for Linux)
# Usage: if zdotfiles_is_wsl; then ...; fi
# Returns: 0 if on WSL, 1 otherwise
zdotfiles_is_wsl() {
  [[ -z "$ZDOTFILES_PLATFORM" ]] && zdotfiles_detect_platform >/dev/null
  [[ "$ZDOTFILES_PLATFORM" == "wsl" ]]
  return $?
}

# ----- Lazy Loading Helpers -----

# Minimal overhead lazy loading - matches original performance
# Usage: zdotfiles_lazy_load INIT_FUNC COMMANDS...
zdotfiles_lazy_load() {
  local init_func=$1
  shift
  local all_cmds="$*"

  # Create wrappers for each command
  local cmd
  for cmd; do
    eval "$cmd() {
      for c in $all_cmds; do
        (( \$+functions[\$c] )) && unfunction \$c
      done
      $init_func && rehash
      $cmd \"\$@\"
    }"
  done
}

# ----- Function Export -----
# Export functions for use in subshells and modules
{
  # List of public functions to export
  local public_funcs=(
    zdotfiles_info
    zdotfiles_warn
    zdotfiles_error
    zdotfiles_path_append
    zdotfiles_path_prepend
    zdotfiles_has_command
    zdotfiles_detect_platform
    zdotfiles_is_macos
    zdotfiles_is_linux
    zdotfiles_is_wsl
    zdotfiles_lazy_load
  )
  
  # Export each function
  local func
  for func in "${public_funcs[@]}"; do
    typeset -gf "$func"
  done
} &>/dev/null

# Don't export this helper file's local variables
unset func public_funcs 