#!/bin/zsh
# Builds Dấu.app (the host app: Settings, onboarding) and installs it into /Applications.
# Side effects: builds, installs app, kills processes, deletes data
# Release unless --debug. The new copy is written next to the installed one first (a
# hidden sibling in /Applications), so a failed copy leaves the installed app as it was;
# then the installed copy goes to the Trash with /usr/bin/trash (it can be put back; no
# Finder, so no Automation prompt) and the new one is renamed into place. It is then
# registered with LaunchServices: ditto alone does not register it, and Spotlight and
# "Open With" miss an unregistered copy (HostApp, behind the input menu's "Cài đặt Dấu…",
# also looks in /Applications itself: docs/ARCHITECTURE.md).
# A running Dấu.app is quit normally first and opened again at the end.
#
# The input method is a separate step (scripts/dev/install-input-method.sh); --with-input-method
# runs it with the same configuration first. Nothing is enabled or selected (N4).
#
# Usage:
#   scripts/dev/install-app.sh                      build Release, install the app
#   scripts/dev/install-app.sh --debug              Debug instead of Release
#   scripts/dev/install-app.sh --with-input-method  also build and install the input method
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT/scripts/lib/log.sh"
source "$ROOT/scripts/lib/wait.sh"
source "$ROOT/scripts/lib/build.sh"
DERIVED="$DAU_DERIVED"
DEST="/Applications/Dau.app"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

CONFIG=Release
WITH_IM=0
for arg in "$@"; do
  case "$arg" in
    --debug) CONFIG=Debug ;;
    --with-input-method) WITH_IM=1 ;;
    -h|--help) log_usage "$0"; exit 0 ;;
    *) log_die 2 "Tham số không hợp lệ: $arg (dùng --debug, --with-input-method hoặc không có tham số)" ;;
  esac
done

# Before the input method step too, so a missing certificate stops before anything is built.
dau_require_signing_identity || exit 1

if [[ "$WITH_IM" == 1 ]]; then
  im_args=()
  [[ "$CONFIG" == Release ]] && im_args+=(--release)
  "$ROOT/scripts/dev/install-input-method.sh" "${im_args[@]}"
fi

dau_build Dau "$CONFIG" || exit 1

APP="$DERIVED/Build/Products/$CONFIG/Dau.app"
[[ -d "$APP" ]] || log_die "Không thấy $APP sau khi build."
if ! codesign --verify --deep --strict "$APP" 2>/dev/null; then
  log_error "Chữ ký của $APP không hợp lệ: không cài."
  log_hint "Xem chứng chỉ \"Apple Development\" trong Keychain Access (CONTRIBUTING.md)."
  exit 1
fi
BUNDLE_ID=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$APP/Contents/Info.plist")

# Quit a running copy normally (never force quit) and remember to open it again.
was_running=0
if pgrep -f "$DEST/Contents/MacOS/" >/dev/null 2>&1; then
  was_running=1
  log_step "Thoát Dấu.app đang chạy"
  osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
  app_gone() { ! pgrep -f "$DEST/Contents/MacOS/" >/dev/null 2>&1; }
  wait_until 10 app_gone
  if pgrep -f "$DEST/Contents/MacOS/" >/dev/null 2>&1; then
    log_error "Dấu.app chưa thoát sau 10 giây: không cài."
    log_hint "Thoát app rồi chạy lại."
    exit 1
  fi
fi

# Copy first, swap after. The copy's name does not end in .app, so LaunchServices does not
# take it for an app while it is being written.
STAGED="${DEST:h}/.${DEST:t}.new-$$"
trap 'rm -rf "$STAGED"' EXIT
trap 'exit 130' INT TERM HUP
log_step "Chép bản mới cạnh $DEST"
ditto "$APP" "$STAGED"
if [[ -e "$DEST" || -L "$DEST" ]]; then
  log_step "Chuyển bản cũ vào Thùng rác"
  if ! /usr/bin/trash -s "$DEST"; then
    log_error "Không chuyển được $DEST vào Thùng rác: bản đã cài giữ nguyên."
    log_hint "Kéo $DEST vào Thùng rác bằng tay rồi chạy lại."
    exit 1
  fi
fi
log_step "Đặt bản mới vào $DEST và đăng ký với LaunchServices"
if ! mv "$STAGED" "$DEST"; then
  log_error "Không đổi tên $STAGED thành $DEST."
  log_hint "Bản cũ nằm trong Thùng rác (Put Back để lấy lại); chạy lại script để cài."
  exit 1
fi
"$LSREGISTER" -f "$DEST"

if [[ "$was_running" == 1 ]]; then
  log_step "Mở lại Dấu.app"
  open "$DEST"
fi

log_step "Phiên bản đã cài"
"$ROOT/scripts/dev/dau-version.sh"
log_done "Đã cài Dấu.app"
