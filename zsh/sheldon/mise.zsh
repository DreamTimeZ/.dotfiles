# ===============================
# MISE - Dev Tool Manager
# ===============================
# Activates mise for per-directory PATH, env vars, and hooks.
# Global config: ~/.config/mise/config.toml
# Project config: mise.toml per repo

if zdotfiles_has_command mise; then
  eval "$(mise activate zsh)"
fi
