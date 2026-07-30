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
  [[ $ZDOTFILES_LOG_LEVEL -ge 3 ]] && echo -e "\033[1;34m==>\033[0m \033[1m$*\033[0m" >&2
  return 0
}

# Print warning message (yellow) - only if log level is warn or higher
zdotfiles_warn() {
  [[ $ZDOTFILES_LOG_LEVEL -ge 2 ]] && echo -e "\033[1;33m==>\033[0m \033[1m$*\033[0m" >&2
  return 0
}

# Print error message (red) - only if log level is error or higher
zdotfiles_error() {
  [[ $ZDOTFILES_LOG_LEVEL -ge 1 ]] && echo -e "\033[1;31m==>\033[0m \033[1m$*\033[0m" >&2
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

  # Lazy-init: cache may not exist in snapshot-restored shells (e.g. Claude
  # Code) where functions are restored without their non-exported variables
  [[ ${(t)ZDOTFILES_CMD_CACHE} != association* ]] && typeset -gA ZDOTFILES_CMD_CACHE=()

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

# ----- Init Script Caching -----

typeset -g ZDOTFILES_INIT_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zdotfiles-init"

# Memoize an expensive `eval "$(tool init)"` to a byte-compiled cache file.
# Spawning mise/atuin/zoxide/sheldon costs ~23ms per shell; sourcing the cached
# output costs ~0.2ms. The cache is regenerated whenever any stamp file (the
# tool binary, its config) is newer than the cache, so upgrades take effect.
# Usage: zdotfiles_source_cached NAME STAMP... -- COMMAND [ARG...]
zdotfiles_source_cached() {
  local name=$1; shift

  local -a stamps
  while (( $# )) && [[ $1 != "--" ]]; do
    stamps+=("$1")
    shift
  done
  (( $# )) && shift  # discard the -- separator, if the caller supplied one
  (( $# )) || return 1

  # Non-exported global: can be missing in snapshot-restored shells, same
  # hazard guarded in zdotfiles_has_command
  [[ -n $ZDOTFILES_INIT_CACHE_DIR ]] || \
    typeset -g ZDOTFILES_INIT_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zdotfiles-init"

  local cache="$ZDOTFILES_INIT_CACHE_DIR/$name.zsh"
  local stamp stale=0
  [[ -s $cache ]] || stale=1
  for stamp in $stamps; do
    (( stale )) && break
    # A vanished stamp means the tool or its state was removed - regenerate
    # rather than trust a cache that may point at deleted files
    [[ -e $stamp ]] || { stale=1; break }
    [[ $stamp -nt $cache ]] && stale=1
  done

  if (( stale )); then
    [[ -d $ZDOTFILES_INIT_CACHE_DIR ]] || mkdir -p -- "$ZDOTFILES_INIT_CACHE_DIR" 2>/dev/null
    local generated
    generated=$("$@" 2>/dev/null) || generated=""
    [[ -n $generated ]] || return 1  # tool failed - nothing to source

    # An init script that hardcodes an absolute PATH cannot be memoized: the
    # snapshot would override PATH in every later shell. Run it uncached.
    local line unsafe=0
    for line in ${(f)generated}; do
      [[ $line == export\ PATH=* && $line != *'$PATH'* ]] && { unsafe=1; break }
    done
    if (( unsafe )); then
      eval "$generated"
      return
    fi

    # $HOST as well as $$: ~/.cache may be a shared home (cf. zsh's own compdump)
    local tmp="$cache.$HOST.$$"
    if print -r -- "$generated" >| "$tmp" 2>/dev/null; then
      mv -f -- "$tmp" "$cache"
      # -U so aliases in scope are not expanded into the compiled form
      zcompile -UR -- "$cache" 2>/dev/null
    else
      # Cache unwritable - initialize uncached from the output already captured
      rm -f -- "$tmp" 2>/dev/null
      eval "$generated"
      return
    fi
  fi

  source "$cache"
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
    zdotfiles_source_cached
  )

  # Export each function
  local func
  for func in "${public_funcs[@]}"; do
    typeset -gf "$func"
  done
} &>/dev/null

# Don't export this helper file's local variables
unset func public_funcs
