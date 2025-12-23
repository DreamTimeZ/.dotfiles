# ===============================
# TMUX DEV SESSION
# ===============================

# Start or attach to dev tmux session with configurable pane grid
dev() {
  zdotfiles_has_command tmux || { print -u2 "dev: tmux not found"; return 1; }

  local session="dev" cmd="" grid=""
  local -i rows=1 cols=2
  local -a pos

  # Parse options (allows: dev 2x2 -n work --cmd htop ~/project)
  while (( $# )); do
    case "$1" in
      -h|--help)
        cat <<'EOF'
Usage: dev [options] [grid] [path]

Grid:  N     N horizontal panes    (e.g., 3)
       RxC   R rows × C columns   (e.g., 2x3)

Options:
  -n <name>       Session name (default: dev)
  --cmd <command> Run command in all panes
  -x              Kill session
  -h              Show this help

Attaches to existing session if found. Use -n for parallel sessions.

Examples:
  dev             2 panes side-by-side
  dev 3           3 horizontal panes
  dev 2x2         4 panes (2×2)
  dev 2x3 --cmd htop
  dev -n work 2x2 ~/project
EOF
        return 0 ;;
      -n) session="${2:?dev: -n requires a name}"; shift 2 ;;
      --cmd) cmd="${2:?dev: --cmd requires a command}"; shift 2 ;;
      -x)
        tmux kill-session -t "$session" 2>/dev/null && print "Session '$session' killed" || print "No session '$session'"
        return 0 ;;
      -*) print -u2 "dev: unknown option '$1'"; return 1 ;;
      *) pos+=("$1"); shift ;;
    esac
  done

  # Parse positional args: [grid] [path]
  if [[ "${pos[1]}" =~ ^[1-6](x[1-6])?$ ]]; then
    grid="${pos[1]}"
    if [[ "$grid" == *x* ]]; then
      rows=${grid%x*} cols=${grid#*x}
    else
      rows=1 cols=$grid
    fi
    set -- "${pos[2]:-}"
  else
    set -- "${pos[1]:-}"
  fi

  (( rows * cols > 12 )) && { print -u2 "dev: max 12 panes"; return 1; }

  # Resolve path
  local dir="${1:-$(git rev-parse --show-toplevel 2>/dev/null || print -n $PWD)}"
  dir="${dir:A}"
  [[ -d "$dir" ]] || { print -u2 "dev: invalid path '$1'"; return 1; }

  # Attach if session exists
  if tmux has-session -t "$session" 2>/dev/null; then
    _dev_attach "$session"; return
  fi

  # Create session
  tmux new-session -d -s "$session" -c "$dir" || { print -u2 "dev: failed to create session"; return 1; }

  local win="${session}:${$(tmux list-windows -t "$session" -F '#{window_index}')[1]}"

  # Build grid
  if (( cols > 1 || rows > 1 )); then
    _dev_build_grid "$win" "$dir" "$rows" "$cols" || {
      tmux kill-session -t "$session" 2>/dev/null
      print -u2 "dev: failed to build grid"; return 1
    }
  fi

  # Wait for all shells to be ready (poll instead of fixed sleep)
  _dev_wait_for_shells "$win"

  # Clear scrollback + screen for each pane (fixes resize-induced blank lines)
  for p in ${(f)"$(tmux list-panes -t "$win" -F '#{pane_id}')"}; do
    tmux clear-history -t "$p"
    tmux send-keys -t "$p" C-l
    [[ -n "$cmd" ]] && tmux send-keys -t "$p" "$cmd" Enter
  done

  tmux select-pane -t "${win}.{top-left}" 2>/dev/null
  _dev_attach "$session"
}

# Build grid of panes (don't use 'path' - tied to PATH in zsh)
_dev_build_grid() {
  local win="$1" dir="$2"
  local -i rows="$3" cols="$4" i
  local pane_id

  # Create columns: split first pane (by ID) to avoid "no space" on shrinking current pane
  for (( i = 1; i < cols; i++ )); do
    pane_id=${$(tmux list-panes -t "$win" -F '#{pane_id}')[1]}
    tmux split-window -t "$pane_id" -h -c "$dir" || return 1
    tmux select-layout -t "$win" even-horizontal
  done

  # Create rows: use tiled for grids (even-vertical disrupts grid layout)
  if (( rows > 1 )); then
    local -a panes=( ${(f)"$(tmux list-panes -t "$win" -F '#{pane_id}')"} )
    for p in "${panes[@]}"; do
      for (( i = 1; i < rows; i++ )); do
        tmux split-window -t "$p" -v -c "$dir" || return 1
        (( cols > 1 )) && tmux select-layout -t "$win" tiled || tmux select-layout -t "$win" even-vertical
      done
    done
  fi
}

# Wait for all panes to have an idle shell (max 2s)
_dev_wait_for_shells() {
  local win="$1"
  local -a cmds
  local -i attempts=0 ready

  while (( attempts < 20 )); do
    cmds=( ${(f)"$(tmux list-panes -t "$win" -F '#{pane_current_command}')"} )
    ready=0
    for c in "${cmds[@]}"; do
      [[ "$c" == (zsh|bash|fish|sh) ]] && (( ready++ ))
    done
    (( ready == ${#cmds[@]} )) && return 0
    sleep 0.1
    (( attempts++ ))
  done
}

# Attach or switch to session (grouped if already attached elsewhere)
_dev_attach() {
  read -t 0 -s -k 10000 2>/dev/null  # Discard pending terminal responses

  if [[ -n "$TMUX" ]]; then
    tmux switch-client -t "$1"
  else
    local sessions=$(tmux list-sessions -F '#{session_name}:#{session_attached}' 2>/dev/null)
    local attached=${${(M)${(f)sessions}:#$1:*}#*:}
    (( attached )) && tmux new-session -t "$1" || tmux attach-session -t "$1"
  fi
}
