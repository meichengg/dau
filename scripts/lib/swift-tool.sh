#!/bin/zsh
# Builds a small Swift command-line tool for a script, once (sourced, not run).
# Side effects: builds
#
#   dau_swift_tool NAME SOURCE...   compile SOURCE... with `xcrun swiftc -O` into
#                                   build/tools/NAME when that binary is missing or older
#                                   than one of the sources, then print its path; on a
#                                   compile error print it and return 1.
#
# Scripts call a compiled binary, never `swift file.swift`: interpreting recompiles on
# every run (about a second even for an empty file), compiling once costs that only when
# the source changes. Which language a script part is written in: scripts/README.md,
# "Ngôn ngữ".
#
# Needs scripts/lib/log.sh sourced first.

dau_swift_tool() {
  local name=$1; shift
  local root=${${(%):-%x}:A:h:h:h}
  local bin=$root/build/tools/$name src stale=0
  [[ -x $bin ]] || stale=1
  for src in "$@"; do [[ $src -nt $bin ]] && stale=1; done
  if (( stale )); then
    mkdir -p ${bin:h}
    local out
    # Absolute source paths: a tool may locate files next to its source through #filePath.
    if ! out=$(xcrun swiftc -O -o $bin "${@:A}" 2>&1); then
      log_error "Không biên dịch được ${(j:, :)@:t}:"
      log_hint ${(f)out}
      return 1
    fi
  fi
  print -r -- $bin
}
