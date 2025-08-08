# ===============================
# ASDF VERSION MANAGER
# ===============================

# Define managed tools (customize this list based on what you actually use)
typeset -ga _asdf_managed_tools=(
  # Python tools
  python python3 pip pip3
  # Java tools
  java javac mvn gradle
)

# Define the asdf initialization function
_init_asdf() {
  # Find asdf install location - checking fastest paths first
  local script=""
  local asdf_locations=(
    "/opt/homebrew/opt/asdf/libexec/asdf.sh"    # Apple Silicon Homebrew
    "/usr/local/opt/asdf/libexec/asdf.sh"       # Intel Homebrew
    "$HOME/.asdf/asdf.sh"                       # Manual installation
  )
  
  # Fast path: check common locations directly
  for location in "${asdf_locations[@]}"; do
    if [[ -f "$location" ]]; then
      script="$location"
      export ASDF_DIR="${location:0:${#location}-8}" # Remove "/asdf.sh"
      break
    fi
  done
  
  # Slow path (fallback): use brew only if necessary
  if [[ -z "$script" ]] && command -v brew >/dev/null 2>&1; then
    local prefix="$(brew --prefix asdf 2>/dev/null)"
    if [[ -n "$prefix" && -f "$prefix/libexec/asdf.sh" ]]; then
      script="$prefix/libexec/asdf.sh"
      export ASDF_DIR="$prefix/libexec"
    fi
  fi
  
  # Source asdf if found
  if [[ -n "$script" ]]; then
    source "$script"
    return 0
  else
    echo "Error: asdf not found" >&2
    return 1
  fi
}

# Check if helper function is available
if typeset -f zdotfiles_lazy_load > /dev/null; then
  # Use the central helper function for asdf
  zdotfiles_lazy_load asdf '_init_asdf'
  
  # Also lazy-load each managed tool
  for cmd in "${_asdf_managed_tools[@]}"; do
    # Only create wrapper if command doesn't already exist
    if ! command -v "$cmd" >/dev/null 2>&1; then
      zdotfiles_lazy_load "$cmd" '_init_asdf'
    fi
  done
else
  # Fallback to direct implementation
  function asdf() {
    unfunction asdf
    _init_asdf
    command asdf "$@"
  }
  
  # Set up lazy loading for managed tools
  for cmd in "${_asdf_managed_tools[@]}"; do
    # Only create wrapper if command doesn't already exist
    if ! command -v "$cmd" >/dev/null 2>&1; then
      eval "function $cmd() {
        unfunction '$cmd' 2>/dev/null
        _init_asdf
        $cmd \"\$@\"
      }"
    fi
  done
fi

# No other code executed during startup