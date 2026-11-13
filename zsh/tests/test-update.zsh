#!/usr/bin/env zsh
set -uo pipefail

DIR=${0:A:h}
MODULE=${MODULE:-$DIR/../config/modules/functions/60-system.zsh}
HELPERS=${HELPERS:-$DIR/../config/helpers.zsh}
PASS=0
FAIL=0
SKIP=0
WORK=$(mktemp -d "${TMPDIR:-/tmp}/tupdate.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

ok()   { (( ++PASS )); print -r -- "PASS  $1" }
no()   { (( ++FAIL )); print -r -- "FAIL  $1 ($2)" }
skip() { (( ++SKIP )); print -r -- "SKIP  $1 ($2)" }

eq()    { [[ $2 == "$3" ]] && ok "$1" || no "$1" "expected [$2] got [$3]" }
has()   { [[ $3 == *"$2"* ]] && ok "$1" || no "$1" "[$2] not in [$3]" }
lacks() { [[ $3 != *"$2"* ]] && ok "$1" || no "$1" "[$2] found in [$3]" }

# Seconds a slow stub sleeps after touching $MARK. STUB_SLOW outlasts feed's
# first key, sent settle seconds after $MARK. STUB_BRIEF ends between that key
# and the next one key_gap_secs later, which the ^Z, ignore and
# key-during-the-check cases rely on.
STUB_SLOW=5
STUB_BRIEF=1

STUB_BODY=$WORK/stub-body
print -r -- 'echo "$name $*" >> "$STUB_LOG"
case "${1:-}" in *[!A-Za-z0-9]*|"") sub=_ ;; *) sub=$1 ;; esac
eval "out=\${OUT_$var:-} err=\${ERR_$var:-} mode=\${MODE_${var}_$sub:-\${MODE_$var:-}} rc=\${RC_${var}_$sub:-\${RC_$var:-0}}"
[ -n "$out" ] && printf "%s\n" "$out"
[ -n "$err" ] && printf "%s\n" "$err" >&2
case "$mode" in
  die) touch "$MARK"; sleep "$STUB_SLOW" ;;
  exit130) trap "exit 130" INT; touch "$MARK"; sleep "$STUB_SLOW" ;;
  ignore) trap "" INT; touch "$MARK"; sleep "$STUB_BRIEF" ;;
esac
exit "$rc"' >| $STUB_BODY

mkstub() {
  print -r -- "#!/bin/sh
name=$2 var=${2//[^a-zA-Z0-9]/_}
. \"\$STUB_BODY\"" >| $1/$2
  chmod +x $1/$2
}

mkswupdate() {
  print -r -- '#!/bin/sh
echo "softwareupdate $*" >> "$STUB_LOG"
if [ "$1" = --list ]; then
  [ -n "${SW_MARK:-}${SW_SLOW:-}" ] && touch "$MARK"
  [ -n "${SW_SLOW:-}" ] && sleep "$SW_SLOW"
  echo "Software Update Tool"
  echo
  echo "Finding available software"
  case "${SW_LIST:-none}" in
    none) echo "No new software available." >&2; exit 0 ;;
    fail) echo "Error: The Internet connection appears to be offline." >&2; exit 1 ;;
  esac
  echo "Software Update found the following new or updated software:"
  if [ "$SW_LIST" = odd ]; then
    printf "%s\n" "* Label: Odd\\cName-1"
  elif [ "$SW_LIST" = nonrec ]; then
    echo "- Label: Tool27.3-1"
  else
    echo "* Label: Safari27.3-27.3"
  fi
  printf "\tTitle: Safari, Version: 27.3, Size: 100K, Recommended: YES,\n"
  if [ "$SW_LIST" = restart ]; then
    echo "* Label: macOS 27.3-27D5"
    printf "\tTitle: macOS 27.3, Version: 27.3, Size: 9000K, Recommended: YES, Action: restart,\n"
  fi
  exit 0
fi
exit "${RC_softwareupdate:-0}"' >| $1/softwareupdate
  chmod +x $1/softwareupdate
}

mksudo() {
  print -r -- '#!/bin/sh
echo "sudo $*" >> "$STUB_LOG"
case "$1" in
  -v) exit "${RC_sudo_v:-0}" ;;
  -n) exit 0 ;;
esac
exec "$@"' >| $1/sudo
  chmod +x $1/sudo
}

mkbin() {
  local dir=$1 tool
  shift
  mkdir -p $dir
  mksudo $dir
  for tool; do
    if [[ $tool == softwareupdate ]]; then mkswupdate $dir; else mkstub $dir $tool; fi
  done
}

ALL_TOOLS=(softwareupdate brew mas mise rustup cargo cargo-install-update sheldon apt-get flatpak)
BIN=$WORK/bin
mkbin $BIN $ALL_TOOLS
FIXHOME=$WORK/home
mkdir -p $FIXHOME/.dotfiles
mkstub $FIXHOME/.dotfiles setup.sh
LOG=$WORK/log
MARK=$WORK/started

# The only host tools on the PATH of a case: with /usr/bin, /usr/sbin or the
# Homebrew prefix on it, the host sudo, softwareupdate or brew would run for
# real where a case leaves its stub out.
SYS=$WORK/sys
mkdir -p $SYS
for tool in zsh cat chmod sleep tee touch; do
  ln -s ${commands[$tool]:?$tool not found} $SYS/$tool
done
STUB_ENV=(HOME=$FIXHOME TMPPREFIX=$WORK/zsh STUB_LOG=$LOG STUB_BODY=$STUB_BODY
  MARK=$MARK HELPERS=$HELPERS MODULE=$MODULE PLATFORM=macos STUB_SLOW=$STUB_SLOW STUB_BRIEF=$STUB_BRIEF)

LOADER='source "$HELPERS"; ZDOTFILES_PLATFORM=$PLATFORM; source "$MODULE"'
DRIVER=$LOADER$'\nupdate "$@"'

run() {
  local bin=$BIN
  [[ $1 == -b ]] && { bin=$2; shift 2 }
  local -a vars
  while [[ $1 != -- ]]; do vars+=("$1"); shift; done
  shift
  : >| $LOG
  env -i $STUB_ENV PATH=$bin:$SYS "${vars[@]}" zsh -f -c "$DRIVER" update "$@" \
    < /dev/null >| $WORK/out 2>| $WORK/err
  RC=$?
  OUT=$(<$WORK/out)
  ERR=$(<$WORK/err)
  CALLS=$(<$LOG)
}

row() {
  local line
  local -a words
  for line in ${(f)OUT}; do
    words=(${=line})
    [[ "$words" == "$1 $2"* ]] && { print -r -- ${words:#(<->s|<->m<->s)}; return }
  done
}

count() { print -r -- ${#${(M)${(f)2}:#${~1}}} }

summary_rows() {
  local rows=${OUT#*==> Summary*$'\n'}
  print -r -- ${#${(f)rows}}
}

MAC_HEAD=('sudo -v' 'softwareupdate --list')
TOOLS=('brew update' 'brew upgrade --yes' 'mas upgrade' 'mise upgrade --global' 'rustup update'
  'cargo install-update -a' 'sheldon lock --update' 'setup.sh --update')
TOOLS_YES=('brew update' 'brew upgrade --yes' 'mas upgrade' 'mise upgrade --global --yes'
  'rustup update' 'cargo install-update -a' 'sheldon --non-interactive lock --update' 'setup.sh --update')
INSTALL=('sudo softwareupdate --install --all --no-scan --agree-to-license'
  'softwareupdate --install --all --no-scan --agree-to-license')
LINUX_HEAD=('sudo -v'
  'sudo apt-get update -qq --error-on=any' 'apt-get update -qq --error-on=any'
  'sudo apt-get full-upgrade -o DPkg::Lock::Timeout=300' 'apt-get full-upgrade -o DPkg::Lock::Timeout=300'
  'flatpak update')

for flag in -h --help; do
  run -- $flag
  eq  "T1 $flag rc" 0 $RC
  has "T1 $flag usage" "Usage: update [-y] [-r]" "$OUT"
  eq  "T1 $flag runs nothing, not even sudo" "" "$CALLS"
done
for bad in "-x" "-f" "--force" "--yes=1" "-yx" "foo" "-y foo" "-- -y"; do
  run -- ${(z)bad}
  eq "T1 '$bad' rc 2" 2 $RC
  has "T1 '$bad' hint on stderr" "Try 'update --help'" "$ERR"
  lacks "T1 '$bad' in update's own format" "zparseopts" "$ERR"
  eq "T1 '$bad' runs nothing" "" "$CALLS"
  eq "T1 '$bad' nothing on stdout" "" "$OUT"
done
run -- foo
has "T1 positional named" "Error: unknown argument: foo" "$ERR"
run -- -yx
has "T1 unknown option named" "Error: unknown option: -yx" "$ERR"
run -- -- -y
has "T1 after --, an argument" "Error: unknown argument: -y" "$ERR"
run SW_LIST=restart -- --yes --restart
eq "T1 long forms" "${(F)MAC_HEAD}"$'\n'"${(F)TOOLS_YES}"$'\n'"${INSTALL[1]} --restart"$'\n'"${INSTALL[2]} --restart" "$CALLS"
run -- --
eq "T1 bare -- accepted" 0 $RC
run -- -y -y
eq "T1 repeated flag accepted" 0 $RC
run SW_LIST=restart -- -yr
eq "T1 bundled -yr rc" 0 $RC
has "T1 bundled -yr restarts" "softwareupdate --install --all --no-scan --agree-to-license --restart" "$CALLS"
run PLATFORM=linux -- -r
eq "T1 --restart on Linux rc 2" 2 $RC
has "T1 --restart on Linux named" "Error: --restart applies to macOS updates only" "$ERR"
eq "T1 --restart on Linux runs nothing" "" "$CALLS"

run --
eq  "T2 rc" 0 $RC
eq  "T2 call order" "${(F)MAC_HEAD}"$'\n'"${(F)TOOLS}" "$CALLS"
eq  "T2 one row per step" 8 $(summary_rows)
eq  "T2 all OK" 8 $(count '  OK  *' "$OUT")
eq  "T2 macOS row" "OK macOS updates none available" "$(row OK 'macOS updates')"
has "T2 says none available" "No macOS updates available." "$OUT"
has "T2 headers on stdout" "==> Homebrew" "$OUT"
lacks "T2 no ANSI color off a terminal" $'\e[' "$OUT$ERR"
eq  "T2 stderr empty" "" "$ERR"
lacks "T2 no Linux steps on macOS" "apt-get" "$CALLS"
lacks "T2 no flatpak on macOS" "flatpak" "$CALLS"

run SW_LIST=restart -- -y
eq  "T3 rc" 0 $RC
eq  "T3 call order" "${(F)MAC_HEAD}"$'\n'"${(F)TOOLS_YES}"$'\n'"${(F)INSTALL}" "$CALLS"
eq  "T3 restart needed, not done" "OK macOS updates restart required" "$(row OK 'macOS updates')"
has "T3 labels listed" "* Label: macOS 27.3-27D5" "$OUT"
lacks "T3 never --restart without -r" "--restart" "$CALLS"
run SW_LIST=restart -- -y -r
has "T3 -r passes --restart" "${INSTALL[1]} --restart" "$CALLS"
eq  "T3 -r row has no restart note" "OK macOS updates" "$(row OK 'macOS updates')"
run SW_LIST=one -- -y
eq  "T3 no restart needed, no note" "OK macOS updates" "$(row OK 'macOS updates')"
run SW_LIST=odd -- -y
has "T3 backslashes printed verbatim" '* Label: Odd\cName-1' "$OUT"
run SW_LIST=nonrec -- -y
has "T3 a non-recommended update is found" "- Label: Tool27.3-1" "$OUT"
has "T3 a non-recommended update installs" "${INSTALL[1]}" "$CALLS"
run SW_LIST=restart -- --restart
eq  "T3 -r alone asks, no terminal skips" 0 $(count '*--install*' "$CALLS")

run SW_LIST=one --
eq  "T4 rc" 0 $RC
eq  "T4 no install" 0 $(count '*--install*' "$CALLS")
eq  "T4 row" "SKIPPED macOS updates no terminal to confirm, run update -y" "$(row SKIPPED 'macOS updates')"
lacks "T4 no prompt printed" "[y/N]" "$OUT$ERR"
eq  "T4 install still last in order" "setup.sh --update" "${${(f)CALLS}[-1]}"

run SW_LIST=fail --
eq  "T5 listing failure rc" 1 $RC
eq  "T5 listing failure row" "FAILED macOS updates listing failed, exit 1" "$(row FAILED 'macOS updates')"
has "T5 listing output on stderr" "appears to be offline" "$ERR"
has "T5 listing error line" "Error: macOS updates failed: listing failed, exit 1" "$ERR"
eq  "T5 listing failure installs nothing" 0 $(count '*--install*' "$CALLS")
has "T5 other steps still run" "setup.sh --update" "$CALLS"
run SW_LIST=fail -- -y
eq  "T5 listing failure with -y installs nothing" 0 $(count '*--install*' "$CALLS")
run SW_LIST=one RC_softwareupdate=3 -- -y
eq  "T5 install failure rc" 1 $RC
eq  "T5 install failure row" "FAILED macOS updates exit 3" "$(row FAILED 'macOS updates')"
mkbin $WORK/bin-nosw brew
run -b $WORK/bin-nosw --
eq  "T5 no softwareupdate" "SKIPPED macOS updates softwareupdate not installed" "$(row SKIPPED 'macOS updates')"

run RC_brew_update=1 --
eq  "T6 brew update failure rc" 1 $RC
has "T6 upgrade still runs after a failed brew update" "brew upgrade" "$CALLS"
eq  "T6 brew update failure row" "FAILED Homebrew brew update failed, see the brew output" "$(row FAILED Homebrew)"
has "T6 later steps run" "mas upgrade" "$CALLS"
run RC_brew_upgrade=1 --
eq  "T6 brew upgrade failure row" "FAILED Homebrew exit 1" "$(row FAILED Homebrew)"
eq  "T6 other rows OK" "OK mise tools" "$(row OK 'mise tools')"
run RC_mas=2 ERR_mas="mas: Warning: 1 error" --
eq  "T6 mas rc" 1 $RC
eq  "T6 mas row" "FAILED App Store apps exit 2" "$(row FAILED 'App Store apps')"
has "T6 inline error on stderr" "Error: App Store apps failed: exit 2" "$ERR"
has "T6 mas stderr streams to stderr" "mas: Warning: 1 error" "$ERR"
lacks "T6 mas stderr not merged into stdout" "mas: Warning" "$OUT"
has "T6 mas failure, later steps run" "setup.sh --update" "$CALLS"
run OUT_mas="Installed Xcode" --
has "T6 mas stdout streams to stdout" "Installed Xcode" "$OUT"
for label tool in 'mise tools' mise 'Rust toolchain' rustup 'cargo packages' cargo \
    'sheldon plugins' sheldon 'Claude skills' setup.sh; do
  run RC_${tool//[^a-zA-Z0-9]/_}=4 --
  eq "T6 $label failure rc" 1 $RC
  eq "T6 $label failure row" "FAILED $label exit 4" "$(row FAILED $label)"
done
run RC_sudo_v=1 --
eq  "T6 sudo failure rc" 1 $RC
eq  "T6 sudo failure runs nothing else" "sudo -v" "$CALLS"
has "T6 sudo failure named" "Error: sudo authentication failed, no step ran" "$ERR"
lacks "T6 sudo failure prints no summary" "Summary" "$OUT"

mkbin $WORK/bin-bare softwareupdate
run -b $WORK/bin-bare --
eq "T7 rc" 0 $RC
for label tool in Homebrew brew 'App Store apps' mas 'mise tools' mise 'Rust toolchain' rustup \
    'cargo packages' cargo-install-update 'sheldon plugins' sheldon; do
  eq "T7 $label skipped" "SKIPPED $label $tool not installed" "$(row SKIPPED $label)"
done
mkbin $WORK/bin-cargo cargo
run -b $WORK/bin-cargo --
eq "T7 cargo without cargo-update skipped" "SKIPPED cargo packages cargo-install-update not installed" "$(row SKIPPED 'cargo packages')"
run HOME=$WORK/nohome --
eq "T7 setup.sh missing" "SKIPPED Claude skills setup.sh not found" "$(row SKIPPED 'Claude skills')"
run ZDOTFILES_DIR=$FIXHOME/.dotfiles HOME=$WORK/nohome --
has "T7 ZDOTFILES_DIR honored" "setup.sh --update" "$CALLS"
mkdir -p $WORK/noexec/.dotfiles
: >| $WORK/noexec/.dotfiles/setup.sh
run HOME=$WORK/noexec --
eq "T7 setup.sh not executable" "SKIPPED Claude skills setup.sh not executable" "$(row SKIPPED 'Claude skills')"

run PLATFORM=linux --
eq  "T8 rc" 0 $RC
eq  "T8 call order" "${(F)LINUX_HEAD}"$'\n'"${(F)${(@)TOOLS:#mas upgrade}}" "$CALLS"
lacks "T8 no App Store on Linux" "mas" "$CALLS"
lacks "T8 no softwareupdate on Linux" "softwareupdate" "$CALLS"
eq  "T8 one row per step" 8 $(summary_rows)
eq  "T8 all OK" 8 $(count '  OK  *' "$OUT")
run PLATFORM=linux -- -y
has "T8 -y full-upgrade" "apt-get full-upgrade -y -o DPkg::Lock::Timeout=300" "$CALLS"
has "T8 -y flatpak" "flatpak update -y" "$CALLS"
has "T8 -y brew" "brew upgrade --yes" "$CALLS"
run PLATFORM=linux RC_apt_get_update=100 --
eq  "T8 refresh failure rc" 1 $RC
has "T8 upgrade runs after a failed refresh" "apt-get full-upgrade" "$CALLS"
eq  "T8 refresh failure row" "FAILED APT packages package list refresh failed, see the apt output" "$(row FAILED 'APT packages')"
run PLATFORM=linux RC_apt_get=100 --
eq  "T8 failed upgrade wins over a failed refresh" "FAILED APT packages exit 100" "$(row FAILED 'APT packages')"
has "T8 later steps run" "flatpak update" "$CALLS"
run PLATFORM=linux RC_flatpak=1 --
eq  "T8 flatpak failure row" "FAILED Flatpak apps exit 1" "$(row FAILED 'Flatpak apps')"
mkbin $WORK/bin-noapt brew
run -b $WORK/bin-noapt PLATFORM=linux --
eq  "T8 no apt-get, no sudo" "brew update"$'\n'"brew upgrade --yes"$'\n'"setup.sh --update" "$CALLS"
eq  "T8 no apt-get row" "SKIPPED APT packages apt-get not installed" "$(row SKIPPED 'APT packages')"
eq  "T8 no flatpak row" "SKIPPED Flatpak apps flatpak not installed" "$(row SKIPPED 'Flatpak apps')"
mkbin $WORK/bin-nosudo apt-get brew
rm $WORK/bin-nosudo/sudo
run -b $WORK/bin-nosudo PLATFORM=linux --
eq  "T8 no sudo rc" 0 $RC
eq  "T8 no sudo, the other steps run" "brew update"$'\n'"brew upgrade --yes"$'\n'"setup.sh --update" "$CALLS"
eq  "T8 no sudo row" "SKIPPED APT packages sudo not installed" "$(row SKIPPED 'APT packages')"
run PLATFORM=linux RC_sudo_v=1 --
eq  "T8 sudo failure rc" 1 $RC
eq  "T8 sudo failure runs nothing else" "sudo -v" "$CALLS"

# In this run the summary pads states to FAILED and labels to "sheldon plugins"
run RC_mas=1 --
has "T9 OK row aligned" $'\n'"$(printf '  %-6s  %-15s  ' OK Homebrew)" "$OUT"
has "T9 FAILED row aligned" $'\n'"$(printf '  %-6s  %-15s  ' FAILED 'App Store apps')" "$OUT"
has "T9 summary header" "==> Summary: " "$OUT"
dur() {
  env -i PATH=$SYS TMPPREFIX=$WORK/zsh HELPERS=$HELPERS MODULE=$MODULE PLATFORM=macos \
    zsh -f -c "$LOADER"'; local REPLY; _update_duration $1; print -r -- $REPLY' _ $1
}
for secs want in 0 0s 59 59s 60 1m00s 61 1m01s 3599 59m59s 3600 60m00s; do
  eq "T9 duration $secs" $want "$(dur $secs)"
done

resrc=$(env -i $STUB_ENV PATH=$BIN:$SYS zsh -f -c '
  repeat 2; do
    source "$HELPERS"; ZDOTFILES_PLATFORM=$PLATFORM; source "$MODULE"
    update -h | { read -r line; print -r -- $line; cat >/dev/null }
    update >/dev/null
    print -r -- "rc=$?"
  done' < /dev/null 2>&1)
eq "T10 re-sourced twice" $'Usage: update [-y] [-r]\nrc=0\nUsage: update [-y] [-r]\nrc=0' "$resrc"

# The modules update loads are preloaded: loading one adds its own parameters.
leak=$(env -i $STUB_ENV PATH=$BIN:$SYS SW_LIST=restart RC_mas=1 zsh -f -c '
  zmodload zsh/zutil zsh/system zsh/zselect
  source "$HELPERS"; ZDOTFILES_PLATFORM=$PLATFORM; source "$MODULE"
  note=caller list=caller answer=caller labels=caller REPLY=caller
  typeset -a before funcs
  typeset opts
  before=(${(k)parameters}) funcs=(${(k)functions}) opts=$(setopt)
  update -y >/dev/null 2>&1
  print -r -- rc=$?
  print -r -- new=${${(k)parameters}:|before}
  print -r -- funcs=${${(k)functions}:|funcs}
  print -r -- opts=$([[ $(setopt) == $opts ]] && print same)
  print -r -- vars=$note,$list,$answer,$labels,$REPLY' < /dev/null)
eq "T11 the probe run failed a step" "rc=1" "${${(f)leak}[1]}"
eq "T11 no new parameters" "new=" "${${(f)leak}[2]}"
eq "T11 no new functions, no TRAPINT left" "funcs=" "${${(f)leak}[3]}"
eq "T11 options restored" "opts=same" "${${(f)leak}[4]}"
eq "T11 caller variables untouched" "vars=caller,caller,caller,caller,caller" "${${(f)leak}[5]}"
# The run's subshell hides a helper's leak from the caller, so _update_run's
# own contract is checked directly
note=$(env -i $STUB_ENV PATH=$SYS zsh -f -c "$LOADER"'
  local -a step_labels step_states step_secs step_notes
  local -i printed=0 current_start=0
  local current_label=
  local -A out err
  sets_note() { note="set by the step"; return 1 }
  note=caller
  _update_run Step sets_note >/dev/null 2>&1
  print -r -- "$note|$step_notes[1]"' < /dev/null 2>&1)
eq "T11 _update_run keeps note to itself" "caller|set by the step" "$note"

mkbin $WORK/bin-late softwareupdate
OUT=$(env -i $STUB_ENV PATH=$WORK/bin-late:$SYS MKSTUB="$(whence -f mkstub)" LATE=$WORK/bin-late zsh -f -c '
  eval "$MKSTUB"
  source "$HELPERS"; ZDOTFILES_PLATFORM=$PLATFORM; source "$MODULE"
  update >/dev/null 2>&1
  hash -f
  mkstub $LATE rustup
  update 2>/dev/null' < /dev/null 2>&1)
eq "T12 rustup found after install" "OK Rust toolchain" "$(row OK 'Rust toolchain')"

# The real keepalive interval is 60 s, so a keepalive holding a pipe on
# update's output open would outlast PIPE_LIMIT_SECS.
KEEPALIVE_TEST_CS=10
OWNER_SECS=1
WATCH_SECS=2
MIN_REFRESHES=3
REAP_POLLS=20
REAP_POLL_SECS=0.05
PIPE_LIMIT_SECS=10
REAP=(REAP_POLLS=$REAP_POLLS REAP_POLL_SECS=$REAP_POLL_SECS)
: >| $LOG
keep=$(env -i $STUB_ENV PATH=$BIN:$SYS OWNER_SECS=$OWNER_SECS WATCH_SECS=$WATCH_SECS \
    INTERVAL=$KEEPALIVE_TEST_CS zsh -f -c '
  source "$HELPERS"; source "$MODULE"
  integer keepalive_pid
  setopt no_bg_nice
  sleep $OWNER_SECS & owner=$!
  _update_sudo_keepalive $owner $INTERVAL
  sleep $WATCH_SECS
  print -r -- ${#${(M)${(f)"$(<$STUB_LOG)"}:#sudo -n -v}}
  kill -0 $keepalive_pid 2>/dev/null && print alive || print gone' < /dev/null 2>&1)
(( ${${(f)keep}[1]} >= MIN_REFRESHES )) && ok "T13 refreshes repeatedly with sudo -n -v" || no "T13 refreshes repeatedly with sudo -n -v" "$keep"
eq "T13 stops once the owner exits" "gone" "${${(f)keep}[2]}"
left=$(env -i $STUB_ENV PATH=$BIN:$SYS KPID=$WORK/kpid $REAP zsh -f -c "$LOADER"'
  functions[_test_keepalive]=$functions[_update_sudo_keepalive]
  _update_sudo_keepalive() { _test_keepalive "$@"; print -r -- $keepalive_pid >| $KPID }
  update >/dev/null 2>&1
  repeat $REAP_POLLS; do kill -0 $(<$KPID) 2>/dev/null || break; sleep $REAP_POLL_SECS; done
  kill -0 $(<$KPID) 2>/dev/null && print alive || print gone' < /dev/null 2>&1)
eq "T13 keepalive gone after update" "gone" "$left"
owner=$(env -i $STUB_ENV PATH=$BIN:$SYS KPID=$WORK/kpid zsh -f -c "$LOADER"'
  zmodload zsh/system
  functions[_test_keepalive]=$functions[_update_sudo_keepalive]
  _update_sudo_keepalive() { print -r -- "$1 $sysparams[pid] $$" >| $KPID; _test_keepalive "$@" }
  update 2>&1 | cat >/dev/null
  read -r watched current shell < $KPID
  [[ $watched == $current && $watched != $shell ]] && print subshell || print "$watched $current $shell"' < /dev/null 2>&1)
eq "T13 piped, the keepalive watches the update subshell, not the shell" "subshell" "$owner"
nokeep=$(env -i $STUB_ENV PATH=$BIN:$SYS zsh -f -c "$LOADER"'
  zmodload() { [[ $1 == zsh/zselect ]] && return 1; builtin zmodload "$@" }
  update >/dev/null 2>&1
  print -r -- rc=$?' < /dev/null 2>&1)
eq "T13 no keepalive, the run goes on" "rc=0" "$nokeep"
has "T13 no keepalive, steps still run" "setup.sh --update" "$(<$LOG)"
SECONDS=0
env -i $STUB_ENV PATH=$BIN:$SYS zsh -f -c "$DRIVER" update < /dev/null 2>&1 | cat >/dev/null
(( SECONDS < PIPE_LIMIT_SECS )) && ok "T13 update | cat ends with update" || no "T13 update | cat ends with update" "${SECONDS}s"

pty() {
  if script --version >/dev/null 2>&1; then
    script -qec "${(j: :)${(q)@}}" /dev/null
  else
    script -q /dev/null "$@"
  fi
}
if ! pty true < /dev/null >/dev/null 2>&1; then
  skip "T14 pty" "no pseudo-terminal (sandboxed?)"
else
  ptyrun() {
    local cmd=$1
    shift
    : >| $LOG
    pty env -i $STUB_ENV PATH=$BIN:$SYS TERM=xterm "$@" \
      zsh -fi -c "$LOADER; $cmd"'; print "RC=$?"' 2>&1 < /dev/null | tr -d '\r'
  }
  out=$(ptyrun update RC_mas=1)
  has "T14 color on a terminal" $'\e[1;34m==>' "$out"
  has "T14 colored error" $'\e[1;31mError:' "$out"
  out=$(ptyrun update NO_COLOR=1)
  lacks "T14 NO_COLOR" $'\e[' "$out"
  out=$(ptyrun update NO_COLOR= RC_mas=1)
  has "T14 empty NO_COLOR keeps color" $'\e[1;34m==>' "$out"
  out=$(ptyrun update TERM=dumb)
  lacks "T14 TERM=dumb" $'\e[' "$out"
  out=$(ptyrun "update 2>$WORK/errfile" RC_mas=1)
  has "T14 stdout colored, stderr to a file" $'\e[1;34m==>' "$out"
  has "T14 stderr file has the error" "Error: App Store apps failed" "$(<$WORK/errfile)"
  lacks "T14 stderr file plain" $'\e[' "$(<$WORK/errfile)"
  out=$(ptyrun "update | cat" RC_mas=1)
  lacks "T14 stdout piped plain" $'\e[1;34m==>' "$out"
  has "T14 stderr on the terminal colored" $'\e[1;31mError:' "$out"

  # Lines typed after a key wait in the terminal until the shell reads them.
  # $? is probed on a later input line because an interrupt must also abort
  # the rest of the line that ran update. An empty first key delays the next
  # by key_gap_secs, giving a prompt time to show up.
  print -r -- $LOADER >| $WORK/driver.zsh
  KEY_GAP=$'\x1f'
  feed() {
    local -ri max_polls=100
    local -r poll_interval=0.1 settle=0.3 key_gap_secs=1.5
    local -i i
    local -a keys=("${(@ps:$KEY_GAP:)2}")
    print -r -- "source \"\$DRIVER_FILE\"; $1; print AFTER-ON-SAME-LINE"
    for (( i = 0; i < max_polls; i++ )); do [[ -e $MARK ]] && break; sleep $poll_interval; done
    sleep $settle
    for (( i = 1; i <= $#keys; i++ )); do
      (( i > 1 )) && sleep $key_gap_secs
      printf '%s' "$keys[i]"
    done
    print -r -- 'print RC=$?'
    print -r -- 'exit'
  }
  # An outer interactive shell runs the shell under test as a job, as a
  # terminal window's login does. Run directly under script, the shell under
  # test leads an orphaned process group, and the kernel discards ^Z for
  # tools run in that group without job control.
  ptykey() {
    local cmd=$1 key=$2
    shift 2
    : >| $LOG
    rm -f $MARK
    out=$(feed $cmd $key | pty env -i $STUB_ENV PATH=$BIN:$SYS TERM=dumb NO_COLOR=1 \
      DRIVER_FILE=$WORK/driver.zsh "$@" zsh -fi -c 'zsh -fi; :' 2>&1 | tr -d '\r')
  }

  ptykey update ${KEY_GAP}y SW_LIST=one SW_MARK=1
  has "T14 prompt shown" "Install 1 macOS update(s) at the end of the run? [y/N]" "$out"
  [[ $out == *'[y/N]'*'==> Homebrew'* ]] && ok "T14 prompt before the first tool step" \
    || no "T14 prompt before the first tool step" "$out"
  has "T14 y installs" "${INSTALL[1]}" "$(<$LOG)"
  ptykey update ${KEY_GAP}n SW_LIST=one SW_MARK=1
  eq  "T14 n declines" 0 $(count '*--install*' "$(<$LOG)")
  OUT=$out
  eq  "T14 declined row" "SKIPPED macOS updates declined" "$(row SKIPPED 'macOS updates')"
  ptykey "update 2>/dev/null >/dev/null" ${KEY_GAP}y SW_LIST=one SW_MARK=1
  has "T14 prompt on the terminal with both streams redirected" "[y/N]" "$out"
  has "T14 answer read with both streams redirected" "${INSTALL[1]}" "$(<$LOG)"
  ptykey "update < /dev/null" ${KEY_GAP}y SW_LIST=one SW_MARK=1
  lacks "T14 stdin not a terminal: no prompt" "[y/N]" "$out"
  OUT=$out
  eq  "T14 stdin not a terminal: skipped" "SKIPPED macOS updates no terminal to confirm, run update -y" "$(row SKIPPED 'macOS updates')"
  ptykey update $'\n'${KEY_GAP}y SW_LIST=one SW_SLOW=$STUB_BRIEF
  has "T14 a key typed during the check does not answer" "${INSTALL[1]}" "$(<$LOG)"

  ptykey update $'\003' SW_SLOW=$STUB_SLOW
  has "T14 ^C in the check: rc 130" "RC=130" "$out"
  has "T14 ^C in the check: interrupted row" "INTERRUPTED  macOS updates" "$out"
  lacks "T14 ^C in the check: no tool step" "brew" "$(<$LOG)"
  ptykey update ${KEY_GAP}$'\003' SW_LIST=one SW_MARK=1
  has "T14 ^C at the prompt: rc 130" "RC=130" "$out"
  has "T14 ^C at the prompt: interrupted row" "INTERRUPTED  macOS updates" "$out"
  lacks "T14 ^C at the prompt: no tool step" "brew" "$(<$LOG)"
  ptykey update $'\003' SW_LIST=fail MODE_brew=die
  OUT=$out
  eq  "T14 ^C after a failed check: row kept" "FAILED macOS updates listing failed, exit 1" "$(row FAILED 'macOS updates')"
  ptykey "update -y" $'\003' SW_LIST=one MODE_brew=die
  OUT=$out
  eq  "T14 ^C before the install: row" "SKIPPED macOS updates interrupted before the install" "$(row SKIPPED 'macOS updates')"
  eq  "T14 ^C before the install: nothing installed" 0 $(count '*--install*' "$(<$LOG)")

  for mode in die exit130 ignore; do
    ptykey update $'\003' MODE_brew=$mode
    has "T14 ^C $mode: rc 130" "RC=130" "$out"
    has "T14 ^C $mode: interrupted step in summary" "INTERRUPTED  Homebrew" "$out"
    has "T14 ^C $mode: message" "Error: interrupted, the remaining steps did not run" "$out"
    lacks "T14 ^C $mode: rest of the line aborted" $'\nAFTER-ON-SAME-LINE' "$out"
    lacks "T14 ^C $mode: later steps not run" "mas upgrade" "$(<$LOG)"
  done
  ptykey "update 2>&1 | tee -i $WORK/teelog >/dev/null" $'\003' MODE_brew=die
  has "T14 ^C piped: summary still written" "INTERRUPTED  Homebrew" "$(<$WORK/teelog)"
  lacks "T14 ^C piped: later steps not run" "mas upgrade" "$(<$LOG)"
  ptykey "update | tee $WORK/teelog2 >/dev/null" $'\003' MODE_brew=die
  has "T14 ^C piped to plain tee: error on the terminal" "Error: interrupted" "$out"
  ptykey update $'\003' MODE_brew_upgrade=die
  has "T14 ^C in brew upgrade: rc 130" "RC=130" "$out"
  has "T14 ^C in brew upgrade: interrupted" "INTERRUPTED  Homebrew" "$out"
  ptykey update $'\003' PLATFORM=linux MODE_apt_get_update=exit130
  has "T14 ^C in apt-get update: rc 130" "RC=130" "$out"
  has "T14 ^C in apt-get update: interrupted" "INTERRUPTED  APT packages" "$out"
  lacks "T14 ^C in apt-get update: no upgrade after" "full-upgrade" "$(<$LOG)"
  ptykey update $'\003' MODE_mas=die
  OUT=$out
  eq  "T14 ^C later step: earlier rows kept" "OK Homebrew" "$(row OK Homebrew)"
  eq  "T14 ^C later step: interrupted row" "INTERRUPTED App Store apps" "$(row INTERRUPTED 'App Store apps')"

  ptykey update $'\032'${KEY_GAP}$'fg\n' MODE_brew_update=ignore
  has "T14 ^Z: suspended" "suspended" "$out"
  has "T14 ^Z then fg: run completes" "RC=0" "$out"
  OUT=$out
  eq  "T14 ^Z then fg: step OK" "OK Homebrew" "$(row OK Homebrew)"
  lacks "T14 ^Z then fg: nothing failed" "FAILED" "$out"
  has "T14 ^Z then fg: later steps run" "setup.sh --update" "$(<$LOG)"
fi

print -r -- "---"
print -r -- "$PASS passed, $FAIL failed, $SKIP skipped"
(( FAIL == 0 ))
