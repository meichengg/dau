# So sánh Dấu với các bộ gõ khác

## Hiện trạng (09/11/2026)

- **Phần C đo xong (09/11/2026).**
  - Điều kiện: macOS 27.2, Dấu Release 24e61ec, 30 ms giữa hai phím, Safari và Chrome. Chi tiết ở mục "Kết quả phần C".
  - Tiếng Việt: Dấu và Telex của Apple ngang nhau (677/678 từ).
  - Từ tiếng Anh và từ trong mã: Dấu giữ nguyên 88/105, Apple 53/105.
  - Câu trộn Việt–Anh: Dấu 184/188 từ, Apple 169/188.
  - Khác biệt chỉ đến từ việc Dấu khôi phục từ không phải tiếng Việt (D4 (Từ nước ngoài)); Apple không khôi phục ("good" ra "gôd", "website" ra "ưebsite").
  - Cả hai cho cùng chữ ở Safari và Chrome.
  - Script tự gõ lúc đó chưa kiểm focus (sửa 09/11/2026, `docs/COMPATIBILITY.md` mục Hiện trạng): chưa loại được việc một số lượt gõ vào thanh địa chỉ thay vì ô của trang. Chữ của Dấu vẫn trùng engine nên kết quả về chữ đứng được; chỉ chưa chắc là ô nào.
  - Đưa lên website (M10, Học cách gõ) chỉ kèm các giới hạn ở mục đó (N5 (Chỉ hứa điều đã kiểm chứng)).
- **Phần B xong (09/11/2026).**
  - Chạy lại trên engine HEAD (sau faff8a3): số ca và số theo lớp không đổi so với 05/11 (10.303 ca; khác: A 435, B 1.493, C 73, D 0, E 0, X 4).
  - Bảng theo chủ đề cho M10 đã có sẵn ở `docs/research/EXTERNAL-TEST-INPUTS.md` mục 9.3–9.5, không dựng bảng mới.
- **Phần A dừng, không trả lời được bằng dữ liệu công khai (09/11/2026).**
  - Bộ dữ liệu duy nhất tải được công khai, có dấu thời gian từng phím của nhiều người, là bộ 136 triệu lần gõ phím của Đại học Aalto (Dhakal và cộng sự, CHI 2018, https://userinterfaces.aalto.fi/136Mkeystrokes/).
  - Bộ này đo bằng trình duyệt, và chính bài báo ghi độ chính xác của cách đo khoảng 10–15 ms, nên không phân biệt được hai phím cách nhau dưới 10 ms.
  - Bài báo không công bố tỉ lệ cặp phím dưới 10 ms; chỉ số "rollover" trong bài (phím trước còn đang giữ khi nhấn phím sau) là chỉ số khác.
  - Giấy phép ghi "nghiên cứu, phi thương mại, ghi nguồn", chưa rõ có cho công bố số phái sinh không.
  - Bộ Buffalo phải xin qua email; KeyRecs chỉ có độ trễ theo cặp chữ, gõ câu cố định.
  - Không đo trên máy người dùng thay thế (mục "Phần A").
- **Câu hỏi của phần A đặt sai chỗ (đo ở M6, 09/11/2026, `docs/PROGRESS.md` nhật ký): app bận không dồn phím; lỗi khi Chrome bận là vị trí con trỏ cũ, ở nhịp gõ bình thường.** Giả thuyết ban đầu:
  - Phím dồn dưới 10 ms ở bộ gõ có thể không do người gõ nhanh, mà do app đích bận (Chrome đang tải trang, VS Code đang lập chỉ mục) rồi chuyển một loạt phím đã xếp hàng cùng lúc.
  - Nếu đúng thì bài test tải nặng của M6 (Hiệu năng dưới tải) mới là chỗ trả lời câu hỏi của D13 (Gạch chân là đường lui cuối cùng).

## Phạm vi

Đây là việc nghiên cứu cho M10, trang "Dấu khác các bộ gõ khác thế nào". Nó **không thuộc M6 và không chặn phát hành**. Phần A trả lời một câu hỏi của D13.

Ba câu hỏi:
- (A) Gõ tay thật có tạo ra hai phím cách nhau dưới 10 ms không (D13, `docs/COMPATIBILITY.md` mục 6.2).
- (B) So với các bộ gõ khác thì Dấu khác ở đâu, ở mức engine.
- (C) So với bộ gõ tiếng Việt có sẵn của macOS thì tiếng Việt thông dụng và từ tiếng Anh ra sao trong ứng dụng thật.

## Phần A. Nhịp gõ thật: dùng dữ liệu công khai, không đo trên người dùng

Trạng thái: dừng (xem Hiện trạng).

- Tìm bộ dữ liệu nhịp gõ công khai của nhiều người gõ thật (ví dụ bộ dữ liệu 136 triệu lần gõ phím của Đại học Aalto, CHI 2018).
  - Kiểm giấy phép trước khi dùng.
  - Chỉ tải về `build/` (không commit), ghi nguồn.
- **Kết quả cần có:** phân bố khoảng cách giữa hai phím liên tiếp; tỉ lệ cặp phím cách nhau dưới 10 ms, theo tốc độ gõ của người gõ.
- **Giới hạn:**
  - Người trong dữ liệu gõ tiếng Anh. Telex có cặp phím riêng ("ee", "ow", phím dấu ở cuối từ), nên chỉ ước lượng được, ghi rõ như vậy.
  - Đổi D13 hay không là việc của người dùng, dựa trên số này.
- Không tìm được dữ liệu có giấy phép phù hợp thì ghi lại và dừng phần A. Không thay bằng việc ghi nhật ký trên máy người dùng.

## Phần B. Khác biệt ở mức engine: dùng lại số đã có

Trạng thái: xong (xem Hiện trạng).

- `docs/research/EXTERNAL-TEST-INPUTS.md` mục 9 đã so 10.303 ca với đáp án test của 10 bộ gõ khác (có Gõ Nhanh và XKey; XKey có engine chuyển từ OpenKey). Không đo lại.
- **Kết quả:** bảng khác biệt theo chủ đề (từ tiếng Anh, đặt dấu, uơ/ươ, Backspace…), mỗi chủ đề có ví dụ và số D, đã có ở `docs/research/EXTERNAL-TEST-INPUTS.md` mục 9.3–9.5; trang M10 dùng bảng đó. Chạy lại offline bằng `scripts/research/external-tests/compare.sh`, không chiếm màn hình.
- **Giới hạn:** đáp án test của họ cho biết hành vi engine theo cấu hình test, không phải hành vi trong ứng dụng thật với cài đặt mặc định. Ghi rõ như vậy.

## Phần C. So với bộ gõ có sẵn của macOS trong ứng dụng thật

Bộ gõ của Apple chỉ đo được bằng cách gõ thật, vì không có engine để chạy riêng.
Trên máy này `com.apple.inputmethod.VietnameseIM.VietnameseTelex` đã được bật sẵn (đọc bằng TIS 09/11/2026), nên không phải đổi cài đặt hệ thống.

- **Bộ gõ:** Dấu (bản Release đã cài, mặc định theo D15 (Cài đặt mặc định)) và Apple Telex.
- **Dữ liệu** (chỉ dùng phần cả hai cùng hỗ trợ: Telex thứ tự chuẩn, không bỏ dấu tự do, không gõ tắt):
  - 60 câu văn xuôi hiện đại tự viết (`scripts/research/compare-ims/vi-sentences.txt`).
  - 20 câu trộn Việt–Anh (`mixed-sentences.txt`).
  - Khoảng 100 từ tiếng Anh và từ trong mã, hầu hết có phím dấu hoặc phím biến đổi của Telex (`en-words.txt`).
  - `cases.swift` chuyển sang phím Telex thứ tự chuẩn, tổng khoảng 5.700 phím.
  - Kiểm offline bằng engine của Dấu trước khi gõ thật (09/11/2026): 677/678 từ tiếng Việt đúng, từ còn lại là "taxi" ra "tãi" (D4), nên bộ chuyển phím đúng.
- **Cách chấm:**
  - Tiếng Việt đúng khi ra đúng chữ gốc sau chuẩn hoá NFC, chấp nhận cả hai kiểu đặt dấu (hoà/hòa).
  - Tiếng Anh đúng khi giữ nguyên chữ đã gõ. Từ vừa là tiếng Anh vừa là âm tiết tiếng Việt hợp lệ ("car", "as") tính riêng một nhóm, không chấm đúng sai (D4).
  - Đáp án lấy từ chữ gốc, không từ kết quả của bộ gõ nào (D10 (Engine tự viết)).
- **Ứng dụng:**
  - Trang thử trong Safari (WebKit, đúng ở mọi tốc độ ở M2 (Bộ gõ tối thiểu); dùng thay app thử riêng vì script đã có sẵn) và Chrome.
  - Khoảng cách giữa hai phím 30 ms; 120 ms bỏ, vì ở 30 ms Dấu đã đúng trong cả hai app (M3, Độ tin cậy) và lượt chạy sẽ dài gấp bốn.
- **Cách chạy:** `scripts/research/compare-ims/run.sh`, gọi `scripts/selftest/typing/run.sh` với tuỳ chọn `--source` (chọn nguồn theo ID) và `--save` (lưu chữ đọc lại).
  - Mọi thứ build xong trước, rồi báo người dùng "sẵn sàng, khoảng 20 phút".
  - Chạy một lượt khi được đồng ý, báo lúc bắt đầu và lúc xong.
  - Sau đó chọn lại nguồn đầu vào như trước khi chạy.
- Lưu mọi ca sai (chuỗi phím và chữ ra) trong `build/`, không commit.

## Để sau

Các bộ gõ chặn phím (OpenKey, Gõ Nhanh, chế độ chặn phím của XKey) trong ứng dụng thật: chúng cần cài phần mềm bên ngoài và cấp quyền Accessibility.
Chỉ làm khi phần B và C cho thấy cần, và theo cách không cần người dùng làm gì thêm.

## Thứ tự

1. Phần A và B (offline, không chiếm màn hình). Đã làm: B xong, A dừng.
2. Chuẩn bị phần C: dữ liệu, đáp án, script, build. Đã làm.
3. Hỏi giờ, chạy phần C một lượt. Đã làm (09/11/2026).
4. Ghi kết quả vào mục Hiện trạng và thân bài file này. Quyết định nào đáng xem lại (D13, D4) thì nêu kèm số đo.

## Kết quả phần C (09/11/2026)

Chạy `scripts/research/compare-ims/run.sh` một lượt, 22 phút 29 giây, khoảng 5.700 phím mỗi app.
Máy phát triển, macOS 27.2; Dấu bản Release 24e61ec, mặc định theo D15; Telex của Apple (`com.apple.inputmethod.VietnameseIM.VietnameseTelex`) với cài đặt sẵn có trên máy.
Chữ đọc lại và bảng điểm ở `build/compare-ims/20261109-122753/` (không commit).

| Nhóm | Số từ | Dấu | Telex của Apple |
|---|---|---|---|
| Câu tiếng Việt | 678 | 677 | 677 |
| Câu trộn Việt–Anh | 188 | 184 | 169 |
| Từ tiếng Anh và từ trong mã | 105 | 88 | 53 |

- Safari và Chrome cho đúng cùng một chữ, với cả hai bộ gõ. Chữ của Dấu trong hai app trùng từng byte với engine chạy offline.
- **Tiếng Việt:** từ sai duy nhất của cả hai là "taxi" ra "tãi" (âm tiết hợp lệ, tiếng Việt thắng theo D4).
- **Từ Dấu sai (17), Apple cũng sai y như vậy:**
  - 7 từ có chữ cái đôi trùng phím dấu mất một chữ: password, coffee, office, assert, offset, session, error (D26 (Gõ đúp phím dấu); hệ quả đã chấp nhận).
  - 10 từ vừa là tiếng Anh vừa ra âm tiết tiếng Việt hợp lệ (D4): seems → sếm, see → sê, door → dổ, moon → môn, soon → sôn, horse → hoé, mix → mĩ, box → bõ, max → mã, major → mảo.
  - Trong câu trộn thêm reset → rết, test → tét.
- **Từ chỉ Apple sai (35 từ đơn, 15 từ trong câu trộn):** từ không phải âm tiết tiếng Việt vẫn bị biến đổi, vì Apple không khôi phục: windows → ưindows, good → gôd, book → bôk, google → gôgle, software → sờtare, work → ửok, push → púh, website → ưebsite, design → déign…

Giới hạn của phép đo này:
- Một máy, một lượt, chỉ 30 ms giữa hai phím, chỉ Telex thứ tự chuẩn.
- Dữ liệu do Dấu tự viết. Danh sách từ tiếng Anh cố ý chọn từ có phím dấu hoặc phím biến đổi của Telex (từ không có các phím đó thì bộ gõ nào cũng để nguyên), nên 88/105 và 53/105 không phải tỉ lệ trên tiếng Anh nói chung.
- Cách chấm bỏ qua vị trí dấu thanh (hoà/hòa coi như nhau), nên không bắt được dấu đặt sai nguyên âm.
- Không đo bỏ dấu tự do, kiểu đặt dấu, Backspace, D20 (Thêm dấu cho từ đã gõ): chỉ phần cả hai bộ gõ cùng hỗ trợ.
