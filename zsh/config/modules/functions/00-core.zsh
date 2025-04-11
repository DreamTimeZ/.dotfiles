# ===============================
# UTILITY FUNCTIONS
# ===============================

# Send desktop notification
notify() {
  terminal-notifier -title "iTerm2" -message "$1"
}

# Retry a command until it succeeds
retry() {
  local cmd="$@"
  until $cmd; do
    echo "Retrying in 2s..."
    sleep 2
  done
} 