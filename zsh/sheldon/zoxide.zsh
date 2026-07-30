# ===============================
# ZOXIDE - Smart Directory Navigation
# ===============================

if zdotfiles_has_command zoxide; then
  zdotfiles_source_cached zoxide "$commands[zoxide]" -- zoxide init zsh --hook prompt
fi
