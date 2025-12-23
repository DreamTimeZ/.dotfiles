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
          print -u2 "Missing argument for $1"; return 1
        fi
        ;;
      -p|--port)
        if [[ -n "$2" ]]; then
          port=$2; shift 2
        else
          print -u2 "Missing argument for $1"; return 1
        fi
        ;;
      --)
        shift; extra_opts=("$@"); break
        ;;
      *)
        print -u2 "Unknown option: $1"
        print -u2 "Usage: serve [directory] [-m mode] [-p port] [-- extra options]"
        return 1
        ;;
    esac
  done

  # Validate port and directory.
  if ! [[ "$port" =~ ^[0-9]+$ ]]; then
    print -u2 "serve: port must be numeric"; return 1
  fi
  if [[ ! -d "$directory" ]]; then
    print -u2 "serve: directory '$directory' does not exist"; return 1
  fi

  # Choose mode if set to auto.
  if [[ "$mode" == "auto" ]]; then
    if zdotfiles_has_command nodemon; then
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
  print -P "%B%F{blue}╔${border}╗%f%b"
  printf "║  Directory: %-50s║\n" "$directory"
  printf "║  Mode: %-55s║\n" "$mode"
  print -P "%B%F{blue}╚${border}╝%f%b"

  # Print the URL inline on the same line as "URL:".
  print -Pn "%B%F{green}URL: %f%b"
  _print_clickable_url "$url"
  print

  # Start serving with the chosen method.
  if [[ "$mode" == "node" ]]; then
    if ! zdotfiles_has_command nodemon; then
      print -u2 "serve: nodemon is not installed"; return 1
    fi
    local cmd=(npx serve "$directory" -l "$port" ${extra_opts[@]})
    nodemon --watch "$directory" -e js,html,css --exec "${cmd[@]}"
  elif [[ "$mode" == "python" ]]; then
    if ! zdotfiles_has_command python3; then
      print -u2 "serve: python3 is not installed"; return 1
    fi
    python3 -m http.server "$port" --directory "$directory" ${extra_opts[@]} 2>&1 | _format_logs
  else
    print -u2 "serve: unknown mode '$mode' (use 'auto', 'node', or 'python')"; return 1
  fi
}