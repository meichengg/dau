# Nhật ký tài liệu

Lưu trữ phần lịch sử đã chuyển ra khỏi các tài liệu sống khi chúng được viết lại để đọc hiện trạng cho nhanh (09/11/2026, người dùng duyệt cách làm): ngày, người chốt, số phiên bản canvas, cách nói và mã nội bộ của các vòng làm việc trước. Tài liệu này ghi lại quá khứ, không sửa cho khớp hiện trạng; hiện trạng chỉ đọc ở tài liệu gốc. Mỗi mục "## <file>" gồm các đoạn chuyển nguyên văn từ file đó, kèm mục nguồn.

## docs/ARCHITECTURE.md

- Mục "DauShared", `DauSettings`/`AppRule`: "Giải mã dễ dãi: khoá lạ hoặc khoá cũ (`rememberModePerApp`, `mode` của quy tắc, từ bản trước 30/10/2026) bị bỏ qua" (bản hiện hành bỏ cụm "từ bản trước 30/10/2026").
- Mục "DauInputMethod", thay tại chỗ: "(N3, cách A đã chốt trong `DECISIONS.md`)". Cách A: hỏi `selectedRange` một lần ở phím có thay chữ để có vị trí tuyệt đối (mục "Vị trí thay chữ: hỏi con trỏ ở mỗi phím hay tự tính" của `docs/DECISIONS.md`).
- Mục "Đổi nguồn nhập liệu không qua `activateServer`": "(M3)" trong tiêu đề; "Kịch bản cũ của ROADMAP (`to` ⇄ `o`) không còn phân biệt được: sau reset, D20 đọc lại "to" và `o` cho "tô" đúng như D20 định."
- Mục "Thêm dấu cho từ đã gõ": các nhãn "E8 ở D20" (phím chữ cái, mục "Chữ cái gõ sát chữ có sẵn" của D20), "ngoại lệ (b)", "ngoại lệ (a)", "ngoại lệ (c)" (các ngoại lệ (a) chữ hoa giữa từ, (b) từ có sẵn không phải tiếng Việt, (c) phím dấu không áp dụng được, đều ở D20), "D20, phạm vi (2)" (chờ 50 ms) và "D20, phạm vi (1)" (không áp dụng ở app gạch chân); "D20 ngoại lệ (b), D33" ở `seedOverflow`.
- Mục "Khởi chạy bộ gõ: người dùng hay hệ thống": tiêu đề "(02/11/2026, `LaunchOrigin.swift`, `InputMethodAppDelegate.swift`)".
- Mục "Đo lường": "ở bản Debug chỉ ghi khi khoá `DauPerfLog` được đặt trong global domain (02/11/2026)".
- Mục "Build": "(Xcode không thay biến trong khoá plist, đã thử 30/10/2026)".

## docs/UI.md

- Mục "Onboarding", dòng cuối thanh bước: "(N5; người dùng chốt 05/11/2026, canvas phiên bản 125)" (đi sau câu "không hứa macOS hỏi mấy lần, vì \"Thử lại\" sau Don't Allow làm hộp thoại hiện lại").
- Mục "Cửa sổ Cài đặt": "Artboard: các artboard \"Cài đặt – …\", canvas phiên bản 127."
- Mục "Cập nhật & hỗ trợ", hàng "Ngôn ngữ": "(D41; artboard \"Cài đặt – hàng Ngôn ngữ (theo macOS)\" và \"(Dấu đặt riêng English, macOS tiếng Việt)\", canvas phiên bản 136, người dùng duyệt 08/11/2026)".
- Mục "Cập nhật & hỗ trợ", hàng "Ngôn ngữ", phần chờ mở lại: "(artboard \"Cài đặt – hàng Ngôn ngữ (đã đổi sang English, chưa mở lại Dấu)\", canvas phiên bản 137)".
- Mục "Cập nhật & hỗ trợ": "Nút gỡ cài đặt dùng dạng `role: .destructive` của hệ thống (người dùng chốt 02/11/2026, D9)."

## docs/UI-CHECKS.md

- Mục "Lệnh", lần mở 6: "Giao diện hệ thống đang không dùng (`--appearance light|dark`; `-AppleInterfaceStyle` truyền như đối số không đổi được giao diện cửa sổ, đo 02/11/2026)" (số đo vẫn giữ trong file, cạnh câu giải thích).
- Mục "Lệnh", cuối phần cửa sổ thật: "Bài học 02/11/2026: một `layoutProbe` đặt ngoài `listRowInsets` làm ảnh chụp ngoài màn hình lệch so với cửa sổ thật mà các kiểm vẫn đạt. Từ 03/11/2026 cửa sổ Cài đặt chỉ được đo trên cửa sổ thật; `layoutProbe` chỉ còn cho ảnh chụp onboarding và bảng so mockup, luôn cùng một cấu trúc view dù có probe hay không, và chỉ đặt trên nội dung hàng hoặc cả control, không bọc ngoài modifier của hàng list."
- Danh sách, mục 16: "(đo 05/11/2026: trước khi sửa, ⌘[ đổi trang và làm sheet tự đóng)".
- Danh sách, mục 18: "(đo 06/11/2026 trên bản sidebar cố định đầu tiên)".
- Tiêu đề mục cuối: "Quy tắc thanh cuộn (chốt 29/10/2026)".

## docs/BRAND.md

- Không có đoạn lịch sử nào cần chuyển. Chỉ tách câu dài thành gạch đầu dòng; số đo "30/10/2026" của biểu tượng thanh menu giữ nguyên cạnh số.

## docs/ROADMAP.md

- M2: "**Giải quyết câu hỏi A/B** (đã chốt cách A, D11) (vị trí thay chữ): đo chi phí `selectedRange` trên TextEdit, Safari, Chrome, Telegram (thay Slack, 30/10/2026), VS Code, Terminal; cập nhật `DECISIONS.md`." (Trong bản hiện hành: "câu hỏi A/B" = hỏi `selectedRange` ở mỗi phím hay tự cộng dồn vị trí; "cách A" = hỏi ở mỗi phím, theo `docs/DECISIONS.md`, mục "Vị trí thay chữ".)
- M3: "Reset khi nguồn nhập liệu đổi mà bộ gõ không nhận `activateServer` — xong (6c1c055). Đo 30/10/2026 lúc M2: chọn lại Dấu bằng `TISSelectInputSource` từ tiến trình khác thì từ đang gõ dở không được reset. Kịch bản đo cũ (`to` → U.S. → Dấu → `o` ra "tô") nay không còn là lỗi: "tô" là hành vi của D20 sau sự kiện reset (D4 × D20). Bản sửa được kiểm bằng `to⇄cj␣` → "tocj" (tắt bộ nghe để đối chứng: "tọc")."
- M6: "Chạy tiếp ma trận tương thích `docs/COMPATIBILITY.md` (người dùng chốt 30/10/2026): … K5, K6 cho phần lớn app (K6 theo D4 × D20)."
- M7: "Làm trước: phần nền đa ngôn ngữ (mục M9, D41)."; "Kiểm tra trước phát hành (cần người, hoãn từ M4)"; "VoiceOver đọc đúng tên "Dấu – Tiếng Việt" khi chuyển nguồn (M3 mới xác nhận là hệ thống có đọc, D17); biểu tượng "V" trên thanh menu đơn sắc, đổi màu theo nền sáng/tối (hoãn từ M2/M3, người dùng chốt 30/10/2026)".
- M9: "Người dùng nêu 04/11/2026: Dấu có thể thành bộ gõ được người Việt dùng rộng rãi, và người nước ngoài học tiếng Việt cũng muốn dùng."; "**Phần nền — làm trước M7** (D41, người dùng chốt 06/11/2026)".
- M10: "Người dùng nêu 04/11/2026: người dùng biết và học được cách gõ, và khác biệt về cách gõ giữa các bộ gõ."

## docs/PROGRESS.md

- Trạng thái hiện tại: "Giữa M5 và M6: M5 đóng 05/11/2026; M6 (hiệu năng dưới tải) chưa bắt đầu, lập kế hoạch ở đầu mốc. Từ 05/11 làm ngoài mốc: phần nền đa ngôn ngữ của M9 (D41; mã xong 06/11, hàng "Ngôn ngữ" xong 08/11, nhật ký ở `docs/history/LOG-M5-M6.md`), rút gọn script và test (09/11, nhật ký dưới đây)." (Nội dung hiện hành giữ trong bản viết lại; dòng này ghi để thấy cách nói cũ.)
- Mốc, bảng cũ, cột "Ghi chú" của M9 và M10: "thêm 04/11; phần nền (D41) xong 06–08/11, còn duyệt câu chữ tiếng Anh" và "thêm 04/11" (hai mốc M9, M10 được thêm ngày 04/11).
- Mốc, hàng M2, cột "Ghi chú" cũ: "cách A" (cách A: hỏi `selectedRange` ở mỗi phím có thay chữ, theo `docs/DECISIONS.md`).
- Mốc, hàng M5, cột "Ghi chú" cũ: "T4 bỏ" (T4: lượt đo trên tài khoản macOS mới; bỏ theo `docs/history/DECISIONS-LOG.md`, 04/11/2026).
- Ghi nhớ cho M7: "(hoãn từ kiểm toán M3)" ở gợi ý "Báo lại để bản sau xử lý đúng cho ứng dụng đó"; "(hoãn từ M3, ARCHITECTURE.md)" ở `temporary-exception.mach-register.global-name`; "M7: đưa phép đếm cấp phát (`malloc_logger`) vào CI (người dùng giữ cho M7, 09/11/2026; chưa làm CI trước đó)."

## .claude/agents/app-ui-dev.md

- Mục "Quy tắc", bản cũ (các sự kiện đã có chỗ ở nơi khác: `docs/DECISIONS.md`, `docs/UI.md`, `docs/GLOSSARY.md`):
  - "Nội dung theo `docs/UI.md` và artboard; bố cục, khoảng cách, control theo System Settings với thông số mặc định (D9, số đo trong `docs/research/SYSTEM-SETTINGS-REFERENCE.md`). Không dùng màu thương hiệu trong app (D25)."
  - "Làm theo artboard phiên chính đưa (canvas đã được người dùng duyệt trước khi giao mã)."
  - "Chuỗi giao diện trong String Catalog: khoá là câu tiếng Anh, có bản tiếng Việt (D41), thuật ngữ theo `docs/GLOSSARY.md`; chạy `scripts/check-l10n/check.sh`. Không đưa lời hứa chưa kiểm chứng (N5); để ô trống dạng `[...]`."
  - "Có giao diện tối, VoiceOver đọc được mọi control, phím Tab đi hết các control."

## .claude/agents/engine-dev.md

- Mục "Quy tắc", bản cũ:
  - "Bắt buộc có test cho các ca chéo tính năng: từ trùng Anh–Việt (car/cả, sex/sẽ, has/há, as/á, test/tét) và gõ đúp phím dấu; gõ tắt phụ âm × khôi phục (fan → phan, big → big, bag → bang, wa → ưa); "Thêm dấu cho từ đã gõ" đọc chữ hiển thị (D20)."
  - "Đường nóng: không cấp phát mỗi phím, không `String`/`any`/closure. Có test hiệu năng; ghi số đo thời gian `handle` mỗi phím."

## .claude/agents/imk-dev.md

- Mục "Quy tắc", bản cũ:
  - "Mỗi phím tối đa một lần gọi `insertText`; cách lấy vị trí thay chữ theo N3/D11."
  - "Không trạng thái toàn cục; mỗi client một `VietEngine`. Phòng thủ với mọi đầu vào từ IMK (D18)."
  - "Tiến trình bộ gõ: sandbox, App Group, **không** quyền mạng (N2)."

## .claude/agents/auditor.md

- Danh sách kiểm tra, mục 3, bản cũ: "tính năng đã loại bỏ (macro, phím chuyển riêng, từ điển tiếng Anh, NSSpellChecker, OpenKey làm đáp án…)."
- Mục 4, bản cũ: "(đường dẫn, số dòng, số D/N, cách nói đã bị thay)" và "(String Catalog, D41)" mô tả hai script.

## .claude/agents/web-dev.md

- Mục "Quy tắc", bản cũ: "nhận diện theo `docs/BRAND.md` (D25). Tên luôn viết "Dấu", không bao giờ "dau" đứng một mình (D24)."; "Ngôn ngữ theo D41 khi phần M9 của trang web đến lượt."

## .claude/agents/release-eng.md

- Không có gì chuyển (chỉ đổi dạng trình bày và tên đầy đủ của D24, tên mốc).

## .claude/agents/researcher.md

- Không có gì chuyển (chỉ đổi dạng trình bày).

