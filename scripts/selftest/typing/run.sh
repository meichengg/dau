#!/bin/zsh
# Types a sentence into real apps with the Dấu input method and checks the text.
# Side effects: builds, takes the screen, changes input source, changes user settings
# Needs the Accessibility permission for the process running the script
# (System Events keystrokes); the input method must be installed (Debug for the per-key
# timings: a Release build types the same but logs nothing per key, D8), the Dấu input
# source enabled (scripts/dev/install-input-method.sh), and the apps installed.
#
# Usage:
#   scripts/selftest/typing/run.sh [options] <app>...
#     app:  safari | chrome | vscode | terminal | edge | firefox | notes | mail
#           | all (= the first four)
#     No TextEdit: it autosaves every new document to iCloud Drive, closed or not
#     (docs/TROUBLESHOOTING.md); Safari's test page is the AppKit/WebKit reference.
#   --delay MS        pause between keys in ms (default 30). 0 sends the whole string in
#                     one System Events keystroke (about 1 ms per key): a stress test that
#                     Chrome, VS Code and Terminal fail with method A (docs/PROGRESS.md);
#                     120 is close to normal typing.
#   --keys "…"        keys to type (default: the sample sentence below). Two marks are
#                     not typed as characters: ⌫ sends the Delete key; ⇄ switches the
#                     input source to U.S. (com.apple.keylayout.US, must be enabled) and
#                     back to Dấu with TISSelectInputSource from this script's process,
#                     which IMK does not report to the input method as a deactivation
#                     (ROADMAP M3). Example (D20, K7): --keys "hoc ⌫j " --expect "học "
#   --expect "…"      expected text (default: what the sample sentence must give)
#   --source ID       type with this input source instead of Dấu (an enabled one, such as
#                     com.apple.inputmethod.VietnameseIM.VietnameseTelex); used by
#                     scripts/research/compare-ims/run.sh. Dấu must still be installed;
#                     the verdict still compares with --expect.
#   --jitter MS       each pause is --delay plus a random whole number of ms between -MS
#                     and +MS (never below 0), drawn per key: closer to a human than an
#                     even pace. With --delay 0 the keys still go one by one.
#   --busy MS:PERIOD  browsers only (safari chrome edge firefox; any other app is an
#                     error): the local test page runs a JavaScript loop that blocks the
#                     page's main thread for MS ms every PERIOD ms (MS < PERIOD), from when
#                     the page loads until its tab closes. The app stays responsive to the
#                     window server; only the page (the renderer, which applies the text) is
#                     late. The clean "busy app" condition of M6.
#   --save DIR        also write the text read back from each app to DIR/<app>.txt and the
#                     input method's perf and diag log (ReplaceDiag: positions of each
#                     replacement) from the start of that app's run (`log show
#                     --style compact`, numbers and bundle IDs only, D8; lines of other apps
#                     too, if any typed meanwhile) to DIR/<app>.perf.log, for
#                     `scripts/perf/perf-report.sh --input`
#   --underline       force underline mode (D13: marked text, committed at the word end)
#                     for each app tested, without touching the user's Dấu settings.
#                     Debug input method only: the script writes the bundle ID into the
#                     global defaults key DauDebugForceUnderline (`defaults write -g`,
#                     the only domain both a shell can write and the sandboxed input
#                     method can read) before the app runs, and deletes the key at exit.
#                     The input method reads it at activation; the report shows
#                     `underline-on` when it took effect. By hand:
#                       defaults write -g DauDebugForceUnderline -array com.google.Chrome
#                       defaults delete -g DauDebugForceUnderline
#
# For each app: opens a new, empty window, selects the Dấu input source (which must be
# enabled already; nothing is enabled or disabled, N4), types, reads the text back,
# closes the window without saving, prints the text, a ✓/✗ verdict and the input method's
# counts and timings for that app (scripts/perf/perf-report.sh; the script sets the global
# defaults key DauPerfLog for the run and at exit puts back what was there: the same value
# and type, or deletes the key if it was absent, D8). The input source selected
# before and the clipboard (read through ⌘C in browsers, VS Code, Notes, Mail) are
# restored; the clipboard is emptied before each ⌘C so a failed copy cannot pass. A new
# document whose first letter the app capitalized by itself counts as a pass (noted).
#
# Edge, Firefox: the same local test page as Safari/Chrome, closed with ⌘W.
# Notes: a new note (⌘N) in the folder shown; it syncs while it exists. The script
# empties it, and Notes drops an empty new note (docs/COMPATIBILITY.md, cleanup line).
# Mail: a new message (⌘N), keys go to the body focused through Accessibility, the To
# field stays empty, Send is never pressed; the body is emptied and the window closed
# with "Don't Save". Apps launched by the script stay running.
#
# Terminal: the keys go to the shell prompt of a new window. The script never presses
# Return; it clears the line with ⌃U before closing the window. Keys must not contain
# a newline.
#
# Safety: keys and shortcuts (⌘A ⌘C ⌘W ⌃U) are only sent while the app under test is
# frontmost (browsers: with the test page in front; VS Code: an Untitled editor; Mail:
# the New Message window). If another app comes to the front, the script stops sending
# keys and exits with status 3, also when that happens during the last app.
#
# After selecting the Dấu input source the script checks that Dấu is the current source
# (TIS is trusted for the current source only); if not, it stops and exits with status 4.
# The "Dấu is enabled" check is cross-checked against com.apple.inputsources ›
# AppleEnabledThirdPartyInputSources (input-source.swift).
#
# Exit status 0 only if every app gives the expected text. Messages: Vietnamese, through
# scripts/lib/log.sh (the per-app text and verdict go to stdout, stops and warnings to stderr).
set -uo pipefail

SELF="${0:A}"   # $0 inside a function is the function name in zsh
ROOT="${SELF:h:h:h:h}"
source "$ROOT/scripts/lib/log.sh"
source "$ROOT/scripts/lib/wait.sh"
HERE="$ROOT/scripts/selftest/typing"
source "$ROOT/scripts/lib/xcode.sh"
source "$ROOT/scripts/lib/swift-tool.sh"
dau_developer_dir
LOG=/usr/bin/log

# "carr" comes first: after Vietnamese text, macOS 27.2 autocorrect turns a typed "car"
# into "cả" (D4, known limit), which would hide what Dấu did.
KEYS='windows carr tooi yeeu tieengs Vieetj, Sunrise '
EXPECT='windows car tôi yêu tiếng Việt, Sunrise '
DELAY_MS=30
UNDERLINE=0
SOURCE_ID=""
SAVE_DIR=""
JITTER_MS=0
BUSY=""
FORCE_KEY=DauDebugForceUnderline
APPS=()
# Prints the whole leading comment block.
usage() { log_usage "$SELF"; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --delay) DELAY_MS="${2:?--delay cần số ms}"; shift 2 ;;
    --keys) KEYS="${2?}"; shift 2 ;;
    --expect) EXPECT="${2?}"; shift 2 ;;
    --underline) UNDERLINE=1; shift ;;
    --source) SOURCE_ID="${2:?--source cần ID nguồn}"; shift 2 ;;
    --save) SAVE_DIR="${2:?--save cần thư mục}"; shift 2 ;;
    --jitter) JITTER_MS="${2:?--jitter cần số ms}"; shift 2 ;;
    --busy) BUSY="${2:?--busy cần MS:PERIOD, ví dụ 300:1000}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    all) APPS+=(safari chrome vscode terminal); shift ;;
    safari|chrome|vscode|terminal|edge|firefox|notes|mail) APPS+=("$1"); shift ;;
    *) log_die 2 "Tham số không hợp lệ: $1" ;;
  esac
done
[[ ${#APPS[@]} -gt 0 ]] || { usage; exit 2; }
[[ "$JITTER_MS" =~ ^[0-9]+$ ]] || log_die 2 "--jitter phải là số nguyên ms"
# --save DIR need not exist yet (compare-ims and load/run.sh create theirs; a call by hand may not).
[[ -z "$SAVE_DIR" ]] || mkdir -p "$SAVE_DIR" || log_die "Không tạo được thư mục $SAVE_DIR"
BUSY_MS=0; BUSY_PERIOD=0
if [[ -n "$BUSY" ]]; then
  [[ "$BUSY" =~ ^[0-9]+:[0-9]+$ ]] || log_die 2 "--busy phải có dạng MS:PERIOD (số nguyên ms), ví dụ 300:1000"
  BUSY_MS=${BUSY%%:*}; BUSY_PERIOD=${BUSY##*:}
  (( BUSY_MS > 0 && BUSY_MS < BUSY_PERIOD )) || log_die 2 "--busy cần 0 < MS < PERIOD"
  for app in "${APPS[@]}"; do
    [[ $app == (safari|chrome|edge|firefox) ]] \
      || log_die 2 "--busy chỉ dùng với trình duyệt (safari chrome edge firefox), không với $app"
  done
fi
# A locked screen (or one asleep behind the lock, e.g. a run started from another device)
# keeps every app from coming to the front: nothing would be typed, and the test pages
# opened would be left behind. Refuse before opening anything.
if ioreg -n Root -d1 -a | grep -A1 CGSSessionScreenIsLocked | grep -q '<true/>'; then
  log_die "Màn hình Mac đang khoá: không mở app, không gõ. Mở khoá rồi chạy lại."
fi
US_SOURCE=com.apple.keylayout.US
if [[ "$KEYS" == *$'\n'*|| "$KEYS" == *$'\r'* ]]; then
  log_die 2 "Phím gõ không được có xuống dòng (không bao giờ nhấn Return trong Terminal)."
fi

# --- helpers -------------------------------------------------------------------------
INPUT_SOURCE="$(dau_swift_tool input-source "$ROOT/scripts/lib/input-source.swift")" || exit 1
CLIPBOARD="$(dau_swift_tool clipboard "$HERE/clipboard.swift")" || exit 1

IM_PLIST="$HOME/Library/Input Methods/DauInputMethod.app/Contents/Info.plist"
[[ -f "$IM_PLIST" ]] || log_die "Chưa cài bộ gõ (scripts/dev/install-input-method.sh)."
IM_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$IM_PLIST")"
DAU_SOURCE="$("$INPUT_SOURCE" enabled "$IM_ID" | grep '\.vi$' | head -1)"
# The helper cross-checks TIS with com.apple.inputsources and says on stderr when they
# disagree (TIS alone has been wrong on macOS 27.2).
[[ -n "$DAU_SOURCE" ]] || {
  log_error "Nguồn nhập liệu Dấu – Tiếng Việt chưa được bật (hoặc TIS và com.apple.inputsources không khớp, xem dòng trên)."
  log_hint "Thêm bằng \"+\" trong System Settings › Keyboard › \"All Input Sources\" (scripts/dev/install-input-method.sh nói rõ các bước)."
  exit 1
}
if [[ -n "$SOURCE_ID" ]]; then
  # Another source in place of Dấu: it must be enabled already (nothing is enabled, N4).
  (( ${${(f)"$("$INPUT_SOURCE" enabled "$SOURCE_ID")"}[(Ie)$SOURCE_ID]} )) \
    || log_die "Nguồn $SOURCE_ID chưa được bật (script không tự bật, N4)."
  DAU_SOURCE="$SOURCE_ID"
fi
if [[ "$KEYS" == *"⇄"* ]] && (( ! ${${(f)"$("$INPUT_SOURCE" enabled "$US_SOURCE")"}[(Ie)$US_SOURCE]} )); then
  log_die "⇄ cần nguồn $US_SOURCE đã bật (script không tự bật, N4)."
fi

WORK="$(mktemp -d)"
# Written when the run must stop: "front" (another app came to the front) or "source"
# (the input source did not become the one selected).
STOP_FILE="$WORK/stop"
# ⇄: U.S., then back to Dấu, from this (unsandboxed) process. AppleScript's `do shell
# script` runs it with /bin/sh. Each select waits (3 s at most) until TIS reports the new
# source as current; if it never does, "source" goes into the stop file and the keys stop.
# The 0.3 s after that stays fixed: the input method learns of the switch through a
# notification this script cannot observe.
SWITCH_CMD="$(printf 'sw() { %q select "$1" >/dev/null || exit 1; i=0; while [ "$(%q current)" != "$1" ]; do i=$((i+1)); if [ $i -ge 30 ]; then echo source > %q; exit 1; fi; sleep 0.1; done; sleep 0.3; }; sw %q; sw %q' \
  "$INPUT_SOURCE" "$INPUT_SOURCE" "$STOP_FILE" "$US_SOURCE" "$DAU_SOURCE")"
ORIGINAL_SOURCE="$("$INPUT_SOURCE" current)"
"$CLIPBOARD" save "$WORK/clipboard.plist" || exit 1
# The per-key log is off unless DauPerfLog is set (D8); turn it on for this run only.
PERF_KEY=DauPerfLog
# Remember the key exactly: absent, or its type and value, so cleanup can put it back.
PERF_TYPE=""; PERF_VALUE=""
if PERF_TYPE="$(defaults read-type -g "$PERF_KEY" 2>/dev/null)"; then
  PERF_TYPE="${PERF_TYPE#Type is }"
  PERF_VALUE="$(defaults read -g "$PERF_KEY")"
  case "$PERF_TYPE" in
    boolean|integer|float|string) ;;
    *) log_error "$PERF_KEY có kiểu $PERF_TYPE: script không khôi phục được kiểu này."
       log_hint "Xoá hoặc đổi tay (defaults delete -g $PERF_KEY) rồi chạy lại."
       exit 1 ;;
  esac
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
  esac
}
defaults write -g "$PERF_KEY" -bool true
cleanup() {
  [[ $UNDERLINE == 1 ]] && defaults delete -g "$FORCE_KEY" >/dev/null 2>&1
  restore_perf_key
  "$CLIPBOARD" restore "$WORK/clipboard.plist" 2>/dev/null || log_warn "Không khôi phục được clipboard"
  if [[ "$("$INPUT_SOURCE" current)" != "$ORIGINAL_SOURCE" ]]; then
    "$INPUT_SOURCE" select "$ORIGINAL_SOURCE" || true
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

PAGE="$WORK/dau-selftest.html"
# The window title the guards look for; also the page's <title>.
PAGE_TITLE="Dấu self test"
# The title the page shows only while its text area has the keyboard focus (the page
# sets it). Keys and ⌘A ⌘C are sent only under this title: a window title alone does not
# say where the focus is, and keys sent while the address bar had it went into the
# address bar (and its read-back passed, since ⌘A ⌘C copied the same text from there).
FOCUS_TITLE="$PAGE_TITLE [focus]"
cat > "$PAGE" <<HTML
<!doctype html><meta charset="utf-8"><title>$PAGE_TITLE</title>
<textarea autofocus spellcheck="false" autocomplete="off" style="width:90%;height:8em"></textarea>
<script>
var t = document.querySelector("textarea");
function mark() {
  document.title = document.hasFocus() && document.activeElement === t ? "$FOCUS_TITLE" : "$PAGE_TITLE";
}
["focus", "blur"].forEach(function (e) { t.addEventListener(e, mark); window.addEventListener(e, mark); });
setInterval(mark, 200);
mark();
</script>
HTML
if (( BUSY_MS > 0 )); then
  # --busy: block the page's main thread for BUSY_MS of every BUSY_PERIOD ms. A timer, not
  # a loop on keys, so the load does not depend on what is typed.
  cat >> "$PAGE" <<HTML
<script>
setInterval(function () {
  var end = performance.now() + $BUSY_MS;
  while (performance.now() < end) {}
}, $BUSY_PERIOD);
</script>
HTML
fi

[[ "$DELAY_MS" =~ ^[0-9]+$ ]] || log_die 2 "--delay phải là số nguyên ms"

# Selects Dấu and checks it is the current source (TIS is trusted for the current source
# only). Stops the run (status 4) with a message if not. Prints nothing on stdout: it runs
# inside the command substitution that collects an app's text.
is_current_source() { [[ "$("$INPUT_SOURCE" current 2>/dev/null)" == "$1" ]]; }
select_dau() {
  stopped && return 1
  "$INPUT_SOURCE" select "$DAU_SOURCE" >&2
  if wait_until 3 is_current_source "$DAU_SOURCE"; then
    # Fixed: the input method is activated for the focused app after the switch, and
    # nothing outside it shows when that is done.
    sleep 0.3
    return 0
  fi
  local now="$("$INPUT_SOURCE" current 2>/dev/null)"
  log_error "Dừng: sau khi chọn $DAU_SOURCE, nguồn nhập liệu hiện tại là \"${now:-không đọc được}\". nguồn đó chưa được chọn nên không gõ gì."
  log_hint "Kiểm tra Dấu có trong System Settings › Keyboard › \"All Input Sources\"."
  echo source > "$STOP_FILE"
  return 1
}

# Every keystroke goes through a check that the app under test is frontmost (and, for
# browsers, that the test page is the front tab of its focused window), in the same osascript as the keys: if
# the user switches app while the script runs, nothing is typed into their window. A
# failed check stops the whole run (exit 3).
front_guard() { # process [window-title-substring] → AppleScript that errors if not front
  cat <<OSA
  tell application "System Events"
    set fp to name of first process whose frontmost is true
    if fp is not "$1" then error "frontmost is " & fp & ", not $1"
    if "${2:-}" is not "" then
      -- The focused window is the one that receives keys. "front window" can be a
      -- floating helper window instead (an Edge extension's popup).
      try
        set fw to name of (value of attribute "AXFocusedWindow" of process "$1")
      on error
        set fw to name of front window of process "$1"
      end try
      if fw does not contain "${2:-}" then error "front window of $1 is " & fw & ", not the test page"
    end if
  end tell
OSA
}
# The guard alone: status 0 when process $1 is frontmost (with $2 in its focused window's
# title, if given). Sends nothing.
front_ok() { osascript -e "$(front_guard "$1" "${2:-}")" -e 'return' >/dev/null 2>&1; }
# Runs AppleScript $3 only if the guard for process $1 (title $2) passes.
# The check alone is retried for a few seconds first: right after `open`, Safari 27 may
# briefly report an untitled front window. Keys are still only sent
# once the check passes.
guarded() {
  local out
  wait_until -i 0.4 3.2 front_ok "$1" "$2"
  if ! out="$(osascript -e "$(front_guard "$1" "$2")" -e "$3" 2>&1)"; then
    log_error "Dừng: $out — không gửi phím nào nữa"
    echo front > "$STOP_FILE"
    return 1
  fi
  printf '%s' "$out"
}
stopped() { [[ -e "$STOP_FILE" ]]; }

type_keys() { # process [window-title-substring]
  stopped && return 1
  # The delay goes in as whole milliseconds: coercing "0.030" to a real follows the
  # user's locale (Vietnamese uses a decimal comma, so it became 30 seconds).
  guarded "$1" "${2:-}" 'return' >/dev/null || return 1
  if ! osascript - "$KEYS" "$DELAY_MS" "$1" "$SWITCH_CMD" "$JITTER_MS" <<'OSA'
on run argv
  set s to item 1 of argv
  set dms to (item 2 of argv) as integer
  set d to dms / 1000
  set p to item 3 of argv
  set sw to item 4 of argv
  set j to (item 5 of argv) as integer
  tell application "System Events"
    if (name of first process whose frontmost is true) is not p then error "frontmost changed"
    if d = 0 and j = 0 and s does not contain "⌫" and s does not contain "⇄" then
      keystroke s
    else
      set i to 0
      repeat with c in characters of s
        -- Re-check now and then; not every key, so the delay stays close to d.
        set i to i + 1
        if i mod 8 = 0 then
          if (name of first process whose frontmost is true) is not p then error "frontmost changed"
        end if
        if (c as text) is "⌫" then
          key code 51
        else if (c as text) is "⇄" then
          tell current application to do shell script sw
          if (name of first process whose frontmost is true) is not p then error "frontmost changed"
        else
          keystroke (c as text)
        end if
        -- Fixed on purpose: the pace the user asked for (--delay, --jitter), between keys.
        if j > 0 then
          -- random number is a scripting addition: run it here, not in System Events.
          tell current application to set r to random number from (0 - j) to j
          set pms to dms + r
          if pms > 0 then delay pms / 1000
        else if d > 0 then
          delay d
        end if
      end repeat
    end if
  end tell
end run
OSA
  then
    if [[ "$(cat "$STOP_FILE" 2>/dev/null)" == source ]]; then
      log_error "Dừng: sau ⇄, nguồn nhập liệu không thành nguồn vừa chọn trong 3 giây; không gõ tiếp."
    else
      log_error "Dừng: app đổi giữa chừng"; echo front > "$STOP_FILE"
    fi
    return 1
  fi
  # Fixed: apps that apply text asynchronously (browsers, Electron) may still be
  # catching up with the last keys, and their text can only be read through ⌘A ⌘C,
  # which changes the selection; no state to poll for that is common to every app.
  sleep 0.8
}

# ⌘A ⌘C in the focused text field of process $1 (front tab title $2), then the plain
# text of the clipboard.
copy_all() {
  stopped && return 1
  # Empty the clipboard first so a failed copy cannot return an earlier run's text.
  printf '' | pbcopy
  # The 0.2 s between ⌘A and ⌘C stays fixed: the selection is not read anywhere.
  guarded "$1" "${2:-}" 'tell application "System Events"
    keystroke "a" using {command down}
    delay 0.2
    keystroke "c" using {command down}
  end tell' >/dev/null || return 1
  # The copy lands on the clipboard emptied above. No text after 3 s: the copy failed or
  # the field is empty, and the comparison reports it.
  wait_until 3 clipboard_has_text
  "$CLIPBOARD" text
}
clipboard_has_text() { [[ -n "$("$CLIPBOARD" text 2>/dev/null)" ]]; }

# --- one function per app; each prints the text typed ---------------------------------
# Safari and Chrome are driven with `open` and System Events keystrokes only: scripting
# them directly needs a separate Automation permission per browser.
# Names of the windows of process $1 (System Events; the window name is the tab title).
window_names() {
  osascript -e 'on run argv' -e 'tell application "System Events" to get name of every window of process (item 1 of argv)' \
    -e 'end run' "$1" 2>/dev/null
}
# Closes the test page's tab with ⌘W (the browser is frontmost), then checks no window of
# process $1 still shows it; tries again a few times.
close_test_tab() {
  for _ in 1 2 3; do
    # Only when the browser is frontmost with the test page in front.
    guarded "$1" "$PAGE_TITLE" 'tell application "System Events" to keystroke "w" using {command down}' \
      >/dev/null || break
    wait_until 3 test_page_closed "$1" && return 0
  done
  log_warn "Còn tab \"$PAGE_TITLE\" trong $1, đóng tay giúp"
}

test_page_closed() { [[ "$(window_names "$1")" != *"$PAGE_TITLE"* ]]; }

# Opens the test page in browser $1 (app name) and waits until process $2 is frontmost
# with the page in its focused window (the title comes from the loaded page). Not there in
# time: type_keys's guard reports it and stops the run.
open_test_page() {
  open -a "$1" "$PAGE"
  wait_until -i 0.3 15 front_ok "$2" "$PAGE_TITLE"
}

run_safari() {
  open_test_page Safari Safari
  select_dau; type_keys Safari "$FOCUS_TITLE"
  copy_all Safari "$FOCUS_TITLE"
  close_test_tab Safari
}

run_chrome() {
  open_test_page "Google Chrome" "Google Chrome"
  select_dau; type_keys "Google Chrome" "$FOCUS_TITLE"
  copy_all "Google Chrome" "$FOCUS_TITLE"
  close_test_tab "Google Chrome"
}

run_edge() {
  open_test_page "Microsoft Edge" "Microsoft Edge"
  select_dau; type_keys "Microsoft Edge" "$FOCUS_TITLE"
  copy_all "Microsoft Edge" "$FOCUS_TITLE"
  close_test_tab "Microsoft Edge"
}

run_firefox() {
  open_test_page Firefox firefox
  select_dau; type_keys firefox "$FOCUS_TITLE"
  copy_all firefox "$FOCUS_TITLE"
  close_test_tab firefox
}

# Notes: a new note (⌘N) in the folder shown; read with ⌘A ⌘C, then emptied. Notes
# discards an empty new note, so no note is kept (the note syncs while it exists).
run_notes() {
  open -a Notes
  wait_until -i 0.3 15 front_ok Notes
  guarded Notes "" 'tell application "System Events" to keystroke "n" using {command down}' \
    >/dev/null || return 0
  # Fixed: the new note takes the focus with no change the script can read without
  # Automation permission for Notes (the window title stays the folder's).
  sleep 1; select_dau; type_keys Notes
  copy_all Notes
  # The delay between the keys stays fixed: pacing, nothing read in between.
  guarded Notes "" 'tell application "System Events"
    keystroke "a" using {command down}
    delay 0.1
    key code 51
  end tell' >/dev/null
}

# Mail: a new message (⌘N); the keys go to the body (focused through Accessibility), the
# To field stays empty and Send is never pressed. Read with ⌘A ⌘C, emptied, closed with
# ⌘W; if Mail asks to save the draft, "Don't Save"/"Delete" is chosen.
MAIL_COMPOSE="New Message"
MAIL_BODY='UI element 1 of scroll area 1 of group 1 of group 1 of front window'
mail_body_focused() {
  [[ "$(osascript -e "tell application \"System Events\" to tell process \"Mail\" to get value of attribute \"AXFocused\" of $MAIL_BODY" 2>/dev/null)" == true ]]
}
run_mail() {
  open -a Mail
  wait_until -i 0.3 15 front_ok Mail
  guarded Mail "" 'tell application "System Events" to keystroke "n" using {command down}' \
    >/dev/null || return 0
  wait_until -i 0.3 10 front_ok Mail "$MAIL_COMPOSE"
  guarded Mail "$MAIL_COMPOSE" "tell application \"System Events\" to tell process \"Mail\"
    set value of attribute \"AXFocused\" of $MAIL_BODY to true
  end tell" >/dev/null || return 0
  # Not focused in time: the keys go wherever Mail put the focus, and the comparison
  # reports it.
  wait_until 3 mail_body_focused
  select_dau; type_keys Mail "$MAIL_COMPOSE"
  copy_all Mail "$MAIL_COMPOSE"
  discard_front_document Mail "$MAIL_COMPOSE"
}

# Status 0 when process $1 has no window titled with $2 left without a sheet: the window
# closed, or it asks whether to save.
document_closed_or_asking() {
  [[ "$(osascript - "$1" "$2" <<'OSA' 2>/dev/null
on run argv
  tell application "System Events" to tell process (item 1 of argv)
    repeat with w in windows
      if name of w contains (item 2 of argv) and (count of sheets of w) = 0 then return "open"
    end repeat
  end tell
  return "done"
end run
OSA
)" == done ]]
}

# Empties the focused text (⌘A ⌫), closes the front window (⌘W) of process $1 whose
# title contains $2, and answers a save prompt with the button that discards.
discard_front_document() {
  # The short delays between the keys stay fixed: pacing, nothing read in between.
  guarded "$1" "$2" 'tell application "System Events"
    keystroke "a" using {command down}
    delay 0.1
    key code 51
    delay 0.3
    keystroke "w" using {command down}
  end tell' >/dev/null || return 0
  # Until the window is gone or shows its save sheet; the step below says which.
  wait_until 5 document_closed_or_asking "$1" "$2"
  osascript - "$1" "$2" <<'OSA' >/dev/null 2>&1 || log_warn "Còn cửa sổ \"$2\" của $1, đóng tay giúp (không lưu)"
on run argv
  set p to item 1 of argv
  set t to item 2 of argv
  tell application "System Events" to tell process p
    repeat with w in windows
      if name of w contains t then
        if (count of sheets of w) = 0 then error "window still open"
        set done to false
        repeat with b in buttons of sheet 1 of w
          if name of b is in {"Don't Save", "Don’t Save", "Delete", "Delete Draft", "Revert Changes"} then
            click b
            set done to true
            exit repeat
          end if
        end repeat
        if not done then error "no discard button"
      end if
    end repeat
  end tell
end run
OSA
}

run_vscode() {
  open -a "Visual Studio Code"
  osascript -e 'tell application "Visual Studio Code" to activate' >/dev/null
  wait_until -i 0.3 15 front_ok Code
  guarded Code "" 'tell application "System Events" to keystroke "n" using {command down}' \
    >/dev/null || return 0
  # Not there in time: type_keys's guard reports it and stops the run.
  wait_until -i 0.3 10 front_ok Code Untitled
  select_dau; type_keys Code Untitled
  copy_all Code Untitled
  # Empty the untitled editor so ⌘W closes it without asking to save. The delays between
  # the keys stay fixed: pacing, nothing read in between.
  guarded Code Untitled 'tell application "System Events"
    keystroke "a" using {command down}
    delay 0.1
    key code 51
    delay 0.2
    keystroke "w" using {command down}
  end tell' >/dev/null
}

# Sets $win to Terminal's front window, if it has one.
terminal_front_window() {
  win="$(osascript -e 'tell application "Terminal" to if (count of windows) > 0 then return id of front window' 2>/dev/null)"
  [[ -n "$win" ]]
}
# The non-blank text of Terminal window $1 (empty while the shell has printed nothing).
terminal_text() {
  local text
  text="$(osascript -e "tell application \"Terminal\" to get contents of selected tab of window id $1" 2>/dev/null)"
  [[ "$text" == *[^[:space:]]* ]] && print -r -- "$text"
}

run_terminal() {
  # Remember the window used here: it is the only one read and closed. When Terminal is
  # not running, launching it opens its startup window, and `do script ""` would open a
  # second one that is the only one closed, leaving the startup window behind. So a
  # Terminal launched here types into its startup window instead.
  local running
  win=""
  running="$(osascript -e 'application "Terminal" is running')"
  if [[ "$running" == false ]]; then
    osascript -e 'tell application "Terminal" to activate' >/dev/null || return 0
    wait_until 5 terminal_front_window
  fi
  # Already running, or set to open no window at launch: a new window of our own.
  [[ -n "$win" ]] || win="$(osascript -e 'tell application "Terminal"' -e 'activate' -e 'do script ""' \
    -e 'return id of front window' -e 'end tell')" || return 0
  # Wait for the shell prompt: keys sent before the shell is ready (a slow zsh theme
  # takes ~3 s) are lost and never reach the input method. Ready: the window shows some
  # text and it stays the same on 3 reads (a theme may redraw its prompt). Not settled in
  # time: typing goes on and the comparison reports lost keys.
  wait_settled 8 3 terminal_text "$win" >/dev/null
  select_dau; type_keys Terminal
  # The keys sit after the prompt on its last line, or on its last rows when they wrap
  # (long --keys): print the last non-blank rows joined, the caller compares by suffix.
  # Under 60 characters, one row as before; longer, enough rows for the text plus a prompt
  # of up to one row at the 80 columns of a new window of the default profile.
  local rows=1
  (( ${#EXPECT} < 60 )) || rows=$(( 2 + ${#EXPECT} / 80 ))
  osascript -e "tell application \"Terminal\" to get contents of selected tab of window id $win" \
    | grep -v '^[[:space:]]*$' | tail -$rows | tr -d '\n'
  # ⌃U clears the line; never Return. Then close that window (only the shell runs in it).
  guarded Terminal "" 'tell application "System Events" to keystroke "u" using {control down}' >/dev/null
  # Fixed: lets the shell take ⌃U before its window closes; nothing read in between.
  sleep 0.2
  osascript -e "tell application \"Terminal\" to close window id $win" >/dev/null 2>&1
}

# --- run -------------------------------------------------------------------------------
trim_right() { sed -e 's/[[:space:]]*$//'; }
EXPECT_TRIMMED="$(printf '%s' "$EXPECT" | trim_right)"
FAILED=0
log_step "Script sẽ mở: ${APPS[*]}"
log_detail "mỗi app một cửa sổ/tab mới, đóng lại sau khi đọc chữ; app nào chưa chạy thì vẫn để chạy"
log_detail "phím: \"$KEYS\"   mong đợi: \"$EXPECT\"   nghỉ giữa phím: ${DELAY_MS} ms"
bundle_id() {
  case "$1" in
    safari) echo com.apple.Safari ;;
    chrome) echo com.google.Chrome ;; vscode) echo com.microsoft.VSCode ;;
    terminal) echo com.apple.Terminal ;;
    edge) echo com.microsoft.edgemac ;; firefox) echo org.mozilla.firefox ;;
    notes) echo com.apple.Notes ;; mail) echo com.apple.mail ;;
  esac
}
[[ $UNDERLINE == 1 ]] && log_detail "chế độ gạch chân (D13) ép bằng $FORCE_KEY cho từng app"
(( JITTER_MS > 0 )) && log_detail "nghỉ giữa phím dao động ±${JITTER_MS} ms"
(( BUSY_MS > 0 )) && log_detail "trang thử chặn luồng chính ${BUSY_MS} ms mỗi ${BUSY_PERIOD} ms (--busy)"
for app in "${APPS[@]}"; do
  if stopped; then break; fi
  if [[ $UNDERLINE == 1 ]]; then
    defaults write -g "$FORCE_KEY" -array "$(bundle_id "$app")"
  fi
  start="$(date '+%Y-%m-%d %H:%M:%S')"
  got="$("run_$app")"
  # Fixed: the input method's perf lines reach the log store asynchronously, and how many
  # to expect is not known, so there is nothing to wait for.
  sleep 0.3
  if stopped; then
    # Another app came to the front, or Dấu could not be selected: no verdict for this app.
    log_error "Dừng $app: không có kết quả (xem thông báo dừng ở trên)."
    break
  fi
  [[ -n "$SAVE_DIR" ]] && print -r -- "$got" > "$SAVE_DIR/$app.txt"
  got_trimmed="$(printf '%s' "$got" | trim_right)"
  if [[ "$app" == terminal ]]; then
    ok=0; [[ "$got_trimmed" == *"$EXPECT_TRIMMED" ]] && ok=1
    # A long text wraps over several rows; if Terminal drops the space where a row
    # breaks, compare again without whitespace (said in the output).
    if [[ $ok == 0 && ${#EXPECT_TRIMMED} -ge 60 && "${got_trimmed//[[:space:]]/}" == *"${EXPECT_TRIMMED//[[:space:]]/}" ]]; then
      ok=1; log_detail "(khớp khi bỏ khoảng trắng: Terminal ngắt dòng dài, không tính lỗi)"
    fi
  else
    ok=0; [[ "$got_trimmed" == "$EXPECT_TRIMMED" ]] && ok=1
    # TextEdit, Notes, Pages… capitalize the first word of a new document by themselves
    # (macOS "Capitalize words automatically") when keys come slowly enough: not the
    # input method's doing.
    if [[ $ok == 0 ]]; then
      # (U) on the first character needs a UTF-8 locale, whatever the caller's is.
      () { local LC_ALL=en_US.UTF-8; capitalized="${(U)EXPECT_TRIMMED[1]}${EXPECT_TRIMMED[2,-1]}" }
      [[ "$got_trimmed" == "$capitalized" ]] && { ok=1; log_detail "(chữ đầu viết hoa do app tự viết hoa, không tính lỗi)"; }
    fi
  fi
  if [[ $ok == 1 ]]; then log_ok "$app đạt: \"$got_trimmed\""; else log_error "$app sai: \"$got_trimmed\""; FAILED=1; fi
  "$LOG" show --start "$start" --style compact \
    --predicate "subsystem == \"$IM_ID\" AND (category == \"perf\" OR category == \"diag\")" > "$WORK/perf.log" 2>/dev/null
  [[ -n "$SAVE_DIR" ]] && cp "$WORK/perf.log" "$SAVE_DIR/$app.perf.log"
  case "$app" in
    safari) filter=Safari ;; chrome) filter=Chrome ;;
    vscode) filter=VSCode ;; terminal) filter=Terminal ;;
    *) filter="$(bundle_id "$app")" ;;
  esac
  "$ROOT/scripts/perf/perf-report.sh" --input "$WORK/perf.log" --app "$filter" \
    | grep -E 'count_|gap_|lag_us|handle_replace_us|selectedRange_us|insertText_us|attributedSubstring_us|event_' || true
  if [[ $UNDERLINE == 1 ]]; then
    settings_log="$("$LOG" show --start "$start" --style compact \
        --predicate "subsystem == \"$IM_ID\" AND category == \"settings\"" 2>/dev/null)"
    if [[ "$settings_log" == *"event=underline-on app=$(bundle_id "$app")"* ]]; then
      log_detail "underline-on"
    else
      log_warn "Không thấy underline-on (bộ gõ chưa nhận khoá ép?)"
    fi
  fi
done
if stopped; then
  # Not overwritten by an earlier failure: the run did not finish.
  if [[ "$(cat "$STOP_FILE")" == source ]]; then
    log_error "Đã dừng: không chọn được Dấu (mã thoát 4)."; FAILED=4
  else
    log_error "Đã dừng: app đang thử không còn ở trước (người dùng đang dùng máy?) (mã thoát 3)."; FAILED=3
  fi
fi
if [[ $FAILED == 0 ]]; then log_ok "Mọi app cho đúng chữ mong đợi"; log_done; else log_error "Có app sai hoặc đã dừng (mã thoát $FAILED)"; fi
exit $FAILED
