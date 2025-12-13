# ===============================
# TMUX DEV SESSION
# ===============================
# Quick development session with configurable pane layout

# Start or attach to dev tmux session
# Usage: dev -h
dev() {
  local session="dev"
  local cmd=""
  local do_exit=false
  local panes=2

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help)
        cat <<'EOF'
Usage: dev [options] [path]

Options:
  -n <name>        Session name (default: dev)
  -l <2|4>         Pane layout: 2=vertical split (default), 4=tiled grid
  -c, --cmd <cmd>  Run command in all panes
  -x, --exit       Kill session
  -h, --help       Show this help

Examples:
  dev                        # 2 panes in current dir (or git root)
  dev -c claude              # 2 panes, both running claude
  dev -l 4 ~/project         # 4 panes in ~/project
  dev -n work ~/work         # Named session "work"
  dev -x                     # Kill dev session
EOF
        return 0
        ;;
      -n)
        [[ -z "$2" ]] && { echo "dev: -n requires a name" >&2; return 1; }
        [[ "$2" =~ [.:] ]] && { echo "dev: session name cannot contain '.' or ':'" >&2; return 1; }
        session="$2"
        shift 2
        ;;
      -l)
        [[ "$2" =~ ^[24]$ ]] || { echo "dev: -l must be 2 or 4" >&2; return 1; }
        panes="$2"
        shift 2
        ;;
      -x|--exit)
        do_exit=true
        shift
        ;;
      -c|--cmd)
        [[ -z "$2" ]] && { echo "dev: -c requires a command" >&2; return 1; }
        cmd="$2"
        shift 2
        ;;
      -*)
        echo "dev: unknown option '$1' (use -h for help)" >&2
        return 1
        ;;
      *)
        break
        ;;
    esac
  done

  # Helper: attach or switch to session
  _dev_attach() {
    if [[ -n "$TMUX" ]]; then
      tmux switch-client -t "$session"
    else
      tmux attach-session -t "$session"
    fi
  }

  # Handle exit
  if [[ $do_exit == true ]]; then
    if tmux has-session -t "$session" 2>/dev/null; then
      tmux kill-session -t "$session"
      echo "Session '$session' killed"
    else
      echo "No '$session' session to kill"
    fi
    return 0
  fi

  # Resolve path (prefer git root if no path specified)
  local input_path="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
  local project_path
  project_path="$(cd "$input_path" 2>/dev/null && pwd)" || {
    echo "dev: invalid path '$input_path'" >&2
    return 1
  }

  # Attach if exists
  if tmux has-session -t "$session" 2>/dev/null; then
    _dev_attach
    return $?
  fi

  # Create session with layout (chained for performance)
  if [[ $panes -eq 4 ]]; then
    tmux new-session -d -s "$session" -c "$project_path" \; \
      split-window -h -c "$project_path" \; \
      select-layout tiled \; \
      split-window -c "$project_path" \; \
      select-layout tiled \; \
      split-window -c "$project_path" \; \
      select-layout tiled || { echo "dev: failed to create session '$session'" >&2; return 1; }
  else
    tmux new-session -d -s "$session" -c "$project_path" \; \
      split-window -h -c "$project_path" || { echo "dev: failed to create session '$session'" >&2; return 1; }
  fi

  # Select first pane (handles both pane-base-index 0 and 1)
  local win="$session:$(tmux display-message -t "$session" -p '#{window_index}')"
  tmux select-pane -t "$win.0" 2>/dev/null || tmux select-pane -t "$win.1"

  # Run command in all panes
  if [[ -n "$cmd" ]]; then
    local pane_id
    tmux list-panes -t "$win" -F '#{pane_id}' | while read -r pane_id; do
      tmux send-keys -t "$pane_id" "$cmd" Enter
    done
  fi

  _dev_attach
}
