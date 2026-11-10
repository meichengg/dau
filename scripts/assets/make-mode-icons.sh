#!/bin/zsh
# Regenerates the temporary input mode icon "V" of the input method.
# Side effects: builds, writes repo files
# Template TIFF, 22 × 16 pt @1x + @2x, written into Apps/DauInputMethod/Resources.
# Apple's headers document .tif/.icns for input method
# icons (TextServices.h, tsInputMethodIconFileKey); built-in input methods use multi-
# resolution TIFF the same way. TODO(M7): official identity files (docs/BRAND.md).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUT="$ROOT/Apps/DauInputMethod/Resources"
source "${0:A:h:h}/lib/log.sh"
source "${0:A:h:h}/lib/xcode.sh"
source "${0:A:h:h}/lib/swift-tool.sh"
dau_developer_dir
TOOL=$(dau_swift_tool make-mode-icons "$ROOT/scripts/assets/make-mode-icons.swift") || exit 1

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

log_step "Dựng biểu tượng chế độ gõ"
# The tools' own progress lines are English; they are shown only when a step fails.
out=$("$TOOL" "$TMP" 2>&1) \
  || { log_error "Không dựng được ảnh V"; log_hint "${(@f)out}"; exit 1; }
# One input mode only (D2): "Dấu – Tiếng Việt".
out=$(tiffutil -cathidpicheck "$TMP/V.png" "$TMP/V@2x.png" -out "$OUT/ModeVietnamese.tiff" 2>&1) \
  || { log_error "tiffutil không ghép được ModeVietnamese.tiff"; log_hint "${(@f)out}"; exit 1; }
log_detail "đã ghi $OUT/ModeVietnamese.tiff"
log_done "Đã dựng biểu tượng chế độ gõ"
