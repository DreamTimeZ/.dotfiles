# ===============================
# PROCESS MANAGEMENT FUNCTIONS
# ===============================

# fp: Interactive process killer using fzf.
# By default, it sends SIGTERM to the selected process(es).
# Options:
#   -f           : Force kill (defaults to SIGKILL unless -s is provided).
#   -s signal    : Specify a custom signal (e.g., HUP, INT, etc.).
#
# Usage examples:
#   fp         # Uses SIGTERM.
#   fp -f      # Uses SIGKILL.
#   fp -s HUP  # Uses SIGHUP.
fp() {
  local signal="TERM"
  local force=0

  # Parse command-line options.
  while getopts ":fs:" opt; do
    case $opt in
      f)
        force=1
        ;;
      s)
        signal="$OPTARG"
        ;;
      *)
        echo "Usage: fp [-f] [-s signal]" >&2
        return 1
        ;;
    esac
  done
  shift $((OPTIND - 1))

  # If the force flag is used and no custom signal is specified, override to SIGKILL.
  if (( force )); then
    [[ "$signal" == "TERM" ]] && signal="KILL"
  fi

  # Check that fzf is installed.
  if ! command -v fzf >/dev/null 2>&1; then
    echo "Error: fzf is required but not installed." >&2
    return 1
  fi

  # List processes using ps aux, skip header with tail, and pipe to fzf.
  # Optional: You can add a preview to show more details for the highlighted process.
  local selection
  selection=$(ps aux | tail -n +2 | fzf --multi \
    --header="Select process(es) to kill with signal SIG$signal (TAB to select, ENTER to confirm)" \
    --preview 'ps -fp $(echo {} | awk "{print \$2}")') || return 1

  # If no selection was made, exit.
  if [[ -z "$selection" ]]; then
    echo "No process selected."
    return 1
  fi

  # Extract the PID (second column) from the selected lines using awk.
  local pids=($(echo "$selection" | awk '{print $2}'))

  # Confirm action and send the kill signal.
  echo "Killing process(es): ${pids[*]} with signal SIG$signal"
  kill -s "$signal" "${pids[@]}" || {
    echo "Error: Failed to kill some processes." >&2
    return 1
  }
}

# Fuzzy search through shell history
fh() {
    fc -l 1 | fzf | sed 's/^[ \t]*//' | while read -r cmd; do
        print -z "$cmd"
    done
} 