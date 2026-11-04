#!/bin/bash
# Signs the built app without a provisioning profile: Xcode is told not to sign during the
# build and this script signs the input method and then the host app, inside out.
#
# A real Apple identity carries the team ID, so the App Group prefix matches it and macOS
# lets the app use the shared container. A throwaway self-signed identity has no team ID in
# the signature ("TeamIdentifier=not set"); carrying com.apple.developer.team-identifier
# with such a signature makes the kernel kill the app at exec, so the entitlement is dropped
# when the signature has no team. The App Group does not work then (containermanagerd
# rejects it) — the app still installs and runs.
#
# Usage: scripts/release/sign-app.sh <path to Dau.app> <signing identity>
set -euo pipefail

APP="${1:?usage: sign-app.sh <app> <identity>}"
IDENTITY="${2:?usage: sign-app.sh <app> <identity>}"
GROUP_ID="433PH64SVW.com.codefastlabs.dau.shared"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IM="$APP/Contents/Library/Input Methods/DauInputMethod.app"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

render() { # <entitlements template> <output> [with-team]
  sed "s|\$(APP_GROUP_ID)|$GROUP_ID|g" "$1" > "$2"
  if [[ "${3:-}" == with-team ]]; then
    /usr/libexec/PlistBuddy -c "Set :com.apple.developer.team-identifier 433PH64SVW" "$2" 2>/dev/null \
      || /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string 433PH64SVW" "$2" >/dev/null
  fi
}

sign_all() {
  if [[ -d "$IM" ]]; then
    codesign --force --options runtime --timestamp=none \
      --entitlements "$WORK/inputmethod.plist" --sign "$IDENTITY" "$IM"
  fi
  codesign --force --options runtime --timestamp=none \
    --entitlements "$WORK/app.plist" --sign "$IDENTITY" "$APP"
}

render "$ROOT/Apps/DauInputMethod/DauInputMethod.entitlements" "$WORK/inputmethod.plist"
render "$ROOT/Apps/Dau/Dau.entitlements" "$WORK/app.plist" with-team
sign_all

if codesign -dvvv "$APP" 2>&1 | grep -q "TeamIdentifier=not set"; then
  echo "Chữ ký không có Team ID: bỏ com.apple.developer.team-identifier (App Group sẽ không chạy)."
  render "$ROOT/Apps/DauInputMethod/DauInputMethod.entitlements" "$WORK/inputmethod.plist"
  render "$ROOT/Apps/Dau/Dau.entitlements" "$WORK/app.plist"
  sign_all
fi

codesign --verify --deep --strict --verbose=2 "$APP"
codesign -dvvv "$APP" 2>&1 | grep -E "TeamIdentifier|Authority|Signature" || true
echo "Đã ký bằng: $IDENTITY"