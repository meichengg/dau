#!/bin/zsh
# Types one text into real apps, idle and under load, to see whether in-place replacement goes wrong when the app is busy (M6).
# Side effects: builds, takes the screen, changes input source, changes user settings
#
# Usage: scripts/selftest/load/run.sh [--reps N] [--apps "A…"] [--loads "L…"] [--text std|edit]
#        [--dry-run | --print keys|expect]
#   --reps N     repetitions of every condition (default 3)
#   --apps "A…"  only these apps of the matrix (safari chrome vscode terminal)
#   --loads "L…" only these loads (idle busy); busy still only in browsers
#   --text T     std (default): TEXT_KEYS below, Telex in standard order; edit:
#                EDIT_KEYS, the same kind of sentences typed with free tone placement
#                (D28), a tone changed (vieetjs), a tone removed (Chaofz), ⌫ inside a
#                word (D32) and a tone added to a typed word (Hoc ⌫j, D20)
#   --dry-run    print the matrix and the estimated duration, run nothing
#   --print P    print the keys or the expected text of --text and exit: for runs this
#                script cannot do (Release build: no t_ns; another input source), e.g.
#                typing/run.sh --keys "$(load/run.sh --text edit --print keys)" …
#
# The question: at a human pace (--delay 100 --jitter 30), does a busy app make Dấu's
# in-place replacement (D11, D13) go wrong, and why. Three hypotheses, told apart by the
# per-key log of the Debug input method (scripts/perf/perf-report.sh):
#   H1  the busy app lets queued keys go in a burst: keys reach the input method < 10 ms
#       apart (gap_a/gap_b) although they were sent evenly (evgap_d), lag_us is large,
#       and the known < 10 ms failure follows (docs/COMPATIBILITY.md 6.2).
#   H2  keys arrive evenly (gap_d) but the app has not applied the previous insertText
#       yet, so selectedRange is stale: mismatch/resync at gaps ≥ 10 ms (gap_ge10_*),
#       or wrong text with even gaps.
#   H3  neither: the text is right and there are no mismatches.
#
# Matrix, each cell one call of scripts/selftest/typing/run.sh (its safety rules apply:
# keys only while the app under test is in front, its windows closed, the input source,
# clipboard, DauPerfLog and DauDebugForceUnderline put back after each call):
#   apps   safari chrome vscode terminal
#   load   idle; busy (--busy 300:1000: the test page blocks its main thread 300 ms of
#          every second; browsers only)
#   mode   inplace; underline (--underline, D13)
#   rep    1..N
# = (2 browsers × 2 loads + 2 apps × 1 load) × 2 modes × N = 36 cells for N = 3. The
# loop runs rep, then app, then load, then mode, so slow drift (heat, other work on the
# Mac) spreads over every condition instead of landing on one.
#
# Text: a fixed Telex string (TEXT_KEYS below, 227 keys) and the text the engine gives for
# it (TEXT_EXPECT): four sentences of modern Vietnamese with English words that must be
# restored (Deadline, project, email, meeting, Netflix, YouTube; D4) and the word ends
# Space , . ? (D4). Not built from scripts/research/compare-ims/*.txt: those cases are
# 100+ sentences (too long to type 60 times), and their scoring accepts both tone
# placements while typing/run.sh compares exactly. Words that are also valid Vietnamese
# ("reset" → "rết", "password" → "pasword" by D26) are left out on purpose, so a wrong
# text means the replacement went wrong. Under macOS 27.2 autocorrect a word may still
# change after Dấu typed it right (D4, known limit): the idle cells are the control.
#
# Needs: the Debug input method built from a commit that logs t_ns (DauPerfLog lines; a
# Release build or an older Debug build logs no arrival times, and the run stops after
# the first cell), the Dấu input source enabled, the four apps installed, the
# Accessibility permission for the terminal running it. Takes the screen for the whole
# run; the estimate is printed before the first cell.
#
# Output in build/load/<time>/: per cell <app>-<load>-<mode>-<rep>/ with the text read
# back (<app>.txt), the raw perf log lines (<app>.perf.log, numbers and bundle IDs only,
# D8), perf-report output (perf.txt) and typing/run.sh's own output (typing.log); and
# summary.tsv, one row per cell:
#   app load mode rep text_ok mismatch resync gap_lt2 gap_2_10 gap_10_20 gap_ge20
#   bad_lt10 bad_ge10 evgap_lt10 lag_p50_us lag_p99_us
# (bad_* = mismatch + resync keys by their arrival gap; evgap_lt10 = keys sent < 10 ms
# after the previous one; "-" = not in the log.) The summary is printed at the end, also
# after ⌃C (cells done so far).
#
# Cleanup: each typing/run.sh call cleans up after itself, also on ⌃C (both scripts get
# it). As a second line, this script saves at start and puts back at exit the selected
# input source, the clipboard and DauPerfLog, so a call that died without its cleanup
# cannot make the next call take a test value for the user's. It refuses to start while
# DauDebugForceUnderline is set (typing/run.sh --underline deletes it at exit).
#
# Exit status: 0 when the matrix ran (wrong texts are results, not failures, and are in
# the summary); 1 on an error; 2 on a bad call; 3/4 as typing/run.sh (another app came
# to the front / Dấu could not be selected), which stops the matrix; 130 on ⌃C.
set -uo pipefail

SELF="${0:A}"
ROOT="${SELF:h:h:h:h}"
source "$ROOT/scripts/lib/log.sh"
source "$ROOT/scripts/lib/swift-tool.sh"
TYPING="$ROOT/scripts/selftest/typing/run.sh"
REPORT="$ROOT/scripts/perf/perf-report.sh"

REPS=3
DRY_RUN=0
ONLY_APPS=""
ONLY_LOADS=""
TEXT=std
PRINT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --reps) REPS="${2:?--reps cần số lần}"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --apps) ONLY_APPS="${2:?--apps cần danh sách app}"; shift 2 ;;
    --loads) ONLY_LOADS="${2:?--loads cần danh sách tải}"; shift 2 ;;
    --text) TEXT="${2:?--text cần std hoặc edit}"; shift 2 ;;
    --print) PRINT="${2:?--print cần keys hoặc expect}"; shift 2 ;;
    -h|--help) log_usage "$SELF"; exit 0 ;;
    *) log_die 2 "Tham số không hợp lệ: $1" ;;
  esac
done
[[ "$REPS" =~ ^[1-9][0-9]*$ ]] || log_die 2 "--reps phải là số nguyên dương"

DELAY_MS=100
JITTER_MS=30
BUSY=300:1000
# Checked with DauEngine (default options, D15): these keys give exactly TEXT_EXPECT.
TEXT_KEYS='Chieeuf nay anh cos ranhr khoong, minhf ddi uoongs caf phee nhes. Deadline cuar project nayf laf thuws saus tuaanf sau. Seeps vuwaf guwir email veef buooir meeting toois qua. Toois nay xem phim treen Netflix hay YouTube ddaay? '
TEXT_EXPECT='Chiều nay anh có rảnh không, mình đi uống cà phê nhé. Deadline của project này là thứ sáu tuần sau. Sếp vừa gửi email về buổi meeting tối qua. Tối nay xem phim trên Netflix hay YouTube đây? '
# --text edit (M6, 09/11/2026). Checked with DauEngine the same way (ExternalCasesTests's
# replay, which also plays ⌫ and D20): these keys give exactly EDIT_EXPECT. "Chao" without
# a tone is on purpose (Chaofz: z removes the tone).
EDIT_KEYS='Sasng nay mojot nguoiwf banj guiwr email hoir veef deadline cuar project. Minhf phari vieetjs laji kees hoajch truwocs meeting chieeuf nay. Hoc ⌫j tieesng Anh khoong⌫g khos, chir caanf dduwowjc luyeenj ddeeuf mooix ngayf. Chaofz banj, xem video treen YouTube huowsng daanx nhes. '
EDIT_EXPECT='Sáng nay một người bạn gửi email hỏi về deadline của project. Mình phải viết lại kế hoạch trước meeting chiều nay. Học tiếng Anh không khó, chỉ cần được luyện đều mỗi ngày. Chao bạn, xem video trên YouTube hướng dẫn nhé. '
case $TEXT in
  std) ;;
  edit) TEXT_KEYS=$EDIT_KEYS; TEXT_EXPECT=$EDIT_EXPECT ;;
  *) log_die 2 "--text phải là std hoặc edit" ;;
esac
case $PRINT in
  "") ;;
  keys) print -rn -- "$TEXT_KEYS"; exit 0 ;;
  expect) print -rn -- "$TEXT_EXPECT"; exit 0 ;;
  *) log_die 2 "--print phải là keys hoặc expect" ;;
esac

APPS=(safari chrome vscode terminal)
if [[ -n "$ONLY_APPS" ]]; then
  for a in ${=ONLY_APPS}; do (( ${APPS[(Ie)$a]} )) || log_die 2 "--apps: app không có trong ma trận: $a"; done
  APPS=(${=ONLY_APPS})
fi
MODES=(inplace underline)
loads_for() { # app → its load conditions
  case "$1" in
    safari|chrome) print -r -- "idle busy" ;;
    *) print -r -- "idle" ;;
  esac
}
CELLS=()
for rep in {1..$REPS}; do
  for app in $APPS; do
    for load in ${=$(loads_for $app)}; do
      [[ -n "$ONLY_LOADS" && " $ONLY_LOADS " != *" $load "* ]] && continue
      for mode in $MODES; do CELLS+=("$app $load $mode $rep"); done
    done
  done
done

# Estimate: each key costs the pause plus ~15 ms for System Events to send it; each cell
# ~12 s more (start the script, open the app or page, select Dấu, read the text back,
# close, read the log).
KEY_COUNT=${#TEXT_KEYS}   # ASCII keys: characters = bytes, whatever the locale
CELL_S=$(( KEY_COUNT * (DELAY_MS + 15) / 1000 + 12 ))
TOTAL_S=$(( ${#CELLS} * CELL_S ))
log_step "Ma trận tải: ${#CELLS} ô (${(j: :)APPS} × ${ONLY_LOADS:-idle/busy} × ${(j:/:)MODES} × $REPS lần; busy chỉ ở trình duyệt)"
log_detail "mỗi ô $KEY_COUNT phím, nghỉ ${DELAY_MS} ± ${JITTER_MS} ms giữa hai phím"
log_detail "ước tính: khoảng $(log_duration $CELL_S) mỗi ô, tổng khoảng $(log_duration $TOTAL_S)"
if (( DRY_RUN )); then
  for c in $CELLS; do log_detail "$c"; done
  exit 0
fi

PERF_KEY=DauPerfLog
FORCE_KEY=DauDebugForceUnderline
if defaults read -g "$FORCE_KEY" >/dev/null 2>&1; then
  log_error "$FORCE_KEY đang được đặt; typing/run.sh --underline sẽ xoá nó khi xong."
  log_hint "Xoá trước nếu không cần (defaults delete -g $FORCE_KEY) rồi chạy lại."
  exit 1
fi

INPUT_SOURCE="$(dau_swift_tool input-source "$ROOT/scripts/lib/input-source.swift")" || exit 1
CLIPBOARD="$(dau_swift_tool clipboard "$ROOT/scripts/selftest/typing/clipboard.swift")" || exit 1

OUT="$ROOT/build/load/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"
SUMMARY="$OUT/summary.tsv"
print -r -- $'app\tload\tmode\trep\ttext_ok\tmismatch\tresync\tgap_lt2\tgap_2_10\tgap_10_20\tgap_ge20\tbad_lt10\tbad_ge10\tevgap_lt10\tlag_p50_us\tlag_p99_us' > "$SUMMARY"

# Second line of cleanup (see the header): what was there before the first call.
ORIGINAL_SOURCE="$("$INPUT_SOURCE" current)"
WORK="$(mktemp -d)"
"$CLIPBOARD" save "$WORK/clipboard.plist" || exit 1
PERF_TYPE=""; PERF_VALUE=""
if PERF_TYPE="$(defaults read-type -g "$PERF_KEY" 2>/dev/null)"; then
  PERF_TYPE="${PERF_TYPE#Type is }"
  PERF_VALUE="$(defaults read -g "$PERF_KEY")"
else
  PERF_TYPE=""
fi
restore_perf_key() {
  case "$PERF_TYPE" in
    "") defaults delete -g "$PERF_KEY" >/dev/null 2>&1 ;;
    boolean) defaults write -g "$PERF_KEY" -bool "$([[ "$PERF_VALUE" == 1 ]] && echo true || echo false)" ;;
    integer) defaults write -g "$PERF_KEY" -int "$PERF_VALUE" ;;
    float) defaults write -g "$PERF_KEY" -float "$PERF_VALUE" ;;
    string) defaults write -g "$PERF_KEY" -string "$PERF_VALUE" ;;
    # Other types: typing/run.sh refuses to start, so nothing was changed.
  esac
}
print_summary() {
  [[ -s "$SUMMARY" ]] || return 0
  log_step "Tóm tắt ($SUMMARY)"
  column -t -s $'\t' "$SUMMARY"
}
cleanup() {
  restore_perf_key
  defaults delete -g "$FORCE_KEY" >/dev/null 2>&1
  "$CLIPBOARD" restore "$WORK/clipboard.plist" 2>/dev/null || log_warn "Không khôi phục được clipboard"
  rm -rf "$WORK"
  if [[ "$("$INPUT_SOURCE" current 2>/dev/null)" != "$ORIGINAL_SOURCE" ]]; then
    "$INPUT_SOURCE" select "$ORIGINAL_SOURCE" >/dev/null 2>&1 || log_warn "Không chọn lại được nguồn $ORIGINAL_SOURCE"
  fi
  print_summary
  log_detail "kết quả: $OUT"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

# Value of metric $2 in perf-report output $1 ("-" when absent): the count, or for a
# p50/p99 row the field named $3.
metric() {
  local line
  line="$(grep -E "^  $2 " "$1" 2>/dev/null | head -1)"
  [[ -n "$line" ]] || { print -r -- "-"; return; }
  if [[ -n "${3:-}" ]]; then
    print -r -- "${${line#*$3=}%% *}"
  else
    print -r -- "${${(z)line}[2]}"
  fi
}
sum() { # numbers or "-": their sum, "-" if all are "-"
  local total=0 any=0 v
  for v in "$@"; do [[ $v == - ]] || { (( total += v )); any=1; }; done
  (( any )) && print -r -- $total || print -r -- "-"
}

STATUS=0
index=0
for cell in $CELLS; do
  (( index += 1 ))
  parts=(${=cell}); app=$parts[1]; load=$parts[2]; mode=$parts[3]; rep=$parts[4]
  dir="$OUT/$app-$load-$mode-$rep"
  mkdir -p "$dir"
  args=(--delay $DELAY_MS --jitter $JITTER_MS --keys "$TEXT_KEYS" --expect "$TEXT_EXPECT" --save "$dir")
  case $load in
    busy) args+=(--busy $BUSY) ;;
  esac
  [[ $mode == underline ]] && args+=(--underline)
  log_step "Ô $index/${#CELLS}: $app, tải $load, $mode, lần $rep"
  rc=0
  "$TYPING" $args $app > "$dir/typing.log" 2>&1 || rc=$?
  # 1 is also log_die's status (no text saved then): only a saved text makes it a result.
  if (( rc > 1 )) || [[ ! -f "$dir/$app.txt" ]]; then
    tail -5 "$dir/typing.log" >&2
    log_error "Ô $index dừng (mã thoát $rc); nhật ký: $dir/typing.log"
    (( rc > 1 )) && STATUS=$rc || STATUS=1
    break
  fi
  # --app matches part of the bundle ID, any case: safari, chrome, vscode, terminal.
  "$REPORT" --input "$dir/$app.perf.log" --app $app > "$dir/perf.txt" 2>&1
  p="$dir/perf.txt"
  if [[ "$(metric "$p" gap_d_ge20ms)" == - ]]; then
    log_error "Ô $index không có thời điểm phím (t_ns) trong nhật ký: bộ gõ đã cài là bản Release, hoặc bản Debug cũ hơn thay đổi ghi t_ns."
    log_hint "Cài bản Debug mới (scripts/dev/install-input-method.sh) rồi chạy lại."
    STATUS=1
    break
  fi
  ok=$(( rc == 0 ))
  row=(
    $app $load $mode $rep $ok
    "$(metric "$p" count_mismatch)"
    "$(sum "$(metric "$p" count_resync)" "$(metric "$p" count_resync_pass)")"
    "$(metric "$p" gap_a_lt2ms)" "$(metric "$p" gap_b_2to10ms)"
    "$(metric "$p" gap_c_10to20ms)" "$(metric "$p" gap_d_ge20ms)"
    "$(sum "$(metric "$p" gap_lt10_mismatch)" "$(metric "$p" gap_lt10_resync)")"
    "$(sum "$(metric "$p" gap_ge10_mismatch)" "$(metric "$p" gap_ge10_resync)")"
    "$(sum "$(metric "$p" evgap_a_lt2ms)" "$(metric "$p" evgap_b_2to10ms)")"
    "$(metric "$p" lag_us p50)" "$(metric "$p" lag_us p99)"
  )
  print -r -- "${(pj:\t:)row}" >> "$SUMMARY"
  if (( ok )); then log_ok "đúng chữ"; else log_error "sai chữ (xem $dir/$app.txt)"; fi
  # Fixed: typing/run.sh reads the log from a start time in whole seconds; one second
  # between cells keeps this cell's lines out of the next cell's log.
  sleep 1
done

(( STATUS == 0 )) && log_done
exit $STATUS
