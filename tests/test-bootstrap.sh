#!/usr/bin/env bash
# Stub suite for bootstrap.sh: every tool it calls is faked in a temp PATH
# with a temp HOME, so no case reaches the network, sudo, apt, brew, the real
# ~/.ssh, the agent or the Keychain. Runs bootstrap the way the README does:
# bash -c "<script text>" -- <args>.
set -uo pipefail

DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BOOTSTRAP=${BOOTSTRAP:-"$DIR/../bootstrap.sh"}
BASH_BIN=$BASH
PASS=0
FAIL=0
SKIP=0
WORK=$(mktemp -d "${TMPDIR:-/tmp}/tboot.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

ok()   { PASS=$((PASS + 1)); printf 'PASS  %s\n' "$1"; }
no()   { FAIL=$((FAIL + 1)); printf 'FAIL  %s (%s)\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP  %s (%s)\n' "$1" "$2"; }

eq()    { if [[ "$2" == "$3" ]]; then ok "$1"; else no "$1" "expected [$2] got [$3]"; fi; }
has()   { if [[ "$3" == *"$2"* ]]; then ok "$1"; else no "$1" "[$2] not in [$3]"; fi; }
lacks() { if [[ "$3" != *"$2"* ]]; then ok "$1"; else no "$1" "[$2] found in [$3]"; fi; }
nonzero() { if [[ "$2" =~ ^[0-9]+$ && "$2" != 0 ]]; then ok "$1"; else no "$1" "exit code 0"; fi; }
absent()  { if [[ ! -e "$2" ]]; then ok "$1"; else no "$1" "$2 exists"; fi; }

count() {
    local n=0 line
    while IFS= read -r line; do
        # shellcheck disable=SC2254 # $1 is a glob by design
        case "$line" in
            $1) n=$((n + 1)) ;;
        esac
    done <<<"$2"
    printf '%s\n' "$n"
}

RUN_LIMIT_SECS=30
RC_POLLS=200
RC_POLL_SECS=0.1
WATCH_POLL_SECS=0.1
# Larger than a pipe buffer plus bsdtar's read-ahead (1 MiB was not, measured
# 2026-11-22), so a tar fed through a pipe quits before the writer is done.
CORRUPT_SNAPSHOT_BYTES=8388608

FAKE_HOST=testhost
FAKE_DATE=2026-11-21
FAKE_UID=1000
PRIVATE_URL='git@example.invalid:owner/private-repo.git'
ENV_PRIVATE_URL='git@example.invalid:owner/env-repo.git'
PUBLIC_HTTPS_URL='https://github.com/DreamTimeZ/.dotfiles.git'
PUBLIC_SSH_URL='git@github.com:DreamTimeZ/.dotfiles.git'
BREW_URL='https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh'
SNAPSHOT_URL='https://github.com/DreamTimeZ/.dotfiles/archive/refs/heads/main.tar.gz'
KEY_PAGE='https://github.com/settings/ssh/new'
GITHUB_HOST_KEY='github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'
GITHUB_KEY_BLOB='AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'
# shellcheck disable=SC2088 # the literal value bootstrap hands to git
CLONE_SSH_COMMAND='ssh -i ~/.ssh/github -o IdentitiesOnly=yes'
APT_ALL='build-essential procps curl file git openssh-client'
SSH_OK_TEXT="Hi tester! You've successfully authenticated, but GitHub does not provide shell access."

REAL_SSH_KEYGEN=$(command -v ssh-keygen) || { echo "ssh-keygen not found" >&2; exit 1; }
# Linux is simulated on every host, so a real Linux Homebrew on the host is
# what bootstrap finds whenever a case leaves no brew on PATH.
HOST_LINUXBREW=/home/linuxbrew/.linuxbrew/bin/brew

write_stub() {
    {
        printf '#!/bin/sh\n'
        printf "echo \"%s \$*\" >> \"\$STUB_LOG\"\n" "$2"
        printf '%s\n' "$3"
    } >"$1/$2"
    chmod +x "$1/$2"
}

stub_body() {
    case "$1" in
        id) cat <<'EOF' ;;
echo "$FAKE_UID"
EOF
        uname) echo 'echo Linux' ;;
        hostname) echo "echo $FAKE_HOST" ;;
        date) echo "echo $FAKE_DATE" ;;
        sudo) cat <<'EOF' ;;
exec "$@"
EOF
        dpkg-query) cat <<'EOF' ;;
for pkg; do :; done
if grep -qx -- "$pkg" "$DPKG_STATE"; then printf "install ok installed"; exit 0; fi
echo "dpkg-query: no packages found matching $pkg" >&2
exit 1
EOF
        apt-get) cat <<'EOF' ;;
if [ "$1" = install ]; then
  shift
  for p; do case "$p" in -*) ;; *) echo "$p" >> "$DPKG_STATE" ;; esac; done
fi
EOF
        curl) cat <<'EOF' ;;
out=
while [ $# -gt 1 ]; do [ "$1" = -o ] && out=$2; shift; done
url=$1
emit() { if [ -n "$out" ]; then cat "$1" >"$out"; else cat "$1"; fi; }
case "$url" in
  "$BREW_URL") [ "${CURL_FAIL:-}" = 1 ] && exit 22; emit "$INSTALLER" ;;
  "$SNAPSHOT_URL") [ "${SNAPSHOT_FAIL:-}" = 1 ] && exit 22; emit "$SNAPSHOT" ;;
  *) exit 22 ;;
esac
EOF
        brew) cat <<'EOF' ;;
[ "$1" = shellenv ] && echo "export BREW_SHELLENV_MARK=evaluated"
exit 0
EOF
        ssh-keygen) cat <<'EOF' ;;
case " $* " in
  *" -t "*)
    while [ $# -gt 0 ]; do [ "$1" = -f ] && file=$2; shift; done
    exec "$REAL_SSH_KEYGEN" -q -t ed25519 -N "" -C fake -f "$file" ;;
esac
exec "$REAL_SSH_KEYGEN" "$@"
EOF
        ssh-add) cat <<'EOF' ;;
if [ "$1" = -l ]; then
  case "${SSH_ADD_LIST:-empty}" in
    noagent) echo "Could not open a connection to your authentication agent." >&2; exit 2 ;;
    has) "$REAL_SSH_KEYGEN" -lf "$HOME/.ssh/github.pub"; exit 0 ;;
    *) echo "The agent has no identities."; exit 1 ;;
  esac
fi
exit "${SSH_ADD_RC:-0}"
EOF
        ssh) cat <<'EOF' ;;
n=$(($(cat "$SSH_COUNT") + 1))
echo "$n" > "$SSH_COUNT"
i=0
for r in $SSH_RESULTS; do i=$((i + 1)); result=$r; [ "$i" -eq "$n" ] && break; done
case "$result" in
  ok) echo "$SSH_OK_TEXT" >&2; exit 1 ;;
  noauth) echo "Connection closed by remote host" >&2; exit 1 ;;
  *) echo "git@github.com: Permission denied (publickey)." >&2; exit 255 ;;
esac
EOF
        git) cat <<'EOF' ;;
echo "GIT_SSH_COMMAND=${GIT_SSH_COMMAND:-}" >> "$STUB_LOG"
if [ "$1" = -C ]; then
  repo=$2
  [ -d "$repo/.git" ] || { echo "fatal: not a git repository" >&2; exit 128; }
  case "$3 $4 $5" in
    "remote get-url origin")
      [ -f "$repo/.git/origin" ] || { echo "error: No such remote 'origin'" >&2; exit 2; }
      cat "$repo/.git/origin" ;;
    "remote set-url origin") echo "$6" > "$repo/.git/origin" ;;
  esac
  exit 0
fi
if [ "$1" = clone ]; then
  for dst; do :; done
  mkdir -p "$dst/.git"
  echo "$2" > "$dst/.git/origin"
  [ "${CLONE_NO_SETUP:-}" = 1 ] || cp "$SETUP_STUB" "$dst/setup.sh"
fi
EOF
        *) echo 'exit 0' ;;
    esac
}

ALL_STUBS=(id uname hostname date sudo dpkg-query apt-get curl ssh-keygen ssh-add ssh git pbcopy open xdg-open)
make_bin() {
    local dir=$1 tool
    shift
    mkdir -p "$dir"
    for tool; do write_stub "$dir" "$tool" "$(stub_body "$tool")"; done
}

BIN=$WORK/bin
make_bin "$BIN" "${ALL_STUBS[@]}"
BIN_NOAPT=$WORK/bin-noapt
NOAPT_STUBS=()
for tool in "${ALL_STUBS[@]}"; do
    [[ "$tool" == apt-get ]] || NOAPT_STUBS+=("$tool")
done
make_bin "$BIN_NOAPT" "${NOAPT_STUBS[@]}"
BREW_STUB_DIR=$WORK/brew-src
make_bin "$BREW_STUB_DIR" brew

INSTALLER=$WORK/installer.sh
cat >"$INSTALLER" <<'EOF'
echo "brew-installer" >> "$STUB_LOG"
[ "${INSTALLER_NOBREW:-}" = 1 ] && exit 0
cat "$BREW_STUB_DIR/brew" > "$CASE_BIN/brew"
chmod +x "$CASE_BIN/brew"
EOF

SETUP_STUB=$WORK/setup-stub.sh
cat >"$SETUP_STUB" <<'EOF'
#!/bin/sh
echo "setup.sh${*:+ $*}" >> "$STUB_LOG"
if [ "${1:-}" = --select ]; then
  echo "$0" > "$STUB_LOG.select"
  exit "${SELECT_RC:-0}"
fi
echo "BREW_SHELLENV_MARK=${BREW_SHELLENV_MARK:-}" > "$STUB_LOG.env"
EOF
chmod +x "$SETUP_STUB"

# GitHub's archive layout: one top-level directory holding the tree.
SNAPSHOT=$WORK/snapshot.tar.gz
SNAPSHOT_TOP=.dotfiles-main
mkdir -p "$WORK/snapshot-src/$SNAPSHOT_TOP"
cp "$SETUP_STUB" "$WORK/snapshot-src/$SNAPSHOT_TOP/setup.sh"
COPYFILE_DISABLE=1 tar -czf "$SNAPSHOT" -C "$WORK/snapshot-src" "$SNAPSHOT_TOP" \
    || { echo "could not build the snapshot archive" >&2; exit 1; }

# The only host tools on a case's PATH, so a tool a case leaves unstubbed fails
# instead of running for real. tar and gzip only unpack the fake snapshot.
SYS=$WORK/sys
mkdir -p "$SYS"
ln -s "$BASH_BIN" "$SYS/bash"
for tool in cat chmod cp grep gzip mkdir mktemp rm tail tar; do
    ln -s "$(command -v "$tool")" "$SYS/$tool"
done

PTY_WRAP=$WORK/pty-wrap.sh
cat >"$PTY_WRAP" <<'EOF'
bash -c "$(cat "$BOOTSTRAP_FILE")" -- "$@"
echo "$?" > "$RC_FILE"
EOF

new_case() {
    CASE=$WORK/case/$1
    H=$CASE/home
    CB=$CASE/bin
    LOG=$CASE/log
    mkdir -p "$H" "$CB" "$CASE/tmp"
    cp "$BREW_STUB_DIR/brew" "$CB/brew"
    local pkgs=${2-$APT_ALL} pkg
    : >"$CASE/dpkg"
    for pkg in $pkgs; do printf '%s\n' "$pkg" >>"$CASE/dpkg"; done
    : >"$LOG"
}

no_brew() { rm -f "$CB/brew"; }

case_env() {
    CASE_ENV=(HOME="$H" TMPDIR="$CASE/tmp" STUB_LOG="$LOG" CASE_BIN="$CB"
        DPKG_STATE="$CASE/dpkg" SSH_COUNT="$CASE/ssh-count" INSTALLER="$INSTALLER"
        BREW_STUB_DIR="$BREW_STUB_DIR" BREW_URL="$BREW_URL" REAL_SSH_KEYGEN="$REAL_SSH_KEYGEN"
        SNAPSHOT_URL="$SNAPSHOT_URL" SNAPSHOT="$SNAPSHOT"
        FAKE_UID="$FAKE_UID" SSH_OK_TEXT="$SSH_OK_TEXT" SETUP_STUB="$SETUP_STUB" SSH_RESULTS=fail)
}

# Own process groups, so the kill reaches the whole tree and the watchdog's sleep.
bounded() {
    local pid watchdog rc
    set -m
    "$@" &
    pid=$!
    sleep "$RUN_LIMIT_SECS" &
    watchdog=$!
    set +m
    while kill -0 "$pid" 2>/dev/null && kill -0 "$watchdog" 2>/dev/null; do sleep "$WATCH_POLL_SECS"; done
    kill -TERM -- "-$pid" "-$watchdog" 2>/dev/null
    wait "$pid"
    rc=$?
    wait "$watchdog" 2>/dev/null
    return "$rc"
}

# shellcheck disable=SC2329 # invoked through bounded
plain_session() {
    env -i "${CASE_ENV[@]}" PATH="$CB:$RUN_BIN:$SYS" ${RUN_VARS[@]+"${RUN_VARS[@]}"} \
        "$SYS/bash" -c "$(cat "$RUN_SCRIPT")" -- "$@" </dev/null
}

run() {
    RUN_BIN=$BIN
    RUN_SCRIPT=$BOOTSTRAP
    RUN_VARS=()
    [[ "$1" == -b ]] && { RUN_BIN=$2; shift 2; }
    [[ "$1" == -s ]] && { RUN_SCRIPT=$2; shift 2; }
    while [[ "$1" != -- ]]; do RUN_VARS+=("$1"); shift; done
    shift
    : >"$LOG"
    rm -f "$LOG.env" "$LOG.select"
    echo 0 >"$CASE/ssh-count"
    case_env
    bounded plain_session ${@+"$@"} >"$CASE/out" 2>&1
    RC=$?
    OUT=$(cat "$CASE/out")
    CALLS=$(cat "$LOG")
}

# shellcheck disable=SC2329 # invoked through bounded
pty() {
    if script --version >/dev/null 2>&1; then
        script -qec "$(printf '%q ' "$@")" /dev/null
    else
        script -q /dev/null "$@"
    fi
}

# script forwards EOF on its stdin into the session, where bootstrap's next read
# returns early (macOS and util-linux 2.39.3, measured 2026-11-23), so stdin
# stays open until bootstrap has finished.
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
    feed "$input" | pty env -i "${CASE_ENV[@]}" PATH="$CB:$RUN_BIN:$SYS" \
        BOOTSTRAP_FILE="$RUN_SCRIPT" RC_FILE="$RC_FILE" ${RUN_VARS[@]+"${RUN_VARS[@]}"} \
        "$SYS/bash" "$PTY_WRAP" "$@"
}

ptyrun() {
    local input=$1
    shift
    RUN_BIN=$BIN
    RUN_SCRIPT=$BOOTSTRAP
    RUN_VARS=()
    [[ "$1" == -b ]] && { RUN_BIN=$2; shift 2; }
    [[ "$1" == -s ]] && { RUN_SCRIPT=$2; shift 2; }
    while [[ "$1" != -- ]]; do RUN_VARS+=("$1"); shift; done
    shift
    : >"$LOG"
    rm -f "$LOG.env" "$LOG.select"
    echo 0 >"$CASE/ssh-count"
    RC_FILE=$CASE/rc
    rm -f "$RC_FILE"
    case_env
    bounded pty_session "$input" ${@+"$@"} >"$CASE/out" 2>&1
    if [[ -e "$RC_FILE" ]]; then RC=$(cat "$RC_FILE"); else RC=none; fi
    OUT=$(tr -d '\r' <"$CASE/out")
    CALLS=$(cat "$LOG")
}

ssh_calls() { count 'ssh *' "$CALLS"; }
keytool_calls() { printf '%s\n' "$(($(count 'ssh-keygen *' "$CALLS") + $(count 'ssh-add *' "$CALLS") + $(count 'ssh *' "$CALLS")))"; }
last_call() { printf '%s\n' "$CALLS" | tail -n 1; }
call_line() { printf '%s\n' "$CALLS" | grep -F -- "$1" | head -n 1; }

pregenerate_key() {
    mkdir -m 700 "$H/.ssh"
    "$REAL_SSH_KEYGEN" -q -t ed25519 -N '' -C fixture -f "$H/.ssh/github"
}

line_of() {
    local n=0 line
    while IFS= read -r line; do
        n=$((n + 1))
        # shellcheck disable=SC2254 # $1 is a glob by design
        case "$line" in
            $1) printf '%s\n' "$n"; return ;;
        esac
    done <<<"$CALLS"
    printf '0\n'
}

shellenv_mark() { cat "$LOG.env" 2>/dev/null; }
select_path() { cat "$LOG.select" 2>/dev/null; }
select_call() { call_line 'setup.sh --select'; }
brew_downloads() { count "curl *$BREW_URL" "$CALLS"; }
snapshot_downloads() { count "curl *$SNAPSHOT_URL" "$CALLS"; }
tmp_left() { ls -A "$CASE/tmp"; }

before() {
    local first second
    first=$(line_of "$2")
    second=$(line_of "$3")
    if [[ "$first" -gt 0 && "$second" -gt "$first" ]]; then
        ok "$1"
    else
        no "$1" "[$2] at call $first, [$3] at call $second"
    fi
}

# Without an argument a plain tree (as the container test copies it).
fake_public_repo() {
    mkdir -p "$H/.dotfiles"
    cp "$SETUP_STUB" "$H/.dotfiles/setup.sh"
    if [[ $# -gt 0 ]]; then
        mkdir "$H/.dotfiles/.git"
        printf '%s\n' "$1" >"$H/.dotfiles/.git/origin"
    fi
}

LINES_TOTAL=$(wc -l <"$BOOTSTRAP")
sed '$d' "$BOOTSTRAP" >"$WORK/cut-last.sh"
head -n "$((LINES_TOTAL / 2))" "$BOOTSTRAP" >"$WORK/cut-mid.sh"
for cut in cut-last cut-mid; do
    new_case "$cut" ''
    no_brew
    run -s "$WORK/$cut.sh" -- "$PRIVATE_URL"
    eq "T1 $cut: nothing called" "" "$CALLS"
    absent "T1 $cut: nothing cloned" "$H/.dotfiles"
done

# The needle is assembled so this file never contains it.
LEAK_REPO=dotfiles-private
LEAK_PATTERN="$LEAK_REPO\\.git|DreamTimeZ/\\.$LEAK_REPO"
leak=$(grep -cE "$LEAK_PATTERN" "$BOOTSTRAP")
eq "T11 bootstrap.sh: no private repo URL" 0 "$leak"
foreign=$(grep -oE 'DreamTimeZ/[^ "'\'')]*' "$BOOTSTRAP" | grep -vE '^DreamTimeZ/\.dotfiles(\.git|/main/bootstrap\.sh|/archive/refs/heads/main\.tar\.gz)$')
eq "T11 bootstrap.sh: only the public repo's URLs" "" "$foreign"
REPO_ROOT=$(cd "$DIR/.." && pwd)
if ! command -v git >/dev/null; then
    skip "T11 public tree: no private repo URL" "git not available"
elif [[ "$(git -C "$REPO_ROOT" rev-parse --is-inside-work-tree 2>/dev/null)" != true ]]; then
    skip "T11 public tree: no private repo URL" "$REPO_ROOT is not a git work tree"
else
    leaks=''
    scanned=0
    while IFS= read -r -d '' path; do
        # A deleted tracked file is still listed.
        [[ -f "$REPO_ROOT/$path" ]] || continue
        scanned=$((scanned + 1))
        if grep -qE "$LEAK_PATTERN" "$REPO_ROOT/$path"; then leaks="$leaks $path"; fi
    done < <(git -C "$REPO_ROOT" ls-files -z --cached --others --exclude-standard)
    eq "T11 public tree: no private repo URL ($scanned files)" "" "$leaks"
fi

new_case root
run FAKE_UID=0 -- "$PRIVATE_URL"
nonzero "T2 root: non-zero exit" "$RC"
eq "T2 root: only id called" "id -u" "$CALLS"
has "T2 root: says why" "not as root" "$OUT"

new_case words
run -- core cli -extra
eq "T12 words: exit 0" 0 "$RC"
eq "T12 words: forwarded in order to --select" "setup.sh --select core cli -extra" "$(select_call)"
has "T12 words: none taken as the URL" "No private repo URL given" "$OUT"
eq "T12 words: plain setup.sh exec'd" "setup.sh" "$(last_call)"
new_case url-first
run -- "$PRIVATE_URL" core
eq "T12 URL then word: exit 0" 0 "$RC"
eq "T12 URL then word: --select gets the word" "setup.sh --select core" "$(select_call)"
has "T12 URL then word: URL was seen" "stdin is not a terminal" "$OUT"
new_case url-last
run -- core "$PRIVATE_URL"
eq "T12 word then URL: exit 0" 0 "$RC"
eq "T12 word then URL: --select gets the word" "setup.sh --select core" "$(select_call)"
has "T12 word then URL: URL was seen" "stdin is not a terminal" "$OUT"
new_case two-urls
run -- "$PRIVATE_URL" core "$ENV_PRIVATE_URL"
nonzero "T12 two URLs: non-zero exit" "$RC"
has "T12 two URLs: says why" "Two private repo URLs" "$OUT"
eq "T12 two URLs: nothing called" "" "$CALLS"
new_case option
run -- core --dry-run
nonzero "T12 --dry-run: non-zero exit" "$RC"
has "T12 --dry-run: says why" "Unknown option --dry-run" "$OUT"
has "T12 --dry-run: points at setup.sh" "$H/.dotfiles/setup.sh" "$OUT"
eq "T12 --dry-run: nothing called" "" "$CALLS"
for opt in -n -h -s -; do
    new_case "short-option$opt"
    if [[ "$opt" == -s ]]; then run -- "$opt" gpg; else run -- core "$opt"; fi
    nonzero "T12 $opt: non-zero exit" "$RC"
    has "T12 $opt: says why" "Unknown option $opt:" "$OUT"
    eq "T12 $opt: nothing called" "" "$CALLS"
done

new_case clone-no-setup
run CLONE_NO_SETUP=1 --
nonzero "T12 clone without setup.sh: non-zero exit" "$RC"
has "T12 clone without setup.sh: cloned first" "git clone $PUBLIC_HTTPS_URL $H/.dotfiles" "$CALLS"
has "T12 clone without setup.sh: names the file" "$H/.dotfiles/setup.sh" "$OUT"

new_case select-snapshot 'procps'
run --
eq "T13 snapshot: exit 0" 0 "$RC"
eq "T13 snapshot: fetched once" 1 "$(snapshot_downloads)"
eq "T13 snapshot: --select without words" "setup.sh --select" "$(select_call)"
selected_by=$(select_path)
has "T13 snapshot: its setup.sh ran --select" "$CASE/tmp/dotfiles-snapshot." "$selected_by"
absent "T13 snapshot: temp dir removed" "${selected_by%/setup.sh}"
eq "T13 snapshot: nothing left in TMPDIR" "" "$(tmp_left)"
eq "T13 snapshot: plain setup.sh exec'd" "setup.sh" "$(last_call)"
before "T13 order: --select before apt" 'setup.sh --select*' 'sudo apt-get *'
before "T13 order: apt before Homebrew" 'sudo apt-get *' 'brew shellenv*'
before "T13 order: the clone before Homebrew" 'git clone *' 'brew shellenv*'
BIN_MAC=$WORK/bin-mac
make_bin "$BIN_MAC" "${ALL_STUBS[@]}"
write_stub "$BIN_MAC" uname 'echo Darwin'
new_case order-macos
run -b "$BIN_MAC" --
eq "T13 macOS: exit 0" 0 "$RC"
eq "T13 macOS: no apt" 0 "$(count 'sudo apt-get *' "$CALLS")"
before "T13 macOS: Homebrew before the clone" 'brew shellenv*' 'git clone *'
new_case select-local
fake_public_repo "$PUBLIC_HTTPS_URL"
run -- core
eq "T13 ~/.dotfiles present: exit 0" 0 "$RC"
eq "T13 ~/.dotfiles present: its setup.sh ran --select" "$H/.dotfiles/setup.sh" "$(select_path)"
eq "T13 ~/.dotfiles present: no snapshot download" 0 "$(snapshot_downloads)"
eq "T13 ~/.dotfiles present: words forwarded" "setup.sh --select core" "$(select_call)"
new_case snapshot-fail 'procps'
run SNAPSHOT_FAIL=1 -- core
nonzero "T13 snapshot download fails: non-zero exit" "$RC"
has "T13 snapshot download fails: says why" "Could not download the public repo snapshot" "$OUT"
eq "T13 snapshot download fails: nothing selected, installed or cloned" 0 \
    "$(($(count 'setup.sh*' "$CALLS") + $(count '*apt-get *' "$CALLS") + $(count 'brew *' "$CALLS") + $(brew_downloads) + $(count 'git *' "$CALLS")))"
eq "T13 snapshot download fails: nothing left in TMPDIR" "" "$(tmp_left)"
new_case snapshot-corrupt
# 0xFF bytes: bsdtar reads zero blocks as an empty tar and text lines as mtree.
head -c "$CORRUPT_SNAPSHOT_BYTES" /dev/zero | LC_ALL=C tr '\0' '\377' >"$CASE/not-an-archive"
run SNAPSHOT="$CASE/not-an-archive" --
nonzero "T13 snapshot not an archive: non-zero exit" "$RC"
has "T13 snapshot not an archive: says why" "Could not unpack the public repo snapshot" "$OUT"
lacks "T13 snapshot not an archive: not blamed on the download" "Could not download" "$OUT"
eq "T13 snapshot not an archive: nothing selected" 0 "$(count 'setup.sh*' "$CALLS")"
eq "T13 snapshot not an archive: nothing left in TMPDIR" "" "$(tmp_left)"
new_case cancel 'procps'
run SELECT_RC=1 -- core
nonzero "T13 selection cancelled: non-zero exit" "$RC"
has "T13 selection cancelled: says why" "Package selection cancelled" "$OUT"
eq "T13 selection cancelled: --select was the last call" "setup.sh --select core" "$(last_call)"
eq "T13 selection cancelled: no apt, Homebrew or clone" 0 \
    "$(($(count '*apt-get *' "$CALLS") + $(count 'brew *' "$CALLS") + $(brew_downloads) + $(count 'git *' "$CALLS")))"
eq "T13 selection cancelled: nothing left in TMPDIR" "" "$(tmp_left)"

new_case nourl
run --
eq "T3 no URL: exit 0" 0 "$RC"
has "T3 no URL: public https clone" "git clone $PUBLIC_HTTPS_URL $H/.dotfiles" "$CALLS"
eq "T3 no URL: no ssh tools" 0 "$(keytool_calls)"
has "T3 no URL: reason shown" "No private repo URL given" "$OUT"
eq "T3 no URL: plain setup.sh exec'd" "setup.sh" "$(last_call)"
absent "T3 no URL: no private repo" "$H/.dotfiles-private"

new_case notty-arg
run -- "$PRIVATE_URL"
eq "T4 arg, no TTY: exit 0" 0 "$RC"
has "T4 arg, no TTY: public https clone" "git clone $PUBLIC_HTTPS_URL $H/.dotfiles" "$CALLS"
eq "T4 arg, no TTY: no ssh tools" 0 "$(keytool_calls)"
has "T4 arg, no TTY: reason shown" "stdin is not a terminal" "$OUT"
lacks "T4 arg, no TTY: URL was seen" "No private repo URL given" "$OUT"
eq "T4 arg, no TTY: plain setup.sh exec'd" "setup.sh" "$(last_call)"
new_case notty-env
run DOTFILES_PRIVATE_URL="$ENV_PRIVATE_URL" --
has "T4 env, no TTY: reason shown" "stdin is not a terminal" "$OUT"
eq "T4 env, no TTY: no ssh tools" 0 "$(keytool_calls)"
eq "T4 env, no TTY: plain setup.sh exec'd" "setup.sh" "$(last_call)"

new_case apt-all
run --
eq "T7 apt all installed: no apt-get" 0 "$(count 'apt-get *' "$CALLS")"
new_case apt-some 'procps curl'
run --
has "T7 apt some missing: update" "sudo apt-get update" "$CALLS"
eq "T7 apt some missing: only the missing ones" "sudo apt-get install -y build-essential file git openssh-client" \
    "$(call_line 'sudo apt-get install')"
eq "T7 apt some missing: exit 0" 0 "$RC"
new_case noapt
run -b "$BIN_NOAPT" --
nonzero "T7 no apt-get: non-zero exit" "$RC"
has "T7 no apt-get: says why" "apt-get not found" "$OUT"
eq "T7 no apt-get: nothing selected, installed or cloned" 0 \
    "$(($(count 'setup.sh*' "$CALLS") + $(snapshot_downloads) + $(brew_downloads) + $(count 'git *' "$CALLS")))"
new_case brew-present
run --
eq "T7 brew present: no installer download" 0 "$(brew_downloads)"
eq "T7 brew present: shellenv evaluated" "BREW_SHELLENV_MARK=evaluated" "$(shellenv_mark)"
new_case public-present
fake_public_repo "$PUBLIC_HTTPS_URL"
run --
eq "T7 ~/.dotfiles present: no git call" 0 "$(count 'git *' "$CALLS")"
eq "T7 ~/.dotfiles present: plain setup.sh exec'd" "setup.sh" "$(last_call)"
new_case public-no-setup
mkdir -p "$H/.dotfiles"
run --
nonzero "T7 ~/.dotfiles without setup.sh: non-zero exit" "$RC"
has "T7 ~/.dotfiles without setup.sh: says why" "setup.sh is missing" "$OUT"
eq "T7 ~/.dotfiles without setup.sh: stops before any download or install" 0 \
    "$(($(count 'curl *' "$CALLS") + $(count '*apt-get *' "$CALLS") + $(count 'brew *' "$CALLS") + $(count 'git *' "$CALLS")))"

if [[ -e "$HOST_LINUXBREW" ]]; then
    skip "T8 re-run without a terminal, T9 Homebrew missing" "these cases start without a brew on PATH, and bootstrap would run this host's real $HOST_LINUXBREW instead of installing the fake"
else
    new_case rerun 'procps'
    no_brew
    run --
    eq "T8 first run: exit 0" 0 "$RC"
    has "T8 first run: installs apt packages" "apt-get install" "$CALLS"
    has "T8 first run: installs Homebrew" "brew-installer" "$CALLS"
    has "T8 first run: clones" "git clone" "$CALLS"
    run -- "$PRIVATE_URL"
    eq "T8 re-run: nothing installed" 0 "$(($(count 'apt-get *' "$CALLS") + $(count 'curl *' "$CALLS")))"
    eq "T8 re-run: nothing cloned" 0 "$(count 'git *' "$CALLS")"
    eq "T8 re-run: plain setup.sh exec'd" "setup.sh" "$(last_call)"

    new_case brew-missing
    no_brew
    run --
    eq "T9 brew missing: exit 0" 0 "$RC"
    has "T9 brew missing: official installer fetched" "curl -fsSL $BREW_URL" "$CALLS"
    has "T9 brew missing: installer executed" "brew-installer" "$CALLS"
    eq "T9 brew missing: brew found and evaluated afterwards" "BREW_SHELLENV_MARK=evaluated" "$(shellenv_mark)"
    before "T9 order: --select before the Homebrew installer" 'setup.sh --select*' 'brew-installer'
    new_case brew-nobrew
    no_brew
    run INSTALLER_NOBREW=1 --
    nonzero "T9 installer leaves no brew: non-zero exit" "$RC"
    has "T9 installer leaves no brew: says why" "no brew is in" "$OUT"
    eq "T9 installer leaves no brew: no hand-over to setup.sh" 0 "$(count 'setup.sh' "$CALLS")"
    new_case brew-curlfail
    no_brew
    run CURL_FAIL=1 --
    nonzero "T9 installer download fails: non-zero exit" "$RC"
    eq "T9 installer download fails: nothing executed" 0 "$(count 'brew-installer*' "$CALLS")"
    has "T9 installer download fails: says why" "Could not download the Homebrew installer" "$OUT"
fi

PTY_PROBE=$(bounded pty "$SYS/bash" -c '[ -t 0 ] && echo PTY-YES' </dev/null 2>&1)
if [[ "$PTY_PROBE" != *PTY-YES* ]]; then
    skip "T4-T10 terminal cases" "no pseudo-terminal (sandboxed?)"
else
    new_case full
    ptyrun '\n' SSH_RESULTS=ok -- "$PRIVATE_URL"
    eq "T5 full: exit 0" 0 "$RC"
    eq "T5 full: ssh-keygen argv" "ssh-keygen -t ed25519 -a 100 -C $FAKE_HOST-$FAKE_DATE -f $H/.ssh/github" \
        "$(call_line 'ssh-keygen -t')"
    lacks "T5 full: no -N" " -N" "$(call_line 'ssh-keygen -t')"
    has "T5 full: ssh-add called" "ssh-add $H/.ssh/github" "$CALLS"
    eq "T5 full: known_hosts seeded" "$GITHUB_HOST_KEY" "$(cat "$H/.ssh/known_hosts" 2>&1)"
    has "T5 full: ssh -T argv" "ssh -i $H/.ssh/github -o IdentitiesOnly=yes -T git@github.com" "$CALLS"
    has "T5 full: public key printed" "$(cut -d ' ' -f 2 "$H/.ssh/github.pub" 2>&1)" "$OUT"
    has "T5 full: key page printed" "$KEY_PAGE" "$OUT"
    has "T5 full: key page opened" "xdg-open $KEY_PAGE" "$CALLS"
    has "T5 full: public ssh clone" "git clone $PUBLIC_SSH_URL $H/.dotfiles"$'\n'"GIT_SSH_COMMAND=$CLONE_SSH_COMMAND" "$CALLS"
    has "T5 full: private ssh clone" "git clone $PRIVATE_URL $H/.dotfiles-private"$'\n'"GIT_SSH_COMMAND=$CLONE_SSH_COMMAND" "$CALLS"
    eq "T5 full: no https clone" 0 "$(count "git clone $PUBLIC_HTTPS_URL*" "$CALLS")"
    eq "T5 full: plain setup.sh exec'd" "setup.sh" "$(last_call)"
    eq "F2 fresh key: one ssh check" 1 "$(ssh_calls)"
    shown=$(line_of 'xdg-open *')
    checked=$(line_of 'ssh -i *')
    if [[ "$shown" -gt 0 && "$checked" -gt "$shown" ]]; then
        ok "F2 fresh key: no ssh check before the key is shown"
    else
        no "F2 fresh key: no ssh check before the key is shown" "page opened at call $shown, first ssh at call $checked"
    fi
    before "T13 full: --select before the key step" 'setup.sh --select*' 'ssh-keygen *'
    before "T13 full: GitHub check before Homebrew" 'ssh -i *' 'brew shellenv*'
    before "T13 full: the clones before Homebrew" 'git clone *' 'brew shellenv*'

    ptyrun '' -- "$PRIVATE_URL"
    eq "T8 re-run after full: exit 0" 0 "$RC"
    eq "T8 re-run after full: nothing installed or cloned" 0 \
        "$(($(count 'apt-get *' "$CALLS") + $(count 'curl *' "$CALLS") + $(count 'git *' "$CALLS")))"
    eq "T8 re-run after full: no ssh tools" 0 "$(keytool_calls)"
    eq "T8 re-run after full: plain setup.sh exec'd" "setup.sh" "$(last_call)"

    # The key step on macOS. Bootstrap calls the absolute /usr/bin/ssh-add
    # there, which no stub intercepts: env -i leaves SSH_AUTH_SOCK unset, so it
    # finds no agent and never reaches a real agent or the Keychain.
    new_case full-macos
    ptyrun '\n' -b "$BIN_MAC" SSH_RESULTS=ok -- "$PRIVATE_URL"
    eq "T5 macOS: exit 0" 0 "$RC"
    eq "T5 macOS: key copied with pbcopy" 1 "$(count 'pbcopy*' "$CALLS")"
    eq "T5 macOS: key page opened with open" 1 "$(count "open $KEY_PAGE" "$CALLS")"
    eq "T5 macOS: no xdg-open" 0 "$(count 'xdg-open *' "$CALLS")"
    has "T5 macOS: private ssh clone" "git clone $PRIVATE_URL $H/.dotfiles-private" "$CALLS"
    before "T5 macOS: Homebrew before the clone" 'brew shellenv*' 'git clone *'

    new_case accepted
    pregenerate_key
    ptyrun '' SSH_RESULTS=ok -- "$PRIVATE_URL"
    eq "T5 already accepted: exit 0" 0 "$RC"
    lacks "T5 already accepted: key not shown" "Public key" "$OUT"
    eq "T5 already accepted: page not opened" 0 "$(count 'xdg-open *' "$CALLS")"
    eq "F2 existing key: pre-check runs, one ssh check" 1 "$(ssh_calls)"
    has "T5 already accepted: private clone" "git clone $PRIVATE_URL $H/.dotfiles-private" "$CALLS"

    new_case tty-env
    ptyrun '\n' SSH_RESULTS=ok DOTFILES_PRIVATE_URL="$ENV_PRIVATE_URL" --
    has "T4 env URL used" "git clone $ENV_PRIVATE_URL $H/.dotfiles-private" "$CALLS"
    new_case tty-arg-wins
    ptyrun '\n' SSH_RESULTS=ok DOTFILES_PRIVATE_URL="$ENV_PRIVATE_URL" -- "$PRIVATE_URL"
    has "T4 argument wins: argument cloned" "git clone $PRIVATE_URL $H/.dotfiles-private" "$CALLS"
    lacks "T4 argument wins: env URL ignored" "$ENV_PRIVATE_URL" "$CALLS"

    new_case tty-words
    ptyrun '' SSH_RESULTS=ok -- core cli
    eq "T12 words, TTY: exit 0" 0 "$RC"
    eq "T12 words, TTY: forwarded to --select" "setup.sh --select core cli" "$(select_call)"
    eq "T12 words, TTY: no ssh tools" 0 "$(keytool_calls)"
    has "T12 words, TTY: public https clone" "git clone $PUBLIC_HTTPS_URL $H/.dotfiles" "$CALLS"
    eq "T12 words, TTY: plain setup.sh exec'd" "setup.sh" "$(last_call)"
    new_case tty-url-between
    ptyrun '\n' SSH_RESULTS=ok -- core "$PRIVATE_URL" -extra
    eq "T12 URL between words, TTY: exit 0" 0 "$RC"
    eq "T12 URL between words, TTY: words forwarded" "setup.sh --select core -extra" "$(select_call)"
    has "T12 URL between words, TTY: private clone" "git clone $PRIVATE_URL $H/.dotfiles-private" "$CALLS"

    new_case tty-cancel
    ptyrun '\n' SSH_RESULTS=ok SELECT_RC=1 -- "$PRIVATE_URL"
    nonzero "T13 cancelled, TTY: non-zero exit" "$RC"
    eq "T13 cancelled, TTY: no ssh tools" 0 "$(keytool_calls)"
    eq "T13 cancelled, TTY: --select was the last call" "setup.sh --select" "$(last_call)"
    eq "T13 cancelled, TTY: nothing left in TMPDIR" "" "$(tmp_left)"
    if [[ -e "$HOST_LINUXBREW" ]]; then
        skip "T13 GitHub check before the Homebrew installer" "starts without a brew on PATH, and bootstrap would run this host's real $HOST_LINUXBREW"
    else
        new_case tty-brew-missing
        no_brew
        ptyrun '\n' SSH_RESULTS=ok -- "$PRIVATE_URL"
        eq "T13 brew missing, TTY: exit 0" 0 "$RC"
        before "T13 brew missing, TTY: GitHub check before the Homebrew installer" 'ssh -i *' 'brew-installer'
        before "T13 brew missing, TTY: the clones before the Homebrew installer" 'git clone *' 'brew-installer'
    fi

    new_case origin-https
    fake_public_repo "$PUBLIC_HTTPS_URL"
    ptyrun '\n' SSH_RESULTS=ok -- "$PRIVATE_URL"
    eq "F1 https origin: exit 0" 0 "$RC"
    has "F1 https origin: switched" "git -C $H/.dotfiles remote set-url origin $PUBLIC_SSH_URL" "$CALLS"
    eq "F1 https origin: now the SSH URL" "$PUBLIC_SSH_URL" "$(cat "$H/.dotfiles/.git/origin")"
    eq "F1 https origin: no public clone" 0 "$(count "git clone $PUBLIC_SSH_URL*" "$CALLS")"
    has "F1 https origin: private clone" "git clone $PRIVATE_URL $H/.dotfiles-private" "$CALLS"
    new_case origin-other
    fake_public_repo "$ENV_PRIVATE_URL"
    ptyrun '\n' SSH_RESULTS=ok -- "$PRIVATE_URL"
    eq "F1 other origin: exit 0" 0 "$RC"
    eq "F1 other origin: not switched" 0 "$(count '*set-url*' "$CALLS")"
    eq "F1 other origin: unchanged" "$ENV_PRIVATE_URL" "$(cat "$H/.dotfiles/.git/origin")"
    new_case origin-nogit
    fake_public_repo
    ptyrun '\n' SSH_RESULTS=ok -- "$PRIVATE_URL"
    eq "F1 not a git repo: exit 0" 0 "$RC"
    eq "F1 not a git repo: not touched" 0 "$(count '*set-url*' "$CALLS")"
    lacks "F1 not a git repo: no warning" "!!" "$OUT"
    eq "F1 not a git repo: plain setup.sh exec'd" "setup.sh" "$(last_call)"

    new_case noauth
    ptyrun '\nr\n' SSH_RESULTS='noauth ok' -- "$PRIVATE_URL"
    has "T6 exit 1 without the text: reported as failure" "did not accept" "$OUT"
    eq "T6 exit 1 without the text: retried" 2 "$(ssh_calls)"
    has "T6 exit 1 without the text: then cloned" "git clone $PRIVATE_URL $H/.dotfiles-private" "$CALLS"
    new_case retry
    ptyrun '\nr\n' SSH_RESULTS='fail ok' -- "$PRIVATE_URL"
    eq "T6 255 then retry: exit 0" 0 "$RC"
    has "T6 255 then retry: failure output shown" "Permission denied (publickey)" "$OUT"
    eq "T6 255 then retry: two checks" 2 "$(ssh_calls)"
    has "T6 255 then retry: private clone" "git clone $PRIVATE_URL $H/.dotfiles-private" "$CALLS"
    new_case eof-enter
    ptyrun '\0004' SSH_RESULTS=ok -- "$PRIVATE_URL"
    eq "F3 EOF at Enter: exit 0" 0 "$RC"
    eq "F3 EOF at Enter: no ssh check" 0 "$(ssh_calls)"
    has "F3 EOF at Enter: public https clone" "git clone $PUBLIC_HTTPS_URL $H/.dotfiles" "$CALLS"
    lacks "F3 EOF at Enter: no private clone" "$PRIVATE_URL" "$CALLS"
    has "F3 EOF at Enter: reason shown" "GitHub SSH access skipped" "$OUT"
    new_case eof-retry
    ptyrun '\n\0004' SSH_RESULTS=fail -- "$PRIVATE_URL"
    eq "F3 EOF at retry: exit 0" 0 "$RC"
    eq "F3 EOF at retry: one ssh check" 1 "$(ssh_calls)"
    has "F3 EOF at retry: public https clone" "git clone $PUBLIC_HTTPS_URL $H/.dotfiles" "$CALLS"
    lacks "F3 EOF at retry: no private clone" "$PRIVATE_URL" "$CALLS"
    has "F3 EOF at retry: reason shown" "GitHub SSH access skipped" "$OUT"
    new_case skip
    ptyrun '\ns\n' SSH_RESULTS=fail -- "$PRIVATE_URL"
    eq "T6 255 then skip: exit 0" 0 "$RC"
    has "T6 255 then skip: public https clone" "git clone $PUBLIC_HTTPS_URL $H/.dotfiles" "$CALLS"
    lacks "T6 255 then skip: no private clone" "$PRIVATE_URL" "$CALLS"
    has "T6 255 then skip: reason shown" "GitHub SSH access skipped" "$OUT"
    eq "T6 255 then skip: plain setup.sh exec'd" "setup.sh" "$(last_call)"

    new_case key-present
    pregenerate_key
    printf '%s\n' "$GITHUB_HOST_KEY" >"$H/.ssh/known_hosts"
    ptyrun '' SSH_RESULTS=ok SSH_ADD_LIST=has -- "$PRIVATE_URL"
    eq "T7 key present: exit 0" 0 "$RC"
    eq "T7 key present: no generation" 0 "$(count 'ssh-keygen -t*' "$CALLS")"
    eq "T7 key in agent: not added again" 0 "$(count "ssh-add $H/.ssh/github" "$CALLS")"
    eq "T7 known_hosts present: not appended" 1 "$(count 'github.com *' "$(cat "$H/.ssh/known_hosts")")"
    new_case known-hosts-no-newline
    pregenerate_key
    other_host_line="example.invalid $(cut -d ' ' -f 1,2 "$H/.ssh/github.pub")"
    printf '%s' "$other_host_line" >"$H/.ssh/known_hosts"
    ptyrun '' SSH_RESULTS=ok -- "$PRIVATE_URL"
    eq "T7 known_hosts without a final newline: exit 0" 0 "$RC"
    eq "T7 known_hosts without a final newline: both entries on their own line" \
        "$other_host_line"$'\n'"$GITHUB_HOST_KEY" "$(cat "$H/.ssh/known_hosts")"
    new_case private-present
    mkdir -p "$H/.dotfiles-private"
    ptyrun '' SSH_RESULTS=ok -- "$PRIVATE_URL"
    eq "F6 ~/.dotfiles-private present, TTY and URL: no ssh, ssh-keygen or ssh-add call" 0 "$(keytool_calls)"
    has "T7 ~/.dotfiles-private present: public https clone" "git clone $PUBLIC_HTTPS_URL $H/.dotfiles" "$CALLS"
    eq "T7 ~/.dotfiles-private present: plain setup.sh exec'd" "setup.sh" "$(last_call)"
    new_case noagent
    ptyrun '\n' SSH_RESULTS=ok SSH_ADD_LIST=noagent -- "$PRIVATE_URL"
    eq "T7 no agent: exit 0" 0 "$RC"
    has "T7 no agent: warned" "No ssh-agent reachable" "$OUT"
    eq "T7 no agent: no add attempted" 0 "$(count "ssh-add $H/.ssh/github" "$CALLS")"
    eq "T7 no agent: plain setup.sh exec'd" "setup.sh" "$(last_call)"

    new_case ssh-add-fails
    ptyrun '\n' SSH_RESULTS=ok SSH_ADD_RC=1 -- "$PRIVATE_URL"
    eq "F4 ssh-add fails: exit 0" 0 "$RC"
    has "F4 ssh-add fails: add attempted" "ssh-add $H/.ssh/github" "$CALLS"
    has "F4 ssh-add fails: warned" "ssh-add failed" "$OUT"
    has "F4 ssh-add fails: run continues" "git clone $PRIVATE_URL $H/.dotfiles-private" "$CALLS"
    eq "F4 ssh-add fails: plain setup.sh exec'd" "setup.sh" "$(last_call)"

    new_case no-pub
    pregenerate_key
    rm -f "$H/.ssh/github.pub"
    ptyrun '' SSH_RESULTS=ok -- "$PRIVATE_URL"
    nonzero "F5 no .pub: non-zero exit" "$RC"
    has "F5 no .pub: recreate hint" "recreate it with: ssh-keygen -y -f $H/.ssh/github" "$OUT"
    eq "F5 no .pub: nothing cloned" 0 "$(count 'git *' "$CALLS")"
    eq "F5 no .pub: no ssh check" 0 "$(ssh_calls)"

    "$REAL_SSH_KEYGEN" -q -t ed25519 -N '' -C other -f "$WORK/otherkey"
    other_blob=$(cut -d ' ' -f 2 "$WORK/otherkey.pub")
    sed "s|$GITHUB_KEY_BLOB|$other_blob|" "$BOOTSTRAP" >"$WORK/tampered.sh"
    new_case tampered
    if cmp -s "$BOOTSTRAP" "$WORK/tampered.sh"; then
        no "T10 tampered: copy differs" "key constant not found in $BOOTSTRAP"
    else
        ptyrun '' -s "$WORK/tampered.sh" SSH_RESULTS=ok -- "$PRIVATE_URL"
        nonzero "T10 tampered: non-zero exit" "$RC"
        has "T10 tampered: says why" "fingerprint is" "$OUT"
        absent "T10 tampered: known_hosts not written" "$H/.ssh/known_hosts"
        eq "T10 tampered: nothing cloned" 0 "$(count 'git *' "$CALLS")"
    fi
fi

printf -- '---\n%s passed, %s failed, %s skipped\n' "$PASS" "$FAIL" "$SKIP"
exit $((FAIL > 0))
