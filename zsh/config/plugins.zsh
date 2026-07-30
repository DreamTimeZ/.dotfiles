# ===============================
# PLUGIN MANAGER: Sheldon
# ===============================
if zdotfiles_has_command sheldon; then
  # `sheldon source` only re-emits source lines for the locked plugin set, so the
  # ~6ms spawn is cached and invalidated by the binary, the config and the lock.
  zdotfiles_source_cached sheldon \
    "$commands[sheldon]" \
    "${SHELDON_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/sheldon}/plugins.toml" \
    "${SHELDON_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/sheldon}/plugins.lock" \
    -- sheldon source
fi
