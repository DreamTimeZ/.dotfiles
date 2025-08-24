# Atuin shell history replacement with config management
{
  # Early exit if atuin not available
  command -v atuin >/dev/null || return 0
  
  # Setup config symlink if needed
  local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}/atuin"
  local dotfiles_config="$HOME/.dotfiles/zsh/config/atuin/config.toml"
  
  if [[ -f "$dotfiles_config" && ! -L "$config_dir/config.toml" ]]; then
    mkdir -p "$config_dir"
    ln -sf "$dotfiles_config" "$config_dir/config.toml"
  fi
  
  # Initialize atuin with zsh integration
  eval "$(atuin init zsh --disable-up-arrow)"
}