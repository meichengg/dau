#!/bin/zsh
# Removes every trace of Dấu from this user account.
# Side effects: builds; with --yes also: kills processes, deletes data, changes user settings, changes input source
# It lets an install test (M5 T4) start from a machine that never had Dấu.
#
# Usage:
#   scripts/dev/clean-dau.sh         list what would be removed; changes nothing
#   scripts/dev/clean-dau.sh --yes   remove what it can of the list, then say to log out
#
# Covers the bundle IDs of Dấu (com.codefastlabs.dau…) and of the M0 placeholder
# (com.example.dau…), for both prefixes alike:
#   - running Dấu / input method processes (Dấu.app is asked to quit if it is running,
#     then the processes are ended);
#   - /Applications/Dau.app and ~/Library/Input Methods/DauInputMethod.app, moved to the
#     Trash with /usr/bin/trash so they can be taken back. If that fails, the script prints
#     the path and says to drag it to the Trash yourself: it never deletes a bundle;
#   - sandbox containers, App Group containers, preference files, saved state, caches,
#     HTTP storages, Application Support, Logs, and the test preference files
#     (dau.snapshot-settings.plist, dau.tests.*.plist);
#   - Dấu's entries in the input source preferences. Only entries whose Bundle ID is Dấu's
#     count; every other input source stays:
#       com.apple.HIToolbox › AppleEnabledInputSources / AppleInputSourceHistory:
#         removed with `defaults import`, after the whole domain is exported to a backup
#         file under the temp directory (its path is printed);
#       the entries are counted and filtered by scripts/lib/input-source.swift (`count`,
#       `drop`), built into build/tools/ on the first run;
#       com.apple.inputsources › AppleEnabledThirdPartyInputSources (where macOS keeps
#         third-party sources that are enabled): only reported. macOS lets only its input
#         source service write it (System Policy denies `defaults import`, which still
#         exits 0), so the script does not try; remove Dấu with "–"
#         in System Settings › Keyboard › "All Input Sources" (before --yes).
#   - LaunchServices registrations of any Dau.app / DauInputMethod.app copy;
#   - the global debug defaults keys DauPerfLog and DauDebugForceUnderline.
#
# Exit status 1 if --yes could not remove something (the lines say what and how); the
# script reads back and never claims a removal it could not see. Run it yourself: it
# changes input source settings and deletes app data, which the assistant does not do on
# its own. Then log out and back in: macOS keeps a catalog of input sources per login
# session and forgets Dấu only at the next login.
set -uo pipefail
setopt null_glob
source "${0:A:h:h}/lib/log.sh"
source "${0:A:h:h}/lib/wait.sh"
source "${0:A:h:h}/lib/swift-tool.sh"

DO=0
case "${1:-}" in
  "") ;;
  --yes) DO=1 ;;
  -h|--help) log_usage "$0"; exit 0 ;;
  *) log_die 2 "Tham số không hợp lệ: $1 (không tham số để xem, --yes để xoá)" ;;
esac

# A boundary after "dau": com.codefastlabs.dau and com.codefastlabs.dau.* but not ….daufoo.
ID_PATTERN='^com\.(codefastlabs|example)\.dau(\.|$)'
# Same boundary for the process list: the line must end with the executable path.
PROC_PATTERN='Dau\.app/Contents/MacOS/Dau$|DauInputMethod\.app/Contents/MacOS/DauInputMethod$'
LIB="$HOME/Library"
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
found=0
unremoved=0
note() { log_detail "$1"; found=1 }
# Something --yes could not remove: say so, and make the exit status non-zero.
notremoved() { log_error "$1"; (( unremoved++ )) }

# --- what is there -----------------------------------------------------------------

log_step "Tiến trình"
procs=(${(f)"$(pgrep -fl "$PROC_PATTERN" 2>/dev/null)"})
for p in $procs; do note "$p"; done

log_step "Ứng dụng và bộ gõ"
bundles=()
trashed_names=()
for b in /Applications/Dau.app "/Applications/Dấu.app" "$LIB/Input Methods/DauInputMethod.app"; do
  [[ -e "$b" ]] && { bundles+=("$b"); note "$b"; }
done

log_step "Dữ liệu của app"
data=()
for d in "$LIB"/Containers/com.{codefastlabs,example}.dau{,.*} \
         "$LIB/Group Containers/"*{codefastlabs,example}.dau{,.*} \
         "$LIB"/Preferences/com.{codefastlabs,example}.dau{,.*}.plist \
         "$LIB/Saved Application State/"com.{codefastlabs,example}.dau{,.*} \
         "$LIB"/Caches/com.{codefastlabs,example}.dau{,.*} \
         "$LIB"/HTTPStorages/com.{codefastlabs,example}.dau{,.*} \
         "$LIB/Application Support/"com.{codefastlabs,example}.dau{,.*} \
         "$LIB"/Logs/com.{codefastlabs,example}.dau{,.*} \
         "$LIB"/Preferences/dau.snapshot-settings.plist "$LIB"/Preferences/dau.tests.*.plist; do
  # A word without wildcard characters (e.g. the brace expansion's exact name) stays in
  # the list even when nothing is there: keep what exists.
  [[ -e $d || -L $d ]] || continue
  data+=("$d"); note "${d#$HOME/}"
done

# Input source preferences: count Dấu's entries per array, without changing anything.
INPUT_SOURCE=$(dau_swift_tool input-source "${0:A:h:h}/lib/input-source.swift") || exit 1
inputsource_entries() { # domain key
  defaults export "$1" - 2>/dev/null | "$INPUT_SOURCE" count "$2" "$ID_PATTERN"
}
log_step "Nguồn nhập liệu"
prefs=()
for spec in "com.apple.inputsources AppleEnabledThirdPartyInputSources" \
            "com.apple.HIToolbox AppleEnabledInputSources" \
            "com.apple.HIToolbox AppleInputSourceHistory"; do
  n=$(inputsource_entries ${=spec})
  if [[ -n $n && $n != 0 ]]; then prefs+=("$spec"); note "${spec/ / › }: $n mục của Dấu"; fi
done
selected=0
n=$(inputsource_entries com.apple.HIToolbox AppleSelectedInputSources)
[[ -n $n && $n != 0 ]] && selected=1
(( selected )) && note "Dấu đang là nguồn được chọn: chuyển sang bàn phím khác trước (menu nguồn nhập liệu)."

log_step "Đăng ký LaunchServices"
registered=(${(f)"$("$LSREGISTER" -dump 2>/dev/null | grep -E '^path: .*/(Dau|DauInputMethod)\.app \(0x' | sed -E 's/^path: +//; s/ \(0x[0-9a-f]+\)$//')"})
for r in $registered; do note "$r"; done

log_step "Khoá defaults gỡ lỗi"
keys=()
for k in DauPerfLog DauDebugForceUnderline; do
  defaults read -g "$k" >/dev/null 2>&1 && { keys+=("$k"); note "-g $k"; }
done

if (( ! found )); then
  log_ok "Không còn gì của Dấu"
  log_detail "Nếu vừa gỡ, đăng xuất rồi đăng nhập lại một lần."
  exit 0
fi
if (( ! DO )); then
  log_step "Chưa xoá gì"
  log_detail "Chạy lại với --yes để xoá những gì xoá được trong danh sách trên."
  if (( ${prefs[(I)com.apple.inputsources *]} )); then
    log_warn "Các mục trong com.apple.inputsources không xoá được bằng script (macOS từ chối ghi)"
    log_hint "Bỏ Dấu bằng \"–\" trong System Settings › Keyboard › (danh sách nguồn nhập liệu, \"All Input Sources\") TRƯỚC khi chạy --yes."
  fi
  exit 0
fi
if (( selected )); then
  log_error "Dấu đang được chọn"
  log_hint "Chuyển sang bàn phím khác rồi chạy lại."
  exit 1
fi
# Order matters: once the bundle is gone System Settings no longer lists Dấu, so its
# entries in com.apple.inputsources can no longer be removed with "–" and stay behind
# (D16). Stop before touching anything while those entries exist and the
# bundle is still installed.
if (( ${prefs[(I)com.apple.inputsources *]} )) && (( ${#bundles} )); then
  log_error "Dấu còn trong danh sách nguồn nhập liệu đang bật. Chưa xoá gì."
  log_hint "Bỏ nó trước, rồi chạy lại:" \
    "System Settings › Keyboard › (danh sách nguồn nhập liệu, \"All Input Sources\"): chọn dòng của Dấu, bấm \"–\", bấm Done." \
    "Xoá bộ gõ trước thì System Settings không còn hiện Dấu để bỏ."
  exit 1
fi

# --- remove --------------------------------------------------------------------------

log_step "Đang xoá"
no_dau_process() { ! pgrep -f "$PROC_PATTERN" >/dev/null 2>&1; }
if (( ${#procs} )); then
  # Ask Dấu.app to quit only if it is running: `tell application` would launch it.
  for id in com.codefastlabs.dau com.example.dau; do
    if [[ -n $(lsappinfo find "bundleid=$id" 2>/dev/null) ]]; then
      osascript -e "tell application id \"$id\" to quit" >/dev/null 2>&1
    fi
  done
  # Give the normal quit up to 3 s, then stop what is left and wait for it to go.
  wait_until 3 no_dau_process
  pkill -f 'Dau\.app/Contents/MacOS/Dau$' 2>/dev/null
  pkill -f 'DauInputMethod\.app/Contents/MacOS/DauInputMethod$' 2>/dev/null
  wait_until 2 no_dau_process
  still=(${(f)"$(pgrep -fl "$PROC_PATTERN" 2>/dev/null)"})
  for p in $still; do notremoved "KHÔNG dừng được tiến trình: $p"; done
fi
# Unregister before the bundles move: LaunchServices follows a bundle into the Trash and
# keeps it registered there, so unregistering the old path afterwards misses it.
for r in $registered; do "$LSREGISTER" -u "$r" >/dev/null 2>&1 && log_detail "bỏ đăng ký: $r"; done
for b in $bundles; do
  if /usr/bin/trash -s "$b" >/dev/null 2>&1; then
    log_detail "vào Thùng rác: $b"
    trashed_names+=("${b:t}")
  else
    # Never `rm -rf` a bundle: the user can take it back from the Trash, not from here.
    notremoved "KHÔNG chuyển được vào Thùng rác: $b"
    log_hint "Kéo $b vào Thùng rác bằng tay."
  fi
done
# A bundle that was never registered gets registered once it lands in the Trash:
# unregister every copy there too.
trashed_registered() { "$LSREGISTER" -dump 2>/dev/null | grep -qE "^path: +$HOME/\.Trash/.*(Dau|DauInputMethod)\.app \(0x"; }
if (( ${#bundles} )); then
  # LaunchServices registers a bundle in the Trash shortly after the move; wait for that
  # (at most 3 s; nothing to unregister if it never happens).
  wait_until -i 0.5 3 trashed_registered
  trashed=(${(f)"$("$LSREGISTER" -dump 2>/dev/null | grep -E "^path: +$HOME/\.Trash/.*(Dau|DauInputMethod)\.app \(0x" | sed -E 's/^path: +//; s/ \(0x[0-9a-f]+\)$//')"})
  for r in $trashed; do "$LSREGISTER" -u "$r" >/dev/null 2>&1 && log_detail "bỏ đăng ký: $r"; done
fi
for d in $data; do
  rm -rf -- "$d"
  if [[ -e $d ]]; then
    notremoved "KHÔNG xoá được: ${d#$HOME/}"
    # Seen (09/11/2026): rm gets "Operation not permitted" on a container when the process
    # running the script has no Full Disk Access. Not tried with that permission granted.
    [[ $d == */Containers/* || $d == */"Group Containers"/* ]] &&
      log_hint "Tiến trình chạy script có thể thiếu Full Disk Access (System Settings › Privacy & Security). Hoặc mở Finder › Đi › Đi tới Thư mục… \"${d:h}\", kéo \"${d:t}\" vào Thùng rác."
  else
    log_detail "đã xoá: ${d#$HOME/}"
  fi
done

# `defaults import` replaces the whole domain: export it first, once per domain.
backup_dir=""
typeset -A backed_up
backup_domain() { # domain → 0 if a backup of the domain exists
  [[ -n ${backed_up[$1]:-} ]] && return 0
  [[ -n $backup_dir ]] || backup_dir=$(mktemp -d "${TMPDIR:-/tmp}/dau-clean-backup.XXXXXX") || return 1
  defaults export "$1" "$backup_dir/$1.plist" 2>/dev/null || return 1
  backed_up[$1]=1
  log_detail "sao lưu $1: $backup_dir/$1.plist"
}
for spec in $prefs; do
  domain=${spec%% *} key=${spec#* }
  if [[ $domain == com.apple.inputsources ]]; then
    # macOS refuses third-party writes to this domain (`defaults import` exits 0 and
    # changes nothing): do not try, report what remains.
    left=$(inputsource_entries "$domain" "$key")
    notremoved "KHÔNG xoá được ($left mục của Dấu còn trong $domain › $key): macOS chỉ cho dịch vụ nguồn nhập liệu ghi domain này."
    log_hint "Bỏ Dấu bằng \"–\" trong System Settings › Keyboard › (danh sách nguồn nhập liệu, \"All Input Sources\")."
    continue
  fi
  if ! backup_domain "$domain"; then
    notremoved "KHÔNG sao lưu được $domain nên không sửa: $domain › $key vẫn còn mục của Dấu."
    continue
  fi
  tmp=$(mktemp)
  defaults export "$domain" - | "$INPUT_SOURCE" drop "$key" "$ID_PATTERN" > "$tmp" && defaults import "$domain" "$tmp" 2>/dev/null
  rm -f "$tmp"
  # `defaults import` exits 0 even when the write is refused: read back.
  left=$(inputsource_entries "$domain" "$key")
  if [[ $left == 0 ]]; then
    log_detail "đã bỏ các mục của Dấu: $domain › $key"
  else
    notremoved "KHÔNG bỏ được ($left mục còn lại): $domain › $key. Bản sao lưu: $backup_dir/$domain.plist"
    log_hint "Gỡ bằng \"–\" trong System Settings › Keyboard › (danh sách nguồn nhập liệu, \"All Input Sources\") nếu Dấu còn trong danh sách;" \
      "muốn thử cài lần đầu thật sạch thì dùng một tài khoản macOS mới."
  fi
done
for k in $keys; do
  if defaults delete -g "$k" 2>/dev/null; then log_detail "đã xoá khoá: -g $k"; else notremoved "KHÔNG xoá được khoá: -g $k"; fi
done

if (( unremoved )); then
  log_error "Chưa xoá hết: còn $unremoved mục (các dòng KHÔNG … ở trên)."
  log_hint "Xử lý tay theo hướng dẫn rồi chạy lại để kiểm." \
    "Sau khi xử lý xong, đăng xuất rồi đăng nhập lại: macOS chỉ quên Dấu trong danh sách nguồn nhập liệu ở lần đăng nhập sau."
  exit 1
fi
(( ${#trashed_names} )) && log_detail "Dọn Thùng rác nếu muốn (vừa chuyển vào: ${(j:, :)trashed_names})."
log_detail "Đăng xuất rồi đăng nhập lại: macOS chỉ quên Dấu trong danh sách nguồn nhập liệu ở lần đăng nhập sau."
log_done "Đã xoá dấu vết của Dấu"
