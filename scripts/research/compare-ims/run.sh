#!/bin/zsh
# Types the comparison cases with Dấu and with the macOS Vietnamese Telex input source in
# Safari and Chrome, then scores both (docs/research/COMPETITOR-COMPARISON.md, part C).
# Side effects: builds, takes the screen, changes input source, changes user settings
#
# Usage: scripts/research/compare-ims/run.sh [--delay MS] [dau|apple]...
#   --delay MS   pause between keys (default 30)
#   dau, apple   which input sources to run (default: both, Dấu first)
#
# Each run goes through scripts/selftest/typing/run.sh (its safety rules apply: keys only
# while the test page is in front, the input source and clipboard put back at the end).
# Both sources must already be enabled; nothing is enabled or disabled (N4). Text read
# back and the score go to build/compare-ims/<time>/ (git-ignored).
set -euo pipefail
ROOT="${0:A:h:h:h:h}"
HERE="${0:A:h}"
source "$ROOT/scripts/lib/log.sh"
source "$ROOT/scripts/lib/swift-tool.sh"

APPLE_TELEX=com.apple.inputmethod.VietnameseIM.VietnameseTelex
DELAY=30
SOURCES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --delay) DELAY="${2:?--delay cần số ms}"; shift 2 ;;
    dau|apple) SOURCES+=("$1"); shift ;;
    -h|--help) log_usage "${0:A}"; exit 0 ;;
    *) log_die 2 "Tham số không hợp lệ: $1" ;;
  esac
done
(( $#SOURCES )) || SOURCES=(dau apple)

OUT="$ROOT/build/compare-ims/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"
CASES=$(dau_swift_tool compare-ims-cases "$HERE/cases.swift") || exit 1
KEYS="$("$CASES" keys)"
EXPECT="$("$CASES" expect)"

for src in $SOURCES; do
  mkdir -p "$OUT/$src"
  args=(--delay "$DELAY" --keys "$KEYS" --expect "$EXPECT" --save "$OUT/$src")
  [[ $src == apple ]] && args+=(--source "$APPLE_TELEX")
  log_step "Gõ bằng nguồn \"$src\" trong Safari và Chrome (${#KEYS} phím mỗi app, ${DELAY} ms giữa hai phím)"
  rc=0
  "$ROOT/scripts/selftest/typing/run.sh" $args safari chrome >"$OUT/$src/typing.log" 2>&1 || rc=$?
  # 1 only means the text differs from the expected one, which the score below counts.
  if (( rc != 0 && rc != 1 )); then
    tail -5 "$OUT/$src/typing.log" >&2
    log_die "Lượt \"$src\" dừng (mã thoát $rc); nhật ký: $OUT/$src/typing.log"
  fi
done

"$CASES" score "$OUT"/*/(safari|chrome).txt | tee "$OUT/score.md"
log_detail "kết quả: $OUT"
log_done
