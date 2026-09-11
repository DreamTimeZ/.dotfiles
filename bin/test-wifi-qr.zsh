#!/usr/bin/env zsh
set -uo pipefail

SCRIPT=${SCRIPT:-${0:A:h}/wifi-qr}
CASE=0
PASS=0
FAIL=0
WORK=$(mktemp -d "${TMPDIR:-/tmp}/wifiqr.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

mkdir "$WORK/bin" "$WORK/empty"
cat > "$WORK/bin/qrencode" <<'FAKE'
#!/bin/sh
printf '%s\n' "$@" > "$FAKE_LOG.args"
cat > "$FAKE_LOG.stdin"
i=0
while [ "$i" -lt "${FAKE_ROWS:-0}" ]; do echo x; i=$((i + 1)); done
FAKE
chmod +x "$WORK/bin/qrencode"

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

run_case() {
  local name=$1 want_exit=$2 want_payload=$3 want_args=$4 want_err=$5 input=$6
  shift 6
  CASE=$((CASE + 1))
  local log="$WORK/case-$CASE" err got_exit payload=NONE args= ok=1
  err=$(print -rn -- "$input" | FAKE_LOG=$log PATH="$WORK/bin:$PATH" "$SCRIPT" "$@" 2>&1 >/dev/null)
  got_exit=$?
  if [[ -e $log.stdin ]]; then payload=$(cat "$log.stdin"; printf X); payload=${payload%X}; fi   # $(<f) would strip a trailing newline the payload must not have
  [[ -e $log.args ]] && args=$(tr '\n' ' ' < "$log.args")
  [[ $got_exit == "$want_exit" ]] || ok=0
  [[ $payload == "$want_payload" ]] || ok=0
  [[ -z $want_args || $args == *"$want_args"* ]] || ok=0
  [[ -z $want_err || $err == *"$want_err"* ]] || ok=0
  report "$name" "$ok" "exit=$got_exit want=$want_exit" "payload=$payload" "args=$args" "stderr=$err"
}

run_case 'plain ssid and password, terminal output' 0 \
  'WIFI:T:WPA;S:homenet;P:hunter22;;' '-8 -t ANSI -l L' '' \
  'hunter22' homenet

run_case 'payload syntax characters are escaped in ssid and password' 0 \
  'WIFI:T:WPA;S:a\;b\:c\,d\"e\\f;P:p\\\;\:\,\"xy;;' '' '' \
  'p\;:,"xy' 'a;b:c,d"e\f'

run_case 'spaces survive in ssid and at both ends of the password' 0 \
  'WIFI:T:WPA;S:Guest Network;P: lead and trail ;;' '' '' \
  ' lead and trail ' 'Guest Network'

run_case '-o writes a png and reports the file' 0 \
  'WIFI:T:WPA;S:x;P:yyyyyyyy;;' "-8 -o $WORK/out.png -t PNG -l Q -s 12" 'cleartext' \
  'yyyyyyyy' -o "$WORK/out.png" x

touch "$WORK/taken.png"
run_case '-o refuses an existing file before asking for the password' 1 \
  NONE '' 'refusing to overwrite' \
  'y' -o "$WORK/taken.png" x

run_case '-o with an empty filename is an error' 2 \
  NONE '' 'needs a filename' \
  'y' -o '' x

run_case 'empty password is an error' 1 NONE '' 'empty password' '' x

run_case 'missing ssid prints usage' 2 NONE '' 'Usage' 'y'

run_case 'two ssids print usage' 2 NONE '' 'Usage' 'y' one two

run_case 'unknown option prints usage' 2 NONE '' 'Usage' 'y' -x ssid

run_case '--help exits 0' 0 NONE '' 'Usage' '' --help

run_case 'a leading-dash ssid is reachable after --' 0 \
  'WIFI:T:WPA;S:-5GHz;P:yyyyyyyy;;' '' '' \
  'yyyyyyyy' -- -5GHz

run_case 'a non-ASCII password is refused, 802.11 has no encoding for it' 1 \
  NONE '' 'outside printable ASCII' \
  'Pä$$wörtß' homenet

run_case 'a control character in the password is refused' 1 \
  NONE '' 'outside printable ASCII' \
  $'pass\tword1' homenet

run_case 'a password under the WPA minimum is refused' 1 \
  NONE '' 'a WPA passphrase is 8 to 63' \
  'short7c' homenet

run_case 'a password over the WPA maximum is refused' 1 \
  NONE '' 'a WPA passphrase is 8 to 63' \
  "$(printf 'a%.0s' {1..70})" homenet

run_case 'the raw 64-hex PSK is accepted despite exceeding the maximum' 0 \
  "WIFI:T:WPA;S:homenet;P:$(printf '0123456789abcdef%.0s' {1..4});;" '' '' \
  "$(printf '0123456789abcdef%.0s' {1..4})" homenet

run_case 'a 64-character non-hex password is still refused' 1 \
  NONE '' 'a WPA passphrase is 8 to 63' \
  "$(printf 'z%.0s' {1..64})" homenet

# zsh takes COLUMNS from the controlling terminal over the environment, so the
# fake's row count alone drives the branch: more rows than any terminal is wide,
# or a handful.
FAKE_ROWS=1000 run_case 'a symbol too wide for the terminal falls back to the packed renderer' 0 \
  'WIFI:T:WPA;S:homenet;P:hunter22;;' '-8 -t ANSIUTF8 -l L' '' 'hunter22' homenet

FAKE_ROWS=4 run_case 'a symbol that fits keeps the wide renderer' 0 \
  'WIFI:T:WPA;S:homenet;P:hunter22;;' '-8 -t ANSI -l L' '' 'hunter22' homenet

# a one-character input reaches the tool check only if it comes before the password read
err=$(print -rn -- 'y' | PATH="$WORK/empty" "${commands[zsh]}" "$SCRIPT" ssid 2>&1 >/dev/null)
rc=$?
ok=0
[[ $rc == 1 && $err == *'qrencode not found'* ]] && ok=1
report 'missing qrencode names the package' $ok "exit=$rc" "stderr=$err"

umask 022   # the fake qrencode inherits the script umask, so its own log shows what -o would give the png
mode_log="$WORK/umask"
print -rn -- 'yyyyyyyy' | FAKE_LOG=$mode_log PATH="$WORK/bin:$PATH" "$SCRIPT" -o "$WORK/mode.png" x >/dev/null 2>&1
mode=$(stat -f '%Lp' "$mode_log.stdin" 2>/dev/null || stat -c '%a' "$mode_log.stdin")
ok=0
[[ $mode == 600 ]] && ok=1
report 'png is written 0600, not world-readable' $ok "mode=$mode want=600"

printf '%d passed, %d failed\n' "$PASS" "$FAIL"
(( FAIL == 0 ))
