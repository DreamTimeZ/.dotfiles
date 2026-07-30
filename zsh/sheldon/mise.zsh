# ===============================
# MISE - Dev Tool Manager
# ===============================
# Activates mise for per-directory PATH, env vars, and hooks.
# Global config: ~/.config/mise/config.toml
# Project config: mise.toml per repo

if zdotfiles_has_command mise; then
  # `mise activate zsh` is only static when mise is not already active: with
  # __MISE_DIFF in the environment (exec zsh, nested shells, tmux panes) it
  # prepends a literal `export PATH=<snapshot>` deactivation line, which caching
  # would freeze into every later shell and wipe .zprofile's PATH entries. Scrub
  # that state so the emitted script stays relocatable. This removes the ~6ms
  # spawn; the per-shell `mise hook-env` inside the template still runs.
  zdotfiles_source_cached mise "$commands[mise]" -- \
    env -u __MISE_DIFF -u __MISE_SESSION -u __MISE_ORIG_PATH -u MISE_SHELL \
        "$commands[mise]" activate zsh
fi
