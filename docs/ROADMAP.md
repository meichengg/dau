# Lộ trình

Mỗi mốc kết thúc khi:
- test xanh;
- đã tự rà soát với `DECISIONS.md`;
- có tóm tắt ngắn (đã làm, số đo, câu hỏi còn mở).

Tình trạng từng mốc: `docs/PROGRESS.md`, bảng Mốc. Lịch sử việc đã chuyển khỏi file này: `docs/history/DOCS-LOG.md`.

## M0 — Khung dự án
- `git init`, `.gitignore`, `LICENSE` (GPLv3), `README.md` ngắn.
- `project.yml` (XcodeGen) có 2 target app (`Dau`, `DauInputMethod`) và 2 package local (`DauEngine`, `DauShared`).
- Bundle ID và Team ID để placeholder, hỏi người dùng.
- Xong khi: `xcodegen generate` và build Debug thành công cho cả hai target, universal.

## M1 — Engine
- Trước khi viết engine:
  - đọc mã nguồn OpenKey (clone ngoài repo);
  - lập `docs/OPENKEY-NOTES.md`: danh sách đầy đủ tính năng của engine, hành vi từng tính năng, ca biên, lỗi tìm thấy, và Dấu làm hay không làm (dẫn số D);
  - đối chiếu với `DECISIONS.md`; có mâu thuẫn mới thì nêu ra trước khi code.
- `VietEngine`:
  - Telex trước, rồi VNI và Telex đơn giản;
  - đặt dấu kiểu mới và kiểu cũ; bỏ dấu tự do;
  - chính tả âm tiết;
  - tự khôi phục từ không phải tiếng Việt;
  - gõ đúp phím dấu để giữ chữ gốc.
- Bộ test gồm ba nhóm:
  1. Ca viết tay:
     - các quy tắc khó: ươ, uyê, gi/qu, đ, dấu trên nguyên âm đôi;
     - nhóm từ trùng Anh–Việt (car/cả, sex/sẽ, has/há, test/tét, as/á) kèm cách gõ đúp;
     - tương tác gõ tắt phụ âm với khôi phục (fan → phan, big → big, bag → bang, wa → ưa).
  2. Ca biên rút ra từ `OPENKEY-NOTES.md`; kết quả mong đợi viết theo quy tắc chính tả và `DECISIONS.md`.
  3. Test hiệu năng.
- Xong khi: toàn bộ test xanh; số đo thời gian `handle` mỗi phím được ghi lại.

## M2 — Bộ gõ tối thiểu
- `DauInputMethod` với Telex, một input mode Tiếng Việt, thay chữ tại chỗ. Tiếng Anh gõ bằng U.S. của macOS (D2 (Chuyển Việt/Anh)).
- Script cài bản Debug vào `~/Library/Input Methods` và hướng dẫn người dùng bật thử.
- Giải quyết câu hỏi vị trí thay chữ: hỏi `selectedRange` ở mỗi phím có thay chữ, hay tự cộng dồn vị trí. Đã chốt hỏi ở mỗi phím (D11 (Kiểm tra ngữ cảnh)).
  - Đo chi phí `selectedRange` trên TextEdit, Safari, Chrome, Telegram, VS Code, Terminal (Telegram thay Slack).
  - Cập nhật `DECISIONS.md`.
- Xong khi: người dùng gõ được tiếng Việt trong TextEdit và Safari không gạch chân.

## M3 — Độ tin cậy
- Reset khi lệch ngữ cảnh.
- Phòng thủ đầu vào IMK (D18 (Phòng thủ với IMK)).
- Dự phòng bằng marked text theo danh sách tương thích (D13 (Gạch chân là đường lui cuối cùng)).
- Quy tắc theo ứng dụng (D5 (Quy tắc theo ứng dụng)).
- Kiểm chứng bằng VoiceOver rằng hệ thống tự đọc tên nguồn nhập liệu khi chuyển (D17 (Trợ năng)).
- Ma trận tương thích: bảng app × kết quả, lưu trong `docs/COMPATIBILITY.md`.
- Reset khi nguồn nhập liệu đổi mà bộ gõ không nhận `activateServer`: xong (6c1c055).
  - Đo 30/10/2026: chọn lại Dấu bằng `TISSelectInputSource` từ tiến trình khác thì từ đang gõ dở không được reset.
  - Bản sửa được kiểm bằng `to⇄cj␣` → "tocj"; tắt bộ nghe để đối chứng thì ra "tọc".
  - Kịch bản đo ban đầu (`to` → U.S. → Dấu → `o` ra "tô") không còn là lỗi: "tô" là hành vi của D20 (Thêm dấu cho từ đã gõ) sau sự kiện reset (D4 (Từ nước ngoài) × D20).
- Ghi tự sửa chính tả của macOS (giới hạn đã biết của D4) vào ma trận tương thích.

## M4 — App Cài đặt
- Dựng 4 mục theo `docs/UI.md`.
- App Group chia sẻ cài đặt; bộ gõ áp dụng thay đổi ngay.

## M5 — Onboarding, cài đặt, gỡ cài đặt
- Onboarding 3 bước theo `docs/UI.md`.
- Phát hiện bộ gõ cũ.
- Cài và gỡ bộ gõ.
- Xác minh câu hỏi mở về `TISEnableInputSource` và sandbox của app chủ.

## M6 — Hiệu năng dưới tải
- Tự gửi phím 20 phím/giây vào trang thử trong Safari, Chrome, VS Code và Telegram trong khi CPU đầy và `memory_pressure` đang chạy.
  - Không dùng TextEdit: nó tự lưu tài liệu thử lên iCloud Drive (`docs/TROUBLESHOOTING.md`).
  - Chrome và VS Code là hai app áp phím bất đồng bộ: lượt này trả lời câu hỏi của D13 (Gạch chân là đường lui cuối cùng), app bận có dồn phím dưới 10 ms không (`docs/research/COMPETITOR-COMPARISON.md`, phần A).
- Chỉ số:
  - văn bản cuối khớp 100%;
  - độ trễ p50/p99 phía bộ gõ;
  - bộ nhớ ổn định theo thời gian.
- So với gõ bằng U.S. (độ trễ nền) và với bộ gõ Telex có sẵn của macOS (`scripts/research/compare-ims/run.sh` so Dấu với Telex của Apple; phần U.S. cần thêm vào script).
  - Không so với OpenKey ở mốc này: phải cài phần mềm ngoài và người dùng phải cấp quyền Accessibility.
- Chốt ngưỡng vào `DECISIONS.md`; quyết định về D12 (Ưu tiên tiến trình) dựa trên số đo.
- Chạy tiếp ma trận tương thích `docs/COMPATIBILITY.md`:
  - app: Zalo, Discord, Messages, Pages, Numbers, Ghostty, Zed, Xcode, WebStorm;
  - kiểm lại Terminal không gửi ⌫ cho bộ gõ;
  - hai bài kiểm của ma trận cho phần lớn app: click chuột rồi gõ tiếp (gõ `tooi`, click chỗ khác, gõ `s`: chỉ thêm "s" ở chỗ mới) và mũi tên rồi gõ tiếp (gõ `tooi`, nhấn ←, gõ `s`: ra "tối", vì ← chỉ xoá bộ đệm còn D20 vẫn đặt dấu vào chữ trước con trỏ).

## M7 — Phát hành
- Làm trước: phần nền của M9 (Đa ngôn ngữ), theo D41 (Ngôn ngữ giao diện).
- Ký Developer ID, notarize, DMG.
- Sparkle 2: EdDSA, 2 kênh, phát hành theo đợt.
- JSON tương thích có chữ ký.
- GitHub Actions build từ tag, kèm artifact attestation.
- Homebrew cask với `auto_updates true`.
- Báo lỗi (URL issue điền sẵn), Quay về bản trước, Gỡ cài đặt.
- Loại bản dựng (D7 (Cập nhật và loại bản dựng), D25 (Nhận diện)):
  - cờ build chọn biểu tượng chuẩn, chỉ quy trình phát hành trên CI đặt;
  - mặc định là biểu tượng bản phát triển;
  - số build tăng dần, số hiển thị có chữ beta;
  - trang Cập nhật & hỗ trợ của bản phát triển ghi cấu hình build và commit (vẽ trên canvas trước).
- Xuất bộ file nhận diện theo `docs/BRAND.md` và gắn thẻ meta cho website. Bộ file gồm: biểu tượng app, biểu tượng bản phát triển, ảnh template thanh menu, favicon, ảnh Open Graph, ảnh xem trước GitHub, nền DMG.
- Việc cần tài khoản Apple Developer: chuẩn bị sẵn, dừng lại để người dùng thực hiện.
- Kiểm tra trước phát hành (cần người):
  - VoiceOver và Tab ("Điều hướng bàn phím") qua cửa sổ Cài đặt;
  - VoiceOver đọc đúng tên "Dấu – Tiếng Việt" khi chuyển nguồn (M3 mới xác nhận là hệ thống có đọc);
  - biểu tượng "V" trên thanh menu đơn sắc, đổi màu theo nền sáng/tối;
  - máy để tiếng Anh hẳn (menu app, tên "Dấu" trong Finder);
  - các sheet ở chế độ tối.

## M8 — Website
- Dựng trang tải về theo `docs/UI.md` (mục "Trang tải về") và `docs/BRAND.md`: trang tĩnh, responsive, thẻ meta và ảnh Open Graph, favicon.
- Công nghệ chọn ở đầu mốc và hỏi người dùng.
- Các ô số liệu và lời hứa chỉ điền từ kết quả M2 và M6 (N5 (Chỉ hứa điều đã kiểm chứng)).
- Xong khi: Lighthouse ≥ 95 ở cả bốn hạng mục trên điện thoại; kiểm toán ĐẠT.

## M9 — Đa ngôn ngữ
Mục đích: Dấu có thể được người Việt dùng rộng rãi, và người nước ngoài học tiếng Việt cũng muốn dùng.
Quy tắc ngôn ngữ, khoá chuỗi, tên nguồn và cách đặt ngôn ngữ riêng cho Dấu: D41.

**Phần nền — làm trước M7** (D41):
- Đổi String Catalog của app chủ và bộ gõ sang ngôn ngữ gốc tiếng Anh.
  - Khoá là câu tiếng Anh; viết đủ tiếng Anh cho mọi chuỗi.
  - Tiếng Việt thành bản dịch, giữ nguyên câu chữ hiện có.
  - Tên nguồn "Dấu – Vietnamese"; menu bộ gõ hết lẫn hai thứ tiếng trên máy tiếng Anh (trước đây "Dấu Settings…" nằm cạnh "Open Keyboard Settings…").
- Dạng số nhiều cho bản tiếng Anh ở các chuỗi có số.
- Bỏ việc ghim `vi` khi app chủ khởi động; vẫn nhận tham số `-AppleLanguages` để chạy kiểm theo ngôn ngữ.
- Script kiểm (vào `check.sh` hoặc script riêng): mọi khoá có bản `vi` và `en` đã dịch, không còn chuỗi "new"/"needs review".
- Test: `snapshot-settings` nạp catalog để so chữ đúng ngôn ngữ; bộ kiểm cửa sổ thật chạy ở `vi`.
- Bảng thuật ngữ tiếng Anh theo Apple (input source, Simple Telex, underline…), đặt ở một chỗ.
- Xong khi:
  - test xanh;
  - máy tiếng Việt thấy mọi chữ như trước;
  - chạy với `-AppleLanguages (en)` không còn chữ tiếng Việt, trừ bốn loại: tên "Dấu", tên giao diện macOS (D38 (Chữ trên giao diện)), nhãn của app khác chép nguyên, và ví dụ gõ (`docs/GLOSSARY.md`);
  - kiểm toán ĐẠT.

**Phần còn lại — M9:**
- Câu chữ tiếng Anh: đã chốt và sửa trong catalog (09/11/2026). Ngôn ngữ khác chỉ thêm khi có người nói thạo duyệt (D41).
- Hàng "Ngôn ngữ" trong Cài đặt chỉ sang mục ngôn ngữ riêng từng ứng dụng của macOS (D41).
  - Canvas trước, mã sau.
  - Câu hỏi mở: đo xem bộ gõ có đặt ngôn ngữ riêng được không.
- Không tự giải quyết được: mục "Open Dấu Settings…" của hệ thống (mục cuối menu nhập liệu) chỉ có khi bộ gõ khai báo được trang cài đặt riêng. Nghiên cứu riêng trước M9.
- Canvas: bản tiếng Anh cho các màn chính trước khi sửa mã.
- Bộ kiểm cửa sổ thật (`run.sh`) chạy theo từng ngôn ngữ vì độ dài chữ đổi bố cục. Chưa làm: hiện mọi lần mở đều ép tiếng Việt (`-AppleLanguages (vi)`).
- Trang tải về (M8) có bản tiếng Anh.
- Xong khi: máy để tiếng Anh hẳn thấy toàn bộ app, bộ gõ, onboarding, hộp thoại bằng tiếng Anh; `run.sh` đạt ở cả hai ngôn ngữ; kiểm toán ĐẠT.

## M10 — Học cách gõ
Mục đích: người dùng biết và học được cách gõ, và biết khác biệt về cách gõ giữa các bộ gõ.
- Trong app:
  - ô gõ thử giải thích từng bước (`vieetj` → vi → viê → việt, phím nào làm gì);
  - bảng tra Telex, Telex đơn giản, VNI;
  - theo D9 (Giao diện) (gọn như System Settings);
  - không lưu gì về chữ đã gõ (D8 (Không telemetry)).
- Trên trang web: trang "Dấu khác các bộ gõ khác thế nào".
  - Chỉ ghi khác biệt đã đo được (N5).
  - Nguồn: `docs/OPENKEY-NOTES.md` và bộ dữ liệu kiểm thử (đặt dấu kiểu mới/cũ, bỏ dấu tự do, khôi phục từ nước ngoài, uơ/ươ…).
  - Dẫn mục "Đã biết nhưng không làm" của `docs/DECISIONS.md`.
- Canvas trước, mã sau. Nội dung có bản tiếng Việt và tiếng Anh nếu M9 đã xong.
- Xong khi: người dùng duyệt nội dung trên canvas; mọi ví dụ trong phần học có test engine tương ứng; kiểm toán ĐẠT.
