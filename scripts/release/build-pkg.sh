#!/bin/zsh
# Wraps an already built Release Dau.app in a .pkg that installs it into /Applications and
# then launches it for the logged-in user (scripts/release/pkg/postinstall).
#
# Usage: scripts/release/build-pkg.sh <version>
#   1. Code sign the package with PKG_SIGN_IDENTITY (skipped when unset). An "Apple
#      Development" identity cannot sign packages; the warning path keeps the unsigned one.
#   2. Version written into the package receipt.
# Side effects: none (writes build/pkg/, git-ignored, nothing outside the repo)
set -uo pipefail
setopt extendedglob

source "$0:A:h/../lib/log.sh"

version=$1
[[ -n $version ]] || log_die 2 'thiếu số phiên bản' '' "$(log_usage $0)"
root=${0:A:h:h:h}
app="$root/build/DerivedData.noindex/Build/Products/Release/Dau.app"
work="$root/build/pkg/work"
out="$root/build/pkg/out"
[[ -d $app ]] || log_die "không thấy $app — build Release trước."

rm -rf "$work"
mkdir -p "$work/payload" "$out"
ditto "$app" "$work/payload/Dau.app"
cp "$root/scripts/release/pkg/postinstall" "$work/postinstall"
chmod +x "$work/postinstall"

pkg="$out/Dau-$version.pkg"
log_step "Đóng gói $version"
pkgbuild \
  --root "$work/payload" \
  --identifier com.codefastlabs.dau.pkg \
  --version "$version" \
  --install-location /Applications \
  --scripts "$work" \
  "$pkg" || log_die 'pkgbuild hỏng.'

if [[ -n ${PKG_SIGN_IDENTITY:-} ]]; then
  if productsign --sign "$PKG_SIGN_IDENTITY" "$pkg" "$work/signed.pkg" 2>"$work/productsign.log"; then
    mv -f "$work/signed.pkg" "$pkg"
    log_ok "Đã ký gói bằng: $PKG_SIGN_IDENTITY"
  else
    log_warn "Không ký được gói bằng \"$PKG_SIGN_IDENTITY\", giữ gói chưa ký"
    sed "s/^/    /" "$work/productsign.log" | while IFS= read -r l; do log_hint "${l#    }"; done
  fi
fi

log_ok "Gói: $pkg"
log_detail "sha256: $(shasum -a 256 "$pkg" | cut -d' ' -f1)"
log_done
