# ===============================
# ZOXIDE - Smart Directory Navigation
# ===============================

# Initialize zoxide directly (~1.3ms, negligible cost for working completion)
if zdotfiles_has_command zoxide; then
  eval "$(zoxide init zsh --hook prompt)"
fi
