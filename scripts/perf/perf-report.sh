#!/bin/zsh
# Prints per-app timing of the input method from the unified log.
# Side effects: none
# Approach A (N3/D11): p50/p99 of `selectedRange()`, `insertText`, `attributedSubstring` (D20), and the whole
# `handle`, plus event counts.
#
# Debug builds only (Release logs nothing per key, D8). The input method logs one line
# per key only while the global defaults key DauPerfLog
# is set (`defaults write -g DauPerfLog -bool true`, then `defaults delete -g DauPerfLog`
# when done; it applies to text fields opened after it is set), category "perf": event
# kind, durations in ns and the client app's bundle ID. Never the text typed (D8).
# D20 reads are also counted as d20_<mark|letter>_seeded<0|1>, and diff_<0|1> counts the
# keys of a seeded word whose result differs from an engine that never read the text.
#
# Gaps between keys (M6, app under load). Each key line carries t_ns (CLOCK_UPTIME_RAW when
# the input method's handle started: the key reached the input method) and ev_ns (the
# event's own timestamp, same clock: when the key event was made, 0 if unknown). Per app:
#   gap_<a_lt2ms|b_2to10ms|c_10to20ms|d_ge20ms>   keys by t_ns gap to the app's previous
#                                                  key line (gaps over 1 s are skipped:
#                                                  another run, or a pause in typing)
#   evgap_<same buckets>                           the same with ev_ns: how the keys were
#                                                  sent. Even evgap with bunched gap = the
#                                                  app held keys back and let them go together
#   gap_<lt10|ge10>_<mismatch|resync>              mismatch and resync/resync_pass keys by
#                                                  their t_ns gap (under/over 10 ms)
#   lag_us                                         t_ns - ev_ns, p50/p99/max
# Mouse clicks and shortcuts (⌘A ⌘C…) are key lines too (kind reset/commit) and count in
# the gaps. Lines written before these fields existed parse as before and give no gap rows.
#
# Usage:
#   scripts/perf/perf-report.sh                      last 1 hour, all apps
#   scripts/perf/perf-report.sh --last 10m           any `log show --last` value
#   scripts/perf/perf-report.sh --app TextEdit       bundle ID or part of it, any case
#                                               (TextEdit, com.apple.Safari, chrome, slack)
#   scripts/perf/perf-report.sh --input FILE         parse saved `log show --style compact` output
#
# Subsystem = the input method's bundle ID, read from the installed bundle; override with
# DAU_IM_BUNDLE_ID.
set -euo pipefail

source "${0:A:h:h}/lib/log.sh"

LAST="1h"
APP_FILTER=""
INPUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --last) LAST="${2:?--last cần giá trị, ví dụ 10m}"; shift 2 ;;
    --app) APP_FILTER="${2:?--app cần tên app hoặc bundle ID}"; shift 2 ;;
    --input) INPUT="${2:?--input cần đường dẫn file}"; shift 2 ;;
    -h|--help) log_usage "$0"; exit 0 ;;
    *) log_die 2 "Tham số không hợp lệ: $1" ;;
  esac
done

INSTALLED_PLIST="$HOME/Library/Input Methods/DauInputMethod.app/Contents/Info.plist"
SUBSYSTEM="${DAU_IM_BUNDLE_ID:-}"
if [[ -z "$SUBSYSTEM" && -f "$INSTALLED_PLIST" ]]; then
  SUBSYSTEM="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$INSTALLED_PLIST" 2>/dev/null || true)"
fi
SUBSYSTEM="${SUBSYSTEM:-com.codefastlabs.dau.inputmethod.Dau}"

read_log() {
  if [[ -n "$INPUT" ]]; then
    cat "$INPUT"
  else
    /usr/bin/log show --last "$LAST" --style compact \
      --predicate "subsystem == \"$SUBSYSTEM\" AND category == \"perf\""
  fi
}

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

# Step 1: one row per measurement: "<app> <metric> <value>".
read_log | awk -v want="$(printf '%s' "$APP_FILTER" | tr '[:upper:]' '[:lower:]')" '
  function field(name,   i, n, parts) {
    for (i = 1; i <= NF; i++) {
      if (index($i, name "=") == 1) { return substr($i, length(name) + 2) }
    }
    return ""
  }
  / key kind=/ {
    app = field("app"); kind = field("kind")
    if (app == "" || kind == "") next
    if (want != "" && index(tolower(app), want) == 0) next
    d20 = field("d20"); seeded = field("seeded"); diff = field("diff")
    if (d20 != "" && d20 != "none") print app, "d20_" d20 "_seeded" seeded, 1
    if (diff == "0" || diff == "1") print app, "diff_" diff, 1
    print app, "count_" kind, 1
    h = field("handle_ns"); s = field("sel_ns"); i = field("ins_ns"); r = field("read_ns")
    if (h != "") print app, "handle_us", h / 1000
    if (kind == "replace" || kind == "mismatch" || kind == "unsupported") {
      if (h != "") print app, "handle_replace_us", h / 1000
    }
    if (s != "" && s + 0 >= 0) print app, "selectedRange_us", s / 1000
    if (i != "" && i + 0 >= 0) print app, "insertText_us", i / 1000
    # D20 "Thêm dấu cho từ đã gõ": attributedSubstring, and the whole key when it read.
    if (r != "" && r + 0 >= 0) print app, "attributedSubstring_us", r / 1000
    if (kind ~ /^seed/ && h != "") print app, "handle_seed_us", h / 1000
    # Arrival times (lines from before t_ns/ev_ns existed have neither: no gap rows).
    t = field("t_ns"); e = field("ev_ns")
    if (t != "") {
      timed[app] = 1
      if (app in last_t) {
        gap = (t - last_t[app]) / 1e6
        # Over 1 s: another run, or a word typed after a pause; not a gap between keys.
        if (gap >= 0 && gap <= 1000) {
          print app, "gap_" bucket(gap), 1
          bad = (kind == "mismatch") ? "mismatch" : (kind ~ /^resync/ ? "resync" : "")
          if (bad != "") print app, (gap < 10 ? "gap_lt10_" : "gap_ge10_") bad, 1
        }
      }
      last_t[app] = t
      if (e != "" && e + 0 > 0) {
        lag = (t - e) / 1000
        if (lag >= 0) print app, "lag_us", lag
        if (app in last_e) {
          gap = (e - last_e[app]) / 1e6
          if (gap >= 0 && gap <= 1000) print app, "evgap_" bucket(gap), 1
        }
        last_e[app] = e
      }
    }
  }
  function bucket(ms) {
    if (ms < 2) return "a_lt2ms"
    if (ms < 10) return "b_2to10ms"
    if (ms < 20) return "c_10to20ms"
    return "d_ge20ms"
  }
  END {
    # Every bucket for every app with arrival times, zero included, so readers of the
    # report (scripts/selftest/load/run.sh) always find the four rows.
    split("a_lt2ms b_2to10ms c_10to20ms d_ge20ms", names, " ")
    for (app in timed) {
      for (k = 1; k <= 4; k++) { print app, "gap_" names[k], 0; print app, "evgap_" names[k], 0 }
      print app, "gap_lt10_mismatch", 0; print app, "gap_lt10_resync", 0
      print app, "gap_ge10_mismatch", 0; print app, "gap_ge10_resync", 0
    }
  }
  / event name=/ {
    app = field("app"); name = field("name")
    if (want != "" && index(tolower(app), want) == 0) next
    if (app != "" && name != "") print app, "event_" name, 1
  }
' | sort -k1,1 -k2,2 -k3,3g > "$TMP"

if [[ ! -s "$TMP" ]]; then
  log_warn "Không có số đo nào (subsystem $SUBSYSTEM, --last $LAST${APP_FILTER:+, app $APP_FILTER})."
  log_hint "Kiểm tra: bộ gõ bản Debug đã cài và đã gõ thử trong khoảng thời gian này chưa?"
  if [[ -n "$APP_FILTER" ]]; then
    log_hint "--app so khớp một phần bundle ID (không phân biệt hoa thường), không nhận PID."
    log_step "Các app có số đo trong khoảng này"
    read_log | grep -o 'app=[^ ]*' | sort -u | sed 's/^app=//' | while IFS= read -r a; do log_detail "$a"; done || true
  fi
  exit 0
fi

echo "Subsystem: $SUBSYSTEM   Khoảng: ${INPUT:-log show --last $LAST}"
echo "Đơn vị: µs. p50/p99 theo hạng gần nhất (nearest rank). n = số mẫu."

# Step 2: per (app, metric) group, counts for count_/event_ rows, p50/p99/max otherwise.
awk '
  function flush(   i50, i99) {
    if (n == 0) return
    if (metric ~ /^(count_|event_|d20_|diff_|gap_|evgap_)/) {
      printf "  %-22s %8d\n", metric, sum
    } else {
      i50 = int((50 * n + 99) / 100); if (i50 < 1) i50 = 1
      i99 = int((99 * n + 99) / 100); if (i99 < 1) i99 = 1
      printf "  %-22s n=%-7d p50=%-10.1f p99=%-10.1f max=%.1f\n", metric, n, v[i50], v[i99], v[n]
    }
  }
  {
    if ($1 != app) {
      flush(); n = 0; sum = 0; metric = ""
      app = $1; printf "\n%s\n", app
    }
    if ($2 != metric) { flush(); n = 0; sum = 0; metric = $2 }
    n++; v[n] = $3; sum += $3
  }
  END { flush() }
' "$TMP"
