# Dấu

Bộ gõ tiếng Việt cho macOS, mã nguồn mở (GPLv3), miễn phí trọn vẹn. Dấu là một nguồn đầu vào của macOS dựng trên InputMethodKit: nó thay chữ tại chỗ qua API nhập liệu của Apple, không giả lập phím Backspace và không cần quyền Trợ năng như các bộ gõ chặn phím kiểu OpenKey.

**Dự án đang phát triển, chưa có bản phát hành.** Đang ở mốc nào và còn gì mở: [`docs/PROGRESS.md`](docs/PROGRESS.md); các mốc tới khi phát hành: [`docs/ROADMAP.md`](docs/ROADMAP.md).

## Dấu khác các bộ gõ khác ở đâu

- **Tự trả lại từ không phải tiếng Việt** khi kết thúc từ ("windows", "good", "website" giữ nguyên), không cần từ điển tiếng Anh: D4 (Từ nước ngoài). Đo trên một bộ thử tự viết, gõ trong Safari và Chrome: tiếng Việt Dấu và bộ gõ Telex có sẵn của macOS ngang nhau; với từ tiếng Anh và từ trong mã có phím dấu Telex, Dấu giữ nguyên 88/105 từ, bộ gõ của macOS 53/105. Điều kiện và giới hạn của phép đo: [`docs/research/COMPETITOR-COMPARISON.md`](docs/research/COMPETITOR-COMPARISON.md).
- **Quy tắc gõ viết thành luật có lý do**, mỗi luật một mục trong [`docs/DECISIONS.md`](docs/DECISIONS.md): đặt dấu kiểu mới, bỏ dấu tự do, Backspace đặt lại dấu theo vần còn lại, thêm dấu cho từ đã gõ…
- **Riêng tư:** tiến trình bộ gõ không có quyền mạng, không telemetry, không ghi gì theo từng phím ở bản phát hành.
- **Cố ý không làm** những gì macOS đã có (macro, phím chuyển Việt/Anh riêng, bảng mã cũ…): danh sách và lý do ở mục "Đã biết nhưng không làm" của `docs/DECISIONS.md`.

## Bắt đầu ở đây

| Bạn là | Đọc |
|---|---|
| Người muốn đóng góp | [CONTRIBUTING.md](CONTRIBUTING.md), rồi `docs/ARCHITECTURE.md` |
| Người duy trì, bắt đầu một phiên làm việc (kể cả trên máy khác) | `docs/PROGRESS.md`, rồi thứ tự đọc trong [CLAUDE.md](CLAUDE.md) |
| AI agent (Claude Code) | [CLAUDE.md](CLAUDE.md): thứ tự đọc, cách điều phối, các luật làm việc đã rút ra |
| Người xem thiết kế | [`docs/ui/canvas/README.md`](docs/ui/canvas/README.md): ảnh chụp mọi màn hình đã duyệt |

**Máy mới:** chạy `scripts/dev/doctor.sh` trước. Lệnh chỉ đọc này liệt kê máy còn thiếu gì để build, test và chạy Dấu (Xcode, XcodeGen, chứng chỉ ký, bản đã cài, nguồn nhập liệu) kèm lệnh sửa từng mục. Sự cố hay gặp khi phát triển: [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md). Mục lục mọi tài liệu: [`docs/README.md`](docs/README.md).

## Cấu trúc

| Thư mục | Nội dung |
|---|---|
| `Apps/Dau` | app chủ SwiftUI, không sandbox (D37 (Cài đặt bộ gõ)): Cài đặt, cài/gỡ bộ gõ, cập nhật |
| `Apps/DauInputMethod` | bộ gõ (input method IMK), sandbox, không có quyền mạng |
| `Packages/DauEngine` | engine xử lý phím, Swift thuần, không dùng Foundation/AppKit |
| `Packages/DauShared` | phần dùng chung giữa app chủ và bộ gõ |

`Dau`, `DauInputMethod`… là định danh kỹ thuật của Dấu (tên target, tên gói), không phải tên hiển thị.

## Sinh project và build

Đã thử với Xcode 27.1 và Swift 6.4. Project Xcode được sinh từ `project.yml` bằng [XcodeGen](https://github.com/yonaskolb/XcodeGen); không sửa tay và không commit `Dau.xcodeproj`.

```sh
brew install xcodegen
xcodegen generate
```

Nếu `xcode-select -p` đang trỏ tới Command Line Tools thay vì Xcode, đặt `DEVELOPER_DIR` cho mọi lệnh `xcodebuild`, `xcrun`, `swift` (không cần đổi `xcode-select`):

```sh
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
```

Build Debug universal (Apple silicon + Intel):

```sh
xcodebuild -project Dau.xcodeproj -scheme Dau -configuration Debug \
  -destination 'generic/platform=macOS' build
xcodebuild -project Dau.xcodeproj -scheme DauInputMethod -configuration Debug \
  -destination 'generic/platform=macOS' build
```

Không có `-destination 'generic/platform=macOS'`, bản Debug chỉ build cho kiến trúc của máy đang chạy: Xcode build các Swift package local theo kiến trúc đang chạy, bỏ qua `ONLY_ACTIVE_ARCH` của app. Bản Release luôn là universal.

Scheme `Dau` build cả bộ gõ và nhúng nó vào `Dau.app/Contents/Library/Input Methods/DauInputMethod.app`.

## Chạy test

```sh
swift test --package-path Packages/DauEngine
swift test --package-path Packages/DauShared
```

Với Command Line Tools (Swift 6.4), `swift test` báo lỗi không tìm thấy plugin `TestingMacros` khi build sạch; dùng toolchain của Xcode qua `DEVELOPER_DIR` như trên.

## Định danh

Bundle ID đã chốt (D24 (Tên và định danh)): `project.yml` dùng `BUNDLE_ID_PREFIX = com.codefastlabs.dau` (app `com.codefastlabs.dau`, bộ gõ `com.codefastlabs.dau.inputmethod.Dau`, App Group `M58DANM3ZP.com.codefastlabs.dau.shared`). `DEVELOPMENT_TEAM` nằm trong `Config/Signing.xcconfig`: Personal Team miễn phí `M58DANM3ZP`, trừ khi `Config/Local.xcconfig` (git bỏ qua) đặt team khác; mọi cấu hình ký tự động "Apple Development" (App Group cần Team ID thật, xem đầu `project.yml`). Build dưới team của bạn: xem [CONTRIBUTING.md](CONTRIBUTING.md). Bản phát hành ký Developer ID ở M7 (phát hành). Bộ gõ chỉ có một input mode, `com.codefastlabs.dau.inputmethod.Dau.vi` (D2 (Chuyển Việt/Anh)). Khi đổi `BUNDLE_ID_PREFIX`, phải sửa cả ID này trong `Apps/DauInputMethod/Info.plist` và `Apps/DauInputMethod/Resources/InfoPlist.xcstrings`, vì Xcode không thay biến trong khoá plist (chỉ thay trong giá trị).

## Giấy phép

GPLv3, xem [LICENSE](LICENSE).
