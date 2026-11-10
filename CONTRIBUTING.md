# Đóng góp cho Dấu

Cảm ơn bạn muốn góp sức. Dấu là phần mềm tự do theo giấy phép GPLv3 ([LICENSE](LICENSE)); mọi đóng góp gửi vào repo cũng theo giấy phép này.

## Trước khi bắt đầu

- Đọc `docs/DECISIONS.md`. Đây là sổ quyết định, nguồn chuẩn duy nhất của dự án. Thay đổi trái với một nguyên tắc (N) hay quyết định (D) sẽ không được nhận; muốn đổi một quyết định thì mở issue nêu lý do trước khi viết mã.
- Việc lớn (tính năng mới, đổi hành vi gõ, đổi giao diện): mở issue trước để thống nhất. Sửa lỗi nhỏ thì gửi PR thẳng.
- Kiến trúc và luồng một phím: `docs/ARCHITECTURE.md`. Lộ trình: `docs/ROADMAP.md`.

## Bạn cần gì

| Bạn muốn làm | Cần tài khoản Apple? | Lệnh |
|---|---|---|
| Engine: quy tắc gõ, đặt dấu, chính tả, khôi phục từ (`Packages/DauEngine`) | Không | `swift test --package-path Packages/DauEngine` |
| Phần dùng chung (`Packages/DauShared`) | Không | `swift test --package-path Packages/DauShared` |
| Giao diện app chủ (`Apps/Dau`), kiểm bằng snapshot | Không | `swift test --package-path scripts/snapshot-settings` |
| Cài và gõ thử bộ gõ thật trên máy bạn | Có: Apple ID miễn phí của chính bạn | xem mục dưới |

Cần Xcode (README ghi bản đã thử) và XcodeGen (`brew install xcodegen`). Nếu `xcode-select -p` trỏ tới Command Line Tools, đặt `export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` trước các lệnh trên.

Chạy `scripts/dev/doctor.sh` trước: lệnh chỉ đọc này liệt kê máy bạn còn thiếu gì (Xcode, XcodeGen, chứng chỉ ký khớp Team, bản đã cài, nguồn nhập liệu) và lệnh sửa từng mục.

## Build và cài bộ gõ bằng Team của bạn

Bộ gõ và app chủ dùng chung cài đặt qua một App Group. macOS chỉ chấp nhận App Group khi bản dựng được ký bằng một Team ID thật; bản ký ad-hoc không chạy được phần này. Vì vậy bạn cần một Team, nhưng Personal Team miễn phí là đủ, không cần chương trình Apple Developer trả phí và không cần provisioning profile.

1. Mở Xcode, vào Settings › Accounts, đăng nhập Apple ID của bạn. Xcode tạo Personal Team và chứng chỉ "Apple Development" khi cần.
2. Chép file mẫu và điền Team ID của bạn (xem ở Settings › Accounts, hoặc trường `OU=` của chứng chỉ "Apple Development" trong Keychain Access):

   ```sh
   cp Config/Local.xcconfig.example Config/Local.xcconfig
   ```

   `Config/Local.xcconfig` bị git bỏ qua, nên Team của bạn không lọt vào commit. Không sửa Team trong `project.yml` hay `Config/Signing.xcconfig`.
3. Sinh project và cài bản Debug:

   ```sh
   xcodegen generate
   scripts/dev/install-input-method.sh
   ```

   Script in ra các bước bật Dấu trong System Settings. Thêm `--release` để dùng hằng ngày (bản Release không ghi nhật ký theo từng phím, D8 (Không telemetry)).

Lưu ý:

- **Bản bạn dựng là bản phát triển (D7 (Cập nhật và loại bản dựng))**, không phải bản chính thức. Chỉ quy trình phát hành trên CI ký Developer ID.
- **Bản của bạn thay bản Dấu đang cài.** Bundle ID giống bản chính thức và không đổi giữa các bản (D37 (Cài đặt bộ gõ)), nên trên một máy chỉ có một bản Dấu. Muốn quay lại bản chính thức thì cài lại từ bản tải về. Liệt kê mọi dấu vết của Dấu trên máy: `scripts/dev/clean-dau.sh` (không tham số thì chỉ đọc).
- **Dùng một Apple ID trên hai máy Mac:** mỗi máy tạo một chứng chỉ riêng, và tạo chứng chỉ ở máy này có thể làm chứng chỉ ở máy kia bị thu hồi (bản đã cài báo `CSSMERR_TP_CERT_REVOKED` khi kiểm chữ ký). Cách dùng chung: ở máy đang có chứng chỉ hợp lệ, mở Keychain Access › login › My Certificates, xuất "Apple Development: …" (kèm khoá riêng) ra file `.p12`, rồi nhập file đó ở máy kia.

## Engine và OpenKey

- Engine là mã của Dấu, viết từ đầu bằng Swift, không import Foundation hay AppKit.
- **Không chép mã từ OpenKey hay UniKey.** OpenKey chỉ là tài liệu tham khảo để hiểu hành vi; ghi hiểu biết bằng lời của bạn vào `docs/OPENKEY-NOTES.md`.
- Kết quả mong đợi trong test viết theo chính tả tiếng Việt và `docs/DECISIONS.md`, không lấy từ kết quả chạy OpenKey.
- Khẳng định về hiệu năng cần số đo (`swift test -c release` chạy test hiệu năng của engine).

## Giao diện

- Giao diện dùng thành phần của macOS, bố cục và khoảng cách theo System Settings (D9 (Giao diện)). Nội dung từng màn hình: `docs/UI.md`.
- Chuỗi giao diện đưa vào String Catalog (`Localizable.xcstrings`): khoá là câu tiếng Anh, có bản tiếng Việt (D41 (Ngôn ngữ giao diện); tên giao diện của macOS theo D38 (Chữ trên giao diện)), không ghi lời hứa chưa kiểm chứng (N5 (Chỉ hứa điều đã kiểm chứng)).
- Thay đổi giao diện: mở issue mô tả (kèm ảnh chụp hoặc phác thảo) trước khi viết mã.

## Quy ước

- Swift 6, strict concurrency. Test bằng Swift Testing.
- Tên định danh, comment và commit message bằng tiếng Anh; commit theo [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`…).
- `Dau.xcodeproj` được sinh từ `project.yml`: sửa `project.yml`, không sửa và không commit `.xcodeproj`.
- Sửa tài liệu trong `docs/` thì chạy `scripts/check-docs/check.sh`; nó bắt đường dẫn sai, số quyết định không tồn tại, cách nói đã bị thay.

## Gửi PR

- Mọi test liên quan xanh.
- Mô tả đã thử gì và thử ở đâu: ứng dụng nào, phiên bản macOS, Telex hay VNI.
- Báo lỗi gõ trong một ứng dụng: mở issue, kèm tên ứng dụng và ví dụ đã gõ. Đừng dán nội dung riêng tư.
