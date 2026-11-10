# Xử lý sự cố khi phát triển

Các sự cố đã gặp trên máy phát triển, nguyên nhân đã xác định và cách xử lý. `scripts/dev/doctor.sh` tự kiểm phần lớn các mục dưới đây.

## "Dấu – Tiếng Việt" bị xám trong menu nguồn đầu vào, máy tự về U.S.

- **Nguyên nhân:** một app đang bật Secure Keyboard Entry, thường là ô mật khẩu đang được chọn (đã gặp với Google Chrome). Khi đó macOS tắt mọi bộ gõ, không riêng Dấu.
- **Kiểm:** `ioreg -l -w 0 | grep kCGSSessionSecureInputPID`, rồi `ps -p <pid>` để biết app nào. `doctor.sh` in ra app đó.
- **Xử lý:** rời khỏi ô mật khẩu hoặc thoát app đó. Không phải lỗi của Dấu.

## "Cài đặt Dấu…" trong menu bộ gõ không mở gì

- **Nguyên nhân:** Dấu.app được chép vào `/Applications` bằng `ditto` hay Finder mà chưa đăng ký với LaunchServices. Bộ gõ chạy sandbox nên tìm app chủ qua LaunchServices, và chỉ thấy các bản trong DerivedData.
- **Xử lý:** cài bằng `scripts/dev/install-app.sh` (chép bản mới cạnh bản cũ, chuyển bản cũ vào Thùng rác, đổi tên, chạy `lsregister -f`, mở lại app nếu nó đang chạy). Cài tay thì chạy `lsregister -f /Applications/Dau.app` sau khi chép; trong nhật ký của bộ gõ phải thấy `event=host-app-open`.

## Thử gõ bằng TextEdit để lại file trên iCloud Drive

- **Nguyên nhân:** TextEdit tự lưu mọi tài liệu "Untitled" vào `~/Library/Mobile Documents/com~apple~TextEdit/Documents/`; đóng mà không lưu vẫn để lại file, và file đó đồng bộ sang mọi thiết bị của người dùng.
- **Xử lý:** thử gõ bằng trang thử trong trình duyệt (`scripts/selftest/typing/run.sh safari chrome`) hoặc một app thử riêng. Không dùng TextEdit hay app nào tự lưu lên iCloud.

## `swift test` hoặc `xcodebuild` báo không thấy SDK

- **Nguyên nhân:** `xcode-select -p` trỏ tới Command Line Tools.
- **Xử lý:** không cần đổi `xcode-select`. Các script tự chọn Xcode (`scripts/lib/xcode.sh`); lệnh gõ tay thì thêm `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`.

## App Group không chạy, cài đặt không sang được bộ gõ

- **Nguyên nhân:** bản dựng ký ad-hoc (không có Team ID): macOS từ chối App Group mà không hiện hộp thoại nào.
- **Xử lý:** ký bằng một Team thật; Personal Team miễn phí là đủ (`CONTRIBUTING.md`). `doctor.sh` kiểm chứng chỉ có khớp Team trong `Config/Signing.xcconfig` không.

## Cửa sổ thử mở sai kích thước ở lần chạy sau

- **Nguyên nhân:** app thử bị dừng bằng `kill`, nên macOS khôi phục cửa sổ cũ ở lần mở sau của cùng bundle ID.
- **Xử lý:** thoát app thử bình thường (`NSRunningApplication.terminate`), như `scripts/selftest/settings-window/run.sh` đang làm. Một lần thoát bình thường là hết.
