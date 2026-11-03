#!/usr/bin/env zsh
set -uo pipefail

[[ $OSTYPE == darwin* ]] || { print 'skipped: api-keys-setup is macOS only'; exit 0; }

SCRIPT=${SCRIPT:-${0:A:h}/api-keys-setup}
PASS=0
FAIL=0
WORK=$(mktemp -d "${TMPDIR:-/tmp}/apikeys.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

# Fake Keychain: accounts listed in $STORED exist, no key value is ever returned. An existence
# check also sources the live config in a fresh shell and logs the status to $PROBE, as a shell
# starting during the rewrite would.
mkdir "$WORK/bin"
cat > "$WORK/bin/security" <<'FAKE'
#!/bin/sh
case "$1" in
  list-keychains|delete-generic-password) exit 0 ;;
  find-generic-password)
    case " $* " in *" -w "*) exit 44 ;; esac
    if [ -n "${PROBE:-}" ]; then
      zsh -fc 'source "$1" 2>/dev/null; print -r -- $?' _ "$CFG" >> "$PROBE"
    fi
    for account; do :; done
    grep -qx -- "$account" "$STORED" ;;
  *) exit 1 ;;
esac
FAKE
chmod +x "$WORK/bin/security"

export ZDOTFILES_DIR=$WORK/dotfiles
export CFG=$ZDOTFILES_DIR/zsh/config/modules/local/api-keys.zsh
export STORED=$WORK/stored
export PATH=$WORK/bin:$PATH
print -l openai claude > "$STORED"

report() {
  local name=$1 ok=$2
  shift 2
  if (( ok )); then
    PASS=$((PASS + 1))
    printf 'PASS  %s\n' "$name"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL  %s\n' "$name"
    printf '  %s\n' "$@"
  fi
}

ok=1
"$SCRIPT" --config >/dev/null 2>&1 || ok=0
grep -qx '    \[OPENAI_API_KEY\]=openai' "$CFG" || ok=0
grep -qx '    \[CLAUDE_API_KEY\]=claude' "$CFG" || ok=0
grep -q gemini "$CFG" && ok=0
zsh -fc 'source "$1"' _ "$CFG" 2>/dev/null || ok=0
report '--config lists only stored services and the result sources cleanly' "$ok" "config=$(<"$CFG")"

ok=1
PROBE=$WORK/probe "$SCRIPT" --config >/dev/null 2>&1 || ok=0
probes=$(tr '\n' ' ' < "$WORK/probe")
[[ -n ${probes// } && -z ${probes//0 /} ]] || ok=0
report 'a shell starting mid-rewrite sources the previous complete config' "$ok" "statuses=$probes"

# 1 block of 512 bytes fits the header but not the whole config. SIGXFSZ is ignored so the
# oversized write fails with EFBIG instead of killing the writer.
ok=1
cp "$CFG" "$WORK/before"
( trap '' XFSZ; ulimit -f 1; "$SCRIPT" --force --remove claude ) >/dev/null 2>&1 && ok=0
cmp -s "$CFG" "$WORK/before" || ok=0
leftovers=( "$CFG".*(N) )
(( ${#leftovers} == 0 )) || ok=0
report 'a failed write during removal keeps the previous config and no temp file' "$ok" \
  "config lines=$(wc -l < "$CFG")" "leftovers=${leftovers[*]}"

printf '%d passed, %d failed\n' "$PASS" "$FAIL"
(( FAIL == 0 ))
