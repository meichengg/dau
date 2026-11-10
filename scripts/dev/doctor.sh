#!/bin/zsh
# What is missing on this Mac to build, test and run Dấu, with the fix for each item.
# Side effects: builds
#
# Usage: scripts/dev/doctor.sh [--tests]
#   --tests   also run the DauEngine test suite (otherwise only checks the package resolves)
#
# Read-only on the system: installs nothing, writes no defaults, enables no input source,
# uses no network, opens no window. The only writes are build artifacts under build/ (the
# input-source helper, in build/tools/ through scripts/lib/swift-tool.sh) and .build/
# of the Swift package. Marks: ✓ fine, ! worth a look (does not block), ✗ blocks building
# or testing. Exit 0 when nothing blocks building and testing, 1 otherwise.
set -uo pipefail
root=${0:A:h:h:h}
source "${0:A:h:h}/lib/log.sh"

run_tests=0
case ${1-} in
  "") ;;
  --tests) run_tests=1 ;;
  *) log_die 2 "Tham số không hợp lệ: $1 (dùng: doctor.sh [--tests])" ;;
esac

blocked=0
fail() { log_error "$1"; shift; (( $# )) && log_hint "$@"; blocked=1; }

# --- Xcode, Swift ----------------------------------------------------------------------
log_step "Công cụ build"
selected=$(xcode-select -p 2>/dev/null)
dev_dir=""
if [[ -n ${DEVELOPER_DIR-} && -x $DEVELOPER_DIR/usr/bin/xcodebuild ]]; then
  dev_dir=$DEVELOPER_DIR
elif [[ -n $selected && -x $selected/usr/bin/xcodebuild ]]; then
  dev_dir=$selected
elif [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
  dev_dir=/Applications/Xcode.app/Contents/Developer
fi
if [[ -z $dev_dir ]]; then
  fail "Không tìm thấy Xcode (xcode-select -p: ${selected:-không có})." \
    "Cài Xcode từ App Store rồi mở một lần để chấp nhận giấy phép; xem phiên bản đã thử trong README.md."
else
  xv=$(DEVELOPER_DIR=$dev_dir xcodebuild -version 2>/dev/null | tr '\n' ' ')
  if [[ -z $xv ]]; then
    fail "Có Xcode ở $dev_dir nhưng xcodebuild không chạy được." \
      "Mở Xcode một lần để chấp nhận giấy phép và cài thành phần bổ sung, hoặc: sudo xcodebuild -license accept"
  else
    log_ok "Xcode: ${xv% }  ($dev_dir)"
  fi
  if [[ $selected == /Library/Developer/CommandLineTools* ]]; then
    log_ok "xcode-select đang trỏ tới Command Line Tools: không sao, các script tự dùng $dev_dir (dau_developer_dir)."
    log_detail "Với lệnh gõ tay, đặt: export DEVELOPER_DIR=$dev_dir"
  fi
  export DEVELOPER_DIR=$dev_dir
fi
sv=$(swift --version 2>/dev/null | head -1)
if [[ -n $sv ]]; then
  log_ok "Swift: $sv"
else
  fail "Không chạy được swift." "Cài Xcode (hoặc: xcode-select --install cho Command Line Tools)."
fi

if command -v xcodegen >/dev/null; then
  log_ok "xcodegen: $(xcodegen --version 2>/dev/null | head -1)"
else
  fail "Chưa có xcodegen." "brew install xcodegen"
fi
if [[ ! -d $root/Dau.xcodeproj ]]; then
  log_warn "Chưa có Dau.xcodeproj (chỉ cần để build app và bộ gõ)."
  log_hint "cd $root && xcodegen generate"
elif [[ $root/project.yml -nt $root/Dau.xcodeproj/project.pbxproj ]]; then
  log_warn "Dau.xcodeproj cũ hơn project.yml."
  log_hint "cd $root && xcodegen generate"
else
  log_ok "Dau.xcodeproj có và không cũ hơn project.yml"
fi

# --- Engine ----------------------------------------------------------------------------
log_step "Engine"
if (( run_tests )); then
  if out=$(swift test --package-path "$root/Packages/DauEngine" 2>&1); then
    log_ok "swift test DauEngine: đạt  ($(print -r -- "$out" | grep -E 'Test run with|Executed' | tail -1))"
  else
    fail "swift test DauEngine không đạt." "swift test --package-path Packages/DauEngine   (xem lỗi đầy đủ)"
  fi
elif swift package --package-path "$root/Packages/DauEngine" describe >/dev/null 2>&1; then
  log_ok "Packages/DauEngine đọc được (chưa chạy test; thêm --tests để chạy)"
else
  fail "Packages/DauEngine không đọc được." "swift package --package-path Packages/DauEngine describe   (xem lỗi)"
fi

# --- Signing ---------------------------------------------------------------------------
log_step "Ký (cần để cài và gõ thử bộ gõ thật)"
want_team=""
if [[ -f $root/Config/Local.xcconfig ]]; then
  want_team=$(sed -n 's/^ *DEVELOPMENT_TEAM *= *\([A-Z0-9]*\).*/\1/p' "$root/Config/Local.xcconfig" | tail -1)
  [[ -n $want_team ]] && log_detail "Team ID từ Config/Local.xcconfig: $want_team"
fi
if [[ -z $want_team ]]; then
  want_team=$(sed -n 's/^ *DEVELOPMENT_TEAM *= *\([A-Z0-9]*\).*/\1/p' "$root/Config/Signing.xcconfig" | tail -1)
  log_detail "Team ID dự án dùng (Config/Signing.xcconfig): ${want_team:-?}"
fi
teams=()
while IFS= read -r name; do
  [[ -n $name ]] || continue
  t=$(security find-certificate -c "$name" -p 2>/dev/null | openssl x509 -noout -subject -nameopt multiline 2>/dev/null \
      | sed -n 's/^ *organizationalUnitName *= *//p' | head -1)
  teams+=("${t:-?}")
done < <(security find-identity -v -p codesigning 2>/dev/null | grep -E '^ +[0-9]+\) ' | sed -n 's/.*"\(Apple Development[^"]*\)".*/\1/p')
if (( ${#teams} == 0 )); then
  log_warn "Không có chứng chỉ \"Apple Development\" hợp lệ trong keychain."
  log_hint "Mở Xcode › Settings › Accounts, đăng nhập Apple ID (Personal Team miễn phí là đủ); Xcode tạo chứng chỉ khi build." \
    "Chứng chỉ bị thu hồi (CSSMERR_TP_CERT_REVOKED) thì không nằm trong danh sách hợp lệ: xem CONTRIBUTING.md, mục dùng một Apple ID trên hai máy."
elif (( ${teams[(Ie)$want_team]} )); then
  log_ok "Có chứng chỉ \"Apple Development\" thuộc Team $want_team"
else
  log_warn "Chứng chỉ \"Apple Development\" có (Team ${(j:, :)teams}) nhưng không khớp Team $want_team của dự án."
  log_hint "Làm theo CONTRIBUTING.md: cp Config/Local.xcconfig.example Config/Local.xcconfig rồi đặt DEVELOPMENT_TEAM = <Team ID của bạn>;" \
    "sau đó xcodegen generate. Không sửa Team trong project.yml hay Config/Signing.xcconfig."
fi

# --- Installed build ---------------------------------------------------------------------
log_step "Bản đã cài (so với HEAD, qua scripts/dev/dau-version.sh)"
im="$HOME/Library/Input Methods/DauInputMethod.app"
[[ -d $im ]] || log_warn "Bộ gõ chưa cài trong ~/Library/Input Methods." "scripts/dev/install-input-method.sh   (thêm --release để dùng hằng ngày)"
[[ -d /Applications/Dau.app ]] || log_warn "Chưa có Dấu.app trong /Applications." "scripts/dev/install-app.sh   (thêm --with-input-method để cài cả bộ gõ)"
ver=$("$root/scripts/dev/dau-version.sh" 2>&1)
print -r -- "$ver" | sed 's/^/    /'
if [[ $ver == *"khác repo"* || $ver == *"đang chạy bản CŨ"* || $ver == *"KHÔNG hợp lệ"* || $ver == *"KHÔNG dùng được"* ]]; then
  log_warn "Bản đã cài lệch HEAD, chữ ký hỏng hoặc tiến trình cũ (xem dòng gợi ý ở trên)."
elif [[ -d $im ]]; then
  log_ok "Bản đã cài khớp HEAD"
fi

# --- Input source ----------------------------------------------------------------------
log_step "Nguồn nhập liệu Dấu (chỉ đọc)"
if [[ ! -f $im/Contents/Info.plist ]]; then
  log_detail "Bỏ qua: bộ gõ chưa cài."
elif [[ -z $dev_dir ]]; then
  log_detail "Bỏ qua: cần Xcode để biên dịch công cụ đọc nguồn nhập liệu."
else
  source "$root/scripts/lib/swift-tool.sh"
  if ! helper=$(dau_swift_tool input-source "$root/scripts/lib/input-source.swift" 2>/dev/null); then
    log_warn "Không biên dịch được scripts/lib/input-source.swift, bỏ qua kiểm tra này."
  else
    im_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$im/Contents/Info.plist" 2>/dev/null)
    src_out=$("$helper" enabled "$im_id" 2>&1); rc=$?
    if (( rc == 0 )) && [[ -n $src_out ]]; then
      log_ok "Đã bật: ${src_out//$'\n'/, }"
    elif (( rc == 4 )); then
      log_warn "TIS và com.apple.inputsources không khớp: ${src_out%%$'\n'*}"
      log_hint "Mở System Settings › Keyboard › Text Input › Input Sources, kiểm tra Dấu có trong danh sách; nếu không, bấm \"+\" và thêm."
    else
      log_warn "Nguồn nhập liệu Dấu chưa được bật."
      log_hint "System Settings › Keyboard › Text Input › Input Sources › Edit… › \"+\" › Vietnamese › Dấu." \
        "(Script không tự bật: việc này do bạn làm.)"
    fi
  fi
fi

# --- Secure input ----------------------------------------------------------------------
log_step "Secure input"
spid=$(ioreg -l -w0 2>/dev/null | sed -n 's/.*"kCGSSessionSecureInputPID" *= *\([0-9]*\).*/\1/p' | head -1)
if [[ -z $spid ]]; then
  log_ok "Không có tiến trình nào đang giữ secure input"
else
  pname=$(ps -o comm= -p "$spid" 2>/dev/null)
  log_warn "Secure input đang bật, do pid $spid (${pname:-không rõ}) giữ: Dấu có thể hiện mờ và gõ không được."
  log_hint "Thường là một ô mật khẩu đang được chọn (trình duyệt, Terminal có Secure Keyboard Entry). Rời ô đó hoặc đóng tiến trình đó."
fi

# --- Research data ---------------------------------------------------------------------
log_step "Dữ liệu nghiên cứu (tuỳ chọn)"
ext=${EXT_IME_DIR:-/tmp/ext-ime}
n_ext=$(ls -d "$ext"/*/ 2>/dev/null | wc -l | tr -d ' ')
n_ans=$(ls "$root"/build/external-answers/*.tsv 2>/dev/null | wc -l | tr -d ' ')
if (( n_ext > 0 && n_ans > 0 )); then
  log_ok "$ext: $n_ext bản clone; build/external-answers: $n_ans file"
else
  log_warn "Thiếu dữ liệu so sánh ($ext: $n_ext bản clone; build/external-answers: $n_ans file). Chỉ cần cho nghiên cứu so sánh."
  log_hint "scripts/research/external-tests/extract.sh   (cần mạng; ghi vào repo và build/, hỏi trước khi chạy)"
fi

echo
if (( blocked )); then
  log_error "Còn mục chặn build hoặc test (dấu ✗ ở trên)."
  exit 1
fi
log_done "Không có gì chặn build và test"
