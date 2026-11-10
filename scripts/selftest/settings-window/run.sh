#!/bin/zsh
# UI checks of the Settings window, onboarding and uninstall alerts (docs/UI-CHECKS.md).
# Side effects: builds, takes the screen, kills processes, changes user settings
#
# Usage: scripts/selftest/settings-window/run.sh [--focus] <output-dir> [Dau.app]
#
# --focus: only two real-window launches (no in-app captures, no pixel check), one per
# appearance, ax-check --focus: the launch focus and accent selection of the sidebar,
# Tab and ⌘F into the sidebar search, the sidebar search rows on the primary display.
#
# Six app launches, one after the other; each shows a window on screen for a while
# (do not click while it runs). Needs the Accessibility and Screen Recording permissions
# of the terminal. Changes no system setting: the scroll bar style and the appearance
# are arguments of that one launch (`-AppleShowScrollBars` lands in the app's argument
# domain; `--appearance` is a Debug flag of Dấu), never the global defaults. Every launch
# passes `-AppleLanguages (vi)`: the expected texts are the Vietnamese ones, whatever the
# Mac's language (the app follows macOS's language list, D41).
#
# In-app captures, on a copy of the Debug app re-signed ad hoc without entitlements (so
# the copy has no App Group and its fake services cannot touch the user's settings):
#   1. --capture-onboarding                    onboarding/
#   2. --capture-onboarding --shortcut none    onboarding-no-shortcut/
#   3. --capture-uninstall                     uninstall/ (alerts laid out, nothing removed)
# The real Debug app, opened as the user opens it (`open -n`), measured from outside by
# ax-check.swift through the Accessibility API; screenshots are `screencapture -l` of the
# Settings window only. Launch 4 also sends ⌘[ ⌘] key events and a mouse wheel over the
# add-rule sheet's list (the pointer moves):
#   4. When scrolling scroll bars              real/                  ax-check --geometry
#   5. Always scroll bars                      always/                ax-check --pixels
#   6. the other appearance, Always bars       always-<light|dark>/   ax-check --focus --pixels --sheet-shots
# The "Dấu chưa được bật" banner is `swift test` "Not-enabled banner" (scripts/snapshot-settings).
# Then check.swift checks the screenshots' pixels and the in-app captures.
# Tables: <dir>.txt per launch, check.txt (rows ok / FAIL / HARNESS: data, docs/UI-CHECKS.md).
# Exit status 0 only if every row is ok. The script's own messages are Vietnamese, through
# scripts/lib/log.sh; the rows shown under each step are the tail of those tables.
#
# ax-check moves and resizes the window, and the app saves its frame: both saved window
# frames of com.codefastlabs.dau, and the sidebar's saved split (AppKit's autosave, left by
# builds before the fixed sidebar, which has none), are put back as they were at the end.
# Every pass sets the window to the default size itself, so the size a launch opens at
# does not matter.
set -euo pipefail
here=${0:A:h}
source "${here:h:h}/lib/log.sh"
source "${here:h:h}/lib/wait.sh"
focus_only=0
if [[ ${1:-} == --focus ]]; then focus_only=1; shift; fi
[[ -n ${1:-} ]] || log_die 2 "Thiếu thư mục kết quả. Dùng: scripts/selftest/settings-window/run.sh [--focus] <output-dir> [Dau.app]"
out=$1
source "${here:h:h}/lib/xcode.sh"
dau_developer_dir
# Absolute: the copy is made from it and pgrep matches its full path (a relative argument
# never matched the launched process).
app=${2:-${here:h:h:h}/build/DerivedData.noindex/Build/Products/Debug/Dau.app}
app=${app:A}
[[ -d $app ]] || log_die 2 "Không thấy $app (build Debug trước, hoặc truyền đường dẫn Dau.app)"
work=$(mktemp -d)
lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
# Running the copy registers it with LaunchServices; unregister it before deleting it,
# or Spotlight and "Open With" keep listing a second Dấu.app with a blank icon.
# The copy and the real app share Dấu's bundle ID, so AppKit saves the frames of the
# windows they show and the checker moves into Dấu's own preferences; a later normal
# launch then opened onboarding squeezed into a screen corner. Keep the saved frames as
# they were before the run and put them back at the end.
frames_domain=com.codefastlabs.dau
frame_keys=("NSWindow Frame onboarding" "NSWindow Frame settings"
  "NSSplitView Subview Frames settings, SidebarNavigationSplitView")
# The whole domain is exported once; each key goes back with its exact value and type:
# `plutil -extract` prints the value as an XML plist, and `defaults write` takes a value in
# plist form. A plutil key path splits at ".", so a key with a dot cannot be extracted.
saved_prefs="$work/saved-prefs.plist"
for k in $frame_keys; do
  [[ $k != *.* ]] || log_die "Khoá có dấu chấm, plutil -extract không đọc được: $k"
done
defaults export $frames_domain "$saved_prefs"
# Runs in the EXIT trap, where errexit still applies: no command may stop the loop (a key
# absent before and after makes `defaults delete` fail).
restore_frames() {
  local k value
  # Never saved (the run stopped before the export): leave the domain alone.
  [[ -f $saved_prefs ]] || return 0
  for k in $frame_keys; do
    if value=$(plutil -extract "$k" xml1 -o - "$saved_prefs" 2>/dev/null); then
      defaults write $frames_domain "$k" "$value" \
        || log_warn "Không trả lại được khoá \"$k\" của $frames_domain"
    else
      defaults delete $frames_domain "$k" >/dev/null 2>&1 || true
    fi
  done
}
cleanup() {
  [[ -d "$work/Dau.app" ]] && { "$lsregister" -u "$work/Dau.app" >/dev/null 2>&1 || true; }
  # Before $work goes: the saved copy of the domain is in it.
  restore_frames
  rm -rf "$work"
}
trap cleanup EXIT
mkdir -p "$out"

result=0
# The last line: a verdict, then the exit status.
finish() {
  if (( result == 0 )); then
    log_ok "Mọi hàng đều ok (kết quả trong $out)"
    log_done
  else
    log_error "Có hàng không đạt; xem các file .txt trong $out"
  fi
  exit $result
}

# A multi-file build takes top-level code only from a file named main.swift, so the
# script is copied to that name next to Reference.swift's compile.
build() {   # <script> <output>
  mkdir -p "$work/src-$2"
  cp "$here/$1" "$work/src-$2/main.swift"
  swiftc -swift-version 6 -O -o "$work/$2" "$here/Reference.swift" "$work/src-$2/main.swift"
}
build ax-check.swift ax-check
build check.swift check

# --- Launches 1–3: in-app captures ----------------------------------------------------

if (( ! focus_only )); then
cp -R "$app" "$work/Dau.app"
cat > "$work/ent.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>com.apple.security.get-task-allow</key><true/></dict></plist>
PLIST
codesign --force --sign - --entitlements "$work/ent.plist" "$work/Dau.app" >/dev/null 2>&1

# Runs the copy with the given arguments; a failure names the step and shows the end of
# the app's output instead of ending the script silently.
capture() {   # <step name> <Dau arguments…>
  local step=$1 rc=0
  shift
  "$work/Dau.app/Contents/MacOS/Dau" -AppleLanguages '(vi)' "$@" >"$work/capture.log" 2>&1 || rc=$?
  if (( rc != 0 )); then
    log_error "Chụp trong app ($step) lỗi: Dau $* — mã thoát $rc"
    log_hint "${(@f)$(tail -5 "$work/capture.log")}"
    result=1
  fi
}

# The onboarding window (steps 1, 2 before "Bật Dấu", 2 with notes, 2 waiting for Allow,
# 2 failed, 2 install error, 2 done, 2 done without a shortcut, 3; light and dark), on fixed services; once with the real
# input-source shortcut, once as if none were set.
capture "onboarding" --capture-onboarding "$out/onboarding"
capture "onboarding without shortcut" --capture-onboarding "$out/onboarding-no-shortcut" \
  --shortcut none
# The uninstall alerts and the "Bỏ Dấu khỏi nguồn đầu vào" sheet (D16, mockup
# "ConfirmDialogs", "UninstallRemoveSource"): laid out, captured, dismissed;
# nothing is uninstalled.
capture "uninstall alerts" --capture-uninstall "$out/uninstall"
fi

# --- Launches 4–6: the real window ----------------------------------------------------

if [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) == Dark ]]; then
  current=dark other=light
else
  current=light other=dark
fi

# Sets $pid to a Dấu process from $app that is not in $1 (the pids before the launch).
new_app_pid() {
  pid=$(comm -13 <(echo "$1") <(pgrep -f "$app/Contents/MacOS/Dau" | sort) | tail -1)
  [[ -n $pid ]]
}
process_gone() { ! kill -0 "$1" 2>/dev/null; }

real_window() {   # <dir name> <appearance> <ax-check modes…> -- <app arguments…>
  local name=$1 look=$2
  shift 2
  local modes=()
  while [[ $1 != -- ]]; do modes+=($1); shift; done
  shift
  local dir="$out/$name"
  mkdir -p "$dir"
  local before=$(pgrep -f "$app/Contents/MacOS/Dau" | sort)
  # --settings-window goes last: launched as `--settings-window --appearance light`
  # (or any flag-value pair after it) the app opened no window at all, while
  # `--appearance light --settings-window` does (measured on Dấu). AppKit
  # pairs each dash argument with the next one, so `--settings-window` takes
  # `--appearance` and `light` is left alone; a windowless test app was handed that
  # leftover as a file to open (`application(_:openFiles:)`). The 8 argument sets measured
  # on Dấu fit this; that SwiftUI then opens no window is not measured. Put every app
  # flag that takes a value (`-AppleShowScrollBars`, `--appearance`) before --settings-window.
  open -n "$app" --args -AppleLanguages '(vi)' "$@" --settings-window
  pid=""
  wait_until 10 new_app_pid "$before" || true
  if [[ -z $pid ]]; then
    # The row is data (docs/UI-CHECKS.md): kept as it is in the result file.
    print -r -- "HARNESS real window ($name): the app did not start; not a UI result" > "$dir.txt"
    log_error "Không mở được app cho cửa sổ thật ($name); đây không phải kết quả giao diện."
    return 1
  fi
  local rc=0
  "$work/ax-check" "$pid" "$dir" "$look" $modes > "$dir.txt" || rc=1
  log_step "$name"
  log_detail "${(@f)$(tail -3 "$dir.txt")}"
  # Quit that one process normally (NSRunningApplication.terminate, by pid: an installed
  # Dấu.app may run with the same bundle ID). Not `kill`: an app that did not quit normally
  # has its window restored at the next launch of the bundle ID, the user's Dấu.app included.
  osascript -l JavaScript -e "ObjC.import('AppKit'); \$.NSRunningApplication.runningApplicationWithProcessIdentifier($pid).terminate" >/dev/null 2>&1 || true
  # Let it quit before the next launch: the next pid lookup must not find it, and the
  # frames put back at the end must not be written over by it.
  if ! wait_until 10 process_gone "$pid"; then
    print -r -- "HARNESS real window ($name): the app (pid $pid) did not quit within 10 s" >> "$dir.txt"
    log_error "App (pid $pid) chưa thoát sau 10 giây."
    rc=1
  fi
  return $rc
}

if (( focus_only )); then
  real_window focus-$current $current --focus -- -AppleShowScrollBars WhenScrolling || result=1
  real_window focus-$other $other --focus -- -AppleShowScrollBars WhenScrolling --appearance $other || result=1
  finish
fi

real_window real $current --geometry -- -AppleShowScrollBars WhenScrolling || result=1
real_window always $current --pixels -- -AppleShowScrollBars Always || result=1
real_window always-$other $other --focus --pixels --sheet-shots -- \
  -AppleShowScrollBars Always --appearance $other || result=1

# --- Pixels of the screenshots, in-app captures ----------------------------------------

"$work/check" "$out" whenScrolling:real always:always always:always-$other > "$out/check.txt" || result=1
log_step "check"
log_detail "${(@f)$(tail -3 "$out/check.txt")}"
finish
