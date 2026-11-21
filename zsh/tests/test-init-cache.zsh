#!/usr/bin/env zsh
set -uo pipefail

DIR=${0:A:h}
HELPERS=${HELPERS:-$DIR/../config/helpers.zsh}
PASS=0
FAIL=0
WORK=$(mktemp -d "${TMPDIR:-/tmp}/tcache.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

ok() { (( ++PASS )); print -r -- "PASS  $1" }
no() { (( ++FAIL )); print -r -- "FAIL  $1 ($2)" }
eq() { [[ $2 == "$3" ]] && ok "$1" || no "$1" "expected [$2] got [$3]" }

source $HELPERS
ZDOTFILES_INIT_CACHE_DIR=$WORK/cache
CACHE=$ZDOTFILES_INIT_CACHE_DIR/t.zsh
LOG=$WORK/log
STAMP=$WORK/stamp
CALLER=$WORK/caller.zsh
# Fixed past mtimes, so freshness never depends on the clock's resolution
CACHE_TIME=202001010000
SOURCE_TIME=201901010000

print -r -- '#!/bin/sh
echo run >> "$LOG"
printf "%s\n" "$GEN_OUT"' >| $WORK/gen
chmod +x $WORK/gen
print -r -- "zdotfiles_source_cached t $STAMP -- $WORK/gen" >| $CALLER
touch $STAMP
GEN_OUT=
export LOG GEN_OUT

runs() {
  local -a lines
  [[ -f $LOG ]] && lines=("${(@f)$(<$LOG)}")
  print -r -- ${#lines}
}
backdate() { touch -t $SOURCE_TIME $STAMP $CALLER; touch -t $CACHE_TIME $CACHE }

GEN_OUT='typeset -g VAL=one'
VAL=
source $CALLER
eq "first call sources the output" one "$VAL"
eq "first call writes the cache" 1 "$([[ -s $CACHE ]] && print 1)"

backdate
GEN_OUT='typeset -g VAL=two'
VAL=
source $CALLER
eq "fresh cache is sourced without running the command" "one 1" "$VAL $(runs)"

touch $CALLER
VAL=
source $CALLER
eq "edited calling file regenerates" "two 2" "$VAL $(runs)"

backdate
touch $STAMP
GEN_OUT='typeset -g VAL=three'
VAL=
source $CALLER
eq "newer stamp regenerates" "three 3" "$VAL $(runs)"

rm -f $CACHE $CACHE.zwc
GEN_OUT='export PATH=/nowhere'
eq "literal PATH output is evaluated" /nowhere "$(source $CALLER; print -r -- $PATH)"
eq "literal PATH output is not cached" 0 "$([[ -e $CACHE ]] && print 1 || print 0)"

print -r -- "---"
print -r -- "$PASS passed, $FAIL failed"
(( FAIL == 0 ))
