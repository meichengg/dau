#!/bin/zsh
# Shared build step for the scripts that build Dấu with xcodebuild (sourced, not run).
# Side effects: builds
# Callers: scripts/dev/install-input-method.sh, scripts/dev/install-app.sh, scripts/selftest/app-group.sh.
# Each caller keeps its own checks of the result (per target: N2 applies to the input
# method only), this file only holds what must be identical everywhere:
#
#   dau_signing_identities        the usable "Apple Development" identities, one
#                                 find-identity line each ("N) <SHA-1> "<name>"")
#   dau_require_signing_identity  stop early when the keychain has no usable
#                                 "Apple Development" identity (revoked, expired, missing)
#   dau_build SCHEME CONFIG       xcodegen, then xcodebuild universal into $DAU_DERIVED
#
# It never passes -allowProvisioningUpdates: that flag can create a new certificate and
# revoke the one of another Mac on the same Apple ID (docs/history/LOG-M5.md), so it is
# the user's action, printed below, never a script's.

# %x is the file being sourced; :A resolves it, each :h drops one path component.
DAU_ROOT="${${(%):-%x}:A:h:h:h}"
DAU_DERIVED="$DAU_ROOT/build/DerivedData.noindex"
source "$DAU_ROOT/scripts/lib/log.sh"
source "$DAU_ROOT/scripts/lib/xcode.sh"
dau_developer_dir

dau_signing_identities() {
  # find-identity -v still lists a revoked identity, tagged CSSMERR_TP_CERT_REVOKED, and
  # a new certificate keeps the revoked one's name: drop CSSMERR lines, never pick by
  # name alone.
  security find-identity -v -p codesigning 2>/dev/null \
    | grep '"Apple Development' | grep -v CSSMERR
}

dau_require_signing_identity() {
  dau_signing_identities >/dev/null && return 0
  log_error "Không có chứng chỉ \"Apple Development\" dùng được trong keychain (thiếu, hết hạn hoặc bị thu hồi)."
  log_hint "scripts/dev/dau-version.sh cho biết lý do. Chọn một trong hai cách (CONTRIBUTING.md):" \
    "a) Máy Mac khác dùng cùng Apple ID đang có chứng chỉ hợp lệ: xuất nó kèm khoá riêng ra" \
    "   .p12 ở máy đó (Keychain Access › login › My Certificates › Export), nhập ở máy này." \
    "b) Tạo chứng chỉ mới cho máy này. Chứng chỉ của máy Mac kia có thể bị thu hồi. Tự chạy:" \
    "   xcodegen generate && DEVELOPER_DIR=$DEVELOPER_DIR \\" \
    "     xcodebuild -project Dau.xcodeproj -scheme DauInputMethod -configuration Release \\" \
    "     -destination 'generic/platform=macOS' -derivedDataPath build/DerivedData.noindex \\" \
    "     -allowProvisioningUpdates build"
  return 1
}

dau_build() {
  local scheme="$1" config="$2"
  if ! command -v xcodegen >/dev/null 2>&1; then
    log_error "Cần XcodeGen: brew install xcodegen"
    return 1
  fi
  dau_require_signing_identity || return 1
  log_step "Sinh Dau.xcodeproj"
  (cd "$DAU_ROOT" && xcodegen generate --quiet) || return 1
  log_step "Build $config universal (scheme $scheme)"
  xcodebuild \
    -project "$DAU_ROOT/Dau.xcodeproj" \
    -scheme "$scheme" \
    -configuration "$config" \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$DAU_DERIVED" \
    -quiet \
    build
}
