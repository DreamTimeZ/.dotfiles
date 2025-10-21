# ===============================
# ZSH SHELL CONFIGURATION
# ===============================

# ------ Powerlevel10k Instant Prompt ------
# Enable Powerlevel10k instant prompt. Should stay at the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------ Base Configuration ------
# Define configuration directories with fallbacks (export for subprocesses)
export ZDOTFILES_DIR="${ZDOTFILES_DIR:-$HOME/.dotfiles}"
export ZDOTFILES_CONFIG_DIR="${ZDOTFILES_CONFIG_DIR:-$ZDOTFILES_DIR/zsh/config}"
export ZDOTFILES_MODULES_DIR="${ZDOTFILES_MODULES_DIR:-$ZDOTFILES_CONFIG_DIR/modules}"
export ZDOTFILES_LOG_LEVEL="${ZDOTFILES_LOG_LEVEL:-1}"  # 0=silent, 1=error, 2=warn, 3=info

# ------ Load Core Helper Functions ------
# Load helpers first to make functions available to other files
if [[ -r "$ZDOTFILES_CONFIG_DIR/helpers.zsh" ]]; then
  source "$ZDOTFILES_CONFIG_DIR/helpers.zsh"
else
  echo "Error: Failed to load helper functions" >&2
  return 1
fi

# ------ Configuration Files Management ------
# Static list of configuration files to load in order
_CONFIG_FILES=(
  "exports.zsh"     # Environment variables and options
  "plugins.zsh"     # Plugin initialization
  "modules.zsh"     # Modular function and plugin system
  "keybindings.zsh" # Custom key bindings (after plugins)
  "aliases.zsh"     # Command aliases
)

# Load each config file directly
for _config_file in "${_CONFIG_FILES[@]}"; do
  _full_path="$ZDOTFILES_CONFIG_DIR/$_config_file"
  if [[ -r "$_full_path" ]]; then
    zdotfiles_info "Loading $_config_file"
    source "$_full_path"
  else
    zdotfiles_warn "Could not load $_config_file"
  fi
done

# ------ WSL Path Cleanup ------
# Aggressively remove Windows paths for faster command lookups
# Windows filesystem access from WSL adds 10-100ms overhead per lookup
# NOTE: Must run AFTER plugins load (plugins might add Windows paths)
if [[ -n "$WSL_DISTRO_NAME" ]] || [[ -n "$WSL_INTEROP" ]]; then
  # Keep only Linux paths, remove all /mnt/c paths
  export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "^/mnt/c" | tr '\n' ':' | sed 's/:$//')

  # Optional: Add back specific Windows tools if needed (uncomment as needed)
  # export PATH="$PATH:/mnt/c/Windows/System32"
fi

# ------ Prompt Configuration ------
# Powerlevel10k configuration
if [[ -f ~/.p10k.zsh ]]; then
  source ~/.p10k.zsh
else
  # Fallback prompt if p10k is not configured
  PROMPT='%F{blue}%n@%m:%~%f$ '
  zdotfiles_warn "p10k configuration not found, using fallback prompt"
fi