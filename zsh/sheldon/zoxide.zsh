# ===============================
# ZOXIDE - Smart Directory Navigation
# ===============================

# Initialize zoxide directly (~1.3ms, negligible cost for working completion)
if [[ -n $commands[zoxide] ]]; then
  eval "$(zoxide init zsh --hook prompt)"
fi
