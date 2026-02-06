# ===============================
# GIT FUNCTIONS
# ===============================

# Multi-repo git status scanner
# Fast implementation using fd + parallel git checks
dirty() {
    setopt LOCAL_OPTIONS NO_MONITOR NO_NOTIFY
    set +x  # Ensure xtrace is off

    local depth="" mode="default" target=""
    local -i fetch=0 verbose=0 all_flag=0
    local timeout_sec="${DIRTY_FETCH_TIMEOUT:-30}"
    local connect_timeout="${DIRTY_CONNECT_TIMEOUT:-5}"

    # Parse arguments (supports combined short flags like -afv)
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                cat <<'EOF'
Usage: dirty [OPTIONS] [PATH]

Scan directories for git repos with uncommitted changes or unpushed commits.

Options:
  -a, --all       Scan unlimited depth (default: 2 levels)
  -d, --depth N   Scan N levels deep
  -f, --fetch     Fetch remotes first (parallel, but slower)
  -p, --push      Show only repos with unpushed commits
  -u, --pull      Show only repos that need pulling (implies -f)
  -v, --verbose   Show details (changed files, commit messages)
  -h, --help      Show this help

Examples:
  dirty              Quick check current dir (2 levels deep)
  dirty -a           Scan ALL repos from home directory
  dirty -a .         Scan all depths from current directory
  dirty -af          Scan all + fetch from home
  dirty -v           Show what changed in each repo
  dirty -pv          Unpushed commits with commit messages

Environment:
  DIRTY_FETCH_TIMEOUT    Hard timeout per fetch (default: 30)
  DIRTY_CONNECT_TIMEOUT  Connection timeout for fast failure (default: 5)
EOF
                return 0
                ;;
            -a|--all) depth="unlimited"; all_flag=1; shift ;;
            -d|--depth)
                [[ "$2" =~ ^[0-9]+$ ]] || { zdotfiles_error "Depth must be a number: $2"; return 1; }
                depth="$2"; shift 2
                ;;
            -f|--fetch) fetch=1; shift ;;
            -p|--push) mode="push"; shift ;;
            -u|--pull) mode="pull"; fetch=1; shift ;;
            -v|--verbose) verbose=1; shift ;;
            -[afpuvh]*)
                local flags="${1#-}"; shift
                for (( i=0; i<${#flags}; i++ )); do
                    case "${flags:$i:1}" in
                        a) set -- "-a" "$@" ;; f) set -- "-f" "$@" ;;
                        p) set -- "-p" "$@" ;; u) set -- "-u" "$@" ;;
                        v) set -- "-v" "$@" ;; h) set -- "-h" "$@" ;;
                        *) zdotfiles_error "Unknown flag: -${flags:$i:1}"; return 1 ;;
                    esac
                done
                ;;
            -*) zdotfiles_error "Unknown option: $1 (use --help)"; return 1 ;;
            *) target="$1"; shift ;;
        esac
    done

    # Default target: ~ if -a without path, else current dir
    if [[ -z "$target" ]]; then
        (( all_flag )) && target="$HOME" || target="."
    fi

    # Validate target
    if [[ ! -d "$target" ]]; then
        if [[ ! -e "$target" ]]; then
            zdotfiles_error "Path not found: $target"
        elif [[ ! -r "$target" ]]; then
            zdotfiles_error "Permission denied: $target"
        else
            zdotfiles_error "Not a directory: $target"
        fi
        return 1
    fi

    # Warn about scanning very broad directories
    case ${target:A} in
        /|/home|/usr|/mnt) zdotfiles_warn "Scanning '${target}' may take a long time" ;;
    esac

    # Find .git directories (fd is 5-10x faster than find)
    local -a repos=()

    if (( $+commands[fd] )); then
        local -a fd_args=(--type d --hidden --no-ignore --glob '.git')
        [[ "$depth" == "unlimited" ]] || fd_args+=(--max-depth "${depth:-3}")
        # Exclude dependency/cache directories that contain many non-user repos
        fd_args+=(--exclude node_modules --exclude vendor --exclude .cache --exclude __pycache__)
        fd_args+=(--exclude '.cargo' --exclude '.npm' --exclude '.pnpm' --exclude 'target')
        fd_args+=(--exclude '.nvm' --exclude '.pyenv' --exclude '.rustup' --exclude '.local')
        fd_args+=(--exclude 'go/pkg' --exclude '.gradle' --exclude '.m2' --exclude '.gem')
        fd_args+=(--exclude '.vscode-server' --exclude '.cursor-server' --exclude '.claude' --exclude 'Library')
        fd_args+=(--exclude '.Trash' --exclude 'snap' --exclude '.var' --exclude '.cpan')
        repos=("${(@f)$(fd "${fd_args[@]}" "$target" 2>/dev/null)}")
    else
        local maxdepth=""
        [[ "$depth" == "unlimited" ]] || maxdepth="-maxdepth ${depth:-3}"
        repos=("${(@f)$(find "$target" $=maxdepth -type d -name '.git' \
            -not -path '*/node_modules/*' -not -path '*/vendor/*' \
            -not -path '*/.cache/*' -not -path '*/__pycache__/*' \
            -not -path '*/.cargo/*' -not -path '*/.npm/*' -not -path '*/.pnpm/*' \
            -not -path '*/target/*' -not -path '*/.nvm/*' -not -path '*/.pyenv/*' \
            -not -path '*/.rustup/*' -not -path '*/.local/*' -not -path '*/go/pkg/*' \
            -not -path '*/.gradle/*' -not -path '*/.m2/*' -not -path '*/.gem/*' \
            -not -path '*/.vscode-server/*' -not -path '*/.cursor-server/*' \
            -not -path '*/.claude/*' \
            -not -path '*/Library/*' -not -path '*/.Trash/*' -not -path '*/snap/*' \
            -not -path '*/.var/*' -not -path '*/.cpan/*' 2>/dev/null)}")
    fi

    (( ${#repos} )) || { echo "No git repositories found"; return 0; }

    # Parallel fetch if requested - connect timeout for fast VPN-off detection
    local -a fetch_failures=()
    if (( fetch )); then
        local failure_output
        failure_output=$(printf '%s\n' "${repos[@]}" | xargs -P 0 -I {} sh -c '
            d="${1%/}"; repo="${d%/.git}"
            # Skip repos without remotes
            git -C "$repo" remote 2>/dev/null | grep -q . || exit 0
            export GIT_SSH_COMMAND="ssh -o ConnectTimeout='"$connect_timeout"' -o BatchMode=yes"
            if command -v timeout >/dev/null 2>&1; then
                timeout '"$timeout_sec"' git -C "$repo" -c http.connectTimeout='"$connect_timeout"' fetch --quiet 2>/dev/null
                rc=$?
                [ $rc -eq 124 ] && echo "$repo	timeout"
                [ $rc -ne 0 ] && [ $rc -ne 124 ] && echo "$repo	failed"
            else
                git -C "$repo" -c http.connectTimeout='"$connect_timeout"' fetch --quiet 2>/dev/null
                [ $? -ne 0 ] && echo "$repo	failed"
            fi
        ' _ {})
        [[ -n "$failure_output" ]] && fetch_failures=("${(@f)failure_output}")
    fi

    # Parallel status checks (all repos at once)
    # Output format: REPO_PATH<TAB>STATUS_ESCAPED<TAB>AHEAD<TAB>BEHIND
    local results
    results=$(printf '%s\n' "${repos[@]}" | xargs -P 0 -I {} sh -c '
        gitdir="${1%/}"
        [ -d "$gitdir" ] || exit 0
        repo="${gitdir%/.git}"

        # Single git call: -s=short, -b=branch (includes ahead/behind)
        output=$(git -C "$repo" status -sb 2>/dev/null | head -21)
        [ -z "$output" ] && exit 0

        # First line: ## branch...upstream [ahead N, behind M]
        firstline="${output%%
*}"
        # Extract ahead/behind from first line
        ahead=0 behind=0
        case "$firstline" in
            *"[ahead "*"] "*|*"[ahead "*)
                tmp="${firstline#*\[ahead }"; ahead="${tmp%%[],]*}" ;;
        esac
        case "$firstline" in
            *"behind "*"]"*)
                tmp="${firstline#*behind }"; behind="${tmp%%]*}" ;;
        esac

        # Rest is status (skip first line, limit to 20)
        status=$(echo "$output" | tail -n +2 | head -20 | tr "\n" "\037")
        [ -z "$status" ] && status="-"

        printf "%s\t%s\t%s\t%s\n" "$repo" "$status" "$ahead" "$behind"
    ' _ {} 2>/dev/null)

    # Parse results and collect repo lists
    local -a dirty_repos=() unpushed_repos=() needs_pull_repos=()
    local -A repo_status repo_ahead  # Associative arrays for verbose lookup

    while IFS=$'\t' read -r repo status_raw ahead behind; do
        [[ -z "$repo" ]] && continue

        # Convert placeholder back to empty (see xargs comment above)
        [[ "$status_raw" == "-" ]] && status_raw=""

        # Check for uncommitted changes
        if [[ -n "$status_raw" ]]; then
            dirty_repos+=("$repo")
            repo_status[$repo]="$status_raw"
        fi

        # Check for unpushed commits
        if [[ "$ahead" =~ ^[0-9]+$ ]] && (( ahead > 0 )); then
            unpushed_repos+=("$repo")
            repo_ahead[$repo]="$ahead"
        fi

        # Check for commits to pull
        if (( fetch )) && [[ "$behind" =~ ^[0-9]+$ ]] && (( behind > 0 )); then
            needs_pull_repos+=("$repo %F{magenta}[${behind} behind]%f")
        fi
    done <<< "$results"

    # Helper: format git status output with colors
    _dirty_format_status() {
        local repo="$1"
        local status_raw="${repo_status[$repo]}"
        [[ -z "$status_raw" ]] && return
        echo "$status_raw" | tr '\037' '\n' | while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            case "${line:0:2}" in
                '??')       print -P "  %F{cyan}untracked:%f ${line:3}" ;;
                'A '*|'A'?) print -P "  %F{green}added:%f ${line:3}" ;;
                ' M'|'M '*) print -P "  %F{yellow}modified:%f ${line:3}" ;;
                ' D'|'D '*) print -P "  %F{red}deleted:%f ${line:3}" ;;
                'R '*)      print -P "  %F{magenta}renamed:%f ${line:3}" ;;
                *)          print "  ${line}" ;;
            esac
        done
    }

    # Helper: format unpushed commits
    _dirty_format_commits() {
        local repo="$1"
        git -C "$repo" log --format="%h %s" @{upstream}..HEAD 2>/dev/null | while IFS= read -r line; do
            print -P "  %F{yellow}${line%% *}%f ${line#* }"
        done
    }

    # Output based on mode
    case "$mode" in
        push)
            (( ${#unpushed_repos} )) || { echo "No unpushed commits"; return 0; }
            for repo in "${unpushed_repos[@]}"; do
                print -P "$repo %F{yellow}[${repo_ahead[$repo]} ahead]%f"
                (( verbose )) && _dirty_format_commits "$repo" && echo ""
            done
            ;;
        pull)
            (( ${#needs_pull_repos} )) || { echo "All repos up to date"; return 0; }
            for line in "${needs_pull_repos[@]}"; do print -P "$line"; done
            ;;
        *)
            local found=0
            if (( ${#dirty_repos} )); then
                print -P "%F{white}━━━ Uncommitted Changes ━━━%f"
                for repo in "${dirty_repos[@]}"; do
                    echo "$repo"
                    (( verbose )) && _dirty_format_status "$repo"
                    (( verbose )) && echo ""
                done
                found=1
            fi
            if (( ${#unpushed_repos} )); then
                (( found )) && echo ""
                print -P "%F{white}━━━ Unpushed Commits ━━━%f"
                for repo in "${unpushed_repos[@]}"; do
                    print -P "$repo %F{yellow}[${repo_ahead[$repo]} ahead]%f"
                    (( verbose )) && _dirty_format_commits "$repo" && echo ""
                done
                found=1
            fi
            if (( fetch )) && (( ${#needs_pull_repos} )); then
                (( found )) && echo ""
                print -P "%F{white}━━━ Needs Pull ━━━%f"
                for line in "${needs_pull_repos[@]}"; do print -P "$line"; done
                found=1
            fi
            (( found )) || echo "All repos clean"
            ;;
    esac

    # Show fetch failures if any
    if (( ${#fetch_failures} )); then
        echo ""
        print -P "%F{white}━━━ Unreachable ━━━%f"
        for entry in "${fetch_failures[@]}"; do
            local repo="${entry%%$'\t'*}"
            local fail_type="${entry##*$'\t'}"
            if [[ "$fail_type" == "timeout" ]]; then
                print -P "$repo %F{red}[timeout]%f"
            else
                print -P "$repo %F{yellow}[failed]%f"
            fi
        done
        print -P "%F{242}  check VPN or network if unexpected%f"
    fi

    # Summary
    print -P "%F{242}(${#repos} repos scanned)%f"
}

# Only define git fuzzy functions if both git and fzf are available
if zdotfiles_has_command git && zdotfiles_has_command fzf; then
    # Fuzzy Git branch switcher
    fbr() {
        # Check if we're in a git repository
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
            zdotfiles_error "Not in a git repository"
            return 1
        fi
        
        local branch
        branch=$(git branch --all | fzf --preview "git log --oneline --decorate --graph --color=always {}" | sed 's/^[* ]*//;s#remotes/[^/]*/##')
        
        if [[ -n "$branch" ]]; then
            git checkout "$branch"
        fi
    }

    # Fuzzy Git file opener
    fgf() {
        # Check if we're in a git repository
        if ! git rev-parse --git-dir >/dev/null 2>&1; then
            zdotfiles_error "Not in a git repository"
            return 1
        fi
        
        local preview_cmd='cat {}'
        if zdotfiles_has_command bat; then
            preview_cmd='bat --style=numbers --color=always {}'
        fi
        
        local files
        files=$(git ls-files | fzf --multi --preview "$preview_cmd")
        
        if [[ -n "$files" ]]; then
            echo "$files" | xargs -r "${EDITOR:-vim}"
        fi
    }
fi 