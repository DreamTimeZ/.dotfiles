# Atuin shell history replacement with config management
{
  # Early exit if atuin not available
  zdotfiles_has_command atuin || return 0
  
  # Setup config symlink if needed
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/atuin"
  local dotfiles_config="${ZDOTFILES_CONFIG_DIR:-$HOME/.dotfiles/zsh/config}/atuin/config.toml"
  
  if [[ -f "$dotfiles_config" && ! -L "$config_dir/config.toml" ]]; then
    mkdir -p "$config_dir"
    ln -sf "$dotfiles_config" "$config_dir/config.toml"
  fi
  
  # Initialize atuin with zsh integration
  eval "$(atuin init zsh --disable-up-arrow)"
}