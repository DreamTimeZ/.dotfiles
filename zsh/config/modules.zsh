# ===============================
# ZSH MODULES LOADER
# ===============================
# This is a centralized module loader that handles loading all
# ZSH extensions based on a clean, convention-based directory structure:
#
# modules/
# ├── functions/  - User-defined shell functions
# ├── plugins/    - Plugin/tool configurations
# └── lib/        - Library code (optional, for future use)

# Ensure we have the current directory where this script resides
typeset -g ZDOTFILES_MODULES_BASE="${0:A:h}/modules"

# ===============================
# HELPER FUNCTIONS
# ===============================

# Validate directory exists and is readable
zdotfiles_validate_dir() {
  [[ -d "$1" && -r "$1" ]] && return 0 || return 1
}

# Helper to load all .zsh files in a directory with error handling
zdotfiles_load_dir() {
  local dir="$1"
  
  if ! zdotfiles_validate_dir "$dir"; then
    return 1
  fi
  
  # First load all numerically-prefixed files in order (00-99)
  for module in "$dir"/[0-9][0-9]-*.zsh(N.on); do
    source "$module" 2>/dev/null
  done
  
  # Load any remaining modules without numerical prefix
  for module in "$dir"/*.zsh(N); do
    # Skip if file has a numerical prefix (already loaded)
    if [[ ! "$(basename "$module")" =~ ^[0-9][0-9]- ]]; then
      source "$module" 2>/dev/null
    fi
  done
  
  return 0
}

# ===============================
# MAIN LOADING PROCESS
# ===============================

# 1. Load function modules (utilities)
zdotfiles_load_dir "$ZDOTFILES_MODULES_BASE/functions"

# 2. Load any future module types (example: lib)
# zdotfiles_load_dir "$ZDOTFILES_MODULES_BASE/lib" "library"

# 3. Use local module overrides if they exist
zdotfiles_load_dir "$ZDOTFILES_MODULES_BASE/local"

# Don't expose loader internals
unset -f zdotfiles_load_dir zdotfiles_validate_dir 