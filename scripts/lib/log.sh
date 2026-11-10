#!/bin/zsh
# Terminal output shared by every script (sourced, not run): one look for steps, details,
# results, warnings and errors. The convention lives in scripts/README.md, "Đầu ra".
# Side effects: none
#
#   log_step TEXT        "==> TEXT"          a step starts (stdout)
#   log_detail TEXT      "    TEXT"          a detail of the current step (stdout)
#   log_ok TEXT          "✓ TEXT"            a check passed (stdout)
#   log_warn TEXT        "! TEXT"            something to look at; the script goes on (stderr)
#   log_error TEXT       "✗ TEXT"            a failure (stderr); the caller decides to stop
#   log_hint TEXT        "    TEXT"          what to do about the warning or error above (stderr)
#   log_die [CODE] TEXT  log_error, then exit CODE (default 1)
#   log_ask TEXT         "? TEXT " with no newline, before a `read` (stderr)
#   log_done [TEXT]      "==> TEXT · <time since the script started>" (default "Xong")
#   log_duration SECONDS "8 giây", "2 phút 14 giây"
#   log_usage FILE       the comment block at the top of FILE, without "# " and the shebang (stdout)
#
# Colors only when that stream is a terminal, NO_COLOR is unset (https://no-color.org)
# and TERM is not "dumb"; the marks stay, so a log written to a file still reads and greps.
# Several lines in one call: each argument is a line, e.g. log_hint "line 1" "line 2".

zmodload zsh/datetime
typeset -gF DAU_LOG_START=${DAU_LOG_START:-$EPOCHREALTIME}

_dau_log_color() { # fd -> 0 when that stream gets colors
  [[ -z ${NO_COLOR-} && ${TERM-} != dumb && -t $1 ]]
}

_dau_log() { # fd mark color-code indent text...
  local fd=$1 mark=$2 code=$3 indent=$4 line on='' off=''
  shift 4
  if _dau_log_color $fd && [[ -n $code ]]; then on=$'\e['"${code}m"; off=$'\e[0m'; fi
  for line in "$@"; do
    if [[ -n $mark ]]; then
      print -r -u $fd -- "${on}${mark}${off} ${line}"
    else
      print -r -u $fd -- "${indent}${line}"
    fi
  done
}

log_step()   { _dau_log 1 '==>' '1;34' '' "$@"; }
log_detail() { _dau_log 1 ''    ''     '    ' "$@"; }
log_ok()     { _dau_log 1 '✓'   '32'   '' "$@"; }
log_warn()   { _dau_log 2 '!'   '1;33' '' "$@"; }
log_error()  { _dau_log 2 '✗'   '1;31' '' "$@"; }
log_hint()   { _dau_log 2 ''    ''     '    ' "$@"; }

log_die() {
  local code=1
  [[ $1 == <-> ]] && { code=$1; shift; }
  log_error "$@"
  exit $code
}

log_ask() {
  local on='' off=''
  _dau_log_color 2 && { on=$'\e[1;36m'; off=$'\e[0m'; }
  print -rn -u 2 -- "${on}?${off} $1 "
}

log_duration() { # seconds (may be fractional)
  local s=${1%.*}
  (( s < 60 )) && { print -r -- "$s giây"; return; }
  print -r -- "$(( s / 60 )) phút $(( s % 60 )) giây"
}

log_done() {
  log_step "${1:-Xong} · $(log_duration $(( EPOCHREALTIME - DAU_LOG_START )))"
}

log_usage() { # file: prints its leading comment block, for -h/--help
  local line first=1
  while IFS= read -r line; do
    (( first )) && { first=0; continue; }
    [[ $line == '#'* ]] || break
    line=${line#\#}; print -r -- "${line# }"
  done < "$1"
}
