#!/bin/bash
# Wraps an already built Release Dau.app in a .pkg that installs it into /Applications
# and then launches it for the logged-in user (scripts/release/pkg/postinstall).
#
# Usage: scripts/release/build-pkg.sh <version>
#   1. Code sign the package with this identity (skipped when unset). An "Apple
#      Development" identity cannot always sign packages; the warning path keeps the
#      unsigned package.
#   2. Version written into the package receipt.
#
# Side effects: writes build/pkg/ (git-ignored), nothing outside the repo.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VERSION="${1:?usage: build-pkg.sh <version>}"
APP="$ROOT/build/DerivedData.noindex/Build/Products/Release/Dau.app"
WORK="$ROOT/build/pkg/work"
OUT="$ROOT/build/pkg/out"
[[ -d "$APP" ]] || { echo "Không thấy $APP — build Release trước." >&2; exit 1; }

rm -rf "$WORK"
mkdir -p "$WORK/payload" "$OUT"
ditto "$APP" "$WORK/payload/Dau.app"
cp "$ROOT/scripts/release/pkg/postinstall" "$WORK/postinstall"
chmod +x "$WORK/postinstall"

PKG="$OUT/Dau-$VERSION.pkg"
pkgbuild \
  --root "$WORK/payload" \
  --identifier com.codefastlabs.dau.pkg \
  --version "$VERSION" \
  --install-location /Applications \
  --scripts "$WORK" \
  "$PKG"

if [[ -n "${PKG_SIGN_IDENTITY:-}" ]]; then
  if productsign --sign "$PKG_SIGN_IDENTITY" "$PKG" "$WORK/signed.pkg" 2>"$WORK/productsign.log"; then
    mv -f "$WORK/signed.pkg" "$PKG"
    echo "Đã ký gói bằng: $PKG_SIGN_IDENTITY"
  else
    echo "Cảnh báo: không ký được gói bằng \"$PKG_SIGN_IDENTITY\", giữ gói chưa ký:" >&2
    sed "s/^/    /" "$WORK/productsign.log" >&2
  fi
fi

echo
echo "Gói: $PKG"
shasum -a 256 "$PKG"
