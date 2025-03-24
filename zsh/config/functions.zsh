# ===============================
# FUNCTIONS
# ===============================

# Serve files with Node.js (using nodemon) or Python
serve() {
  # Nested helper: Print clickable URL inline using OSC 8.
  _print_clickable_url() {
    local url=$1
    printf "\e]8;;%s\e\\%s\e]8;;\e\\" "$url" "$url"
  }

  # Nested helper: Format logs by filtering out traceback blocks and colorizing output.
  _format_logs() {
    local skip=0
    while IFS= read -r line; do
      if [[ "$line" == *"Exception occurred"* || "$line" == Traceback* || "$line" == *"BrokenPipeError:"* ]]; then
        skip=1
        continue
      elif [[ $skip -eq 1 && "$line" =~ ^[[:space:]] ]]; then
        continue
      else
        skip=0
      fi

      if [[ "$line" == *"GET"* ]]; then
        print -P "%F{green}${line}%f"
      elif [[ "$line" == *"404"* || "$line" == *"Error"* ]]; then
        print -P "%F{red}${line}%f"
      else
        print "$line"
      fi
    done
  }

  # Defaults
  local mode="auto"        # 'auto' chooses node if available, else python.
  local port=8000          # Default port.
  local directory="."      # Default directory.
  local extra_opts=()

  # If the first argument is not an option, treat it as the directory.
  if [[ $# -gt 0 && $1 != -* ]]; then
    directory=$1
    shift
  fi

  # Simple option parsing for mode and port.
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m|--mode)
        if [[ -n "$2" ]]; then
          mode=$2; shift 2
        else
          echo "Missing argument for $1"; return 1
        fi
        ;;
      -p|--port)
        if [[ -n "$2" ]]; then
          port=$2; shift 2
        else
          echo "Missing argument for $1"; return 1
        fi
        ;;
      --)
        shift; extra_opts=("$@"); break
        ;;
      *)
        echo "Unknown option: $1"
        echo "Usage: serve [directory] [-m mode] [-p port] [-- extra options]"
        return 1
        ;;
    esac
  done

  # Validate port and directory.
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    echo "Error: Port must be numeric."; return 1
  fi
  if [[ ! -d "$directory" ]]; then
    echo "Error: Directory '$directory' does not exist."; return 1
  fi

  # Choose mode if set to auto.
  if [[ "$mode" == "auto" ]]; then
    if command -v nodemon >/dev/null; then
      mode="node"
    else
      mode="python"
    fi
  fi

  local url="http://localhost:$port"

  # Build a fancy banner.
  local width=65
  local inner_width=$((width - 2))  # 63 characters.
  local border=$(printf '%*s' "$inner_width" '' | tr ' ' '═')
  echo -e "\e[1;34m╔${border}╗"
  # "  Directory: " is 13 characters; field width = 63 - 13 = 50.
  printf "║  Directory: %-50s║\n" "$directory"
  # "  Mode: " is 8 characters; field width = 63 - 8 = 55.
  printf "║  Mode: %-55s║\n" "$mode"
  echo -e "╚${border}╝\e[0m"

  # Print the URL inline on the same line as "URL:".
  printf "\e[1;32mURL: \e[0m"
  _print_clickable_url "$url"
  echo ""

  # Start serving with the chosen method.
  if [[ "$mode" == "node" ]]; then
    if ! command -v nodemon >/dev/null; then
      echo "Error: nodemon is not installed."; return 1
    fi
    local cmd="npx serve \"$directory\" -l $port ${extra_opts[*]}"
    nodemon --watch "$directory" -e js,html,css --exec "$cmd"
  elif [[ "$mode" == "python" ]]; then
    if ! command -v python3 >/dev/null; then
      echo "Error: python3 is not installed."; return 1
    fi
    python3 -m http.server "$port" --directory "$directory" ${extra_opts[*]} 2>&1 | _format_logs
  else
    echo "Error: Unknown mode '$mode'. Use 'auto', 'node', or 'python'."; return 1
  fi
}

# Create a directory and navigate to it
mkcd() {
    mkdir -p "$1" && cd "$1"
}

# Show disk usage for top 10 largest directories/files
dusage() {
    du -ah . | sort -rh | head -n 10
}

# ===============================
# FZF FUNCTIONS & ALIASES
# ===============================

# Fuzzy file finder with preview (using bat if available)
ffind() {
    find . -type f | fzf --preview 'bat --style=numbers --color=always {} 2>/dev/null || cat {}'
}

# Fuzzy directory finder
fd() {
    local dir
    dir=$(find . -type d 2>/dev/null | fzf +m) && cd "$dir"
}

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

# Fuzzy Git branch switcher
fbr() {
    git branch --all | fzf --preview "git log --oneline --decorate --graph --color=always {}" | sed 's/^[* ]*//;s#remotes/[^/]*/##' | xargs git checkout
}

# Fuzzy Git file opener
fgf() {
    git ls-files | fzf --preview "bat --style=numbers --color=always {}" | xargs -r ${EDITOR:-vim}
}

# Fuzzy search through shell history
fh() {
    fc -l 1 | fzf | sed 's/^[ \t]*//' | while read -r cmd; do
        print -z "$cmd"
    done
}

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

venv() {
  # Helper: convert a path to an absolute path.
  absolute_path() {
    case "$1" in
      /*) echo "$1" ;;
      *)  echo "$(pwd)/$1" ;;
    esac
  }

  # Defaults
  local venv_dir=".venv"
  local python_bin="python3"

  # Use Homebrew's Python if available.
  if command -v brew &>/dev/null; then
    local brew_prefix
    brew_prefix="$(brew --prefix python 2>/dev/null)"
    if [ -n "$brew_prefix" ] && [ -x "$brew_prefix/bin/python3" ]; then
      python_bin="$brew_prefix/bin/python3"
    fi
  fi

  local delete_flag=false

  # Process parameters: support -n/--name, -p/--python, and the subcommand "rm"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      rm)
        delete_flag=true
        shift
        ;;
      -n|--name)
        if [[ -n "$2" ]]; then
          venv_dir="$2"
          shift 2
        else
          echo "Error: Missing argument for $1" >&2
          return 1
        fi
        ;;
      -p|--python)
        if [[ -n "$2" ]]; then
          python_bin="$2"
          shift 2
        else
          echo "Error: Missing argument for $1" >&2
          return 1
        fi
        ;;
      *)
        echo "Usage: venv [rm] [-n|--name <venv_folder>] [-p|--python <python_bin>]" >&2
        return 1
        ;;
    esac
  done

  # Handle deletion if requested.
  if $delete_flag; then
    if [ -d "$venv_dir" ]; then
      echo "Deleting virtual environment '$venv_dir'..."
      rm -rf "$venv_dir"
      echo "Deleted."
    else
      echo "Virtual environment '$venv_dir' not found."
    fi

    # Compute absolute path for proper comparison.
    local abs_venv_dir
    abs_venv_dir="$(absolute_path "$venv_dir")"

    # If the deleted venv is currently activated, deactivate it.
    if [ "$VIRTUAL_ENV" = "$abs_venv_dir" ]; then
      if command -v deactivate >/dev/null 2>&1; then
        deactivate
      else
        unset VIRTUAL_ENV
      fi
      echo "Deactivated current virtual environment."
    fi
    return 0
  fi

  # Show the Python version to be used.
  echo "Using Python: $("$python_bin" --version 2>&1)"

  # Create the venv if it doesn't exist.
  if [ ! -d "$venv_dir" ]; then
    echo "Creating virtual environment '$venv_dir'..."
    if ! "$python_bin" -m venv "$venv_dir"; then
      echo "Error: Failed to create virtual environment '$venv_dir'" >&2
      return 1
    fi
  else
    echo "Virtual environment '$venv_dir' exists."
  fi

  # Activate the venv if not already active or if the active one is missing.
  if [ -z "$VIRTUAL_ENV" ] || [ ! -d "$VIRTUAL_ENV" ]; then
    if [ -f "$venv_dir/bin/activate" ]; then
      source "$venv_dir/bin/activate"
      echo "Activated virtual environment '$venv_dir'."
    else
      echo "Error: Activate script not found in '$venv_dir/bin/activate'" >&2
      return 1
    fi
  else
    echo "Virtual environment already activated ($VIRTUAL_ENV)."
  fi
}