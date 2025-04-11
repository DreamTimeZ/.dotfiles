# ===============================
# ASDF VERSION MANAGER
# ===============================
# Lazy-loading implementation for asdf

# Cache the brew prefix for better performance
export ASDF_DIR=""

# Initialize ASDF_DIR only if we haven't already
_init_asdf_dir() {
  [[ -n "$ASDF_DIR" ]] && return
  
  # First try standard homebrew location
  if [[ -d "/opt/homebrew/opt/asdf/libexec" ]]; then
    ASDF_DIR="/opt/homebrew/opt/asdf/libexec"
    return
  fi
  
  # Then try Apple Silicon homebrew location
  if [[ -d "/usr/local/opt/asdf/libexec" ]]; then
    ASDF_DIR="/usr/local/opt/asdf/libexec"
    return
  fi
  
  # Only call brew as a last resort (expensive)
  if command -v brew &>/dev/null; then
    local prefix=$(brew --prefix asdf 2>/dev/null)
    [[ -d "$prefix/libexec" ]] && ASDF_DIR="$prefix/libexec"
  fi
}

# Define a wrapper function for asdf that will load asdf only when needed
function asdf() {
  # Initialize ASDF_DIR if not already done
  _init_asdf_dir
  
  # Remove this wrapper function
  unfunction asdf
  
  if [[ -f "$ASDF_DIR/asdf.sh" ]]; then
    source "$ASDF_DIR/asdf.sh"
    # Execute the command that was passed to this function
    command asdf "$@"
  else
    echo "asdf not found. Please install asdf." >&2
    return 1
  fi
}

# Add lazy loading for common asdf-managed commands
for cmd in node npm yarn pnpm ruby gem bundle rails python pip pip3 php composer go java mvn gradle; do
  if ! command -v $cmd >/dev/null 2>&1; then
    eval "function $cmd() { unfunction $cmd; asdf; command $cmd \"\$@\"; }"
  fi
done