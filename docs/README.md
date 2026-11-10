# Tài liệu

Mục lục mọi tài liệu trong `docs/`. Cách ghi (mỗi sự kiện ở một chỗ, khi nào sửa file nào) xem mục "Nguồn chuẩn" trong `CLAUDE.md`.

## Đang dùng

Đọc khi bắt đầu một phiên (thứ tự trong `CLAUDE.md`):

| File | Chứa gì |
|---|---|
| `docs/DECISIONS.md` | nguyên tắc N và quyết định D (nguồn chuẩn duy nhất), câu hỏi mở |
| `docs/ARCHITECTURE.md` | thành phần, build, luồng một phím |
| `docs/ROADMAP.md` | các mốc và tiêu chí hoàn thành |
| `docs/UI.md` | nội dung từng màn hình (mockup trên canvas) |
| `docs/ui/canvas/README.md` | bản chụp canvas thiết kế trong repo: ảnh và nguồn từng artboard đã duyệt (sinh bằng `scripts/design/render-canvas.sh`) |
| `docs/BRAND.md` | biểu tượng, màu, chữ, file nhận diện cần xuất |
| `docs/PROGRESS.md` | trạng thái hiện tại, bảng mốc, kế hoạch mốc đang làm, số đo, nhật ký theo ngày |

Tra khi cần:

| File | Chứa gì |
|---|---|
| `docs/UI-CHECKS.md` | danh sách kiểm giao diện và lệnh chạy |
| `docs/COMPATIBILITY.md` | ma trận ứng dụng: cách thử, kết quả, giới hạn đã biết |
| `docs/OPENKEY-NOTES.md` | đọc mã OpenKey: tính năng, ca biên, Dấu làm hay không |
| `docs/GLOSSARY.md` | thuật ngữ Anh–Việt của chuỗi giao diện (input source / nguồn đầu vào…) và cách viết câu tiếng Anh |
| `docs/TROUBLESHOOTING.md` | sự cố hay gặp khi phát triển (Dấu bị xám, app chưa đăng ký, TextEdit và iCloud…) và cách xử lý |

## Nghiên cứu

Mỗi chủ đề một file; kết luận hiện hành ở đầu file, mỗi khẳng định có nguồn.

| File | Chủ đề |
|---|---|
| `docs/research/M5-INSTALL.md` | cài, bật, nâng cấp, gỡ bộ gõ; lần cài đầu; bộ gõ cũ cần phát hiện |
| `docs/research/SYSTEM-SETTINGS-REFERENCE.md` | số đo giao diện của System Settings dùng làm chuẩn (script kiểm đọc theo) |
| `docs/research/SWIFTUI-WINDOW-API.md` | API cửa sổ của Apple cho cửa sổ Cài đặt (`NavigationSplitView`, thanh công cụ, tiêu đề, Lùi/Tiến), có nguồn; đối chiếu từng chỗ vá với API chính thức |
| `docs/research/EXTERNAL-TEST-INPUTS.md` | ca thử (chuỗi phím, không đáp án) gom từ bộ test của 10 bộ gõ tiếng Việt khác, để viết đáp án mù cho engine; ghi công ở `docs/research/external-test-inputs/NOTICE.md` |
| `docs/research/COMPETITOR-COMPARISON.md` | so sánh với bộ gõ khác (nghiên cứu cho M10): Telex của macOS trong Safari và Chrome (đã đo 09/11), khác biệt engine từ số đã có, nhịp gõ dưới 10 ms (dữ liệu công khai không đủ) |
| `docs/research/WEB-INPUT-DELAY.md` | luồng chính của trang web bận bao lâu khi gõ: INP theo origin (CrUX 09/2026, desktop) cho 17 trang, giới hạn khi suy ra rủi ro của thay chữ tại chỗ trong Chrome (D13 (Gạch chân là đường lui cuối cùng)) |

## Lưu trữ

Ghi lại quá khứ, không sửa theo hiện trạng.

| File | Chứa gì |
|---|---|
| `docs/history/PLANS.md` | kế hoạch của các mốc đã đóng |
| `docs/history/M2-TESTING.md` | gõ thử M2 trên máy thật và kết quả (cách thử hiện hành: `docs/COMPATIBILITY.md` mục 4) |
| `docs/history/M4-TESTING.md` | cách thử M4 trên máy thật |
| `docs/history/LOG-M0-M4.md` | nhật ký M0–M4 (29–30/10/2026), chuyển từ `PROGRESS.md` khi đóng M4; bảng số đo M1–M3 |
| `docs/history/LOG-M5.md` | nhật ký M5 (30/10–05/11/2026), chuyển từ `PROGRESS.md` khi đóng M5 |
| `docs/history/LOG-M5-M6.md` | nhật ký giữa M5 và M6 (05–08/11/2026), chuyển từ `PROGRESS.md` ngày 09/11/2026 |
| `docs/history/DECISIONS-LOG.md` | lịch sử từng nguyên tắc và quyết định của `DECISIONS.md`: ngày, ai chốt, bản trước, cách nói cũ |
| `docs/history/DOCS-LOG.md` | phần lịch sử (ngày chốt, bản trước, số phiên bản canvas) tách khỏi ARCHITECTURE, UI, ROADMAP, PROGRESS, CONTRIBUTING và file agent khi các file đó chuyển sang chỉ ghi hiện trạng (09/11/2026) |
| `docs/history/RESEARCH-LOG.md` | đoạn kết luận cũ đã bị thay của các tài liệu nghiên cứu, chuyển ra khi viết lại (09/11/2026) |
| `docs/history/COMMIT-MAP.md` | mã commit cũ → mới sau khi viết lại lịch sử (02/11/2026) |
| `docs/history/KICKOFF.md` | brief khởi động M0–M8 lúc bắt đầu dự án |
