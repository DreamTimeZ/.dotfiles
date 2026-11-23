#!/usr/bin/env bash
# Stub suite for setup.sh's package category selection. Every run gets a temp
# HOME and XDG_CONFIG_HOME, a stubbed uname picks the platform, and brew is a
# stub that does nothing or only logs. A run that reaches the install steps
# uses --dry-run or --packages-only, so nothing is installed, linked or written
# outside the temp dir. setup.sh runs under the bash that runs this suite (run
# it with /bin/bash on macOS to cover bash 3.2).
set -uo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SETUP=${SETUP:-"$DIR/../setup.sh"}
PACKAGES=$DIR/../packages
BASH_BIN=$BASH
PASS=0
FAIL=0
SKIP=0
WORK=$(mktemp -d "${TMPDIR:-/tmp}/tsel.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

ok()   { PASS=$((PASS + 1)); printf 'PASS  %s\n' "$1"; }
no()   { FAIL=$((FAIL + 1)); printf 'FAIL  %s (%s)\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP  %s (%s)\n' "$1" "$2"; }

eq()    { if [[ "$2" == "$3" ]]; then ok "$1"; else no "$1" "expected [$2] got [$3]"; fi; }
has()   { if [[ "$3" == *"$2"* ]]; then ok "$1"; else no "$1" "[$2] not in output"; fi; }
lacks() { if [[ "$3" != *"$2"* ]]; then ok "$1"; else no "$1" "[$2] found in output"; fi; }
nonzero() { if [[ "$2" =~ ^[0-9]+$ && "$2" != 0 ]]; then ok "$1"; else no "$1" "exit code $2"; fi; }
absent()  { if [[ ! -e "$2" ]]; then ok "$1"; else no "$1" "$2 exists"; fi; }

RUN_LIMIT_SECS=30
BOUNDED_POLL_SECS=0.1
RC_POLLS=200
RC_POLL_SECS=0.1

PROMPT_HINT='Enter takes the default. Several: "core cli". All but one: "-extra". Everything: "all". q quits.'
LINUX_ALL='core cli dev extra'
MACOS_ALL='core cli dev extra macos'

write_stub() {
    printf '#!/bin/sh\n%s\n' "$2" >"$1"
    chmod +x "$1"
}

make_bin() {
    mkdir -p "$1"
    write_stub "$1/uname" "echo $2"
    write_stub "$1/brew" 'exit 0'
    [[ $# -gt 2 ]] && write_stub "$1/dpkg" "echo $3"
    return 0
}
BIN_LINUX=$WORK/bin-linux
BIN_MAC=$WORK/bin-mac
BIN_ARM=$WORK/bin-arm
make_bin "$BIN_LINUX" Linux
make_bin "$BIN_MAC" Darwin
make_bin "$BIN_ARM" Linux arm64
# macOS with a brew that only logs, for the cases that run a real install
# path. No sudo, apt-get or dpkg anywhere on the run's PATH.
BIN_MACLOG=$WORK/bin-maclog
make_bin "$BIN_MACLOG" Darwin
# shellcheck disable=SC2016 # expands in the stub
write_stub "$BIN_MACLOG/brew" 'echo "brew $*" >> "$BREW_LOG"'

SYS=$WORK/sys
mkdir -p "$SYS" "$WORK/tmp"
for tool in cat chmod dirname find grep ln mkdir mktemp mv readlink rm sed stat tr; do
    ln -s "$(command -v "$tool")" "$SYS/$tool"
done

PTY_WRAP=$WORK/pty-wrap.sh
cat >"$PTY_WRAP" <<'EOF'
if [ -n "${STDOUT_TO:-}" ]; then exec >"$STDOUT_TO"; fi
if [ -n "${STDERR_TO:-}" ]; then exec 2>"$STDERR_TO"; fi
"$BASH_BIN" "$SETUP_FILE" "$@"
echo "$?" > "$RC_FILE"
EOF

new_case() {
    CASE=$WORK/case/$1
    H=$CASE/home
    X=$H/.cfg
    SEL=$X/dotfiles/categories
    EXTRA_ENV=(BREW_LOG="$CASE/brew.log")
    mkdir -p "$H"
}

save() { mkdir -p "${SEL%/*}" && printf '%s\n' "$1" >"$SEL"; }
saved() { cat "$SEL" 2>/dev/null || printf '<none>'; }
# shellcheck disable=SC2012 # a fixed path, ls -i is the portable inode read
inode() { ls -i "$SEL" 2>/dev/null | sed 's/^ *\([0-9]*\).*/\1/'; }

installed() {
    printf '%s\n' "$OUT" | sed -n 's/.*Would install from Brewfile\.\([a-z]*\):.*/\1/p' | tr '\n' ' ' | sed 's/ $//'
}

# The command and the watchdog sleep each lead their own process group, so a
# timeout kills the whole tree and no sleep outlives the call.
bounded() {
    local pid watchdog rc
    set -m
    "$@" &
    pid=$!
    sleep "$RUN_LIMIT_SECS" &
    watchdog=$!
    set +m
    while kill -0 "$pid" 2>/dev/null && kill -0 "$watchdog" 2>/dev/null; do sleep "$BOUNDED_POLL_SECS"; done
    kill -TERM -- "-$pid" "-$watchdog" 2>/dev/null
    wait "$pid"
    rc=$?
    wait "$watchdog" 2>/dev/null
    return "$rc"
}

# shellcheck disable=SC2329 # invoked through bounded
plain_session() {
    env -i HOME="$H" XDG_CONFIG_HOME="$X" TMPDIR="$WORK/tmp" PATH="$RUN_BIN:$SYS" \
        "${EXTRA_ENV[@]}" "$BASH_BIN" "$SETUP" "$@" </dev/null
}

run() {
    RUN_BIN=$1
    shift
    bounded plain_session ${@+"$@"} >"$CASE/out" 2>&1
    RC=$?
    OUT=$(cat "$CASE/out")
}

# shellcheck disable=SC2329 # invoked through bounded
pty() {
    if script --version >/dev/null 2>&1; then
        script -qec "$(printf '%q ' "$@")" /dev/null
    else
        script -q /dev/null "$@"
    fi
}

# shellcheck disable=SC2329 # invoked by pty_session
feed() {
    local i
    printf '%b' "$1"
    for ((i = 0; i < RC_POLLS; i++)); do
        [[ -e "$RC_FILE" ]] && break
        sleep "$RC_POLL_SECS"
    done
}

# shellcheck disable=SC2329 # invoked through bounded
pty_session() {
    local input=$1
    shift
    feed "$input" | pty env -i HOME="$H" XDG_CONFIG_HOME="$X" TMPDIR="$WORK/tmp" \
        PATH="$RUN_BIN:$SYS" BASH_BIN="$BASH_BIN" SETUP_FILE="$SETUP" RC_FILE="$RC_FILE" \
        "${EXTRA_ENV[@]}" "$BASH_BIN" "$PTY_WRAP" "$@"
}

ptyrun() {
    local input=$1
    RUN_BIN=$2
    shift 2
    RC_FILE=$CASE/rc
    rm -f "$RC_FILE"
    bounded pty_session "$input" ${@+"$@"} >"$CASE/out" 2>&1
    if [[ -e "$RC_FILE" ]]; then RC=$(cat "$RC_FILE"); else RC=none; fi
    OUT=$(tr -d '\r' <"$CASE/out")
}

DRY=(--dry-run --packages-only)

bundled() {
    sed -n 's/^brew bundle .*Brewfile\.\([a-z]*\).*/\1/p' "$CASE/brew.log" 2>/dev/null | tr '\n' ' ' | sed 's/ $//'
}
upgrading_bundles() {
    grep '^brew bundle' "$CASE/brew.log" 2>/dev/null | grep -vc -- '--no-upgrade'
}

listed=$(sed -n 's/^readonly -a CATEGORY_ORDER=(\(.*\))$/\1/p' "$SETUP" | tr ' ' '\n' | sort | tr '\n' ' ')
files=$(for f in "$PACKAGES"/Brewfile.*; do printf '%s\n' "${f##*.}"; done | sort | tr '\n' ' ')
if [[ -z "$listed" ]]; then
    no "parity: category list found in setup.sh" "CATEGORY_ORDER line not found"
else
    eq "parity: CATEGORY_ORDER equals packages/Brewfile.* suffixes" "$files" "$listed"
fi

new_case default
run "$BIN_LINUX" "${DRY[@]}"
eq "default: exit 0" 0 "$RC"
eq "default: all Linux categories" "$LINUX_ALL" "$(installed)"
has "default: source and reason shown" "Selection: default (nothing saved, no terminal: all)" "$OUT"
has "default: plan shown" "Install plan" "$OUT"
absent "default: nothing saved" "$SEL"
new_case default-select
run "$BIN_LINUX" --select
eq "default --select: exit 0" 0 "$RC"
absent "default --select: nothing saved" "$SEL"
lacks "default --select: nothing installed" "Would install" "$OUT"

new_case args-save
run "$BIN_LINUX" --select Core,CLI
eq "args --select: exit 0" 0 "$RC"
eq "args --select: saved normalized" "core cli" "$(saved)"
lacks "args --select: nothing installed" "Would install" "$OUT"
new_case exclude
run "$BIN_LINUX" --select -EXTRA
eq "-extra: saved" "-extra" "$(saved)"
before=$(inode)
run "$BIN_LINUX" "${DRY[@]}"
eq "saved -extra: reused by a dry run" "core cli dev" "$(installed)"
has "saved -extra: path shown" "saved in ~/.cfg/dotfiles/categories" "$OUT"
has "saved -extra: how to change" "setup.sh --select" "$OUT"
eq "saved -extra: file not rewritten" "$before" "$(inode)"
eq "saved -extra: content unchanged" "-extra" "$(saved)"
new_case exclude-mac
run "$BIN_MAC" "${DRY[@]}" -extra
eq "-extra on macOS: keeps macos" "core cli dev macos" "$(installed)"
new_case mixed
run "$BIN_LINUX" "${DRY[@]}" DEV,Core
eq "mixed case, comma list: install order" "core dev" "$(installed)"
has "mixed case, comma list: source shown" "from arguments (dev core)" "$OUT"
absent "dry run with words: nothing saved" "$SEL"
new_case spaced
run "$BIN_LINUX" "${DRY[@]}" all -dev
eq "all then -dev" "core cli extra" "$(installed)"

new_case unknown
run "$BIN_LINUX" --select core bogus
nonzero "unknown word: non-zero exit" "$RC"
has "unknown word: says which" "Unknown category: bogus" "$OUT"
has "unknown word: lists valid ones" "valid: all core cli dev extra" "$OUT"
absent "unknown word: nothing saved" "$SEL"
run "$BIN_LINUX" --dry-run --link-only bogus
nonzero "unknown word with --link-only: non-zero exit" "$RC"
has "unknown word with --link-only: says which" "Unknown category: bogus" "$OUT"
run "$BIN_LINUX" --bogus
nonzero "unknown option: non-zero exit" "$RC"
has "unknown option: says so" "Unknown option: --bogus" "$OUT"
new_case macos-linux
run "$BIN_LINUX" --select macos
nonzero "macos on Linux: non-zero exit" "$RC"
has "macos on Linux: says why" "category macos is macOS-only" "$OUT"
absent "macos on Linux: nothing saved" "$SEL"
run "$BIN_LINUX" "${DRY[@]}" -macos
eq "-macos on Linux: accepted" "$LINUX_ALL" "$(installed)"
new_case empty
run "$BIN_LINUX" --select core -core
nonzero "empty result: non-zero exit" "$RC"
has "empty result: points at --link-only" "--link-only" "$OUT"
absent "empty result: nothing saved" "$SEL"
run "$BIN_LINUX" "${DRY[@]}" -core,-cli,-dev,-extra
nonzero "everything excluded: non-zero exit" "$RC"
lacks "everything excluded: nothing installed" "Would install" "$OUT"

new_case all-linux
run "$BIN_LINUX" "${DRY[@]}" all
eq "all on Linux: no macos" "$LINUX_ALL" "$(installed)"
new_case all-mac
run "$BIN_MAC" "${DRY[@]}" --all
eq "--all on macOS: includes macos" "$MACOS_ALL" "$(installed)"

new_case override
save core
run "$BIN_LINUX" "${DRY[@]}" extra
eq "args over saved: args used" "extra" "$(installed)"
eq "args over saved, dry run: file kept" "core" "$(saved)"
run "$BIN_LINUX" --select dev
eq "args over saved, --select: replaced" "dev" "$(saved)"
run "$BIN_LINUX" --select
eq "saved, --select without terminal: kept" "dev" "$(saved)"
has "saved, --select without terminal: saved source" "saved in" "$OUT"

new_case bad-saved
save 'core bogus'
before=$(inode)
run "$BIN_LINUX" "${DRY[@]}"
has "bad saved word: warned with the file" "Ignoring 'bogus' in ~/.cfg/dotfiles/categories" "$OUT"
eq "bad saved word: rest used" "core" "$(installed)"
eq "bad saved word: file not rewritten" "$before" "$(inode)"
new_case macos-saved-linux
save macos
run "$BIN_LINUX" "${DRY[@]}"
has "saved macos on Linux: warned" "Ignoring 'macos'" "$OUT"
eq "saved macos on Linux: treated as absent" "$LINUX_ALL" "$(installed)"
has "saved macos on Linux: default source" "Selection: default (saved selection ignored" "$OUT"
lacks "saved macos on Linux: not reported as nothing saved" "nothing saved" "$OUT"

new_case help
run "$BIN_LINUX" --help
eq "help: exit 0" 0 "$RC"
# shellcheck disable=SC2088 # the literal text help prints
has "help: readable saved path" "~/.config/dotfiles/categories" "$OUT"
# shellcheck disable=SC2016 # the literal text help must not print
lacks "help: no unexpanded parameter" '${XDG_CONFIG_HOME' "$OUT"
new_case select-output
run "$BIN_LINUX" --select core
lacks "--select: no Dotfiles line" "Dotfiles:" "$OUT"
lacks "--select: no missing private repo line" "not found" "$OUT"
mkdir -p "$H/.dotfiles-private"
run "$BIN_LINUX" --select core
has "--select: private repo shown when present" "Private:   ~/.dotfiles-private present" "$OUT"
new_case install-output
run "$BIN_LINUX" "${DRY[@]}"
has "install run: missing private repo reported" "Private:   ~/.dotfiles-private not found" "$OUT"

# A failing private post-install is reported in the summary, not instead of
# it. setup.sh starts that script through bash, so this PATH carries one.
BIN_MACBASH=$WORK/bin-macbash
make_bin "$BIN_MACBASH" Darwin
ln -s "$BASH_BIN" "$BIN_MACBASH/bash"
for private_rc in 1 0; do
    new_case "private-rc$private_rc"
    mkdir -p "$H/.dotfiles-private"
    printf '#!/bin/bash\necho "fake-post-install $*"\nexit %s\n' "$private_rc" >"$H/.dotfiles-private/post-install.sh"
    run "$BIN_MACBASH" --dry-run --all
    has "private post-install rc $private_rc: it ran" "fake-post-install --dry-run" "$OUT"
    has "private post-install rc $private_rc: summary printed" "Symlinks:" "$OUT"
    if [[ $private_rc -eq 0 ]]; then
        eq "private post-install ok: exit 0" 0 "$RC"
        lacks "private post-install ok: no failure line" "Private post-install failed" "$OUT"
    else
        nonzero "private post-install fails: non-zero exit" "$RC"
        has "private post-install fails: named in the summary" "Private post-install failed (review output above)" "$OUT"
    fi
done

# A regular file where the directory belongs fails for root too.
new_case save-blocked
mkdir -p "$X"
: >"$X/dotfiles"
run "$BIN_LINUX" --select core
nonzero "unwritable save, --select: non-zero exit" "$RC"
has "unwritable save, --select: says so" "Nothing saved" "$OUT"
run "$BIN_MACLOG" --packages-only core
eq "unwritable save, install run: exit 0" 0 "$RC"
has "unwritable save, install run: warned" "for this run only" "$OUT"
eq "unwritable save, install run: selection used" "core" "$(bundled)"
new_case save-dir
mkdir -p "$SEL"
run "$BIN_LINUX" --select core
nonzero "categories is a directory, --select: non-zero exit" "$RC"
has "categories is a directory: says why" "not a regular file" "$OUT"
eq "categories is a directory: no stray file inside" "" "$(ls -A "$SEL")"
run "$BIN_LINUX" "${DRY[@]}"
has "categories is a directory, read: warned" "Ignoring ~/.cfg/dotfiles/categories (not a regular file)" "$OUT"
eq "categories is a directory, read: default used" "$LINUX_ALL" "$(installed)"
lacks "categories is a directory, read: not reported as nothing saved" "nothing saved" "$OUT"
new_case save-symlink
mkdir -p "${SEL%/*}"
printf 'core\n' >"$H/real-categories"
ln -s "$H/real-categories" "$SEL"
run "$BIN_LINUX" --select dev
eq "symlink to a file: replaced, exit 0" 0 "$RC"
eq "symlink to a file: new selection" "dev" "$(saved)"
if [[ -L "$SEL" ]]; then no "symlink to a file: link replaced by a file" "$SEL is still a symlink"; else ok "symlink to a file: link replaced by a file"; fi
eq "symlink to a file: link target untouched" "core" "$(cat "$H/real-categories")"

new_case link-only
save bogus
run "$BIN_LINUX" --dry-run --link-only
lacks "--link-only: no plan" "Install plan" "$OUT"
lacks "--link-only: saved file not read" "Ignoring" "$OUT"

new_case arm
run "$BIN_ARM" "${DRY[@]}" core
has "arm64: espanso skipped" "espanso: no .deb for arm64" "$OUT"
eq "arm64: not a failure" 0 "$RC"

new_case group-lists
run "$BIN_LINUX" "${DRY[@]}" --skip gpg cli
eq "--skip then a word: the word is a category" "cli" "$(installed)"
run "$BIN_LINUX" --dry-run --only shell,git core
eq "--only list then a word: the word is a category" "core" "$(installed)"
has "--only list: both groups" "Only groups: shell git" "$OUT"
run "$BIN_LINUX" --dry-run --skip gpg --skip bin core
has "--skip twice: both apply" "Skipping groups: gpg bin" "$OUT"
run "$BIN_LINUX" "${DRY[@]}" --skip gpg,bogus
nonzero "--skip unknown group: non-zero exit" "$RC"
has "--skip unknown group: says which" "Unknown symlink group: bogus" "$OUT"
run "$BIN_LINUX" "${DRY[@]}" --skip ,
nonzero "--skip without a name: non-zero exit" "$RC"
has "--skip without a name: says so" "--skip requires a comma separated list" "$OUT"
run "$BIN_LINUX" "${DRY[@]}" --only
nonzero "--only without an argument: non-zero exit" "$RC"

new_case modes
run "$BIN_LINUX" --dry-run --link-only core
nonzero "words with --link-only: non-zero exit" "$RC"
has "words with --link-only: says why" "Category words need an install run or --select" "$OUT"
run "$BIN_LINUX" --select --doctor core
nonzero "--select with --doctor: non-zero exit" "$RC"
has "--select with --doctor: says why" "--select, --doctor, --unlink and --update are mutually exclusive" "$OUT"
absent "--select with --doctor: nothing saved" "$SEL"

for saved_case in empty:'' blank-first:'\ncore\n'; do
    new_case "saved-${saved_case%%:*}"
    mkdir -p "${SEL%/*}"
    printf '%b' "${saved_case#*:}" >"$SEL"
    run "$BIN_LINUX" "${DRY[@]}"
    has "saved ${saved_case%%:*}: warned" "Ignoring ~/.cfg/dotfiles/categories (no categories on its first line)" "$OUT"
    eq "saved ${saved_case%%:*}: default used" "$LINUX_ALL" "$(installed)"
done
new_case saved-crlf
mkdir -p "${SEL%/*}"
printf 'core cli\r\n' >"$SEL"
run "$BIN_LINUX" "${DRY[@]}"
eq "saved CRLF: every word used" "core cli" "$(installed)"
lacks "saved CRLF: no warning" "Ignoring" "$OUT"

# apt-get must be on PATH, the dry run never calls it.
BIN_APT=$WORK/bin-apt
make_bin "$BIN_APT" Linux amd64
write_stub "$BIN_APT/apt-get" 'exit 0'
apt_line() { printf '%s\n' "$OUT" | grep 'Would install apt packages'; }
new_case apt-core
run "$BIN_APT" "${DRY[@]}" core
has "apt core: prerequisites" "Would install apt packages: build-essential" "$(apt_line)"
lacks "apt core: no extra packages" "ffmpeg" "$(apt_line)"
new_case apt-extra
run "$BIN_APT" "${DRY[@]}" extra
has "apt extra: extra packages" "ffmpeg tesseract-ocr tesseract-ocr-deu" "$(apt_line)"

plan_count() { printf '%s\n' "$OUT" | sed -n "s/.* \([0-9][0-9]*\)  $1.*/\1/p" | head -n 1; }
brew_listing() { printf '%s\n' "$OUT" | sed -n "/Would install from Brewfile\.$1:/,/==>/p"; }
EXTRA_DESC='Benchmarks, code stats'
new_case extra-linux
run "$BIN_LINUX" "${DRY[@]}" extra
eq "extra on Linux: plan counts brew and apt entries" 10 "$(plan_count "$EXTRA_DESC")"
lacks "extra on Linux: listing skips macOS-only entries" "ffmpeg" "$(brew_listing extra)"
lacks "extra on Linux: listing has no guard text" "OS.mac?" "$(brew_listing extra)"
new_case extra-mac
run "$BIN_MAC" "${DRY[@]}" extra
eq "extra on macOS: plan counts brew entries" 9 "$(plan_count "$EXTRA_DESC")"
has "extra on macOS: listing has macOS-only entries" "ffmpeg" "$(brew_listing extra)"
lacks "extra on macOS: listing has no guard text" "OS.mac?" "$(brew_listing extra)"

new_case espanso-wayland
EXTRA_ENV+=(XDG_SESSION_TYPE=wayland)
run "$BIN_APT" "${DRY[@]}" core
has "espanso Wayland: Wayland .deb" "espanso-debian-wayland-amd64.deb" "$OUT"
has "espanso Wayland: capability granted" "Would grant espanso the capability cap_dac_override+p" "$OUT"
new_case espanso-x11
EXTRA_ENV+=(XDG_SESSION_TYPE=x11)
run "$BIN_APT" "${DRY[@]}" core
has "espanso X11: X11 .deb" "espanso-debian-x11-amd64.deb" "$OUT"
lacks "espanso X11: no capability" "cap_dac_override" "$OUT"

BIN_ESPANSO=$WORK/bin-espanso
make_bin "$BIN_ESPANSO" Linux amd64
write_stub "$BIN_ESPANSO/apt-get" 'exit 0'
write_stub "$BIN_ESPANSO/espanso" 'exit 0'
write_stub "$BIN_ESPANSO/getcap" 'exit 0'
new_case espanso-installed-no-cap
EXTRA_ENV+=(XDG_SESSION_TYPE=wayland)
run "$BIN_ESPANSO" "${DRY[@]}" core
has "espanso installed: not reinstalled" "Already installed: espanso" "$OUT"
has "espanso installed without capability: granted" "Would grant espanso the capability cap_dac_override+p" "$OUT"
# shellcheck disable=SC2016 # expands in the stub
write_stub "$BIN_ESPANSO/getcap" 'echo "$1 cap_dac_override=p"'
new_case espanso-installed-cap
EXTRA_ENV+=(XDG_SESSION_TYPE=wayland)
run "$BIN_ESPANSO" "${DRY[@]}" core
lacks "espanso installed with capability: not granted again" "Would grant espanso" "$OUT"
rm "$BIN_ESPANSO/getcap"
new_case espanso-installed-no-getcap
EXTRA_ENV+=(XDG_SESSION_TYPE=wayland)
run "$BIN_ESPANSO" "${DRY[@]}" core
has "espanso installed, no getcap: granted" "Would grant espanso the capability cap_dac_override+p" "$OUT"

BIN_MISE=$WORK/bin-mise
make_bin "$BIN_MISE" Linux
write_stub "$BIN_MISE/mise" 'echo "mise broke" >&2; exit 1'
new_case doctor-mise
run "$BIN_MISE" --doctor
nonzero "doctor, mise ls fails: non-zero exit" "$RC"
has "doctor, mise ls fails: reported" "mise ls --missing failed (run it to see why)" "$OUT"
has "doctor, mise ls fails: summary printed" "issue(s) found" "$OUT"
write_stub "$BIN_MISE/mise" 'echo "mise warning" >&2; exit 0'
new_case doctor-mise-noise
run "$BIN_MISE" --doctor
has "doctor, mise ls warns on stderr: all tools installed" "All tools installed" "$OUT"
lacks "doctor, mise ls warns on stderr: not missing tools" "Missing tools" "$OUT"

PTY_PROBE=$(bounded pty "$BASH_BIN" -c '[ -t 0 ] && echo PTY-YES' </dev/null 2>&1)
if [[ "$PTY_PROBE" != *PTY-YES* ]]; then
    skip "terminal cases" "no pseudo-terminal (sandboxed?)"
else
    new_case tty-enter
    ptyrun '\n' "$BIN_LINUX" --select
    eq "tty Enter: exit 0" 0 "$RC"
    has "tty Enter: hint" "$PROMPT_HINT" "$OUT"
    has "tty Enter: default all" "Install which? [all]: " "$OUT"
    eq "tty Enter: all saved" "all" "$(saved)"
    has "tty: table lists packages" "Shell, git, tmux" "$OUT"
    lacks "tty on Linux: no macos row" "Hammerspoon" "$OUT"

    new_case tty-words
    ptyrun 'Core dev\n' "$BIN_LINUX" --select
    eq "tty words: saved" "core dev" "$(saved)"
    has "tty words: prompt source" "from the prompt (core dev)" "$OUT"

    new_case tty-invalid
    ptyrun 'bogus\ncli\n' "$BIN_LINUX" --select
    has "tty invalid: error shown" "Unknown category: bogus" "$OUT"
    prompts=$(printf '%s\n' "$OUT" | grep -o 'Install which?' | wc -l | tr -d ' ')
    eq "tty invalid: asked again" 2 "$prompts"
    eq "tty invalid: then saved" "cli" "$(saved)"

    new_case tty-quit
    ptyrun 'q\n' "$BIN_LINUX" --select
    nonzero "tty q: non-zero exit" "$RC"
    has "tty q: says so" "Nothing installed" "$OUT"
    absent "tty q: nothing saved" "$SEL"

    new_case tty-eof
    ptyrun '\0004' "$BIN_LINUX" --select
    eq "tty EOF: exit 0" 0 "$RC"
    eq "tty EOF: default saved" "all" "$(saved)"

    new_case tty-keep-subset
    save 'core cli'
    ptyrun '\n' "$BIN_LINUX" --select
    eq "tty saved subset: exit 0" 0 "$RC"
    has "tty saved subset: asked with it as default" "Install which? [core cli]: " "$OUT"
    eq "tty saved subset, Enter: file unchanged" "core cli" "$(saved)"
    has "tty saved subset, Enter: plan has only those" "Skipped:   dev extra" "$OUT"

    # Typed text, then Ctrl-D twice: the first hands "core" to read without a
    # newline, the second is EOF.
    new_case tty-eof-text
    ptyrun 'core\0004\0004' "$BIN_LINUX" --select
    eq "tty EOF after text: exit 0" 0 "$RC"
    eq "tty EOF after text: typed text kept" "core" "$(saved)"

    new_case tty-stdout-redirected
    EXTRA_ENV+=(STDOUT_TO="$CASE/stdout")
    ptyrun '\n' "$BIN_LINUX" --select
    has "stdout redirected: prompt still on the terminal" "Install which? [all]: " "$OUT"
    lacks "stdout redirected: prompt not in the log" "Install which?" "$(cat "$CASE/stdout")"
    eq "stdout redirected: saved" "all" "$(saved)"

    new_case tty-stderr-redirected
    EXTRA_ENV+=(STDERR_TO="$CASE/stderr")
    ptyrun '' "$BIN_LINUX" --select
    eq "stderr redirected: exit 0 without asking" 0 "$RC"
    lacks "stderr redirected: no prompt" "Install which?" "$OUT$(cat "$CASE/stderr")"
    has "stderr redirected: default taken" "Selection: default" "$OUT"
    absent "stderr redirected: nothing saved" "$SEL"

    new_case tty-handover
    save 'core dev'
    before=$(inode)
    ptyrun '' "$BIN_MACLOG" --packages-only
    eq "hand-over: exit 0" 0 "$RC"
    lacks "hand-over: no prompt" "Install which?" "$OUT"
    eq "hand-over: only the saved categories bundled" "core dev" "$(bundled)"
    eq "hand-over: every bundle with --no-upgrade" 0 "$(upgrading_bundles)"
    eq "hand-over: saved file not rewritten" "$before" "$(inode)"

    new_case tty-dry
    ptyrun '' "$BIN_LINUX" "${DRY[@]}"
    lacks "tty dry run: never asks" "Install which?" "$OUT"
    eq "tty dry run: all" "$LINUX_ALL" "$(installed)"
    selection_line=$(printf '%s\n' "$OUT" | grep 'Selection:')
    has "tty dry run: reason names the dry run" "a dry run does not ask" "$selection_line"
    lacks "tty dry run: reason is not a missing terminal" "no terminal" "$selection_line"
    absent "tty dry run: nothing saved" "$SEL"

    new_case tty-dry-saved
    save dev
    ptyrun '' "$BIN_LINUX" "${DRY[@]}"
    lacks "tty dry run with saved: never asks" "Install which?" "$OUT"
    eq "tty dry run with saved: saved used" "dev" "$(installed)"
fi

printf -- '---\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
exit $((FAIL > 0))
