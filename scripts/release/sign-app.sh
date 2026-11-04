#!/bin/bash
# Signs the built app without a provisioning profile: Xcode is told not to sign during the
# build and this script signs the input method and then the host app, inside out.
#
# A real Apple identity would also work through Xcode automatic signing, but that needs an
# Apple ID (or profile) on the runner; ad-hoc/self-signed signing of a team-ID-prefixed App
# Group does not, and macOS only checks that the signature's team ID matches the group
# prefix at runtime.
#
# Usage: scripts/release/sign-app.sh <path to Dau.app> <signing identity>
set -euo pipefail

APP="${1:?usage: sign-app.sh <app> <identity>}"
IDENTITY="${2:?usage: sign-app.sh <app> <identity>}"
GROUP_ID="M58DANM3ZP.com.codefastlabs.dau.shared"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
IM="$APP/Contents/Library/Input Methods/DauInputMethod.app"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

render() { # <entitlements template> <output>
  sed "s|\$(APP_GROUP_ID)|$GROUP_ID|g" "$1" > "$2"
  /usr/libexec/PlistBuddy -c "Add :com.apple.developer.team-identifier string M58DANM3ZP" "$2" \
    2>/dev/null || /usr/libexec/PlistBuddy -c "Set :com.apple.developer.team-identifier M58DANM3ZP" "$2"
}

render "$ROOT/Apps/DauInputMethod/DauInputMethod.entitlements" "$WORK/inputmethod.plist"
render "$ROOT/Apps/Dau/Dau.entitlements" "$WORK/app.plist"

if [[ -d "$IM" ]]; then
  codesign --force --options runtime --timestamp=none \
    --entitlements "$WORK/inputmethod.plist" --sign "$IDENTITY" "$IM"
fi
codesign --force --options runtime --timestamp=none \
  --entitlements "$WORK/app.plist" --sign "$IDENTITY" "$APP"

codesign --verify --deep --strict --verbose=2 "$APP"
echo "Đã ký bằng: $IDENTITY"
