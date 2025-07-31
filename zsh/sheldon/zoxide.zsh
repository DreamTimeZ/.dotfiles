# Zoxide lazy-loading with immediate completion support
{
  # Early exit if zoxide not available
  command -v zoxide >/dev/null || return 0
  
  # Placeholder completion to prevent errors before lazy-load
  [[ -o zle ]] && {
    __zoxide_z_complete() { return 1 }  # No completion until loaded
    (( ${+functions[compdef]} )) && compdef __zoxide_z_complete z
  }
  
  # Initialize zoxide (called on first use)
  _zdot_init() {
    unfunction z zi __zoxide_z_complete 2>/dev/null
    eval "$(zoxide init zsh --hook prompt)" && "$1" "${@:2}"
  }
  
  # Create lazy-loaded functions
  if (( ${+functions[zdotfiles_lazy_load]} )); then
    zdotfiles_lazy_load z '_zdot_init z'
    zdotfiles_lazy_load zi '_zdot_init zi'
  else
    z() { _zdot_init z "$@" }
    zi() { _zdot_init zi "$@" }
  fi
}