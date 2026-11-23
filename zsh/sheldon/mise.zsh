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
  # that state so the emitted script stays relocatable. mise 2026.11.11 also embeds
  # PATH snapshots: `__MISE_ORIG_PATH='...'` while that variable is unset, and a shims
  # `PATH='...'` under activate_shims. Setting the one and disabling the other leaves the
  # template's runtime guard to assign __MISE_ORIG_PATH, and hook-env still adds the
  # shims after the install dirs. Top-level shells get the PATH of an uncached eval,
  # nested shells keep the inherited order, where an uncached eval put the shims first
  # (checked 2026-11-23). This removes the ~13.5ms spawn, the per-shell `mise hook-env`
  # inside the template still runs.
  zdotfiles_source_cached mise "$commands[mise]" -- \
    env -u __MISE_DIFF -u __MISE_SESSION -u MISE_SHELL \
        __MISE_ORIG_PATH="$PATH" MISE_ACTIVATE_SHIMS=false \
        "$commands[mise]" activate zsh
fi
