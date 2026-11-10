#!/bin/zsh
# Which build of Dấu is installed and running, against the repo.
# Side effects: none
#
# Usage: scripts/dev/dau-version.sh
#
# Prints the commit (Resources/BuildCommit.txt, scripts/build/stamp-build-commit.sh) of the
# installed input method and of the Debug Dấu.app, the repo's HEAD, and whether the
# running input method process started after the installed bundle was written (if not,
# switch input source away from Dấu and back, so macOS starts the new one). Also prints
# whether each installed bundle's signature still verifies (a revoked "Apple Development"
# certificate, e.g. after the same Apple ID made a new one on another Mac, shows here as
# CSSMERR_TP_CERT_REVOKED) and the Apple Development identities in the keychain. An
# installed bundle built from another commit than HEAD gets the command that reinstalls it.
# Reads only; changes nothing.
set -uo pipefail
root=${0:A:h:h:h}
source "${0:A:h:h}/lib/log.sh"
im="$HOME/Library/Input Methods/DauInputMethod.app"
app="$root/build/DerivedData.noindex/Build/Products/Debug/Dau.app"
host="/Applications/Dau.app"

commit_of() { # bundle
  local f="$1/Contents/Resources/BuildCommit.txt"
  if [[ -f $f ]]; then print -r -- "$(<"$f")"; else print -r -- "(không có mã commit)"; fi
}

stale_note() { # bundle label reinstall-command -> a warning when the bundle was built from another commit
  local f="$1/Contents/Resources/BuildCommit.txt" built
  [[ -f $f && -n $head ]] || return 0
  built=$(<"$f")
  # Compare commits only: "+" (uncommitted changes) on either side says nothing either way.
  [[ ${built%+} == ${head%+} ]] && return 0
  log_warn "$2 ($built) khác repo ($head)"
  log_hint "cài lại bằng $3"
}

signature_of() { # bundle -> "hợp lệ, Team X" or the codesign error
  local out team
  team=$(codesign -dv "$1" 2>&1 | sed -n 's/^TeamIdentifier=//p')
  if out=$(codesign --verify --strict "$1" 2>&1); then
    print -r -- "hợp lệ, Team ${team:-?}"
  else
    out=${out%%$'\n'*}   # first line: "<path>: <reason>"
    print -r -- "KHÔNG hợp lệ, Team ${team:-?}: ${out##*: }"
  fi
}

head=$(git -C "$root" rev-parse --short=7 HEAD 2>/dev/null)
[[ -n $(git -C "$root" status --porcelain --untracked-files=no 2>/dev/null) ]] && head+="+"
print -r -- "Repo:              $head"

if [[ -d $im ]]; then
  print -r -- "Bộ gõ đã cài:      $(commit_of "$im")  (ghi lúc $(stat -f '%Sm' "$im/Contents/MacOS/DauInputMethod"))"
  stale_note "$im" "Bộ gõ đã cài" "scripts/dev/install-input-method.sh (hoặc install-app.sh --with-input-method)"
  print -r -- "  chữ ký:          $(signature_of "$im")"
else
  print -r -- "Bộ gõ đã cài:      chưa cài"
fi
if [[ -d $host ]]; then
  print -r -- "Dấu.app (/Applications): $(commit_of "$host")"
  stale_note "$host" "Dấu.app" "scripts/dev/install-app.sh"
  print -r -- "  chữ ký:          $(signature_of "$host")"
fi
[[ -d $app ]] && print -r -- "Dấu.app (Debug):   $(commit_of "$app")"

# Apple Development identities: valid, or why not (revoked, expired).
# find-identity prints "Matching identities" then "Valid identities only": keep the first list.
ids=$(security find-identity -p codesigning 2>/dev/null | sed '/Valid identities only/q' | grep -E '^ +[0-9]+\) .*"Apple Development' | sed -E 's/^ +[0-9]+\) [0-9A-F]+ //')
if [[ -z $ids ]]; then
  print -r -- "Chứng chỉ ký:      không có \"Apple Development\" trong keychain"
else
  print -r -- "Chứng chỉ ký:"
  print -r -- "$ids" | while IFS= read -r l; do
    if [[ $l == *CSSMERR* ]]; then print -r -- "  KHÔNG dùng được: $l"; else print -r -- "  dùng được:       $l"; fi
  done
fi

pid=$(pgrep -f "Input Methods/DauInputMethod.app/Contents/MacOS/DauInputMethod" | head -1)
if [[ -z $pid ]]; then
  print -r -- "Tiến trình bộ gõ:  chưa chạy (macOS mở khi gõ phím với nguồn Dấu)"
elif [[ -d $im ]]; then
  started=$(date -j -f "%a %b %d %T %Y" "$(ps -o lstart= -p $pid | sed 's/  */ /g; s/^ //; s/ $//')" +%s 2>/dev/null)
  written=$(stat -f %m "$im/Contents/MacOS/DauInputMethod")
  if [[ -z $started ]]; then
    # Never claim an old build runs when the start time could not be parsed.
    print -r -- "Tiến trình bộ gõ:  pid $pid, không xác định bản nào (không đọc được giờ khởi động)"
  elif (( started >= written )); then
    print -r -- "Tiến trình bộ gõ:  pid $pid, chạy bản đã cài"
  else
    print -r -- "Tiến trình bộ gõ:  pid $pid, đang chạy bản CŨ"
    log_warn "Tiến trình bộ gõ đang chạy bản CŨ (khởi động trước lúc bản đã cài được ghi)"
    log_hint "chuyển nguồn nhập liệu ra rồi vào lại Dấu"
  fi
fi
