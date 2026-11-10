#!/bin/zsh
# Installs a downloaded Dau-<version>.pkg and verifies the result. Run it from Terminal: it
# asks for the admin password once (the package installs into /Applications).
#
# Usage: scripts/release/install-pkg.sh [--dist] <path to Dau-<version>.pkg>
#   --dist  package came from a GitHub download (still quarantined). Unnotarized builds are
#           expected until M7, so the flag is cleared for the package; the postinstall then
#           clears it for the installed app.
#
# No logout: the postinstall clears quarantine, stops the old copies and opens the app for
# the console user; the app copies the input method to ~/Library/Input Methods, registers
# it, clears the input-source caches and asks macOS to enable it (DECISIONS.md D37). The
# user confirms the "Allow" dialog macOS shows. Log out only when the source still does not
# appear in System Settings › Keyboard › Input Sources: that is the documented last resort,
# not part of the normal install.
# Side effects: needs admin password, installs app, kills processes, changes input source
set -uo pipefail
setopt extendedglob

source "$0:A:h/../lib/log.sh"

dist=0
if [[ ${1:-} == --dist ]]; then
  dist=1
  shift
fi
pkg=$1
[[ -n $pkg ]] || log_die 2 'thiếu đường dẫn gói' '' "$(log_usage $0)"
[[ -f $pkg ]] || log_die "không thấy $pkg"

app=/Applications/Dau.app
im="$app/Contents/Library/Input Methods/DauInputMethod.app"

log_step "Kiểm gói"
log_detail "gói: $pkg"
log_detail "sha256: $(shasum -a 256 "$pkg" | cut -d' ' -f1)"
if /usr/sbin/pkgutil --check-signature "$pkg" >/dev/null 2>&1; then
  log_ok 'Gói có chữ ký'
else
  log_warn 'Gói chưa ký (Apple Development không ký được gói; chờ M7 ký Developer ID)'
fi

if [[ $dist == 1 ]] && xattr -p com.apple.quarantine "$pkg" >/dev/null 2>&1; then
  log_step 'Bỏ cờ cách ly của gói (bản chưa công chứng bị Gatekeeper chặn ở bước cài)'
  xattr -d com.apple.quarantine "$pkg"
fi

log_step 'Cài (hỏi mật khẩu quản trị)'
sudo /usr/sbin/installer -pkg "$pkg" -target / || log_die 'installer hỏng.'

log_step 'Kiểm tra'
codesign --verify --deep --strict "$app" 2>/dev/null || log_die "chữ ký $app không hợp lệ."
log_ok "Chữ ký: $(codesign -dvvv "$app" 2>&1 | sed -n 's/^Authority=//p' | head -1)"
log_ok "Team: $(codesign -dvvv "$app" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
log_ok "App Group: $(codesign -d --entitlements - --xml "$app" 2>/dev/null | sed -n 's/.*<string>\(.*codefastlabs[^<]*\)<.*/\1/p')"
if [[ -d $im ]]; then
  log_ok 'Bộ gõ nằm trong app'
else
  log_die 'Không có bộ gõ trong app (bản build sai).'
fi
# The postinstall already opened the app; the app installs and enables the input method.
if [[ $(defaults read com.apple.inputsources AppleEnabledThirdPartyInputSources 2>/dev/null) == *'com.codefastlabs.dau.inputmethod.Dau'* ]]; then
  log_ok 'Dấu đã bật trong danh sách nguồn nhập liệu'
else
  log_warn 'Dấu chưa bật'
  log_hint 'Mở /Applications/Dau.app, bấm "Bật Dấu" rồi Allow.'
  log_hint 'Mục Dấu không có trong System Settings › Keyboard › Input Sources sau đó thì đăng xuất một lần, rồi thêm bằng "+".'
fi
log_done 'Xong — không cần đăng xuất'
