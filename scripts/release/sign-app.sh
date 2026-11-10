#!/bin/zsh
# Signs a built app without a provisioning profile: Xcode is told not to sign during the
# build and this script signs the input method and then the host app, inside out.
# Every $(PLACEHOLDER) in the entitlements is rendered here, because signing happens outside
# Xcode (an unrendered $(PRODUCT_BUNDLE_IDENTIFIER) once shipped as a literal string in the
# input method's mach-register exception, which then named a service nobody registers).
# The team comes from the certificate behind the identity, never from a constant: it decides
# the App Group name. A real Apple identity carries it, so the group prefix matches the
# signature and macOS lets the app use the shared container. A throwaway self-signed identity
# has no team ID in the signature ("TeamIdentifier=not set"); carrying
# com.apple.developer.team-identifier with such a signature makes the kernel kill the app at
# exec, so the entitlement is dropped when the signature has no team. The App Group does not
# work then (containermanagerd rejects it) — the app still installs and runs.
# Side effects: none
#
# Usage: scripts/release/sign-app.sh </path/to/Dau.app> <signing identity>
#   GROUP_ID overrides the rendered App Group; pass the value the app was built with.
set -uo pipefail
setopt extendedglob

source "$0:A:h/../lib/log.sh"

[[ $# -ge 2 ]] || log_die 2 "dùng: sign-app.sh <app> <identity>" "" "$(log_usage $0)"
app=$1 identity=$2
[[ -d $app ]] || log_die "không thấy $app — build Release trước."
prefix=${BUNDLE_ID_PREFIX:-com.codefastlabs.dau}
root=${0:A:h:h:h}
im="$app/Contents/Library/Input Methods/DauInputMethod.app"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

team=$("$root/scripts/release/team-id.sh" "$identity")
group=${GROUP_ID:-${team:+$team.}$prefix.shared}
log_step "Ký bộ gõ rồi tới app (từ trong ra)"
log_detail "identity: $identity"
log_detail "team: ${team:-không có (App Group sẽ không chạy)}"
log_detail "App Group: $group"

render() { # <template> <output> <bundle id> [with-team]
  sed -e "s|\$(APP_GROUP_ID)|$group|g" -e "s|\$(PRODUCT_BUNDLE_IDENTIFIER)|$3|g" "$1" > "$2"
  [[ ${4:-} == with-team ]] || return 0
  /usr/libexec/PlistBuddy -c "Set :com.apple.developer.team-identifier $team" "$2" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string $team" "$2" >/dev/null
}

render_im() {
  render "$root/Apps/DauInputMethod/DauInputMethod.entitlements" \
    "$work/inputmethod.plist" "$prefix.inputmethod.Dau"
}

sign_all() {
  if [[ -d $im ]]; then
    codesign --force --options runtime --timestamp=none \
      --entitlements "$work/inputmethod.plist" --sign "$identity" "$im"
  fi
  codesign --force --options runtime --timestamp=none \
    --entitlements "$work/app.plist" --sign "$identity" "$app"
}

render_im
render "$root/Apps/Dau/Dau.entitlements" "$work/app.plist" "$prefix" with-team
sign_all

# No pipe: grep -q under pipefail can end on SIGPIPE and report failure.
if [[ $(codesign -dvvv "$app" 2>&1) == *'TeamIdentifier=not set'* ]]; then
  log_warn 'Chữ ký không có Team ID: bỏ com.apple.developer.team-identifier (App Group sẽ không chạy).'
  render_im
  render "$root/Apps/Dau/Dau.entitlements" "$work/app.plist" "$prefix"
  sign_all
  [[ $(codesign -d --entitlements - --xml "$app" 2>/dev/null) != *team-identifier* ]] \
    || log_die 'vẫn còn com.apple.developer.team-identifier dù chữ ký không có team.'
fi

codesign --verify --deep --strict --verbose=2 "$app" || log_die "chữ ký không hợp lệ."
log_ok "Đã ký bằng: $identity"
log_done
