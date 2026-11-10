#!/bin/zsh
# Waiting for a state instead of a fixed time (sourced, not run): the self tests poll what
# they can observe, so a slow Mac gets more time and a fast one does not wait for nothing.
# Side effects: none
#
#   wait_until [-i INTERVAL] TIMEOUT CMD [ARG…]
#       Runs CMD every INTERVAL seconds (default 0.2) until it exits 0 or TIMEOUT seconds
#       have passed. CMD runs in this shell (a function may set variables) and once more at
#       the deadline. Status 0 when CMD succeeded, 1 on timeout; the caller says what failed
#       (scripts/lib/log.sh) and decides whether to stop.
#   wait_settled [-i INTERVAL] TIMEOUT READS CMD [ARG…]
#       Runs CMD every INTERVAL seconds (default 0.2) until its output is non-empty and the
#       same on READS reads in a row, or TIMEOUT seconds have passed. Prints the last
#       output; status 0 when it settled, 1 on timeout.
#
# A fixed `sleep` stays only for pacing where nothing can be observed (between typed keys,
# time for the input method between events); each one says why next to it.

zmodload zsh/datetime

wait_until() {
  local interval=0.2
  [[ $1 == -i ]] && { interval=$2; shift 2; }
  local -F deadline=$(( EPOCHREALTIME + $1 ))
  shift
  while true; do
    "$@" && return 0
    (( EPOCHREALTIME < deadline )) || return 1
    sleep $interval
  done
}

wait_settled() {
  local interval=0.2
  [[ $1 == -i ]] && { interval=$2; shift 2; }
  local -F deadline=$(( EPOCHREALTIME + $1 ))
  local -i reads=$2 same=0
  shift 2
  local now last=""
  while true; do
    now="$("$@" 2>/dev/null || true)"
    if [[ -n $now && $now == "$last" ]]; then (( same += 1 )); else same=1; fi
    [[ -z $now ]] && same=0
    last=$now
    if (( same >= reads )); then print -r -- "$now"; return 0; fi
    if (( EPOCHREALTIME >= deadline )); then print -r -- "$now"; return 1; fi
    sleep $interval
  done
}
