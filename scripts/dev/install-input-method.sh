#!/bin/zsh
# Builds the input method and installs it for the current user.
# Side effects: builds; unless --build-only: installs input method, kills processes
# Universal, Debug unless --release, into ~/Library/Input Methods; then it stops the old
# input method process so macOS loads the new one on the next key press.
#
# It does NOT register or enable the input source: that is the user's action in
# System Settings (N4). The steps are printed at the end.
#
# Usage:
#   scripts/dev/install-input-method.sh               build, install, stop the old process
#   scripts/dev/install-input-method.sh --build-only  build and check only, touch nothing outside the repo
#   scripts/dev/install-input-method.sh --no-build    skip xcodegen and xcodebuild: check and install the
#                                          build already in build/DerivedData.noindex (for a
#                                          caller that has just built it, e.g. scripts/selftest/app-group.sh)
#   scripts/dev/install-input-method.sh --release     Release instead of Debug: for day-to-day typing
#                                          (no get-task-allow, no per-key log, D8)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
source "$ROOT/scripts/lib/log.sh"
source "$ROOT/scripts/lib/build.sh"
DERIVED="$DAU_DERIVED"
PROCESS_NAME="DauInputMethod"            # CFBundleExecutable of the input method
BUNDLE_NAME="$PROCESS_NAME.app"
DEST_DIR="$HOME/Library/Input Methods"

BUILD_ONLY=0
SKIP_BUILD=0
CONFIG=Debug
for arg in "$@"; do
  case "$arg" in
    --build-only) BUILD_ONLY=1 ;;
    --no-build) SKIP_BUILD=1 ;;
    # Day-to-day typing: Release has no get-task-allow (no debugger can attach) and no
    # per-key log or debug defaults keys (D8). Debug only while testing.
    --release) CONFIG=Release ;;
    -h|--help) log_usage "$0"; exit 0 ;;
    *) log_die 2 "Tham số không hợp lệ: $arg (dùng --release, --build-only, --no-build hoặc không có tham số)" ;;
  esac
done

if [[ "$SKIP_BUILD" == 1 && "$BUILD_ONLY" == 1 ]]; then
  log_die 2 "--no-build và --build-only không đi cùng nhau."
fi
if [[ "$SKIP_BUILD" == 0 ]]; then
  dau_build DauInputMethod "$CONFIG" || exit 1
else
  log_step "--no-build: dùng bản build có sẵn trong build/DerivedData.noindex"
fi

BUILT="$DERIVED/Build/Products/$CONFIG/$BUNDLE_NAME"
if [[ ! -d "$BUILT" ]]; then
  log_die "Không tìm thấy $BUILT sau khi build."
fi

log_step "Kiểm tra bản build"
ARCHS="$(lipo -archs "$BUILT/Contents/MacOS/$PROCESS_NAME")"
log_detail "kiến trúc: $ARCHS"
if [[ "$ARCHS" != *arm64* || "$ARCHS" != *x86_64* ]]; then
  log_die "Bản build không phải universal (D1)."
fi
codesign --verify --strict "$BUILT"
# Matched in the shell, not with `| grep -q`: under pipefail a grep that quits at the first
# match can fail the pipeline through SIGPIPE on codesign, and the check would pass.
ENTITLEMENTS="$(codesign -d --entitlements - --xml "$BUILT" 2>/dev/null)"
if [[ "$ENTITLEMENTS" == *com.apple.security.network* ]]; then
  log_die "Bộ gõ có quyền mạng, trái N2. Dừng."
fi
log_ok "Bản build có chữ ký hợp lệ, không có quyền mạng (N2)"
if [[ "$CONFIG" == Release && "$ENTITLEMENTS" == *get-task-allow* ]]; then
  log_die "Bản Release còn get-task-allow (cho phép gắn debugger). Dừng."
fi

if [[ "$BUILD_ONLY" == 1 ]]; then
  log_step "--build-only: không cài. Bản build: $BUILT"
  log_done "Đã build bộ gõ"
  exit 0
fi

log_step "Cài vào $DEST_DIR"
mkdir -p "$DEST_DIR"
# Copy first, swap after: a failed or interrupted copy leaves the installed input method
# as it was. The copy is a hidden sibling on the same volume, so the swap is two renames;
# its name does not end in .app, so macOS never takes it for an input method.
INSTALLED="$DEST_DIR/$BUNDLE_NAME"
STAGED="$DEST_DIR/.$BUNDLE_NAME.new-$$"
ASIDE="$DEST_DIR/.$BUNDLE_NAME.old-$$"
install_cleanup() {
  rm -rf "$STAGED"
  # Stopped between the two renames: put the old copy back.
  if [[ -e "$ASIDE" && ! -e "$INSTALLED" ]]; then mv "$ASIDE" "$INSTALLED"; fi
  rm -rf "$ASIDE"
}
trap install_cleanup EXIT
trap 'exit 130' INT TERM HUP
ditto "$BUILT" "$STAGED"
# ditto keeps the build's dates; a new date makes Finder drop the icon it cached for
# this path.
touch "$STAGED"
if [[ -e "$INSTALLED" || -L "$INSTALLED" ]]; then
  mv "$INSTALLED" "$ASIDE"
fi
mv "$STAGED" "$INSTALLED"
rm -rf "$ASIDE"

log_step "Dừng tiến trình bộ gõ cũ (nếu đang chạy)"
if killall "$PROCESS_NAME" 2>/dev/null; then
  log_detail "đã dừng $PROCESS_NAME; macOS sẽ chạy bản mới ở lần gõ tiếp theo"
else
  log_detail "không có tiến trình $PROCESS_NAME đang chạy"
fi

log_step "Đã cài bản $CONFIG của Dấu. Các bước còn lại do bạn làm trên máy"
log_detail \
  "1. Dấu đã bật từ trước trên máy này: không phải làm gì thêm. Chuyển nguồn đầu vào ra" \
  "   rồi vào lại Dấu để macOS chạy bản vừa cài." \
  "2. Lần đầu trên máy này: bật bằng app chủ (build scheme Dau, mở Dau.app, bấm \"Bật Dấu\"," \
  "   rồi Allow trong hộp thoại của macOS). App xoá bộ đệm danh sách nguồn đầu vào trước" \
  "   khi đăng ký, nên không cần đăng xuất (D37). Thêm tay bằng \"+\" trong System Settings" \
  "   có thể không thấy Dấu, vì danh sách đó đọc bộ đệm cũ." \
  "3. Bật không được: làm theo màn \"Chưa bật được\" của app (tự thêm bằng \"+\"; đăng xuất" \
  "   một lần là đường lui, D37). Một ứng dụng vẫn không chọn được Dấu: đăng xuất rồi đăng" \
  "   nhập lại một lần." \
  "4. Dấu chỉ có \"Dấu – Tiếng Việt\" (D2); gõ tiếng Anh bằng U.S. sẵn có của macOS. Còn" \
  "   \"Dấu – Tiếng Anh\" từ bản cũ thì bỏ nó bằng \"–\"." \
  "5. Chọn \"Dấu – Tiếng Việt\" trên menu nguồn đầu vào ở thanh menu, hoặc bằng phím tắt" \
  "   chuyển nguồn đầu vào của macOS." \
  "6. Tắt các bộ gõ tiếng Việt khác đang chạy (OpenKey, EVKey, GoTiengViet…) trước khi thử."
if [[ "$CONFIG" == Debug ]]; then
  log_detail \
    '7. Gõ thử theo docs/COMPATIBILITY.md mục 4. Muốn lấy số đo: bật nhật ký từng phím bằng' \
    '   `defaults write -g DauPerfLog -bool true`, gõ, chạy scripts/perf/perf-report.sh, rồi tắt' \
    '   bằng `defaults delete -g DauPerfLog` (nhật ký có giờ và app của từng phím, D8).'
else
  log_detail "7. Gõ thử theo docs/COMPATIBILITY.md mục 4. Bản Release không ghi nhật ký từng phím (D8)."
fi
log_step "Gỡ bản thử"
log_detail \
  "Xoá ~/Library/Input Methods/DauInputMethod.app, bỏ \"Dấu\" bằng \"–\" trong System Settings › Keyboard ›" \
  "\"All Input Sources\" (trước khi xoá), rồi đăng xuất."
log_done "Đã cài bộ gõ"
