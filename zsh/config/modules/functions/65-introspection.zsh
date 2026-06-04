# ===============================
# CONFIG INTROSPECTION
# ===============================

# zh: fzf picker over every dotfiles-authored alias, function, export, and
# keybinding (public repo + private layers). Parses the authored files, not
# the live shell, so generated wrappers (grc) and plugin noise never appear
# and every row carries its source file and layer tag.
# Core flags exist since fzf 0.20 (semantics validated on 0.73). The ctrl-t
# type cycle needs transform-query (fzf 0.36) and is version-gated, so an
# older fzf keeps a working picker without the bind.

# Emit one TSV row per definition: TYPE NAME TAG FILE LINE DESC.
# Args: $1 = fixed-string body filter ("" = none), $2 = keybindings.md path
# ("" = skip), $3.. = zsh files to parse. POSIX awk only (BSD/gawk/mawk).
# Known residuals (verified absent today, cosmetic if they ever appear): a
# heredoc line that exactly mimics a definition adds one bogus row; an
# unbalanced literal brace inside a string skews the depth gate.
_zh_rows() {
    local pat="$1" kbmd="$2"
    shift 2
    # Pattern travels via ENVIRON: awk -v would expand backslash escapes,
    # breaking the fixed-string contract for patterns like "a\nb".
    (( $# )) && ZH_PAT="$pat" awk '
        BEGIN { pat = ENVIRON["ZH_PAT"] }
        # First "#" preceded by whitespace with even quote parity starts a
        # trailing comment (a "#" inside a quoted value has odd parity).
        function tcomment(s,    i, n, ch, sq, dq, prev, t) {
            n = length(s)
            for (i = 1; i <= n; i++) {
                ch = substr(s, i, 1)
                if (ch == "\047") sq++
                else if (ch == "\"") dq++
                else if (ch == "#" && (prev == " " || prev == "\t") && sq % 2 == 0 && dq % 2 == 0) {
                    t = substr(s, i + 1)
                    gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
                    return t
                }
                prev = ch
            }
            return ""
        }
        function unquote(s,    a, z) {
            a = substr(s, 1, 1); z = substr(s, length(s), 1)
            if ((a == "\047" && z == "\047") || (a == "\"" && z == "\"")) return substr(s, 2, length(s) - 2)
            return s
        }
        function clean(s) { gsub(/\t/, " ", s); return s }
        # In body-filter mode rows are buffered until the definition span
        # ends; without a filter they print immediately.
        function emit(row, defline) {
            if (pat == "") { print row; return }
            flush()
            pend = row
            hit = index(defline, pat) > 0
        }
        function flush() {
            if (pend != "" && hit) print pend
            pend = ""; hit = 0
        }
        FNR == 1 {
            flush()
            depth = 0; cblock = 0; desc = ""; span = 0
            if      (FILENAME ~ /\/machines\//)                 tag = "machine"
            else if (FILENAME ~ /\.dotfiles-private\/shared\//) tag = "shared"
            else if (FILENAME ~ /\.dotfiles-private\/macos\//)  tag = "macos"
            else if (FILENAME ~ /\.dotfiles-private\/linux\//)  tag = "linux"
            else if (FILENAME ~ /\.dotfiles-private\/wsl\//)    tag = "wsl"
            else                                                tag = "public"
        }
        span && index($0, pat) > 0 { hit = 1 }
        # Description block: first comment line wins; banners, blank
        # comments, and shellcheck pragmas poison the block.
        /^[[:space:]]*#/ {
            if (!cblock) {
                cblock = 1
                if ($0 ~ /^[[:space:]]*#[[:space:]]*={3,}/ || $0 ~ /^[[:space:]]*#[[:space:]]*$/ || $0 ~ /^[[:space:]]*#[[:space:]]*shellcheck/ || $0 ~ /^#!/) desc = ""
                else { desc = $0; sub(/^[[:space:]]*#[[:space:]]?/, "", desc) }
            }
            next
        }
        {
            # Definitions count only at brace depth 0: function-body aliases
            # and runtime exports are not config-level definitions.
            if (depth == 0) {
                # The regex below has an unpaired brace char. Its trailing
                # comment carries the closer ON THE CODE LINE (pure comment
                # lines are skipped by the counter) so the depth gate stays
                # balanced when zh parses its own file.
                if ($0 ~ /^[[:space:]]*(function[[:space:]]+[A-Za-z][A-Za-z0-9_-]*(\(\))?|[A-Za-z][A-Za-z0-9_-]*\(\))[[:space:]]*\{/) {  # }
                    name = $0
                    sub(/^[[:space:]]*/, "", name)
                    sub(/^function[[:space:]]+/, "", name)
                    sub(/\(.*/, "", name)
                    sub(/[[:space:]].*/, "", name)
                    dsc = tcomment($0); if (dsc == "") dsc = desc
                    emit("function\t" name "\t" tag "\t" FILENAME "\t" FNR "\t" clean(dsc), $0)
                    if (pat != "") { span = 1; sbase = depth }
                } else if ($0 ~ /^[[:space:]]*alias[[:space:]]/) {
                    line = $0
                    sub(/^[[:space:]]*alias[[:space:]]+/, "", line)
                    sub(/^-[A-Za-z]+[[:space:]]+/, "", line)
                    eq = index(line, "=")
                    if (eq > 1) {
                        name = unquote(substr(line, 1, eq - 1))
                        val = substr(line, eq + 1)
                        # Reject generated names ("$cmd") and programmatic
                        # reassignments (values starting with $).
                        if (name ~ /^[A-Za-z?][A-Za-z0-9_.?-]*$/ && val !~ /^\$/) {
                            dsc = tcomment($0); if (dsc == "") dsc = desc
                            if (dsc == "") { gsub(/^[[:space:]]+|[[:space:]]+$/, "", val); dsc = unquote(val) }
                            emit("alias\t" name "\t" tag "\t" FILENAME "\t" FNR "\t" clean(dsc), $0)
                        }
                    }
                } else if ($0 ~ /^[[:space:]]*(export|typeset[[:space:]]+-gx)[[:space:]]/) {
                    line = $0
                    sub(/^[[:space:]]*(export|typeset[[:space:]]+-gx)[[:space:]]+/, "", line)
                    eq = index(line, "=")
                    if (eq > 1) {
                        name = substr(line, 1, eq - 1)
                        if (name ~ /^[A-Za-z_][A-Za-z0-9_]*$/) {
                            val = substr(line, eq + 1)
                            dsc = tcomment($0); if (dsc == "") dsc = desc
                            if (dsc == "") { gsub(/^[[:space:]]+|[[:space:]]+$/, "", val); dsc = unquote(val) }
                            emit("export\t" name "\t" tag "\t" FILENAME "\t" FNR "\t" clean(dsc), $0)
                        }
                    }
                }
            }
            t = $0; depth += gsub(/\{/, "", t)
            t = $0; depth -= gsub(/\}/, "", t)
            if (span && depth <= sbase) { flush(); span = 0 }
            cblock = 0; desc = ""
        }
        END { flush() }
    ' "$@"
    if [[ -n "$kbmd" && -r "$kbmd" ]]; then
        ZH_PAT="$pat" awk -F"|" '
            BEGIN { pat = ENVIRON["ZH_PAT"] }
            /^##/ { sec = $0; sub(/^#+[[:space:]]*/, "", sec); next }
            /^\|/ {
                key = $2; act = $3
                gsub(/`/, "", key); gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
                gsub(/`/, "", act); gsub(/^[[:space:]]+|[[:space:]]+$/, "", act)
                if (key == "" || key == "Key" || key ~ /^-+$/) next
                gsub(/\t/, " ", key); gsub(/\t/, " ", act)
                d = sec " | " act
                if (pat != "" && index(key, pat) == 0 && index(d, pat) == 0) next
                print "keybinding\t" key "\tpublic\t" FILENAME "\t" FNR "\t" d
            }
        ' "$kbmd"
    fi
    return 0
}

# Render the selected display line in the fzf preview pane. Serialized into
# the fzf subshell via typeset -f, so it must not call other dotfiles
# helpers. Args: $1 = whole selected line ({}), $2 = bat available (0/1).
# Parsing the line here mirrors esp and the Enter recovery: one idiom, no
# reliance on fzf field-token delimiter-stripping semantics. Read-only:
# extracts text with awk, never evaluates parsed content.
_zh_preview() {
    local has_bat="$2" type file line
    IFS=$'\t' read -r type file line <<< "$(print -r -- "$1" | awk -F"│" '{
        gsub(/^[ \t]+|[ \t]+$/, "", $1)
        gsub(/^[ \t]+|[ \t]+$/, "", $5)
        gsub(/^[ \t]+|[ \t]+$/, "", $6)
        print $1 "\t" $5 "\t" $6
    }')"
    [[ -r "$file" ]] || return 0
    case "$type" in
        keybinding)
            awk -v L="$line" '
                NR < L && /^##/ { h = $0 }
                NR == L { if (h != "") { print h; print "" } print; exit }
            ' "$file"
            ;;
        function)
            # Preceding comment block, then the brace-matched body.
            awk -v L="$line" '
                NR < L && /^[[:space:]]*#/ { c = c $0 "\n"; next }
                NR < L { c = ""; next }
                NR == L { printf "%s", c }
                NR >= L {
                    print
                    t = $0; n += gsub(/\{/, "", t)
                    t = $0; n -= gsub(/\}/, "", t)
                    if (n <= 0) exit
                }
            ' "$file" | if (( has_bat )); then bat --language=zsh --color=always --style=plain; else cat; fi
            ;;
        *)
            # Alias or export: preceding comment block plus the definition.
            awk -v L="$line" '
                NR < L && /^[[:space:]]*#/ { c = c $0 "\n"; next }
                NR < L { c = ""; next }
                NR == L { printf "%s%s\n", c, $0; exit }
            ' "$file" | if (( has_bat )); then bat --language=zsh --color=always --style=plain; else cat; fi
            ;;
    esac
}

# Cycle the type anchor of the fzf query: all -> alias -> function ->
# export -> keybinding -> all, preserving any other query terms.
# Serialized into the fzf subshell. Arg: $1 = current query ({q}).
_zh_cycle() {
    printf "%s\n" "$1" | awk '{
        r = $0
        sub(/^ +/, "", r)
        if      (sub(/^\^alias( +|$)/, "", r))      a = "^function "
        else if (sub(/^\^function( +|$)/, "", r))   a = "^export "
        else if (sub(/^\^export( +|$)/, "", r))     a = "^keybinding "
        else if (sub(/^\^keybinding( +|$)/, "", r)) a = ""
        else                                        a = "^alias "
        printf "%s%s", a, r
    }'
}

# Interactive picker for everything the dotfiles define (see -h).
zh() {
    local -a opt_help opt_all opt_list opt_body
    zparseopts -D -E -F -- h=opt_help -help=opt_help a=opt_all -all=opt_all \
        -list=opt_list b:=opt_body 2>/dev/null || {
        echo "zh: invalid option. Use -h for help." >&2
        return 1
    }

    if (( ${#opt_help} )); then
        cat <<-'EOF'
	Usage: zh [-h|--help] [-a|--all] [-b PATTERN] [--list] [TYPE] [QUERY...]

	Browse and search dotfiles-authored aliases, functions, exports, and
	keybindings (public repo + private layers) with fzf.

	Arguments:
	  TYPE          Pre-filter by type (optional first argument):
	                alias|aliases, fn|func|function|functions,
	                export|exports|env, kb|key|keys|keybinding|keybindings
	  QUERY         Initial fzf query (optional, multiple words joined)

	Options:
	  -h, --help    Show this help
	  -a, --all     Include all platforms and machines (default: current only)
	  -b PATTERN    Only entries whose definition contains PATTERN (fixed string)
	  --list        Print raw rows (TYPE NAME TAG FILE LINE DESC, tab-separated)

	Keys (inside fzf):
	  Ctrl-T        Cycle the type filter: all -> alias -> function -> export
	                -> keybinding -> all (keeps your query; needs fzf 0.36+,
	                otherwise type ^alias etc. as query anchors)

	Enter:
	  alias/function  Insert the name into the command line
	  export          Insert $NAME into the command line
	  keybinding      Print the key and action

	Examples:
	  zh              Browse everything on this platform
	  zh fn serve     Functions, query "serve"
	  zh -a wsl       All layers, query "wsl"
	  zh -b pbpaste   Entries whose definition mentions pbpaste

	Related: esp (espanso picker), esh (espanso cheatsheet), kb (keybindings doc)
	EOF
        return 0
    fi

    local type=""
    case "$1" in
        alias|aliases)                      type=alias; shift ;;
        fn|func|function|functions)         type=function; shift ;;
        export|exports|env)                 type=export; shift ;;
        kb|key|keys|keybinding|keybindings) type=keybinding; shift ;;
    esac

    local zdir="${ZDOTFILES_DIR:-$HOME/.dotfiles}/zsh"
    local pub="$zdir/config"
    local priv="$HOME/.dotfiles-private"
    local plat="${ZDOTFILES_PLATFORM:-$(zdotfiles_detect_platform)}"
    local mach="${(L)${HOST%%.*}}"
    local kbmd="$zdir/docs/keybindings.md"
    [[ -r "$kbmd" ]] || kbmd=""

    # Layer selection happens here: the default globs only current-platform
    # dirs, -a widens to every platform and machine. (N) makes every missing
    # layer (private repo absent, no machine dir) degrade silently.
    local -a privdirs=( "$priv"/shared "$priv"/$plat "$priv"/machines/$mach )
    (( ${#opt_all} )) && privdirs=( "$priv"/shared "$priv"/{macos,linux,wsl} "$priv"/machines/*(N/) )
    local -a files=( "$pub"/*.zsh(N) "$pub"/modules/functions/[0-9][0-9]-*.zsh(N) )
    local d
    for d in "${privdirs[@]}"; do
        files+=( "$d"/zsh/config/modules/local/*.zsh(N) "$d"/zsh/config/local/*.zsh(N) )
    done

    local rows
    rows=$(_zh_rows "${opt_body[-1]:-}" "$kbmd" "${files[@]}")
    [[ -n "$type" ]] && rows=$(print -r -- "$rows" | awk -F"\t" -v t="$type" '$1 == t')

    if (( ${#opt_list} )); then
        [[ -n "$rows" ]] && print -r -- "$rows"
        return 0
    fi

    zdotfiles_has_command fzf || { echo "zh: fzf required for interactive mode (use --list)" >&2; return 1; }
    [[ -n "$rows" ]] || { echo "zh: no definitions found" >&2; return 1; }

    local _zh_preview_fn="$(typeset -f _zh_preview)"
    local has_bat=0
    zdotfiles_has_command bat && has_bat=1

    # Ctrl-T type cycle is gated on transform-query (fzf 0.36): on older
    # fzf the bind is omitted and the header advertises the ^anchor syntax.
    autoload -Uz is-at-least
    local -a cycle_bind=()
    local header="enter: insert (kb: print)  │  ^alias ^function ^export ^keybinding to filter"
    if is-at-least 0.36 "${${$(fzf --version 2>/dev/null)%% *}:-0}"; then
        local _zh_cycle_fn="$(typeset -f _zh_cycle)"
        cycle_bind=(--bind "ctrl-t:transform-query($_zh_cycle_fn; _zh_cycle {q})")
        header="enter: insert (kb: print)  │  ctrl-t: cycle type"
    fi

    # Column widths: 10 = keybinding (longest type), 24 = longest typical
    # name, 7 = machine (longest tag). Longer names just lose their padding.
    local sel
    sel=$(print -r -- "$rows" |
        awk -F"\t" '{ gsub(/│/, "|"); printf "%-10s │ %-24s │ %-7s │ %s │ %s │ %s\n", $1, $2, $3, $6, $4, $5 }' |
        fzf --prompt="zh> " \
            --header="$header" \
            --delimiter=' *│ *' --with-nth=1,2,3,4 --nth=1,2,3,4 \
            --query="$*" \
            "${cycle_bind[@]}" \
            --preview="$_zh_preview_fn; _zh_preview {} $has_bat" \
            --preview-window=right:55%:wrap)
    [[ -n "$sel" ]] || return 0

    local t n desc
    IFS=$'\t' read -r t n desc <<< "$(print -r -- "$sel" | awk -F"│" '{
        gsub(/^[ \t]+|[ \t]+$/, "", $1)
        gsub(/^[ \t]+|[ \t]+$/, "", $2)
        gsub(/^[ \t]+|[ \t]+$/, "", $4)
        print $1 "\t" $2 "\t" $4
    }')"

    case "$t" in
        keybinding) print -r -- "$n  →  $desc" ;;
        export)     print -z -- "\$$n" ;;
        *)          print -z -- "$n" ;;
    esac
}
