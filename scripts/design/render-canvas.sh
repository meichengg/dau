#!/bin/zsh
# Renders the design canvas artboards to PNG and copies their sources into docs/ui/canvas/,
# so the approved design can be read without access to the canvas on claude.ai.
# Side effects: builds, writes repo files
#
# Usage: scripts/design/render-canvas.sh <dir>
#   dir   a local copy of the canvas files: <dir>/project/*.dc.html, <dir>/project/canvas.json
#         and <dir>/artifact-type/dc-runtime.js. Claude saves them with the Artifact tool
#         (action "read" with `paths`); there is no other way to download them.
#
# Renders every artboard on the canvas page "Thiết kế" (not the archive page) with Chrome in
# headless mode: no window is shown and the screen is not used. The canvas runtime
# (dc-runtime.js) is the canvas publisher's code: it is opened from build/canvas/ as a file://
# page for the render only and never copied into the repo. --allow-file-access-from-files lets
# it fetch the page itself and sibling boards, which Chrome otherwise blocks on file://.
# Writes docs/ui/canvas/<name>.png, docs/ui/canvas/src/<name>.dc.html,
# docs/ui/canvas/canvas.json and docs/ui/canvas/README.md (index by section), replacing what
# was there. Needs network for the web fonts.
set -euo pipefail
ROOT="${0:A:h:h:h}"
source "$ROOT/scripts/lib/log.sh"
source "$ROOT/scripts/lib/swift-tool.sh"

SRC="${1:-}"
[[ -n "$SRC" && -f "$SRC/project/canvas.json" && -f "$SRC/artifact-type/dc-runtime.js" ]] \
  || log_die 2 "Cần thư mục có project/canvas.json và artifact-type/dc-runtime.js (xem đầu script)."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[[ -x "$CHROME" ]] || log_die "Không thấy Google Chrome ở /Applications."

WORK="$ROOT/build/canvas"
OUT="$ROOT/docs/ui/canvas"
rm -rf "$WORK"; mkdir -p "$WORK/project" "$WORK/profile"
cp "$SRC"/project/*.dc.html "$SRC/project/canvas.json" "$WORK/project/"
cp "$SRC/artifact-type/dc-runtime.js" "$WORK/project/support.js"

# name<TAB>width<TAB>height for the boards on the "Thiết kế" page, in canvas order.
INDEX=$(dau_swift_tool canvas-index "${0:A:h}/canvas-index.swift") || exit 1
"$INDEX" boards "$WORK/project/canvas.json" > "$WORK/boards.tsv"
(( $(wc -l < "$WORK/boards.tsv") > 0 )) || log_die "canvas.json không có artboard nào trên trang Thiết kế."

trap 'rm -rf "$WORK/profile"' EXIT

rm -rf "$OUT"; mkdir -p "$OUT/src"
log_step "Chụp $(wc -l < "$WORK/boards.tsv" | tr -d ' ') artboard bằng Chrome chạy ẩn"
failed=0
while IFS=$'\t' read -r name w h; do
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --no-first-run \
    --user-data-dir="$WORK/profile" --allow-file-access-from-files \
    --window-size="$w,$h" --virtual-time-budget=8000 \
    --screenshot="$OUT/${name%.dc.html}.png" "file://$WORK/project/$name" >/dev/null 2>&1 \
    || { log_warn "Không chụp được $name"; failed=1; continue; }
  cp "$WORK/project/$name" "$OUT/src/"
  log_detail "$name (${w}×${h})"
done < "$WORK/boards.tsv"
cp "$WORK/project/canvas.json" "$OUT/"
"$INDEX" readme "$WORK/project/canvas.json" > "$OUT/README.md"
(( failed == 0 )) || log_die "Có artboard không chụp được (xem trên)."
log_ok "Xong: $OUT"
log_done
