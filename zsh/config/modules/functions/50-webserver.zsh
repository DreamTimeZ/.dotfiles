# ===============================
# WEB SERVER FUNCTIONS
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