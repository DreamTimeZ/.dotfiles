# ===============================
# KNOWLEDGE MANAGEMENT FUNCTIONS
# ===============================

if zdotfiles_has_command yt-dlp; then
    zmodload zsh/datetime 2>/dev/null

    _yt2note_fmt_words() {
        if (( $1 >= 1000 )); then printf '%.1fk' $(( $1 / 1000.0 ))
        else print -rn -- "$1"; fi
    }

    _yt2note_sanitize() {
        local name="$1"
        name="${name//[\/\\\\:*?\"<>|]/}"
        name="${name//  / }"
        while [[ "$name" == *--* ]]; do name="${name//--/-}"; done
        [[ ${#name} -gt 200 ]] && name="${name:0:200}"
        print -r -- "$name"
    }

    _yt2note_vault_tree() {
        local vault="${1%/}"

        # Read attachment folder from Obsidian config (fall back to empty)
        local attach_dir=""
        local app_json="${vault}/.obsidian/app.json"
        if [[ -r "$app_json" ]] && zdotfiles_has_command jq; then
            attach_dir=$(jq -r '.attachmentFolderPath // empty' "$app_json" 2>/dev/null)
        fi

        # Read exclusion patterns from vault-level .yt2note-exclude
        local -a exclude_patterns=()
        local exclude_file="${vault}/.yt2note-exclude"
        if [[ -r "$exclude_file" ]]; then
            local _line
            while IFS= read -r _line || [[ -n "$_line" ]]; do
                _line="${_line//$'\r'/}"
                _line="${_line%%#*}"
                _line="${_line#"${_line%%[^ ]*}"}"
                _line="${_line%"${_line##*[^ ]}"}"
                _line="${_line%/}"
                [[ -n "$_line" ]] && exclude_patterns+=("$_line")
            done < "$exclude_file"
        fi

        find "$vault" -mindepth 1 -maxdepth 4 \( -name '.*' -prune \) -o -type d -print 2>/dev/null |
            sort | while IFS= read -r d; do
                local rel="${d#${vault}/}"
                # Skip attachment directory and vault infrastructure
                [[ -n "$attach_dir" && ( "$rel" == "$attach_dir" || "$rel" == "$attach_dir/"* ) ]] && continue

                # Skip directories matching .yt2note-exclude patterns
                local _excluded=0 _excl=""
                for _excl in "${exclude_patterns[@]}"; do
                    if [[ "$rel" == ${~_excl} || "$rel" == ${~_excl}/* ]]; then
                        _excluded=1
                        break
                    fi
                done
                (( _excluded )) && continue

                print -r -- "${rel}/"

                # List up to 3 sample .md filenames
                local -a md_files=("$d"/*.md(N:t))
                local -i total=${#md_files}
                local -i show=$(( total < 3 ? total : 3 ))
                local -i i
                for (( i=1; i<=show; i++ )); do
                    print -r -- "  ${md_files[$i]}"
                done
                (( total > 3 )) && print -r -- "  ... (+$(( total - 3 )) more)"
            done
    }

    _yt2note_find_dir() {
        local vault="${1%/}" dir_tree="$2" title="$3" preview="$4" history="${5:-}"

        local placement_rules=""
        [[ -n "${YT2NOTE_PLACEMENT_PROMPT:-}" && -f "$YT2NOTE_PLACEMENT_PROMPT" ]] && \
            placement_rules=$(<"$YT2NOTE_PLACEMENT_PROMPT")

        local system_prompt
        if [[ -n "$placement_rules" ]]; then
            system_prompt="${placement_rules}

Given the vault directory tree and a note's title and preview, respond with exactly one directory path from the list. No other text."
        else
            system_prompt="Respond with exactly one directory path from the provided list. No other text."
        fi

        local user_prompt="Vault tree (directories with sample note names):
${dir_tree}

Note title: \"${title}\"
Content preview: ${preview}${history:+

Refinement history:${history}
Choose a better directory based on the latest feedback.}"

        [[ -z "$dir_tree" ]] && return 1

        local result
        result=$(print -r -- "$user_prompt" | claude -p --no-session-persistence --system-prompt "$system_prompt" 2>/dev/null)
        result="${result//$'\r'}"              # strip CR (WSL line endings)
        result="${result//\`}"                 # strip backticks (LLM formatting)
        result="${result#"${result%%[^$'\n']*}"}" # skip blank lines from stripped fences
        result="${result%%$'\n'*}"            # first line only
        result="${result#"${result%%[^ ]*}"}" # trim all leading spaces
        result="${result%"${result##*[^ ]}"}" # trim all trailing spaces
        result="${result#/}"
        result="${result%/}"
        if [[ -n "$result" && -d "${vault}/${result}" ]]; then
            print -r -- "$result"
            return 0
        fi
        zdotfiles_warn "yt2note: AI returned '${result:-<empty>}' (not a valid directory)" >&2
        return 1
    }

    _yt2note_render() {
        local template="$1" title="$2" date="$3" source="$4" channel="$5" duration="$6" tags="$7" content="$8"

        # Strip leading blank lines from content to avoid double spacing after title
        content="${content#"${content%%[^$'\n']*}"}"

        template="${template//\{\{title\}\}/$title}"
        template="${template//\{\{date\}\}/$date}"
        template="${template//\{\{source\}\}/$source}"
        template="${template//\{\{channel\}\}/$channel}"
        template="${template//\{\{duration\}\}/$duration}"
        template="${template//\{\{tags\}\}/$tags}"
        template="${template//\{\{content\}\}/$content}"

        print -r -- "$template"
    }

    # Resolve the original auto-caption language key for a video.
    # yt-dlp uses "-orig" suffix for some videos (en-orig) but not others
    # (de-DE, pt-BR). This queries metadata to find the actual key.
    _yt2note_resolve_sub_lang() {
        local url="$1" lang="${2:-}"
        zdotfiles_has_command jq || {
            zdotfiles_warn "yt2note: jq not found, subtitle language detection may fail"
            return 1
        }
        if [[ -n "$lang" ]]; then
            yt-dlp -j --no-download --no-playlist "$url" 2>/dev/null | \
                jq -r --arg l "$lang" \
                '[.automatic_captions // {} | keys[] | select(startswith($l))] | sort_by(length) | .[0] // empty' 2>/dev/null
        else
            yt-dlp -j --no-download --no-playlist "$url" 2>/dev/null | \
                jq -r '((.language | strings | select(length > 0) | split("-")[0]) // "en") as $l |
                    [.automatic_captions // {} | keys[] | select(startswith($l))] |
                    sort_by(length) | .[0] // empty' 2>/dev/null
        fi
    }

    # Download auto-generated VTT subtitle, print path to best file.
    # Caller must create tmpdir and handle cleanup.
    # Usage: _yt2note_download_vtt URL TMPDIR [LANG]
    _yt2note_download_vtt() {
        local url="$1" tmpdir="$2" lang="${3:-}"
        local sub_langs
        [[ -n "$lang" ]] && sub_langs="${lang}-orig,${lang}" || sub_langs='.*-orig'

        yt-dlp --write-auto-subs --skip-download --no-playlist --sub-format vtt \
            --sub-langs "$sub_langs" -o "${tmpdir}/%(id)s.%(ext)s" "$url" >/dev/null 2>&1 || true

        local -a vtt_files=("${tmpdir}"/*.vtt(N))

        # Fallback: .*-orig didn't match (regional codes like de-DE, pt-BR)
        if (( ! ${#vtt_files} )); then
            local orig_key
            orig_key=$(_yt2note_resolve_sub_lang "$url" "$lang")
            if [[ -n "$orig_key" ]]; then
                yt-dlp --write-auto-subs --skip-download --no-playlist --sub-format vtt \
                    --sub-langs "$orig_key" -o "${tmpdir}/%(id)s.%(ext)s" "$url" >/dev/null 2>&1 || true
                vtt_files=("${tmpdir}"/*.vtt(N))
            fi
        fi

        (( ${#vtt_files} )) || return 1
        local vtt=${vtt_files[1]}
        for f in "${vtt_files[@]}"; do [[ $f == *-orig.vtt ]] && { vtt=$f; break }; done
        print -r -- "$vtt"
    }

    _yt2note_fetch_transcript() {
        emulate -L zsh
        local url="$1" ts_flag="${2:---transcript}" lang="${3:-}"
        local tmpdir=$(mktemp -d /tmp/yt2note-vtt.XXXXXX)
        trap "rm -rf $tmpdir" EXIT

        local vtt
        vtt=$(_yt2note_download_vtt "$url" "$tmpdir" "$lang") || return 1

        if [[ $ts_flag == "--transcript-with-timestamps" ]]; then
            awk '
            /^WEBVTT/ || /^Kind:/ || /^Language:/ || /^NOTE/ || /^STYLE/ || /^$/ || /^[0-9]+$/ { next }
            /^[0-9][0-9]:[0-9][0-9].*-->/ { split($1, t, "."); ts = "[" t[1] "]"; next }
            {
                gsub(/<[^>]+>/, ""); gsub(/^ +| +$/, "")
                if ($0 != "" && !seen[$0]++) print ts " " $0
            }' "$vtt"
        else
            awk '
            /^WEBVTT/ || /^Kind:/ || /^Language:/ || /^NOTE/ || /^STYLE/ || /^$/ || /^[0-9]+$/ { next }
            /^[0-9][0-9]:[0-9][0-9]/ { next }
            {
                gsub(/<[^>]+>/, ""); gsub(/^ +| +$/, "")
                if ($0 != "" && !seen[$0]++) out = out (out ? " " : "") $0
            }
            END { print out }' "$vtt"
        fi
    }

    _yt2note_timer_start() {
        _YT2NOTE_TIMER_PID=""
        [[ ${ZDOTFILES_LOG_LEVEL:-0} -lt 3 ]] && return 0
        local msg="$1"
        _YT2NOTE_TIMER_START=$EPOCHREALTIME
        stty -echo 2>/dev/null
        printf '\033[1;34m==>\033[0m \033[1m%s %.1fs\033[0m' "$msg" $(( EPOCHREALTIME - _YT2NOTE_TIMER_START )) >&2
        {
            trap 'printf "\r\033[2K\033[1;34m==>\033[0m \033[1m%s %.1fs\033[0m\n" "$msg" $(( EPOCHREALTIME - _YT2NOTE_TIMER_START )) >&2; exit 0' TERM INT
            zmodload zsh/datetime 2>/dev/null
            local _use_zselect=0
            zmodload zsh/zselect 2>/dev/null && _use_zselect=1
            while true; do
                if (( _use_zselect )); then zselect -t 10; else sleep 0.1; fi
                printf '\r\033[2K\033[1;34m==>\033[0m \033[1m%s %.1fs\033[0m' "$msg" $(( EPOCHREALTIME - _YT2NOTE_TIMER_START )) >&2
            done
        } &
        _YT2NOTE_TIMER_PID=$!
    }

    _yt2note_timer_stop() {
        [[ -z "${_YT2NOTE_TIMER_PID:-}" ]] && return 0
        kill $_YT2NOTE_TIMER_PID 2>/dev/null
        wait $_YT2NOTE_TIMER_PID 2>/dev/null
        stty echo 2>/dev/null
        _YT2NOTE_TIMER_PID=""
    }

    # Extract YouTube transcript to stdout
    # Usage: ytt [-l lang] [-r] URL
    ytt() {
        local lang="" raw=0
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -h|--help)
                    cat <<'EOF'
Usage: ytt [OPTIONS] URL

Extract YouTube transcript to stdout.

Options:
  -l, --lang LANG   Subtitle language (default: original)
  -r, --raw         Output raw VTT (no cleanup)
  -h, --help        Show help
EOF
                    return 0 ;;
                -l|--lang) [[ $# -lt 2 ]] && { print -u2 "ytt: $1 requires an argument"; return 1; }; lang="$2"; shift 2 ;;
                -r|--raw) raw=1; shift ;;
                -*) print -u2 "ytt: unknown option: $1"; return 1 ;;
                *) break ;;
            esac
        done

        [[ -z "$1" ]] && { print -u2 "Usage: ytt [-l lang] [-r] URL"; return 1; }
        local url="$1"

        if (( raw )); then
            local tmpdir=$(mktemp -d /tmp/ytt-vtt.XXXXXX)
            trap "rm -rf $tmpdir" EXIT
            local vtt
            vtt=$(_yt2note_download_vtt "$url" "$tmpdir" "$lang") || { print -u2 "ytt: no subtitles found"; return 1; }
            cat "$vtt"
        else
            _yt2note_fetch_transcript "$url" "--transcript" "$lang" || {
                print -u2 "ytt: no transcript available"; return 1
            }
        fi
    }

    if zdotfiles_has_command claude; then

    # YouTube transcript → Claude summary to stdout
    # Usage: ytc "URL" [prompt_file]  (default: $YT2NOTE_PROMPT)
    ytc() {
        [[ -z "$1" ]] && { print -u2 "Usage: ytc \"URL\" [prompt_file]"; return 1; }

        local url="$1"
        local prompt_file="${2:-${YT2NOTE_PROMPT:-}}"
        [[ -n "$prompt_file" && -f "$prompt_file" ]] || {
            print -u2 "ytc: prompt file required (pass as arg or set YT2NOTE_PROMPT)"
            return 1
        }

        local transcript
        transcript=$(_yt2note_fetch_transcript "$url") || {
            print -u2 "ytc: no transcript available"; return 1
        }

        {
            yt-dlp --print "Title: %(title)s" --print "Channel: %(channel)s" \
                   --print "Duration: %(duration_string)s" \
                   --print "Description: %(description).300s" \
                   --no-download "$url" 2>/dev/null
            print ""
            print -r -- "$transcript"
        } | claude -p --no-session-persistence --system-prompt "$(<"$prompt_file")"
    }

    yt2note() {
        local -i raw=0 dry_run=0 open_after=0
        local dir="${YT2NOTE_DIR:-}" title="" url=""

        while [[ $# -gt 0 ]]; do
            case "$1" in
                -h|--help)
                    cat <<'EOF'
Usage: yt2note [OPTIONS] URL

Create an Obsidian note from a YouTube video with optional AI summary.

Options:
  -r, --raw                Save raw transcript, skip AI summary
  -d, --dir SUBDIR         Target subdirectory in vault (skip AI placement)
  -t, --title TITLE        Override note title
  -n, --dry-run            Print to stdout instead of saving
  -o, --open               Open note in $EDITOR after creation
  -h, --help               Show help

Directory placement:
  Without -d, AI suggests a directory and prompts for confirmation.
  Enter to accept, 'n' to cancel, or type feedback to refine the suggestion.

Environment variables:
  OBSIDIAN_VAULT           Path to vault root (required)
  YT2NOTE_PROMPT           Path to system prompt for AI summary (required unless --raw)
  YT2NOTE_PLACEMENT_PROMPT Path to placement rules for AI directory selection
  YT2NOTE_TEMPLATE         Path to custom note template file
  YT2NOTE_DIR              Default subdirectory (skips AI placement)

Files:
  $OBSIDIAN_VAULT/.yt2note-exclude   Directories to hide from AI placement
                                      (one prefix per line, supports globs)
EOF
                    return 0
                    ;;
                -r|--raw) raw=1; shift ;;
                -d|--dir) [[ $# -lt 2 ]] && { zdotfiles_error "yt2note: $1 requires an argument"; return 1; }; dir="$2"; shift 2 ;;
                -t|--title) [[ $# -lt 2 ]] && { zdotfiles_error "yt2note: $1 requires an argument"; return 1; }; title="$2"; shift 2 ;;
                -n|--dry-run) dry_run=1; shift ;;
                -o|--open) open_after=1; shift ;;
                -[rnoh]*)
                    local flags="${1#-}"; shift
                    local i
                    for (( i=0; i<${#flags}; i++ )); do
                        case "${flags:$i:1}" in
                            r) set -- "-r" "$@" ;;
                            n) set -- "-n" "$@" ;;
                            o) set -- "-o" "$@" ;;
                            h) set -- "-h" "$@" ;;
                            *) zdotfiles_error "yt2note: unknown flag: -${flags:$i:1}"; return 1 ;;
                        esac
                    done
                    ;;
                -*) zdotfiles_error "yt2note: unknown option: $1"; return 1 ;;
                *) url="$1"; shift ;;
            esac
        done

        if [[ -z "$url" ]]; then
            zdotfiles_error "yt2note: URL required"
            return 1
        fi

        if [[ ! "$url" =~ ^https?://([a-zA-Z0-9-]+\.)?(youtube\.com|youtu\.be)/ ]]; then
            zdotfiles_error "yt2note: not a YouTube URL: $url"
            return 1
        fi

        if [[ -z "${OBSIDIAN_VAULT:-}" ]]; then
            zdotfiles_error "yt2note: OBSIDIAN_VAULT not set"
            return 1
        fi

        if [[ ! -d "$OBSIDIAN_VAULT" ]]; then
            zdotfiles_error "yt2note: vault not found: $OBSIDIAN_VAULT"
            return 1
        fi

        if (( ! dry_run )) && [[ -n "$dir" && ! -d "${OBSIDIAN_VAULT%/}/${dir}" ]]; then
            zdotfiles_error "yt2note: target directory not found: ${OBSIDIAN_VAULT%/}/${dir}"
            return 1
        fi

        if (( ! raw )) && [[ -z "${YT2NOTE_PROMPT:-}" || ! -f "${YT2NOTE_PROMPT:-}" ]]; then
            zdotfiles_error "yt2note: YT2NOTE_PROMPT not set or file not found (required for AI summary)"
            return 1
        fi

        setopt local_options no_monitor
        local _t0=$EPOCHREALTIME _YT2NOTE_TIMER_PID="" _YT2NOTE_TIMER_START=""
        TRAPEXIT() { local _ret=$?; _yt2note_timer_stop; stty echo 2>/dev/null; return $_ret }
        _yt2note_timer_start "yt2note: fetching metadata..."
        local meta_raw
        meta_raw=$(yt-dlp --print "%(title)s" --print "%(channel)s" --print "%(duration_string)s" --no-download "$url" 2>/dev/null)
        if [[ -z "$meta_raw" ]]; then
            _yt2note_timer_stop
            zdotfiles_error "yt2note: failed to fetch video metadata"
            return 1
        fi

        local vid_title channel duration
        { IFS= read -r vid_title; IFS= read -r channel; IFS= read -r duration; } <<< "$meta_raw"

        [[ -n "$title" ]] && vid_title="$title"
        title="$vid_title"
        _yt2note_timer_stop

        _yt2note_timer_start "yt2note: downloading transcript..."
        local transcript
        transcript=$(_yt2note_fetch_transcript "$url")
        if [[ -z "$transcript" ]]; then
            _yt2note_timer_stop
            zdotfiles_warn "yt2note: no transcript available for this video"
            return 1
        fi
        _yt2note_timer_stop

        local content
        if (( raw )); then
            content="$transcript"
        else
            local llm_input="Title: ${title}
Channel: ${channel}
Duration: ${duration}

${transcript}"
            local _sys_prompt
            _sys_prompt=$(<"$YT2NOTE_PROMPT")
            local -a _words=(${=llm_input})
            local -a _sys_words=(${=_sys_prompt})
            local -i _total_words=$(( ${#_words} + ${#_sys_words} ))
            _yt2note_timer_start "yt2note: generating summary (~$(_yt2note_fmt_words $_total_words) words)..."
            content=$(print -r -- "$llm_input" | claude -p --no-session-persistence --system-prompt "$_sys_prompt" 2>/dev/null)
            _yt2note_timer_stop
            if [[ -z "$content" ]]; then
                zdotfiles_warn "yt2note: AI summary failed, falling back to raw transcript"
                content="$transcript"
            fi
        fi

        local target_dir=""
        if [[ -n "$dir" ]]; then
            target_dir="$dir"
        elif (( ! dry_run )); then
            # Scan vault tree once, reuse for all refinements
            local vault_tree
            vault_tree=$(_yt2note_vault_tree "$OBSIDIAN_VAULT")
            if [[ -n "$vault_tree" ]]; then
                local -a _dir_words=(${=vault_tree} ${=title} ${=content:0:200})
                _yt2note_timer_start "yt2note: selecting directory (~$(_yt2note_fmt_words ${#_dir_words}) words)..."
                target_dir=$(_yt2note_find_dir "$OBSIDIAN_VAULT" "$vault_tree" "$title" "${content:0:200}") || target_dir=""
            fi
            _yt2note_timer_stop

            # Confirm AI-selected directory (loop for follow-up refinements)
            local refinement_history="" confirm_dir reply new_dir
            while true; do
                confirm_dir="${target_dir:-(vault root)}"
                printf "\n  Directory: %s\n\n" "$confirm_dir"
                reply=""
                while read -t 0 -k 1 2>/dev/null; do :; done
                vared -p "  [Enter=accept / n=cancel / feedback to refine] " reply
                case "$reply" in
                    "") break ;;  # accept
                    [yY]) break ;;  # accept
                    [nN]) zdotfiles_info "yt2note: cancelled"; return 0 ;;
                    *)
                        if [[ -z "$vault_tree" ]]; then
                            zdotfiles_warn "yt2note: no vault directories found, cannot refine"
                            continue
                        fi
                        refinement_history+="
Previously suggested: ${target_dir}. User feedback: ${reply}"
                        zdotfiles_info "yt2note: refining directory..."
                        new_dir=$(_yt2note_find_dir "$OBSIDIAN_VAULT" "$vault_tree" "$title" "${content:0:200}" "$refinement_history")
                        if [[ -n "$new_dir" ]]; then
                            target_dir="$new_dir"
                        else
                            zdotfiles_warn "yt2note: could not find a matching directory, try again"
                        fi
                        ;;
                esac
            done
        fi

        local vault_path="${OBSIDIAN_VAULT%/}"
        [[ -n "$target_dir" ]] && vault_path="${vault_path}/${target_dir}"

        local date
        date=$(date +%Y-%m-%d)
        local tags=$'tags:\n  - youtube'

        local template
        if [[ -n "${YT2NOTE_TEMPLATE:-}" && -f "$YT2NOTE_TEMPLATE" ]]; then
            template=$(<"$YT2NOTE_TEMPLATE")
        else
            template='---
fileClass: Global
created: {{date}}
source: "{{source}}"
channel: "{{channel}}"
duration: "{{duration}}"
{{tags}}
links:
status:
---
# {{title}}

{{content}}'
        fi

        local safe_channel="${channel//\"/\\\"}"

        local note
        note=$(_yt2note_render "$template" "$title" "$date" "$url" "$safe_channel" "$duration" "$tags" "$content")

        if (( dry_run )); then
            print -r -- "$note"
            return 0
        fi

        local safe_name
        safe_name=$(_yt2note_sanitize "$title")
        local filepath="${vault_path}/${safe_name}.md"

        if [[ -f "$filepath" ]]; then
            local _reply=""
            zdotfiles_warn "yt2note: file already exists: ${filepath#${OBSIDIAN_VAULT%/}/}"
            while read -t 0 -k 1 2>/dev/null; do :; done
            vared -p "  [Enter=overwrite / n=cancel] " _reply
            case "$_reply" in
                ""|[yY]) ;;
                *) zdotfiles_info "yt2note: cancelled"; return 0 ;;
            esac
        fi

        if [[ ! -d "$vault_path" ]]; then
            zdotfiles_error "yt2note: target directory not found: $vault_path"
            return 1
        fi

        print -r -- "$note" > "$filepath" || {
            zdotfiles_error "yt2note: failed to write: $filepath"
            return 1
        }

        zdotfiles_info "yt2note: saved to $filepath (total $(printf '%.1f' $(( EPOCHREALTIME - _t0 )))s)"

        if (( open_after )) && [[ -n "${EDITOR:-}" ]]; then
            "$EDITOR" "$filepath"
        fi
    }

    fi
fi
