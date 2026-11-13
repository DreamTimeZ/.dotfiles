# poweroff exists natively on Linux but not macOS
if zdotfiles_is_macos; then
  poweroff() { sudo shutdown -h "${@:-now}"; }
fi

# The _update_* helpers run only inside update and share its locals through
# dynamic scope: out/err (colors), o_* (options), step_* (results), current_*
# (running step), printed (headers so far), macos and macos_* (the macOS
# update check), keepalive_pid, REPLY.

_update_usage() {
  cat <<'EOF'
Usage: update [-y] [-r]

Upgrade the system and developer tools, in this order:

  macOS   check for macOS updates, Homebrew, App Store apps (mas), mise
          tools (global config), Rust toolchain (rustup), cargo packages
          (cargo-update), sheldon plugins, Claude skills, then install
          the macOS updates
  Linux   APT packages (full-upgrade), Flatpak apps, then Homebrew and
          the developer tools as on macOS

A step whose tool is not installed is left out. A missing softwareupdate,
a missing or non-executable setup.sh, a missing sudo where apt-get exists,
and a missing cargo-update where cargo exists show as SKIPPED instead.
sudo asks for your password at the start (macOS, and Linux with apt-get),
and if that fails, no step runs. A Homebrew cask that runs an installer,
and softwareupdate on Apple silicon, may ask again.

  -y, --yes       Run unattended: apt, flatpak, mise and sheldon get their
                  yes flag, and macOS updates install without asking
  -r, --restart   macOS: let softwareupdate restart the Mac when an update
                  needs it. It quits all apps right after installing, so
                  the summary may not appear
  -h, --help      Show this help

Without -y, update asks after the check whether to install the macOS
updates, and skips them when stdin is not a terminal. apt and flatpak ask
before they change anything. Homebrew upgrades without asking.

Tool output streams as it runs. A summary closes the run with every step
marked OK, FAILED, SKIPPED or INTERRUPTED, and the duration of each that
ran. Ctrl-C stops the run and still prints the summary of the steps so
far. To keep it in a piped log, pipe through tee -i, which survives
Ctrl-C. Ctrl-Z suspends the whole run, and fg resumes it.

Returns 0 when no step failed, 1 when one did or sudo failed, 2 on bad
usage, 130 when interrupted.
EOF
}

_update_use_color() {
  [[ -t $1 && -z ${NO_COLOR-} && ${TERM-} != dumb ]]
}

_update_header() {
  (( printed++ )) && print
  print -r -- "${out[blue]}==>${out[reset]} ${out[bold]}$1${out[reset]}"
}

_update_error() {
  print -ru2 -- "${err[red]}Error:${err[reset]} $1"
}

_update_try_help() {
  print -ru2 -- "Try 'update --help' for more information."
}

_update_duration() {
  local -ri minute=60
  if (( $1 < minute )); then
    REPLY="${1}s"
  else
    printf -v REPLY '%dm%02ds' $(( $1 / minute )) $(( $1 % minute ))
  fi
}

_update_record() {
  step_labels+=("$1")
  step_states+=("$2")
  step_secs+=("$3")
  step_notes+=("${4-}")
}

_update_run() {
  local label=$1 note=
  shift
  _update_header "$label"
  current_label=$label
  current_start=$SECONDS
  "$@"
  local rc=$?
  current_label=
  if (( rc )); then
    [[ -n $note ]] || note="exit $rc"
    _update_error "$label failed: $note"
    _update_record "$label" FAILED $(( SECONDS - current_start )) "$note"
  else
    _update_record "$label" OK $(( SECONDS - current_start )) "$note"
  fi
}

# whence -p searches $PATH afresh, where $commands misses a tool installed
# since the last rehash.
_update_tool() {
  if whence -p -- "$2" >/dev/null; then
    _update_run "$1" "${@:3}"
  fi
}

# zselect sleeps without a child process, so killing the loop leaves nothing
# behind, and the redirections keep the loop from holding a pipe on update's
# output open. no_bg_nice: where setpriority is denied, as in the Claude Code
# sandbox, renicing the job prints an error that the job's own redirections
# do not catch.
_update_sudo_keepalive() {
  setopt local_options no_bg_nice
  zmodload zsh/zselect || return
  {
    while zselect -t $2; kill -0 $1; do
      sudo -n -v
    done
  } </dev/null >/dev/null 2>&1 &!
  keepalive_pid=$!
}

# Homebrew resets the sudo timestamp the first time it needs sudo itself (pkg
# casks), so that step can still prompt. The keepalive goes on refreshing
# whatever timestamp is current. Without it the run goes on, only with more
# prompts.
_update_sudo() {
  local -ri keepalive_centiseconds=6000
  if ! sudo -v; then
    _update_error "sudo authentication failed, no step ran"
    return 1
  fi
  # $$ is the calling shell, which outlives the run's subshell
  _update_sudo_keepalive $sysparams[pid] $keepalive_centiseconds
  return 0
}

_update_confirm() {
  local answer
  [[ -t 0 ]] || return 2
  while read -s -t 0 -k 1 answer; do :; done
  { print -nr -- "$1 [y/N] " >/dev/tty } 2>/dev/null || return 2
  read -q answer
  print >/dev/tty
  [[ $answer == y ]]
}

# softwareupdate lists each update as "* Label: ..." ("-" instead of "*" for a
# non-recommended one) and its details on a "Title: ..." line that ends in
# "Action: restart," when the update needs one (man softwareupdate). The exit status of a listing with updates is unknown,
# so labels win over it. The listing is read through a pipe: Ctrl-C during a
# command substitution makes update return 2, not 130 (zsh 5.9 and 5.9.2).
_update_macos_check() {
  if ! whence -p softwareupdate >/dev/null; then
    macos_state=SKIPPED macos_note="softwareupdate not installed"
    return
  fi
  local list
  local -a lines labels
  _update_header "Checking for macOS updates"
  current_label="macOS updates"
  current_start=$SECONDS
  softwareupdate --list 2>&1 | IFS= read -rd '' list
  local -i rc=$pipestatus[1]
  macos_secs=$(( SECONDS - current_start ))
  lines=(${(f)list})
  labels=(${(M)lines:#*[*-]' Label: '*})
  if (( ! $#labels )); then
    current_label=
    if (( rc )); then
      print -ru2 -- "${list%$'\n'}"
      macos_state=FAILED macos_note="listing failed, exit $rc"
      _update_error "macOS updates failed: $macos_note"
    else
      macos_state=OK macos_note="none available"
      print -r -- "No macOS updates available."
    fi
    return
  fi
  print -rl -- ${(M)lines:#*(Label|Title): *}
  [[ $list == *'Action: restart'* ]] && macos_restart=1
  if (( $#o_yes )); then
    macos_install=1
  else
    _update_confirm "Install $#labels macOS update(s) at the end of the run?"
    case $? in
      (0) macos_install=1 ;;
      (1) macos_state=SKIPPED macos_note="declined" ;;
      (*) macos_state=SKIPPED macos_note="no terminal to confirm, run update -y" ;;
    esac
  fi
  current_label=
}

# --no-scan installs what the check at the start found instead of scanning again.
_update_macos_install() {
  local -a args=(--install --all --no-scan --agree-to-license)
  (( $#o_restart )) && args+=(--restart)
  sudo softwareupdate $args || return
  (( macos_restart && ! $#o_restart )) && note="restart required"
  return 0
}

_update_macos() {
  if (( macos_install )); then
    _update_run "macOS updates" _update_macos_install
  else
    _update_macos_result
  fi
}

# The interrupt path in _update_main calls this too. The row already exists
# when the interrupt hit the check, its prompt or the install.
_update_macos_result() {
  (( ${step_labels[(Ie)macOS updates]} )) && return
  if (( macos_install )); then
    _update_record "macOS updates" SKIPPED "" "interrupted before the install"
  elif [[ $macos_state == SKIPPED ]]; then
    _update_record "macOS updates" SKIPPED "" "$macos_note"
  elif [[ -n $macos_state ]]; then
    _update_record "macOS updates" $macos_state $macos_secs "$macos_note"
  fi
}

# A refresh failure fails the step but must not hold back the upgrades from
# the sources that did refresh. The refresh status is read on its own line:
# after `cmd || rc=$?`, Ctrl-C during cmd makes update return 1, not 130
# (zsh 5.9 and 5.9.2).
_update_apt() {
  # Another apt client (Pop!_Shop, automatic updates) can hold the dpkg lock.
  # The timeout does not cover the lists lock of apt-get update.
  local -ri lock_timeout_seconds=300
  sudo apt-get update -qq --error-on=any
  local -i refresh_rc=$?
  sudo apt-get full-upgrade ${o_yes:+-y} -o "DPkg::Lock::Timeout=$lock_timeout_seconds" || return
  (( refresh_rc )) && note="package list refresh failed, see the apt output"
  return refresh_rc
}

_update_flatpak() {
  flatpak update ${o_yes:+-y}
}

# Same refresh pattern as _update_apt. --yes: brew's own prompt reads Ctrl-C
# as a key and exits 1, so Ctrl-C there could not stop the run, and n would
# count as a failure.
_update_brew() {
  brew update
  local -i refresh_rc=$?
  brew upgrade --yes || return
  (( refresh_rc )) && note="brew update failed, see the brew output"
  return refresh_rc
}

# --global: inside a project, plain mise upgrade would also upgrade that
# project's tools and, with lockfiles enabled, update its mise.lock.
_update_mise() {
  mise upgrade --global ${o_yes:+--yes}
}

_update_sheldon() {
  sheldon ${o_yes:+--non-interactive} lock --update
}

_update_summary() {
  local -A color=(OK green FAILED red SKIPPED yellow INTERRUPTED red)
  local -i i n=$#step_labels width=0 state_width=0 duration_width=0
  local -a durations
  local line
  for (( i = 1; i <= n; i++ )); do
    REPLY=
    [[ -n $step_secs[i] ]] && _update_duration $step_secs[i]
    durations[i]=$REPLY
    (( $#step_labels[i] > width )) && width=$#step_labels[i]
    (( $#step_states[i] > state_width )) && state_width=$#step_states[i]
    (( $#REPLY > duration_width )) && duration_width=$#REPLY
  done
  _update_duration $1
  printed=0
  print
  _update_header "Summary: $REPLY"
  for (( i = 1; i <= n; i++ )); do
    line="  ${out[$color[$step_states[i]]]}${(r:state_width:)step_states[i]}${out[reset]}"
    line+="  ${(r:width:)step_labels[i]}  ${(l:duration_width:)durations[i]}"
    [[ -n $step_notes[i] ]] && line+="  $step_notes[i]"
    print -r -- "$line"
  done
}

# Upgrade the system and developer tools (update --help)
update() {
  emulate -L zsh
  local -ri exit_usage=2 interrupted=130

  local -A sgr=(blue $'\e[1;34m' green $'\e[1;32m' yellow $'\e[1;33m' red $'\e[1;31m' bold $'\e[1m' reset $'\e[0m')
  local -A out err
  _update_use_color 1 && out=("${(@kv)sgr}")
  _update_use_color 2 && err=("${(@kv)sgr}")

  # Without -F, zparseopts leaves an unknown option in place, to be named
  # below in the same Error: format as everything else.
  local -a o_help o_yes o_restart
  zparseopts -D -E -- \
    h=o_help    -help=o_help \
    y=o_yes     -yes=o_yes \
    r=o_restart -restart=o_restart
  local -i end_of_options=0
  [[ ${1-} == -- ]] && { shift; end_of_options=1 }
  if (( $# )); then
    if [[ $1 == -?* ]] && (( ! end_of_options )); then
      _update_error "unknown option: $1"
    else
      _update_error "unknown argument: $1"
    fi
    _update_try_help
    return exit_usage
  fi
  if (( $#o_help )); then
    _update_usage
    return 0
  fi
  local -i macos=0
  zdotfiles_is_macos && macos=1
  if (( $#o_restart && ! macos )); then
    _update_error "--restart applies to macOS updates only"
    _update_try_help
    return exit_usage
  fi

  zmodload zsh/system || return
  # One job: ^Z suspends the whole run and fg resumes it. Run in this shell,
  # ^Z would stop only the running tool, and the run would go on without it.
  ( _update_main )
  local -i rc=$?
  # Under job control the Ctrl-C reached only the subshell's process group.
  # Raising it in this shell as well aborts the rest of the command line.
  (( rc == interrupted )) && kill -INT $sysparams[pid]
  return rc
}

_update_main() {
  local -a step_labels step_states step_secs step_notes
  local -i printed=0 current_start=0 started=$SECONDS keepalive_pid=0
  local -i macos_install=0 macos_restart=0
  local current_label= macos_state= macos_secs= macos_note= REPLY
  local setup=${ZDOTFILES_DIR:-$HOME/.dotfiles}/setup.sh

  # The subshell has no job control (emulate -L zsh leaves POSIX_JOBS off), so
  # every step runs in its process group, and Ctrl-C reaches the subshell as
  # well, also when the tool traps SIGINT and exits normally (brew exits 130).
  # The trap's non-zero status (128 + signal) then aborts the run like an
  # interrupt.
  TRAPINT() {
    local -ri signal_status_base=128
    return $(( signal_status_base + $1 ))
  }

  {
    if (( macos )); then
      _update_sudo || return
      _update_macos_check
    else
      if whence -p apt-get >/dev/null; then
        if whence -p sudo >/dev/null; then
          _update_sudo || return
          _update_run "APT packages" _update_apt
        else
          _update_record "APT packages" SKIPPED "" "sudo not installed"
        fi
      fi
      _update_tool "Flatpak apps" flatpak _update_flatpak
    fi

    # mas, mise and sheldon come from brew, and cargo packages build with the
    # toolchain that brew or rustup has just updated
    _update_tool "Homebrew" brew _update_brew
    (( macos )) && _update_tool "App Store apps" mas mas upgrade
    _update_tool "mise tools" mise _update_mise
    _update_tool "Rust toolchain" rustup rustup update
    if whence -p cargo-install-update >/dev/null; then
      _update_run "cargo packages" cargo install-update -a
    elif whence -p cargo >/dev/null; then
      _update_record "cargo packages" SKIPPED "" "cargo-install-update not installed"
    fi
    _update_tool "sheldon plugins" sheldon _update_sheldon

    if [[ -x $setup ]]; then
      _update_run "Claude skills" "$setup" --update
    elif [[ -e $setup ]]; then
      _update_record "Claude skills" SKIPPED "" "setup.sh not executable"
    else
      _update_record "Claude skills" SKIPPED "" "setup.sh not found"
    fi

    # Last, as --restart can end the session
    (( macos )) && _update_macos
  } always {
    (( keepalive_pid )) && kill $keepalive_pid 2>/dev/null
    # Left set, so the subshell ends with the interrupt status (130).
    # The message goes first and to stderr: in `update | tee log`, tee dies on
    # Ctrl-C and the next write to stdout ends the run (SIGPIPE).
    if (( TRY_BLOCK_INTERRUPT )); then
      [[ -n $current_label ]] && _update_record "$current_label" INTERRUPTED $(( SECONDS - current_start ))
      (( macos )) && _update_macos_result
      print -u2
      _update_error "interrupted, the remaining steps did not run"
    fi
    (( $#step_labels )) && _update_summary $(( SECONDS - started ))
  }

  (( ${step_states[(I)FAILED]} )) && return 1
  return 0
}
