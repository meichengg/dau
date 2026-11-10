#!/bin/zsh
# Regenerates the temporary app icon (docs/BRAND.md "Biểu tượng", D25).
# Side effects: builds, writes repo files
#
#   scripts/assets/make-app-icon.sh [<preview-dir>]
#       Render Resources/Brand/AppIcon*.svg and
#       Apps/Dau/Resources/Assets.xcassets/AppIcon.appiconset from the outlined glyphs in
#       Resources/Brand/app-icon-glyphs.txt. No font needed. With <preview-dir>, also write
#       icon-512.png and sizes.png (16/32/64/128 px, actual size and magnified).
#
#   scripts/assets/make-app-icon.sh outline <BeVietnamPro-Bold.ttf>
#       Re-extract the glyph outlines. Download the font from the official source
#       (https://github.com/google/fonts/tree/main/ofl/bevietnampro or
#       https://github.com/bettergui/BeVietnamPro) to a directory outside the repo.
#       Never commit the font file.
#
# TODO(M7): the official icon is built in Icon Composer (Default / Dark / Clear / Tinted).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
BRAND="$ROOT/Resources/Brand"
GLYPHS="$BRAND/app-icon-glyphs.txt"
ICONSET="$ROOT/Apps/Dau/Resources/Assets.xcassets/AppIcon.appiconset"
source "${0:A:h:h}/lib/log.sh"
source "${0:A:h:h}/lib/xcode.sh"
source "${0:A:h:h}/lib/swift-tool.sh"
dau_developer_dir
TOOL=$(dau_swift_tool make-app-icon "$ROOT/scripts/assets/make-app-icon.swift") || exit 1

if [[ "${1:-}" == "outline" ]]; then
  [[ $# -eq 2 ]] || log_die 2 "Cách dùng: $0 outline <font.ttf>"
  mkdir -p "$BRAND"
  exec "$TOOL" outline "$2" "$GLYPHS"
fi

log_step "Dựng biểu tượng app"
mkdir -p "$ROOT/Apps/Dau/Resources/Assets.xcassets"
if [[ ! -f "$ROOT/Apps/Dau/Resources/Assets.xcassets/Contents.json" ]]; then
  printf '{\n  "info" : {\n    "author" : "xcode",\n    "version" : 1\n  }\n}\n' \
    > "$ROOT/Apps/Dau/Resources/Assets.xcassets/Contents.json"
fi

# Render into a temp dir first; the repo's SVGs and iconset are replaced only when the
# render succeeded, so a failed run never leaves the iconset empty or half written.
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/svg" "$TMP/iconset"
# The renderer's "wrote …" lines are English; they are shown only when it fails.
out=$("$TOOL" render "$GLYPHS" "$TMP/svg" "$TMP/iconset" ${1:+"$1"} 2>&1) \
  || { log_error "Không render được biểu tượng app"; log_hint "${(@f)out}"; exit 1; }
rendered=("$TMP"/iconset/*.png(N))
if (( ${#rendered} == 0 )) || [[ ! -f "$TMP/iconset/Contents.json" ]]; then
  log_die "Render không ra đủ file (không có PNG hoặc Contents.json): giữ nguyên $ICONSET"
fi
mkdir -p "$ICONSET" "$BRAND"
old_pngs=("$ICONSET"/*.png(N))
(( ${#old_pngs} == 0 )) || rm -f "${old_pngs[@]}"
cp "$TMP"/iconset/* "$ICONSET"/
cp "$TMP"/svg/* "$BRAND"/
log_detail "đã cập nhật $ICONSET và các SVG trong $BRAND"
log_done "Đã dựng biểu tượng app"
