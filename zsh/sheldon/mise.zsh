# ===============================
# MISE - Runtime Version Manager
# ===============================
# Activates mise for dynamic PATH and env management per-directory.
# Handles Node, Python, pnpm, and other tools configured in ~/.config/mise/config.toml

if zdotfiles_has_command mise; then
  eval "$(mise activate zsh)"
fi
