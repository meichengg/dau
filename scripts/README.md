# Scripts

Mỗi script có dòng `# Side effects:` ở đầu file (ngay sau dòng chú thích đầu tiên), dùng đúng các từ trong bảng chú giải dưới đây. `scripts/check-docs/check.sh` báo lỗi khi script thiếu dòng này, hoặc khi script có tác dụng phụ làm phiền người dùng (chiếm màn hình, dừng tiến trình, đổi nguồn nhập liệu, cài, xoá, đổi cài đặt) mà chưa có trong bảng của hook `.claude/hooks/guard-scripts.sh`. Hook chặn agent chạy các script đó theo bảng ghi rõ trong hook (script nào, với đối số nào), không đọc dòng `# Side effects:`; đổi tác dụng phụ của một script thì sửa cả bảng ấy.

Thư mục theo mục đích:

| Thư mục | Chứa |
|---|---|
| `scripts/build/` | bước build do `project.yml` gọi |
| `scripts/dev/` | cài, dọn, xem bản bộ gõ trên máy |
| `scripts/perf/` | đọc số đo từ nhật ký |
| `scripts/assets/` | sinh biểu tượng tạm |
| `scripts/selftest/` | thử trên app thật (chiếm màn hình hoặc đổi nguồn nhập liệu): gõ thử một câu (`typing/`), ma trận gõ khi app bận cho M6 (`load/`), cửa sổ Cài đặt, App Group |
| `scripts/check-docs/` | kiểm tài liệu |
| `scripts/check-l10n/` | kiểm String Catalog |
| `scripts/lib/` | công cụ dùng chung giữa các script |
| `scripts/snapshot-settings/` | test đơn vị app chủ và công cụ chụp Cài đặt |
| `scripts/research/` | công cụ cho tài liệu nghiên cứu: trích dữ liệu từ dự án khác (chỉ đọc file, không chạy mã của họ), so Dấu với bộ gõ có sẵn của macOS bằng cách gõ thật (`compare-ims/`) |
| `scripts/design/` | chụp canvas thiết kế thành bản trong repo (`docs/ui/canvas/`) |

Mỗi script tự mô tả ở phần đầu file: dòng chú thích đầu, `# Usage:` và `# Side effects:`. Không có bảng liệt kê riêng.

## Mở đầu

Mỗi script chạy riêng (không phải file nạp bằng `source` trong `scripts/lib/`) có dòng `set` với `-u` (biến chưa đặt là lỗi) và `-o pipefail` (một lệnh hỏng giữa pipeline làm cả pipeline hỏng). `-e` chỉ bật ở script dừng ngay khi có lỗi; script gom lỗi rồi báo một lượt (ví dụ `check.sh`, `clean-dau.sh`, `typing/run.sh`) để `-e` tắt và tự kiểm mã thoát. Dưới `pipefail`, `grep -q` ở cuối pipeline có thể làm lệnh trước nó hỏng vì SIGPIPE: so trong shell (`[[ $(lệnh) == *mẫu* ]]`) hoặc dùng `grep -c`. Thư mục Xcode lấy qua `dau_developer_dir` (`scripts/lib/xcode.sh`), không viết cứng; riêng `dev/doctor.sh` tự tìm vì chính việc tìm Xcode là thứ nó kiểm. `scripts/check-docs/check.sh` kiểm `zsh -n`, `-u` và `pipefail` (cả hook trong `.claude/hooks/`). Chờ một trạng thái bằng `scripts/lib/wait.sh`, không bằng `sleep` cố định; `sleep` chỉ còn ở chỗ không có gì để đọc, kèm chú thích lý do. ShellCheck không đọc zsh nên không có chú thích `# shellcheck`.

## Ngôn ngữ

Dấu viết bằng Swift, nên script chỉ dùng thứ có sẵn khi đã cài Xcode:

- **zsh** cho phần điều phối: gọi lệnh, đọc tham số, in kết quả.
- **Swift** cho phần cần API của Apple (Accessibility, nguồn nhập liệu, pasteboard, vẽ ảnh) hoặc có logic đáng kể (đọc JSON, plist, so văn bản tiếng Việt). Script gọi bản đã biên dịch qua `dau_swift_tool` (`scripts/lib/swift-tool.sh`), không chạy `swift file.swift`: chạy kiểu thông dịch thì mỗi lần mất khoảng một giây để biên dịch lại.
- **Công cụ có sẵn của macOS**: `defaults`, `plutil`, `PlistBuddy`, `awk`, `sed`, `osascript` (AppleScript là cách duy nhất để điều khiển app khác).

Không dùng Python, Perl hay Ruby: bản `python3` trên máy là của Command Line Tools, cũ và không được hứa giữ lâu dài, còn người đóng góp cho một dự án Swift không cần đọc thêm ngôn ngữ khác. Ngoại lệ duy nhất là `scripts/research/external-tests/`: công cụ đọc file test của dự án khác cho tài liệu nghiên cứu, không chạm vào máy hay sản phẩm, giữ nguyên bằng Python. `scripts/check-docs/check.sh` kiểm luật này.

## Đầu ra

Mọi script in ra terminal bằng tiếng Việt, qua các hàm của `scripts/lib/log.sh` (nạp bằng `source`), để mọi script trông như nhau:

```
==> Build Release universal (scheme Dau)
    kiến trúc: arm64 x86_64
✓ Chữ ký hợp lệ, không có quyền mạng (N2)
! Bộ gõ đã cài (fa954b8) khác repo (416eddd)
    cài lại: scripts/dev/install-input-method.sh
✗ Bản build không phải universal (D1)
==> Xong · 2 phút 14 giây
```

| Hàm | Dấu | Luồng | Dùng khi |
|---|---|---|---|
| `log_step` | `==>` | stdout | bắt đầu một bước |
| `log_detail` | 4 dấu cách | stdout | chi tiết của bước đang chạy |
| `log_ok` | `✓` | stdout | một điều kiện đạt |
| `log_warn` | `!` | stderr | có điều cần xem, script chạy tiếp |
| `log_error` | `✗` | stderr | lỗi; script gọi tự quyết dừng hay không |
| `log_hint` | 4 dấu cách | stderr | cách xử lý cảnh báo hay lỗi ngay trên |
| `log_die` | `✗` | stderr | lỗi rồi thoát (mã mặc định 1) |
| `log_ask` | `?` | stderr | câu hỏi trước `read` |
| `log_done` | `==>` | stdout | dòng cuối của script chạy xong, kèm thời gian từ lúc bắt đầu |

- Mã thoát: 0 đạt; 1 lỗi hoặc kiểm không đạt; 2 gọi sai (tham số lạ, hai cờ không đi cùng nhau). Script có mã riêng thì ghi ở đầu file (`typing/run.sh`: 3 khi app khác ra trước, 4 khi không chọn được nguồn). Riêng hook `.claude/hooks/guard-scripts.sh` thoát 2 để chặn lệnh, theo quy ước hook của Claude Code.
- Màu chỉ có khi luồng đó là terminal; `NO_COLOR=1` tắt màu. Ghi ra file thì còn dấu, không có mã màu, nên vẫn grep được.
- Tên kỹ thuật (đường dẫn, lệnh, cờ, khoá, bundle ID, số D/N) giữ nguyên trong câu tiếng Việt.
- Không đi qua `log.sh`: dữ liệu cho máy đọc hay để so (TSV, JSON, bảng số của `perf-report.sh`, các dòng `dau-version.sh` in theo cột); đầu ra của công cụ Swift mà script đọc lại; đầu ra của lệnh khác (`xcodebuild`, `git`, `codesign`).
- Chỉ `log.sh` được viết mã màu ANSI và dấu `==>` (`scripts/check-docs/check.sh` kiểm).

## Chú giải tác dụng phụ

| Từ | Nghĩa |
|---|---|
| `none` | chỉ đọc; không ghi gì ngoài file tạm |
| `builds` | chạy xcodegen, xcodebuild hoặc swiftc; ghi vào `build/` hoặc thư mục tạm, không đổi file được theo dõi bởi git |
| `writes repo files` | ghi đè file được theo dõi bởi git trong repo (xem bằng `git diff`) |
| `installs input method` | chép bộ gõ vào `~/Library/Input Methods` |
| `installs app` | chép Dấu.app vào `/Applications` và đăng ký với LaunchServices |
| `kills processes` | dừng tiến trình đang chạy (bộ gõ, Dấu.app, app do script tự mở) |
| `takes the screen` | mở app, gõ phím hoặc bấm chuột tự động: người dùng không dùng máy được trong lúc chạy |
| `changes input source` | chọn lại nguồn nhập liệu, hoặc bỏ Dấu khỏi danh sách nguồn |
| `changes user settings` | ghi `defaults` hoặc cài đặt App Group của người dùng (script tự trả lại khi xong, trừ khi ghi khác) |
| `deletes data` | xoá hoặc chuyển vào Thùng rác dữ liệu, bộ cài của Dấu |
| `needs admin password` | cần mật khẩu quản trị (chưa script nào cần) |

"Ai chạy": subagent chạy được khi tác dụng phụ chỉ gồm `none`, `builds`, `writes repo files`. Còn lại phiên chính chạy, sau khi người dùng chọn giờ (CLAUDE.md, mục Điều phối; hook chặn tới khi người dùng đồng ý). Riêng `clean-dau.sh --yes` (gỡ Dấu khỏi máy) do người dùng tự chạy.

## `scripts/snapshot-settings`

Gói Swift chứa bộ test đơn vị của app chủ (`InputMethodInstallerTests`, `OnboardingFlowTests`, …) và công cụ chụp cửa sổ Cài đặt (`SnapshotSettings`) để đối chiếu với artboard. Không phải script chạy một lệnh. Chạy test:

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path scripts/snapshot-settings
```

## Thư mục khác

- `scripts/lib/input-source.swift`: công cụ dòng lệnh nhỏ (đọc, chọn nguồn nhập liệu; đếm và lọc mục của Dấu trong plist cho `scripts/dev/clean-dau.sh`) mà `scripts/selftest/app-group.sh`, `scripts/selftest/typing/run.sh`, `scripts/selftest/load/run.sh`, `scripts/dev/doctor.sh` và `scripts/dev/clean-dau.sh` biên dịch qua `scripts/lib/swift-tool.sh`; hưởng tác dụng phụ của script gọi nó.
- Các file `.swift` trong `scripts/assets/make-*.swift`, `scripts/selftest/settings-window/`, `scripts/selftest/typing/clipboard.swift` (cả `scripts/selftest/load/run.sh` dùng), `scripts/check-docs/doc-check.swift`, `scripts/design/canvas-index.swift`, `scripts/research/compare-ims/cases.swift` do script `.sh` tương ứng biên dịch và chạy; hưởng tác dụng phụ của script đó.
- `scripts/check-docs/superseded.txt`: danh sách cách nói đã bị thay, do `check.sh` đọc.
