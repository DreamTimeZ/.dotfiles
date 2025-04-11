# ===============================
# ZSH CONFIGURATION HELPERS
# ===============================
# Central place for helper functions used throughout the zsh configuration system

# ----- Constants and Defaults -----
# Define these at the top for easy configuration
typeset -g ZDOTFILES_LOG_LEVEL=${ZDOTFILES_LOG_LEVEL:-1}  # 0=silent, 1=error, 2=warn, 3=info
typeset -g ZDOTFILES_STARTUP_SILENT=${ZDOTFILES_STARTUP_SILENT:-1}  # 1=suppress logs during startup

# Cache for frequently used values
typeset -g ZDOTFILES_PLATFORM=""  # Will be set on first use

# ----- Logging Helpers -----

# Check if logging should be suppressed during startup
# Returns: 0 if should suppress, 1 otherwise
_zdotfiles_should_suppress_log() {
  [[ $ZDOTFILES_STARTUP_SILENT -eq 1 && -n "$POWERLEVEL9K_INSTANT_PROMPT" ]] && return 0
  return 1
}

# Print informational message (blue) - only if log level is info or higher
zdotfiles_info() { 
  _zdotfiles_should_suppress_log && return 0
  [[ $ZDOTFILES_LOG_LEVEL -ge 3 ]] && echo -e "\033[1;34m==>\033[0m \033[1m$*\033[0m"
  return 0
}

# Print warning message (yellow) - only if log level is warn or higher
zdotfiles_warn() { 
  _zdotfiles_should_suppress_log && return 0
  [[ $ZDOTFILES_LOG_LEVEL -ge 2 ]] && echo -e "\033[1;33m==>\033[0m \033[1m$*\033[0m"
  return 0
}

# Print error message (red) - only if log level is error or higher
zdotfiles_error() { 
  _zdotfiles_should_suppress_log && return 0
  [[ $ZDOTFILES_LOG_LEVEL -ge 1 ]] && echo -e "\033[1;31m==>\033[0m \033[1m$*\033[0m"
  return 0
}

# ----- Path Management Helpers -----

# Add directory to end of PATH without duplicates
# Usage: zdotfiles_path_append /path/to/directory
# Returns: 0 on success, 1 if directory doesn't exist
zdotfiles_path_append() {
  [[ ! -d "$1" ]] && zdotfiles_error "Cannot add non-existent directory to PATH: $1" && return 1
  
  # Path check using parameter expansion
  [[ ":$PATH:" == *":$1:"* ]] && return 0
  
  export PATH="$PATH:$1"
  zdotfiles_info "Added to PATH: $1"
  return 0
}

# Add directory to beginning of PATH without duplicates
# Usage: zdotfiles_path_prepend /path/to/directory
# Returns: 0 on success, 1 if directory doesn't exist
zdotfiles_path_prepend() {
  [[ ! -d "$1" ]] && zdotfiles_error "Cannot add non-existent directory to PATH: $1" && return 1
  
  # Path check using parameter expansion
  [[ ":$PATH:" == *":$1:"* ]] && return 0
  
  export PATH="$1:$PATH"
  zdotfiles_info "Prepended to PATH: $1"
  return 0
}

# ----- System Detection Helpers -----

# Check if a command exists in PATH
# Usage: if zdotfiles_has_command git; then ...; fi
# Returns: 0 if command exists, 1 otherwise
zdotfiles_has_command() {
  [[ -z "$1" ]] && return 1
  command -v "$1" &>/dev/null
  return $?
}

# Detect operating system platform - with caching
# Usage: platform=$(zdotfiles_detect_platform)
# Returns: String with platform name (macos, linux, bsd, windows, unknown)
zdotfiles_detect_platform() {
  # Use cached value if available
  [[ -n "$ZDOTFILES_PLATFORM" ]] && echo "$ZDOTFILES_PLATFORM" && return 0
  
  # Detect platform and cache it
  local platform
  case "$OSTYPE" in
    darwin*)  platform="macos" ;;
    linux*)   platform="linux" ;;
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

# ----- Function Export -----
# Export functions without displaying their definitions
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
  )
  
  # Export each function
  local func
  for func in "${public_funcs[@]}"; do
    typeset -g -f "$func" &>/dev/null
  done
  
  # Keep internal functions hidden
  typeset -g +f _zdotfiles_should_suppress_log &>/dev/null
} &>/dev/null

# Don't export this helper file's local variables
unset func public_funcs 