# Sổ quyết định

Nguồn chuẩn duy nhất cho mọi nguyên tắc (N) và quyết định (D) đang có hiệu lực của dự án; mỗi quyết định ghi nguyên tắc nó dựa vào. Mỗi mục gồm số và tên ngắn (tài liệu khác dẫn dạng "D4 (Từ nước ngoài)"), luật hiện hành, rồi **Vì sao**; ngày, người quyết và các bản trước nằm ở `docs/history/DECISIONS-LOG.md`. Muốn đổi một quyết định: sửa luật và lý do ở đây, ghi ngày và bản cũ vào `docs/history/DECISIONS-LOG.md`, trong cùng commit với thay đổi mã.

## Nguyên tắc

- **N1. Không làm lại việc hệ thống đã có.** Hệ thống đã có thì Dấu không tự làm lại. Ngoại lệ phải có lý do đo được (xem D4 (Từ nước ngoài)).
- **N2. Bộ gõ không có quyền mạng.** Tiến trình bộ gõ không có quyền mạng. Mọi kết nối nằm ở app chủ (cập nhật, danh sách tương thích).
- **N3. Ít lời gọi vào ứng dụng đích.** Tối thiểu lời gọi vào ứng dụng đích khi đang gõ.
  - Mỗi phím tối đa một lần gọi `insertText`.
  - Chỉ hỏi vị trí con trỏ (`selectedRange`) ở phím có thay chữ, không hỏi ở phím đi thẳng.
  - Ngoại lệ được đọc chữ trước con trỏ một lần để dựng lại từ: lệch vị trí ở phím có thay chữ (kể cả lần thay đầu của một từ, so với vị trí Dấu tự theo dõi), và phím dấu/biến đổi đầu tiên trong một từ đã hết hợp lệ (D11 (Kiểm tra ngữ cảnh)).
  - Ngoại lệ của "Thêm dấu cho từ đã gõ" (D20 (Thêm dấu cho từ đã gõ)): được hỏi vị trí và đọc chữ trước con trỏ ở phím đầu tiên khi bộ đệm trống mà chưa biết chữ trước con trỏ, nếu phím đó là phím dấu/biến đổi hoặc chữ cái, kể cả khi phím đó cuối cùng đi thẳng.
  - **Vì sao:** `insertText(_:replacementRange:)` cần vị trí tuyệt đối của từ đang gõ; chi phí đo được của `selectedRange` ghi ở mục "Câu hỏi đã trả lời" (vị trí thay chữ).
- **N4. Không tự đổi cài đặt hệ thống.** Không tự ý đổi cài đặt hệ thống của người dùng.
  - Dấu chỉ đổi cài đặt hệ thống khi người dùng bấm đúng nút làm việc đó ("Bật Dấu", "Gỡ cài đặt"), luôn có Hoàn tác hoặc xác nhận, và không bao giờ tự làm.
  - Mọi thứ khác chỉ hướng dẫn hoặc mở đúng màn hình Cài đặt.
  - Sau khi bật phải đọc lại trạng thái thật trước khi báo thành công (N5 (Chỉ hứa điều đã kiểm chứng)).
  - Nút "Bật Dấu"/"Bật lại" được làm thêm hai việc để macOS và các app thấy Dấu (D37 (Cài đặt bộ gõ)): xoá bộ đệm danh sách nguồn nhập liệu (của System Settings và của từng app) và thoát System Settings nếu đang mở. Việc bật vẫn do người dùng xác nhận trong hộp thoại của macOS.
  - Nút "Gỡ cài đặt" được xoá cùng bộ đệm đó sau khi người dùng đã bỏ Dấu bằng "–" (D16 (Bảo trì và gỡ cài đặt)).
- **N5. Chỉ hứa điều đã kiểm chứng.** Chữ hiển thị cho người dùng phải là lời hứa đã kiểm chứng được.

## Quyết định

- **D1. Nền tảng.** Chỉ macOS, tối thiểu macOS 14, binary universal (Apple silicon + Intel). Swift, Xcode. Không làm Windows/Linux/web.
- **D2. Chuyển Việt/Anh.**
  - Dấu chỉ có **một** input mode, "Tiếng Việt".
  - Gõ tiếng Anh dùng nguồn nhập liệu tiếng Anh sẵn có của macOS (U.S. — bàn phím mặc định —, ABC…), chuyển bằng phím tắt nguồn nhập liệu của macOS.
  - Chỉ báo dưới con trỏ do hệ thống hiển thị (N1 (Không làm lại việc hệ thống đã có)).
  - Không có phím chuyển riêng, không thông báo nổi, không âm thanh.
  - Từ tiếng Anh lẫn trong câu Việt do D4 (Từ nước ngoài) lo.
  - **Vì sao:** một chế độ tiếng Anh trong Dấu chỉ cho phím đi thẳng, trùng bàn phím tiếng Anh của macOS (N1); nó nằm ở nhóm "Tiếng Anh" trong danh sách thêm nguồn nên người dùng không tìm thấy; và nó làm mất các tiện ích chỉ nguồn của macOS có, như dùng Caps Lock để chuyển sang/về bàn phím tiếng Anh.
- **D3. Không macro, chỉ Unicode dựng sẵn.** Không làm macro (macOS có Thay thế văn bản), viết hoa đầu câu, bảng mã cũ (TCVN3, VNI-Windows…), công cụ chuyển mã (N1 (Không làm lại việc hệ thống đã có)). Chỉ xuất Unicode dựng sẵn (NFC).
- **D4. Từ nước ngoài.** Một quy tắc duy nhất:
  - Khi kết thúc từ (xem "Ranh giới từ" bên dưới), từ không phải âm tiết tiếng Việt hợp lệ (định nghĩa ở D31 (Âm tiết tiếng Việt hợp lệ)) được khôi phục đúng như phím đã gõ (windows, Sunrise).
  - Từ vừa là tiếng Anh vừa là tiếng Việt hợp lệ thì tiếng Việt thắng (car → cả, sex → sẽ, as → á). Muốn giữ chữ gốc thì gõ đúp phím dấu theo chuẩn Telex (carr → car).
  - Không dùng từ điển tiếng Anh.
  - **Ranh giới từ:** mọi ký tự kết thúc từ có in ra (Space, Enter, Tab và **mọi** dấu câu, ký hiệu, kể cả `! ? ( ) "`) kích hoạt kiểm tra và khôi phục như nhau ("windows," → "windows,", "Sunrise!" → "Sunrise!").
  - Chỉ reset bộ đệm, **không** khôi phục: mũi tên, Esc, click chuột và tổ hợp có ⌘/⌃/⌥; đổi cài đặt, đổi nguồn nhập liệu, đổi ô nhập hoặc ứng dụng giữa chừng một từ.
  - **Mốc khôi phục:** "đúng như phím đã gõ" tính từ mốc gần nhất. Mặc định là đầu từ; sau gõ đúp (D26 (Gõ đúp phím dấu)), sau Backspace (D32 (Backspace)) hoặc khi từ được đọc từ ứng dụng (D20 (Thêm dấu cho từ đã gõ)) thì mốc là chữ đang hiển thị lúc đó, cộng các phím gõ sau ("carr␣" → "car␣", "tesst␣" → "test␣", "nha" + f + k␣ → "nhafk␣").
  - **Giới hạn đã biết — tự sửa chính tả của macOS:** từ macOS 27.2, ở app bật tự sửa chính tả, hệ thống có thể sửa chữ tiếng Anh vừa gõ thành chữ tiếng Việt khi phía trước là câu tiếng Việt ("…Sunrise car␣" → "cả"), kể cả khi gõ bằng bàn phím U.S. Việc này xảy ra sau khi Dấu đã trả đúng "car" nên đè lên kết quả gõ đúp ("carr" → "car"). Dấu không tắt tự sửa của hệ thống (N4 (Không tự đổi cài đặt hệ thống)); người dùng hoàn tác bằng ⌘Z hoặc bấm vào chữ bị sửa. Ghi trong ma trận tương thích (`docs/COMPATIBILITY.md` mục 6.1).
  - **Vì sao:** từ điển tiếng Anh chỉ có tác dụng ở đúng nhóm từ trùng, và ở đó nó làm hỏng các từ tiếng Việt rất phổ biến như "cả", "sẽ". Mũi tên, Esc, click và tổ hợp phím chỉ reset vì lúc đó con trỏ có thể đã đi chỗ khác, ghi lại chữ dễ thay sai vùng.
- **D5. Quy tắc theo ứng dụng.**
  - Quy tắc riêng của một app chỉ có một nội dung: có/không gạch chân khi gõ trong app đó (D13 (Gạch chân là đường lui cuối cùng)), luôn áp dụng.
  - Dấu **không** tự đổi Việt/Anh theo app và không có "Nhớ chế độ theo từng ứng dụng".
  - Nhớ nguồn nhập liệu theo từng cửa sổ là việc của tuỳ chọn macOS "Tự động chuyển sang nguồn đầu vào của tài liệu" (Cài đặt Bàn phím › Nguồn đầu vào, N1 (Không làm lại việc hệ thống đã có)); trang Ứng dụng chỉ dẫn tới tuỳ chọn đó.
  - **Vì sao:** Dấu chỉ có một input mode (D2 (Chuyển Việt/Anh)), nên đổi sang U.S. phải gọi `TISSelectInputSource` từ bộ gõ. Đo được: lệnh đổi được nguồn nhưng bước macOS báo cho app đang gõ bị sandbox chặn (`deny mach-lookup com.apple.tsm.portname`, per-pid), thêm temporary-exception không gỡ được; còn khi U.S. đang bật thì Dấu không nhận sự kiện nào để đổi lại. Thêm một tiến trình chạy nền chỉ để đổi nguồn là không đáng.
- **D6. Phát hành.** GPLv3. DMG ký Developer ID + notarize trên GitHub Releases, Homebrew cask (khai báo `auto_updates true`). Không có Mac App Store.
  - **Vì sao:** Apple không hỗ trợ phân phối input method qua Mac App Store.
- **D7. Cập nhật và loại bản dựng.**
  - Sparkle 2 nằm trong app chủ, appcast ký EdDSA, kênh Ổn định/Beta, có phát hành theo đợt.
  - Danh sách ứng dụng tương thích là file JSON có chữ ký, cập nhật riêng (N2 (Bộ gõ không có quyền mạng)).
  - Cài bản mới lúc người dùng không gõ, sau đó dừng tiến trình bộ gõ cũ để hệ thống nạp bản mới.
  - **Loại bản dựng:** ba trục độc lập, không có loại thứ tư.
    - Cấu hình build: Debug hoặc Release (D8 (Không telemetry) nói khác nhau ở đâu).
    - Người ký: **bản chính thức** là bản ký Developer ID của codefastlabs, đã notarize, và chỉ dựng bằng quy trình phát hành trên CI; mọi bản khác (ký Personal Team, bản người khác tự build hay bản fork) là **bản phát triển**.
    - Kênh: Ổn định hoặc Beta, chỉ có ở bản chính thức.
  - Phát hành theo đợt và quay về bản trước (D19 (Quay về bản trước)) dùng lại bản ổn định.
  - **Số phiên bản:** `CFBundleVersion` là số build tăng dần, Sparkle so sánh bằng số này; số hiển thị dạng "1.3 beta 2", tag git dạng `v1.3.0-beta.2`; bản ổn định dựng lại từ cùng commit với bản beta cuối, số hiển thị không có chữ beta.
  - Bản dựng theo từng commit (Nightly), nếu làm, là bản phát triển: CI dựng, chỉ phát qua GitHub, không qua Sparkle.
  - Tính năng mới có thể nằm sau công tắc "Thử nghiệm" ngay trong bản ổn định (cài đặt cục bộ), kiểm chéo với các tính năng cùng tác động lên một đầu vào như mọi tính năng khác.
  - Không phát hành dần theo số liệu và không có cờ tính năng điều khiển từ xa. Không dùng TestFlight.
  - Nhận diện từng loại bản: D25 (Nhận diện).
  - **Vì sao:** phát hành dần theo số liệu và cờ tính năng điều khiển từ xa đều cần số liệu từ máy người dùng (D8), nên Dấu dựa vào người dùng Beta và báo lỗi. TestFlight chỉ dành cho app phân phối qua App Store (D6 (Phát hành)).
- **D8. Không telemetry.**
  - Không telemetry. Báo lỗi qua GitHub issue điền sẵn hoặc "Sao chép nội dung" để gửi email.
  - Không bao giờ gửi nội dung người dùng đã gõ.
  - Log chẩn đoán dùng `os.Logger`, nằm trên máy.
  - Bản phát hành không ghi gì theo từng phím, kể cả không có chữ.
  - Nhật ký từng phím chỉ có ở bản Debug và chỉ bật bằng khoá `DauPerfLog`.
  - **Vì sao:** giờ và app của từng phím là siêu dữ liệu về cách gõ, và ai chạy được lệnh dưới tài khoản người dùng có thể bật rồi đọc mà không cần quyền Theo dõi đầu vào.
- **D9. Giao diện.**
  - Theo macOS hiện hành (mockup vẽ theo macOS 27), dùng control hệ thống qua SwiftUI, cửa sổ Cài đặt có sidebar, không tự vẽ control (N1 (Không làm lại việc hệ thống đã có)).
  - **Chuẩn đối chiếu:** dùng thành phần của macOS với thông số mặc định. Khi mockup và macOS khác nhau về bố cục, khoảng cách, cỡ chữ hay hình dáng control thì theo **System Settings của macOS hiện hành** (số đo trong `docs/research/SYSTEM-SETTINGS-REFERENCE.md` và `scripts/selftest/settings-window/Reference.swift`).
  - Mockup quy định nội dung: có mục nào, chữ gì, thứ tự, icon, màu hệ thống.
  - Không chỉnh thông số của thành phần hệ thống để khớp pixel mockup.
  - Mọi thay đổi giao diện sửa artboard trên canvas trước, người dùng duyệt, rồi mới sửa mã; mã xong thì đối chiếu lại với artboard.
  - **Màu:** chỉ dùng màu hệ thống, không mã hex, không ngoại lệ. Ô icon sidebar dùng `systemBlue/systemPurple/systemOrange/systemGreen` (glyph nét theo mockup), nhãn "Mới" nền `accentColor`, banner "Dấu chưa được bật" dùng cam hệ thống như mockup.
  - Nút mở/thu "Nâng cao" ghép từ nút hệ thống + chevron được chấp nhận.
  - **Vỏ cửa sổ Cài đặt** (`docs/research/SWIFTUI-WINDOW-API.md`): thanh công cụ có cụm Lùi/Tiến như System Settings (`ControlGroup` kiểu `.navigation` ở vị trí `.navigation`, lịch sử các mục đã xem); tiêu đề trang là `navigationTitle` của hệ thống; không tự vẽ tiêu đề, không ẩn tiêu đề cửa sổ bằng cách với vào `NSWindow`.
  - **Sidebar cố định như System Settings:** sidebar rộng 232, không kéo rộng hẹp, không thu gọn, con trỏ ở đường chia là mũi tên thường, không có lệnh "Show/Hide Sidebar" (⌃⌘S).
    - Cửa sổ (vẫn là scene SwiftUI) chứa một `NSSplitViewController` do app tự tạo: mục sidebar `canCollapse = false`, `canCollapseFromWindowResize = false`, độ dày tối thiểu bằng tối đa.
    - Sidebar và trang vẫn là view SwiftUI trong `NSHostingController`; thanh công cụ và tiêu đề đưa lên cửa sổ bằng `sceneBridgingOptions`.
    - Ô tìm sidebar là `NSSearchField` cỡ lớn (`controlSize = .large`) với lề chuẩn 10 của sidebar, nên ô tìm và hàng đầu lệch System Settings 1–2 pt (không chỉnh lề cho khớp pixel).
    - Mọi thuộc tính đều thuộc split view của chính app, có tài liệu Apple; vẫn không với vào cấu trúc bên trong của SwiftUI.
    - Số đo trên app thử: `docs/research/SWIFTUI-WINDOW-API.md` mục 10.
  - **Vì sao:**
    - Chỉnh thông số cho khớp mockup (ví dụ lề hàng sidebar) trong khi app dựng bằng UI thuần vừa trái N1 vừa dễ vỡ khi macOS đổi.
    - Nút "Nâng cao": System Settings không có hàng mở/thu nào, còn `DisclosureGroup` trong Form không có vạch ngăn dưới hàng mở và không có AXPress cho trợ năng (đo trên macOS 27.2).
    - Sidebar cố định: kéo thu sidebar bị giật và System Settings không cho thu. SwiftUI không có API khoá sidebar của `NavigationSplitView`, nên dùng `NSSplitViewController` của chính app. Đã loại: duyệt cây view tìm `NSSplitView` mà `NavigationSplitView` dựng, phủ view lên đường chia.
- **D10. Engine tự viết.** Engine tự viết bằng Swift thuần (struct, hàm thuần, không Foundation).
  - OpenKey chỉ là tài liệu tham khảo: đọc mã nguồn để hiểu tính năng và ca biên, ghi vào `docs/OPENKEY-NOTES.md`; không nhúng mã, không dùng kết quả chạy OpenKey làm đáp án test.
  - UniKey không dùng.
- **D11. Kiểm tra ngữ cảnh.**
  - Engine tự theo dõi trạng thái trong bộ nhớ.
  - Ở mỗi phím có thay chữ, hỏi `selectedRange` một lần để lấy vị trí tuyệt đối (N3 (Ít lời gọi vào ứng dụng đích)); phím đi thẳng không hỏi gì, trừ ngoại lệ của D20 (Thêm dấu cho từ đã gõ) ghi ở N3.
  - Vị trí khác dự đoán (app tự sửa chữ, con trỏ đã đi chỗ khác) thì reset bộ đệm, không thay chữ, trừ khi app chỉ trả lời chậm (ý "App trả lời chậm" bên dưới).
  - **Gợi ý tự hoàn thành:** vùng bôi đen bắt đầu đúng chỗ con trỏ khi Dấu đang giữ một từ là gợi ý tự hoàn thành của app (thanh địa chỉ trình duyệt, Spotlight): thay cả từ lẫn phần gợi ý, như phím thường gõ đè vùng chọn.
  - **Dựng lại khi lệch:** khi lệch, nếu phím trước cách ít nhất 50 ms (như D20) và app cho đọc chữ, Dấu đọc từ ngay trước con trỏ, dựng lại bộ đệm từ chữ thật rồi xử lý phím đó; không đọc được hoặc không có từ thì reset như trên.
  - **App trả lời chậm:** Dấu tự theo dõi vị trí con trỏ qua các từ, cùng các chữ chính nó vừa gõ.
    - Khi kiểm: `selectedRange` lùi sau vị trí đó tối đa 2 chữ và phím trước cách ít nhất 50 ms; Dấu đọc chữ trước con trỏ một lần (lần đọc khi lệch ở N3).
    - Chữ đọc được chứng minh app chỉ chưa áp các phím vừa gõ: thay ở vị trí Dấu theo dõi.
    - Không chứng minh được, ở lần thay đầu của một từ, và trước vị trí app trả không có đủ cả từ: vẫn thay ở vị trí Dấu theo dõi.
    - Không chứng minh được, ở giữa từ: như "Dựng lại khi lệch".
    - Vị trí app trả mà có thể là vị trí cũ thì không ghi đè vị trí Dấu theo dõi.
    - Phím dồn dưới 50 ms: chưa áp dụng (M6).
  - **Từ đã hết hợp lệ:** từ trong bộ đệm đã hết hợp lệ (D30 (Kiểm tra chính tả), không tính D33 (Độ dài từ)) mà người dùng gõ phím dấu/biến đổi thì đọc chữ trước con trỏ một lần cho từ đó; khác bộ đệm thì dựng lại từ chữ thật rồi xử lý phím (cùng điều kiện 50 ms). Chi phí: tối đa một lần đọc cho mỗi từ không phải tiếng Việt.
  - Chỉ đọc chữ từ ứng dụng (`attributedSubstring`) cho tính năng "Thêm dấu cho từ đã gõ" (D20).
  - **Vì sao:**
    - Gợi ý tự hoàn thành: mọi cách người dùng tự chọn chữ (chuột, ⇧ + mũi tên, ⌘A) đều đã reset bộ đệm trước đó, nên vùng bôi đen như vậy chỉ có thể là gợi ý của app.
    - Dựng lại khi lệch: bấm chuột vào thanh địa chỉ Chrome không được báo cho bộ gõ, nên "tieemf" từng ra "tieemf".
    - Từ đã hết hợp lệ: ⌘A trong thanh địa chỉ Chrome là phím tắt menu, không tới bộ gõ; "tốt", ⌘A, "toots" từng ra "toots" và hỏng tới dấu cách.
    - App trả lời chậm: Chrome khi trang bận trả vị trí và chữ từ bộ đệm của trình duyệt, thường thiếu phím vừa gõ. Thay theo vị trí đó sai 3/3 lượt, thay theo vị trí Dấu tự theo dõi đúng 3/3; Telex của Apple cùng điều kiện ra chữ 2/3 lượt (M6, 09–10/11/2026; cơ chế ở `docs/ARCHITECTURE.md` mục "App trả lời chậm").
- **D12. Ưu tiên tiến trình.** Không bật `.latencyCritical` hay `beginActivity` mặc định. Chỉ thêm khi bài test tải nặng chứng minh có App Nap hoặc bị xếp vào nhân tiết kiệm điện.
- **D13. Gạch chân là đường lui cuối cùng.**
  - Thay tại chỗ là cách gõ của Dấu. Gõ sai ở một app là lỗi của Dấu và phải sửa, không giải quyết bằng gạch chân: gạch chân (marked text) là cách bộ gõ mặc định của macOS hiện chữ, thứ Dấu muốn làm tốt hơn.
  - Gạch chân chỉ còn là đường lui cho app mà thay tại chỗ chưa sửa được, người dùng tự bật theo từng app (D5 (Quy tắc theo ứng dụng)). **Mặc định mọi app không gạch chân.**
  - Nhãn "Đề xuất" trong danh sách tương thích chỉ gắn cho app mà số đo cho thấy thay tại chỗ còn sai ở tốc độ gõ thật; sửa được ở app nào thì bỏ nhãn của app đó.
  - Hiện còn nhãn: VS Code, các app Electron/Chromium và Firefox (sai khi phím dồn, M3). Terminal không đề xuất.
  - **Vì sao (nhãn hiện có):** đo ở M3 (độ tin cậy) bằng câu mẫu `scripts/selftest/typing/run.sh`: thay tại chỗ chỉ sai khi phím cách nhau dưới 10 ms (Chrome, Terminal sai ở 0 ms; VS Code ở 0 và 5 ms), từ 10 ms đúng ở lượt đo M3; riêng VS Code ở 10 ms đã sai một lần ở lượt đo M2 với câu mẫu cũ, từ 20 ms đúng ở mọi lượt (`docs/COMPATIBILITY.md` mục 6.2); gạch chân sửa được Chrome và VS Code ở 0 ms, Terminal ở 0 ms vẫn lỗi (còn vẽ marked text cũ). Firefox vào danh sách theo số đo: thay tại chỗ sai ở 0 và 5 ms, gạch chân đúng ở 0 ms.
- **D14. Onboarding.**
  - Bước 1 phát hiện bộ gõ cũ đang chạy (OpenKey, EVKey, GoTiengViet…) qua `NSWorkspace` và hướng dẫn tắt (N4 (Không tự đổi cài đặt hệ thống)).
  - Bước 2 bật Dấu (một nguồn nhập liệu duy nhất, D2 (Chuyển Việt/Anh)).
  - Bước 3 chọn kiểu gõ và gõ thử.
- **D15. Cài đặt mặc định.** Telex, đặt dấu kiểu mới (hoà, thuý), bỏ dấu tự do bật, tự khôi phục từ không phải tiếng Việt bật, "Thêm dấu cho từ đã gõ" bật, nhóm Nâng cao (gõ tắt phụ âm, cho phép z/f/w/j) tắt.
- **D16. Bảo trì và gỡ cài đặt.**
  - App có "Quay về bản trước" và "Gỡ cài đặt" (bộ gõ nằm trong `~/Library/Input Methods`, không gỡ được bằng cách kéo vào Thùng rác).
  - **Gỡ cài đặt cần người dùng bấm "–":**
    - Sau khi xác nhận, app mở thẳng danh sách Input Sources của System Settings và hướng dẫn bỏ "Dấu – Tiếng Việt" bằng "–".
    - App không tự chuyển bàn phím. Nếu Dấu đang được chọn, sheet nhắc chọn bàn phím khác khi nút "–" bị mờ, phòng bản macOS khác chưa đo.
    - App tự nhận ra khi Dấu ra khỏi `com.apple.inputsources` rồi mới chuyển bộ gõ vào Thùng rác, dừng nó và xoá bộ đệm danh sách nguồn của System Settings (để "+" không còn dòng không tên).
    - Người dùng không bấm "–" thì không gỡ gì.
  - **Dấu đã cài nhưng không có trong nguồn đầu vào:** không có mục nào để bỏ, nên sau alert xác nhận thì gỡ luôn; không mở System Settings, không hiện sheet bấm "–".
  - **Vì sao:**
    - Chỉ System Settings ghi được danh sách nguồn đang bật, app không tự bỏ được (`docs/research/M5-INSTALL.md` mục 4.1).
    - App không tự chuyển bàn phím vì trên macOS 27.2 nút "–" bấm được cả khi Dấu đang được chọn và macOS tự chuyển sang nguồn khác (đo bằng Dấu thật).
    - Đã cân nhắc và loại gỡ tự động không cần "–" (xoá bộ gõ và bộ đệm, đo bằng bản thử ở `docs/research/M5-INSTALL.md` mục 8.1b): mọi chỗ người dùng thấy đều sạch nhưng mục "đã bật" của Dấu còn ẩn trong `com.apple.inputsources`, và cài lại thì macOS bật Dấu ngay không hỏi (mục 4.1). Dấu chọn máy sạch và việc gỡ do chính người dùng xác nhận bằng "–".
- **D17. Trợ năng.**
  - Chuyển Việt/Anh là chuyển nguồn nhập liệu của hệ thống, VoiceOver tự đọc tên nguồn (N1 (Không làm lại việc hệ thống đã có)); Dấu không tự thông báo thêm.
  - Kiểm chứng bằng VoiceOver: hệ thống có đọc khi chuyển nguồn (đã kiểm ở M3, `docs/history/LOG-M0-M4.md`); đọc đúng tên "Dấu – Tiếng Việt" chưa xác nhận, kiểm ở M7 (phát hành).
  - Nếu hệ thống không đọc thì xét lại.
  - **Vì sao:** tránh đọc hai lần.
- **D18. Phòng thủ với IMK.** Coi mọi tham số từ IMK là có thể nil hoặc bất thường (ví dụ bảng Emoji từng truyền NSEvent rỗng); không bao giờ crash vì đầu vào.
- **D19. Quay về bản trước.** Quay về bản trước tạm tắt tự động cập nhật cho tới khi có bản mới hơn bản lỗi. Cài đặt và quy tắc ứng dụng được giữ nguyên.
  - **Vì sao:** để Sparkle không cài lại bản vừa gặp lỗi.
- **D20. Thêm dấu cho từ đã gõ.** Tính năng "Thêm dấu cho từ đã gõ" đọc chữ đang hiển thị như chữ cái, không như chuỗi phím đã gõ, và chỉ áp dụng khi kết quả là âm tiết tiếng Việt hợp lệ; nếu không thì phím đi thẳng.
  - Nhờ vậy không xung đột với D4 (Từ nước ngoài): "car" giữ bằng "carr", sau đó quay lại gõ thêm "s" vẫn ra "cars"; gõ liền trong cùng từ thì do D26 (Gõ đúp phím dấu).
  - Áp dụng cho cả phím dấu thanh lẫn phím biến đổi (aa, ee, oo, w, dd…) theo luật bình thường trên chữ đang hiển thị.
  - Không tự thêm biến đổi khác để từ thành hợp lệ ("viet" + j → "vietj" vì "viẹt" không hợp lệ; "viet" + e + j → "việt").
  - "Hợp lệ" ở đây xét theo mức tiền tố của D30 (Kiểm tra chính tả), như lúc đang gõ ("viet" + e → "viêt"), với một khác biệt: nguyên âm phải giữ đúng dấu phụ đang hiển thị, vì không tự thêm biến đổi khác (nên "viet" + j → "vietj", không chờ mũ như lúc gõ "viẹt"). Hệ quả: "hoc" + f hiện "hòc", kết thúc từ thì D31 (Âm tiết tiếng Việt hợp lệ) khôi phục thành "hocf".
  - Gõ đúp trên từ đọc lại vẫn là bỏ dấu theo D26 ("cả" + r → "car").
  - Không giữ "lịch sử từ" để Backspace quay lại sửa như OpenKey: lùi về sau từ rồi gõ phím dấu đã được D20 phủ.
  - **Phạm vi:**
    - Không áp dụng ở app đang bật gạch chân (D13 (Gạch chân là đường lui cuối cùng)), vì chế độ đó không hỏi vị trí con trỏ.
    - Chỉ đọc lại chữ khi phím trước đó trên cùng ô nhập cách ít nhất 50 ms (biên an toàn khi gõ dồn; đo ở 0–30 ms chưa thấy hỏng).
    - Chỉ xét phần chữ ngay trước con trỏ ("hoc|tap" + j → "họctap").
  - **Khi nào đọc:** mỗi lần đọc tốn một `selectedRange` và một `attributedSubstring` 16 đơn vị UTF-16, ở phím chữ cái hoặc dấu/biến đổi đầu tiên khi bộ đệm trống mà chưa biết chữ trước con trỏ (sau reset, click, ⌫, Return/Tab), kể cả khi trước con trỏ không có chữ hoặc phím đó cuối cùng đi thẳng (N3 (Ít lời gọi vào ứng dụng đích)). Gõ liền qua dấu cách không đọc.
  - **Chữ cái gõ sát chữ có sẵn:** phím đầu tiên là chữ cái thường cũng đọc từ ngay trước con trỏ. Chữ đó nối vào từ chỉ khi từ ghép vẫn là tiền tố hợp lệ theo D30, ngược lại chữ đó bắt đầu từ mới ("q" có sẵn + "uer" → "quẻ", "g" + "ias" → "giá", "tiê" + "ngs" → "tiếng"; "tôi" + "laf" → "tôilà", "sắc" + "mauf" → "sắcmàu").
    - Hệ quả: chữ cái sau ⌫ qua dấu cách nối lại từ trước khi hợp lệ ("ba␣⌫nj" → "bạn"; "duow␣⌫c" giữa từ hiện "dươc", kết thúc từ D31 khôi phục "duơc" vì "ươc" cần sắc hoặc nặng).
  - **Ba ngoại lệ:**
    - (a) Chữ cuối của từ có sẵn là chữ thường mà phím là chữ hoa thì bắt đầu từ mới, vì tiếng Việt không có chữ hoa giữa âm tiết ("#Hà" + "Nooij" → "#HàNội"; "VI" + "EEJT" → "VIỆT" và "V" + "ieejt" → "Việt" vẫn nối). Trừ khi phím đó đặt dấu thanh hoặc biến đổi lên từ có sẵn, vì khi đó phím không thêm chữ nào ("hoc" + "J" → "học").
    - (b) Từ có sẵn không phải tiếng Việt (không là tiền tố hợp lệ theo D30, dài hơn 7 chữ cái như D33 (Độ dài từ), hoặc có chữ cái engine không biết) thì chữ gõ tiếp, kể cả phím dấu, thuộc về từ đó và đi thẳng tới hết từ, như khi gõ liền ("foo" + "bar" → "foobar", "keyboard" + "bar" → "keyboardbar").
    - (b) thắng (a), vì chữ hoa giữa một từ nước ngoài là kiểu viết camelCase ("foo" + "Bar" → "fooBar", như gõ liền). Đánh đổi: từ tiếng Việt gõ dính sau từ nước ngoài cũng đi thẳng ("iPhone" + "mowis" → "iPhonemowis", như gõ liền).
    - (c) Phím đầu tiên là phím dấu/biến đổi mà không áp dụng được lên từ tiếng Việt có sẵn (từ ghép hết hợp lệ) thì bắt đầu từ mới như chữ cái ("anh" + "emx" → "anhẽm", "tôi" + "ddi" → "tôiđi"). Gõ đúp bỏ dấu theo D26 vẫn là áp dụng ("cả" + "r" → "car").
  - **Giới hạn còn lại:** từ mới viết thường, hoặc viết hoa như từ có sẵn, gõ dính sau từ tiếng Việt mà vài chữ đầu ghép lại vẫn hợp lệ thì vẫn nối ("#hà" + "nooij" → "#hànooij", "ba" + "nawm" → "banawm"). Giữ song song hai cách hiểu sửa được nhưng phải viết lại cả chữ có sẵn trong app; chưa làm.
  - **Sau sự kiện reset của D4:** sự kiện reset của D4 (mũi tên, click, đổi nguồn, ⌘/⌃/⌥) chỉ xoá bộ đệm, không chặn D20. Phím dấu kế tiếp có thể đặt dấu vào chữ ngay trước con trỏ ("tooi" rồi ← thì con trỏ ở "tô|i"; gõ "s": phần trước con trỏ "tô" thành "tố", chữ "i" sau con trỏ giữ nguyên, cả từ là "tối"; "to" đổi nguồn rồi về, "o" → "tô"). Muốn không có hành vi này thì tắt công tắc D20.
  - **Vì sao:**
    - Chi phí mỗi lần đọc (bản Debug, trung vị `selectedRange` + `attributedSubstring`): TextEdit 0,4 + 1,0 ms, Safari 0,6 + 3,7 ms, Chrome 0,3 + 0,8 ms, VS Code 0,3 + 0,7 ms.
    - Chữ cái gõ sát chữ có sẵn: chọn bằng mô phỏng engine trên 10.303 ca ngoài và các tình huống sửa chữ, so với chỉ đọc ở phím dấu và với luôn nối (luôn nối làm hỏng 34 ca gõ từ mới sát từ cũ): `docs/research/EXTERNAL-TEST-INPUTS.md` mục 9.8.
    - Ba ngoại lệ: trên cùng 10.303 ca, (a) không đổi ca nào, (b) đổi 2, (c) đổi 24 (một chuỗi của gonhanh, nay "sắcđẹp"), không bất biến nào hỏng.
- **D21. Gõ tắt phụ âm.** Thuộc nhóm Nâng cao, mặc định tắt.
  - Chỉ áp dụng khi kết thúc từ (ranh giới theo D4 (Từ nước ngoài)) và chỉ khi kết quả là âm tiết tiếng Việt hợp lệ; nếu không thì D4 khôi phục.
  - Khác OpenKey, nơi gõ tắt chạy trước và chặn luôn bước khôi phục ("big" thành "bing" dù không hợp lệ — xem nhánh xử lý phím Space trong `Engine.cpp` của OpenKey).
  - Từ trùng như "bag" → "bang", "fix" → "phĩ" vẫn xảy ra vì người dùng đã chủ động bật; ghi rõ trong test.
  - Trong lúc gõ (trước khi kết thúc từ), khi tuỳ chọn bật thì f, j ở đầu từ và g, h, k ở cuối từ được coi là phụ âm tạm hợp lệ để phím dấu vẫn có tác dụng ("fanf" hiện "fàn", kết thúc từ ra "phàn").
- **D22. Gõ tắt loại trừ z, f, w, j.** Gõ tắt phụ âm và "Cho phép z, f, w, j" loại trừ nhau.
  - Bật mục này thì tắt mục kia, ghi rõ trong giao diện.
  - Với Telex, w đầu từ luôn thành ư (D23 (w → qu chỉ ở VNI)) nên "cho phép w" không có tác dụng; giao diện ghi chú điều này khi đang dùng Telex.
  - **Vì sao:** hai tuỳ chọn cùng tác động lên f, j, w ở đầu từ.
- **D23. w → qu chỉ ở VNI.** Gõ tắt w → qu chỉ có ở VNI. Với Telex, w ở đầu từ luôn là ư ("wa" → "ưa").
  - **Vì sao:** trong OpenKey quy tắc w → qu không bao giờ kích hoạt ở Telex nên không đưa vào Telex.
- **D24. Tên và định danh.**
  - "Dấu" là tên thương hiệu, như "Phở" hay "Mì Quảng": ở mọi ngôn ngữ vẫn viết "Dấu", không dịch, không bỏ dấu (`scripts/check-l10n/check.sh` chặn "Dau" trong chuỗi giao diện).
  - Luôn viết có dấu ở mọi chỗ người dùng nhìn thấy: tên app, tên nguồn nhập liệu ("Dấu – Tiếng Việt"; trên macOS tiếng Anh "Dấu – Vietnamese", D41 (Ngôn ngữ giao diện)), website, logo.
  - Bản không dấu "dau" chỉ dùng cho định danh kỹ thuật (bundle ID, tên target, repo, cask) và không bao giờ đứng một mình trước người dùng.
  - Tên miền: `dau.codefastlabs.com`.
  - Định danh kỹ thuật theo tên miền đảo: bundle ID app `com.codefastlabs.dau`, bộ gõ `com.codefastlabs.dau.inputmethod.Dau`, input mode `com.codefastlabs.dau.inputmethod.Dau.vi`, App Group `<Team ID>.com.codefastlabs.dau.shared`.
  - Team ID: Personal Team `M58DANM3ZP` cho bản phát triển; bản phát hành ký Developer ID ở M7.
  - Tên cask Homebrew: chọn sau khi tra (xem câu hỏi mở về tên "Dấu").
  - **Vì sao:** "dau" đứng một mình dễ đọc thành "đau"/"dầu".
- **D25. Nhận diện.**
  - Biểu tượng "ấ" màu Giấy trên nền Mực, riêng dấu sắc màu Son; logo chữ "Dấu" Be Vietnam Pro một màu; Son chỉ dùng trong biểu tượng; app vẫn dùng phông và màu hệ thống (D9 (Giao diện)). Chi tiết: `docs/BRAND.md`.
  - **Biểu tượng theo loại bản** (các loại bản ở D7 (Cập nhật và loại bản dựng)):
    - Biểu tượng chuẩn chỉ có ở bản chính thức, chọn bằng một cờ build mà chỉ quy trình phát hành trên CI đặt. Mặc định, tức mọi bản phát triển (Debug, Release tự dựng, bản người khác build), dùng biểu tượng **bản phát triển**.
    - Biểu tượng bản phát triển giữ chữ "ấ", khác nền và có thêm một dấu hiệu bằng hình để vẫn nhận ra khi macOS bỏ màu (kiểu Trong suốt, Phủ màu của Icon Composer): **nền Chì, dải chéo màu Hổ phách ở góc dưới phải**. Không có chữ, không dùng Son cho dải, không đảo màu. Màu và artboard: `docs/BRAND.md`.
    - Kênh Beta dùng biểu tượng chuẩn, phân biệt bằng số phiên bản ("1.3 beta 2") ở trang Cập nhật & hỗ trợ và trong báo lỗi điền sẵn (D8 (Không telemetry)).
    - Debug và Release không có hai biểu tượng: trang Cập nhật & hỗ trợ của bản phát triển ghi cấu hình build và commit; `scripts/dev/dau-version.sh` cho biết commit của từng bản đã cài.
    - Bundle ID không đổi theo loại bản (D37 (Cài đặt bộ gõ)).
    - Biểu tượng "V" trên thanh menu giống nhau ở mọi bản (ảnh template, D9).
  - **Vì sao:**
    - Biểu tượng chỉ trả lời câu "đây có phải bản chính thức không"; bằng chứng là chữ ký Developer ID, app chủ kiểm chữ ký và Team ID của bộ gõ (D37).
    - Dải góc thay vì nền sọc: nền sọc mất ở 16–32 pt và ở kiểu Trong suốt. Không có chữ vì 16–32 pt không đọc được. Không đảo màu vì dễ nhầm với kiểu Tối của biểu tượng chuẩn.
    - Kênh Beta dùng biểu tượng chuẩn: người dùng Beta là người dùng thật, đổi biểu tượng mỗi lần đổi kênh chỉ gây rối.
- **D26. Gõ đúp phím dấu.** Sau khi gõ đúp phím dấu để giữ chữ gốc (chuẩn Telex, D4 (Từ nước ngoài)), các phím dấu tiếp theo trong cùng từ đi thẳng như chữ cái cho tới khi kết thúc từ (ranh giới theo D4): "carr" → "car", "carrs" → "cars". Khớp với ví dụ ở D20 (Thêm dấu cho từ đã gõ).
  - Cùng luật cho gõ đúp phím biến đổi ("aaa" → "aa", "ddd" → "dd", "ww" → "w") và cho VNI ("a11" → "a1").
  - Khoá này giữ nguyên tới hết từ, kể cả sau Backspace ("tesst" ⌫ s → "tess").
  - Ngoại lệ "ooo": "ooo" → "oo" nhưng **không** khoá phím dấu sau đó, để gõ được "xoong", "boong", "xoòng" ("xooongf" → "xoòng").
  - "ww" trên "ưa" cũng bỏ móc như mọi nguyên âm khác ("huaww" → "huaw").
  - Ngoại lệ chữ ư từ một phím w đứng riêng (D23 (w → qu chỉ ở VNI)): khi sau chữ ư đó đã có nguyên âm khác, nó không bị phím w sau bỏ móc ("ww" → "w" vẫn theo D26); phím w đó là chữ cái, kết thúc từ thì D4 khôi phục ("Warwick", "waxwing" giữ nguyên).
  - **Hệ quả đã chấp nhận:** từ tiếng Anh có chữ cái lặp trùng phím dấu mất một chữ nếu gõ bình thường ("password" → "pasword", "coffee" → "cofee"); muốn giữ thì gõ chữ đó 3 lần ("passsword", "cofffee").
  - **Giới hạn đã biết** (ca thử của bộ gõ khác, `docs/research/EXTERNAL-TEST-INPUTS.md` mục 9): từ tiếng Anh có chữ cái lặp trùng phím dấu hoặc phím biến đổi mất cả dấu lẫn một chữ ("worry" → "ưory", "express" → "êps", "versus" → "veus"). Giữ nguyên hành vi; gõ tiếng Anh bằng U.S. (D2 (Chuyển Việt/Anh)).
  - **Vì sao:**
    - Đã cân nhắc khôi phục theo phím gốc thay vì chữ hiển thị: gõ "password" tự nhiên được, nhưng các từ vừa là tiếng Anh vừa là âm tiết hợp lệ có phím dấu giữa từ (test, best, list, most, post) không còn cách nào gõ ở chế độ Tiếng Việt. Loại, vì mọi từ phải gõ được.
    - Ngoại lệ chữ ư: đã loại cách áp D26 ở đây, vì "Warwick" → "Waick", "waxwing" → "waing", mất chữ không khôi phục được.
- **D27. Không có phím gõ nhanh ơ, ư.** Không có phím gõ nhanh `[` → ơ, `]` → ư trong Telex. `[` và `]` luôn là dấu câu, kết thúc từ.
- **D28. Bỏ dấu tự do.** Mặc định bật (D15 (Cài đặt mặc định)).
  - **Khi bật:** phím dấu thanh gõ ở bất kỳ đâu sau nguyên âm đầu, kể cả sau phụ âm cuối; dấu tự vào đúng nguyên âm và tự dời khi gõ thêm nguyên âm ("hof" + a → "hoà" kiểu mới).
    - Phím d sau nguyên âm vẫn biến d đầu từ thành đ ("did" → "đi"; từ trùng thì tiếng Việt thắng theo D4 (Từ nước ngoài)).
    - Phím biến đổi (aa, ee, oo, w, dd; VNI 6, 7, 8, 9) và phím dấu tác dụng lên nguyên âm/phụ âm phù hợp trong từ, không cần đứng sát ("tuongw" → "tương"; VNI "duo7c59" → "được").
  - **Khi tắt:** phím dấu chỉ có tác dụng khi gõ ngay sau nguyên âm (dấu đã đặt vẫn tự dời khi gõ thêm nguyên âm: "hof" + a → "hoà"); phím biến đổi nguyên âm (w, aa, ee, oo; VNI 6, 7, 8) vẫn tác dụng từ xa ("tuongw" → "tương"), và d → đ chỉ khi hai d liền nhau ("did" giữ "did").
  - **Phím biến đổi khác loại** (ca thử của bộ gõ khác, `docs/research/EXTERNAL-TEST-INPUTS.md` mục 9): gõ lên nguyên âm đã có dấu phụ khác thì đổi sang dấu mới, kể cả trên cụm hai nguyên âm: "aaw" → "ă", "owo" → "ô", "ươ" + o → "uô" ("cuoiwo" → "cuôi").
- **D29. Telex đơn giản.** Telex đơn giản là Telex trừ hai điểm:
  - w chỉ biến đổi khi trong từ có a, o, u để nhận dấu trăng/móc (theo D28 (Bỏ dấu tự do), không cần đứng sát: "tuongw" → "tương"); nếu không có thì w là chữ w, không thành ư ("web", "www" gõ thoải mái).
  - Không có `[ ]` (như D27 (Không có phím gõ nhanh ơ, ư)).
  - Không có gõ tắt w → qu (D23 (w → qu chỉ ở VNI)).
  - Theo Simple Telex 1 của OpenKey (xem `docs/OPENKEY-NOTES.md` 3.5).
- **D30. Kiểm tra chính tả.** Kiểm tra chính tả luôn chạy trong engine, không có công tắc riêng: khi từ đã sai chính tả thì ngừng biến đổi phím tiếp theo.
  - Trong lúc gõ chỉ xét từ có còn là **tiền tố** của một âm tiết hợp lệ hay không ("viêt", "hoc", "tră" vẫn biến đổi tiếp: "vieetj" → "việt", "hocj" → "học", "trawngf" → "trằng"); quy tắc đầy đủ của D31 (Âm tiết tiếng Việt hợp lệ) chỉ áp khi kết thúc từ.
  - Sau Backspace (D32 (Backspace)), trạng thái sai chính tả được tính lại từ chữ còn hiển thị.
  - Công tắc "Tự khôi phục từ không phải tiếng Việt" chỉ điều khiển việc khôi phục khi kết thúc từ.
  - **Dấu thanh trên vần tắc:** "tiền tố hợp lệ" xét chữ cái của âm tiết; dấu thanh chỉ kiểm theo D31 khi kết thúc từ. Vì vậy huyền, hỏi, ngã trên vần có âm cuối p, t, c, ch vẫn được nhận giữa từ ("hoc" + f hiện "hòc"); kết thúc từ thì D4 (Từ nước ngoài) khôi phục ("metric", "catr" giữ nguyên).
    - Hệ quả đã chấp nhận: giữa từ tiếng Anh có thể nháy chữ có dấu ("mẻt…"); khi tắt tự khôi phục, chữ sai chính tả ở lại.
  - **Vì sao:** nhận dấu thanh trên vần tắc giữa từ để sửa dấu bằng phím dấu khác ("hocfj" → "học", "matfs" → "mát") và bỏ dấu tự do (D28 (Bỏ dấu tự do): "cafts" → "cát") vẫn chạy (`docs/research/EXTERNAL-TEST-INPUTS.md` mục 9). Đã loại phương án cho phím đó đi thẳng như chữ cái: hỏng cả ba cách gõ trên.
- **D31. Âm tiết tiếng Việt hợp lệ.** Định nghĩa dùng cho D4 (Từ nước ngoài), D20 (Thêm dấu cho từ đã gõ), D21 (Gõ tắt phụ âm), D30 (Kiểm tra chính tả), theo chính tả chuẩn:
  - Phụ âm đầu thuộc danh sách chuẩn, có thêm "p" (pin, pa-tê).
  - Quy tắc phân bố c/k/q, g/gh, ng/ngh: gh, ngh chỉ đứng trước i, e, ê; c, g, ng không đứng trước i, e, ê, y; k đứng trước i, e, ê, y và — nới cho địa danh, xem bên dưới — trước mọi nguyên âm; c không đứng trước oa, oă, oe, uy, uê, uâ vì chính tả viết qu; q luôn đi với u.
  - iê không đứng đầu âm tiết (viết yê: yên, yêu); yê sau phụ âm chỉ trong uyê (khuyên, tuyết).
  - Vần thuộc bảng vần hợp lệ do Dấu tự lập theo chính tả (không chép bảng OpenKey). Bảng vần có "oao" (ngoao, ngoáo) và "uêu" (nguều).
  - Vần kết thúc bằng p, t, c, ch chỉ mang sắc hoặc nặng; không dấu thanh là không hợp lệ (vì vậy "bak" với gõ tắt phụ âm giữ nguyên "bak").
  - ă, â không đứng cuối âm tiết ("aw" khôi phục thành "aw").
  - Phím dấu gõ ngay sau "qu" được nhận như sau "gi" ("qusa" → "quá"); "qui" vẫn không hợp lệ, chỉ "quy" theo chính tả chuẩn.
  - b, m, p, v đi với âm đệm o, u hợp lệ (buýt, boa, voan; "more" → "moẻ" theo D4, gõ đúp để giữ chữ gốc).
  - **Nới cho địa danh:** k đứng trước mọi nguyên âm (Kon Tum, Bắc Kạn, Kơ Tu), phụ âm đầu "kr" (Krông Pắc), và âm cuối k **chỉ sau ă**, cùng ràng buộc dấu như c (Đắk Lắk). Không dùng danh sách ngoại lệ (cùng tinh thần D4).
    - Vần "ăk" chỉ nhận khi ă đã có trước k ("Lawks" → "Lắk"); gõ phím biến đổi sau k ("lakws") không biến đổi.
  - Ba điểm "qu", âm đệm sau b, m, p, v và hai vần "oao", "uêu" đến từ ca thử của bộ gõ khác (`docs/research/EXTERNAL-TEST-INPUTS.md` mục 9).
  - **Vì sao:**
    - Nới cho địa danh: đo trên 428 từ tiếng Anh, 6 từ đổi (karma → kẩm, Kansas → Kâns, Kris → Krí, hawks → hắk, gawks → gắk, awkward → akward); chấp nhận. Đã loại phương án cho âm cuối k ở mọi vần: hỏng 19 từ (ask → ák, task, desk, mask…).
    - "ăk" chỉ khi ă có trước k: cho "ak" là tiền tố hợp lệ sẽ làm "asks", "tasks", "masks" mất một chữ s (D26 (Gõ đúp phím dấu)).
    - "qui": đã loại cho "qui" hợp lệ, vì khi đó "quits" → "quít", "quips" → "quíp".
- **D32. Backspace.** Backspace bỏ chữ cuối đang hiển thị khỏi bộ đệm và đặt lại dấu theo vần còn lại ("hoà" ⌫ → "hò").
  - Từ đó mốc khôi phục của từ là chữ đang hiển thị (không giữ chuỗi phím gốc cũ).
  - Còn lại chỉ "qu" thì không còn vần để đặt dấu: "quá" ⌫ → "qu".
  - **Vì sao:** tránh lệch hai bộ đệm như OpenKey.
- **D33. Độ dài từ.** Từ dài hơn âm tiết dài nhất (7 chữ cái, như "nghiêng") thì khôi phục ngay về chuỗi phím đã gõ (nếu đã biến đổi, không chờ kết thúc từ) và để mọi phím còn lại đi thẳng tới hết từ.
  - Khi tắt công tắc "Tự khôi phục từ không phải tiếng Việt" thì chỉ ngừng biến đổi, không khôi phục (cùng ý nghĩa công tắc ở D30 (Kiểm tra chính tả)).
  - Xoá hết từ bằng Backspace thì hết trạng thái đi thẳng, như khoá gõ đúp của D26 (Gõ đúp phím dấu): "permission" + 10 ⌫ + "vieetj" → "việt" (ca thử: `docs/research/EXTERNAL-TEST-INPUTS.md` mục 9.8).
  - **Vì sao:** nhờ vậy bộ đệm có dung lượng cố định, không cấp phát thêm, không mất chữ.
- **D34. Chữ hoa với phím biến đổi.** Phím biến đổi và phím dấu không đổi kiểu hoa của chữ; chữ hoa/thường theo chữ cái gõ đầu tiên ("dD" → "đ", "Dd" → "Đ", "aA" → "â").
- **D35. "uơ" và "ươ".** Móc trên cặp u-o (Telex "uow"/"uwo", VNI "uo7") cho "uơ" khi cặp đứng cuối từ ("huơ", "thuở") và tự thành "ươ" khi gõ thêm chữ sau ("uown" → "ươn", "nguwowif" → "người").
  - **Thứ tự u + móc + o:** Telex "uwo" và VNI "u7o" theo cùng luật ("uwo␣" → "uơ␣", "thuwor" → "thuở", VNI "thu7o3" → "thuở"; "nguwoif" → "người").
  - Phím móc gõ thêm trên cặp đó thêm móc cho u ("nguwowif", VNI "ngu7o72i" → "người"), không bỏ móc theo D26 (Gõ đúp phím dấu).
  - Hệ quả: "thu7o73␣", "thuwowr␣" giữa từ thành "thưở", không phải vần hợp lệ, nên kết thúc từ D4 (Từ nước ngoài) khôi phục phím đã gõ.
- **D36. VNI: chữ số thành dấu.** Với VNI, chữ số sau âm tiết hợp lệ thành dấu ("U23" → "Ủ", "A4" → "Ã", "lan2" → "làn"), cùng luật tiếng Việt thắng (D4 (Từ nước ngoài)).
  - Muốn giữ chữ số thì gõ đúp ("U223" → "U23", D26 (Gõ đúp phím dấu)).
  - Chữ số khi bộ đệm rỗng đi thẳng ("2024").
  - Ghi rõ trong bảng gõ VNI và phần hỏi đáp của website (M8 (website)).
- **D37. Cài đặt bộ gõ.**
  - **App chủ không chạy sandbox.** Dấu.app không chạy sandbox. Bộ gõ vẫn chạy sandbox và không có quyền mạng (N2 (Bộ gõ không có quyền mạng)); App Group giữ nguyên.
  - **Không đổi giữa các bản:** bundle ID, ID mode `….Dau.vi`, tên kết nối, tên file và tên tiến trình bộ gõ (đổi thì bộ đệm TIS lệch, phải đăng xuất).
  - **Bật lần đầu không cần đăng xuất.** Khi người dùng bấm "Bật Dấu", app:
    1. chép bộ gõ;
    2. xoá `com.apple.IntlDataCache.le*` trong **mọi** thư mục con của `DARWIN_USER_CACHE_DIR` (của System Settings và của từng app; thư mục nào không có quyền thì bỏ qua và ghi nhật ký) ngay trước khi đăng ký bộ gõ;
    3. thoát System Settings nếu đang chạy;
    4. gọi `TISEnableInputSource` cho mục cha: macOS mở System Settings và hỏi "Allow “Dấu” to enable “…”?".
  - Chỉ tính là bật khi `com.apple.inputsources` › `AppleEnabledThirdPartyInputSources` có mục của Dấu (không tin cờ enabled của TIS).
  - Sau khi đã bật, app quét lại một lượt: bộ đệm nào vẫn không có `DauInputMethod.app` (dựng lại trong khoảng giữa lúc xoá và lúc đăng ký) thì xoá rồi đăng ký lại một lần.
  - Gỡ cài đặt chỉ xoá bộ đệm của System Settings (D16 (Bảo trì và gỡ cài đặt)); bộ đệm riêng của từng app vẫn nhớ bộ gõ đã gỡ, chưa đo hậu quả.
  - **Đường lui:** hành vi bộ đệm của System Settings và của từng app (xem "Vì sao") không có tài liệu Apple, bản macOS sau có thể khác. Đọc lại không thấy mục của Dấu thì hướng dẫn tự thêm bằng "+", và nếu "+" không có Dấu thì đăng xuất một lần (Apple DTS 6/2026).
  - **Một app vẫn không chọn được Dấu** (bộ đệm riêng không xoá được, như các thư mục được hệ thống bảo vệ): hướng dẫn đăng xuất rồi đăng nhập lại một lần, ở màn "Đã bật" của onboarding, sheet Báo lỗi và Hỏi đáp của trang tải về.
  - Homebrew cask chỉ khai `app`. Chi tiết: `docs/research/M5-INSTALL.md`.
  - **Kiểm chữ ký:** mỗi lần mở app và mỗi lần app được đưa lên trước, app kiểm chữ ký và Team ID của bộ gõ đã cài; không khớp thì hiện banner "Cài lại".
  - **Nâng cấp trước, kiểm chữ ký sau:** khi bộ gõ đã cài vừa cũ hơn vừa có chữ ký sai, app nâng cấp trước; kiểm chữ ký và Team ID chạy sau khi nâng cấp xong, nên banner "Cài lại" chỉ hiện khi bản đã cài sau đó vẫn sai.
  - **Vì sao:**
    - Không sandbox: app phải chép bộ gõ vào `~/Library/Input Methods`, nâng cấp tại chỗ và dừng tiến trình bộ gõ cũ. App có sandbox thì file chép ra luôn bị gắn cờ quarantine mà app không gỡ được, và không dừng được app khác (Apple DTS; không bộ gõ tham khảo nào làm vậy).
    - Bật không cần đăng xuất (đo bằng bản thử rồi bằng Dấu thật, macOS 27.2, tài khoản đã từng cài Dấu; `docs/research/M5-INSTALL.md` mục 9.9, mục 9.10 và 8.1b): danh sách "+" và việc dựng hộp thoại đọc bộ đệm của System Settings; bộ đệm không làm mới khi có nguồn mới đăng ký (không xoá thì chỉ đăng xuất mới làm mới); yêu cầu bật gửi lúc trang Keyboard đang mở sẵn bị bỏ qua im lặng.
    - Mỗi app có sandbox cũng giữ bộ đệm riêng, dùng nguyên bộ đệm có sẵn kể cả khi mở lại app: Telegram dựng bộ đệm lúc chưa có Dấu thì không chọn được Dấu, gõ vẫn ra bộ gõ khác. Xoá bộ đệm trước khi đăng ký thì app đang chạy dựng lại ở lần đăng ký và dùng được nguồn mới, không cần mở lại (bản thử).
    - Đăng xuất là đường lui cho app còn lại (đo bằng Dấu thật, `docs/research/M5-INSTALL.md` mục 9.12): sau một lần đăng nhập mới, mỗi app có sandbox dựng lại bộ đệm của nó ở lần đầu đọc nguồn đầu vào; thoát rồi mở lại app thì không.
    - Kiểm chữ ký: thư mục `~/Library/Input Methods` tài khoản người dùng ghi được, nên bundle có thể bị thay; macOS có chặn bundle bị thay hay vẫn đưa phím cho nó thì chưa đo.
- **D38. Chữ trên giao diện.**
  - Chữ của Dấu theo ngôn ngữ giao diện của Dấu (D41 (Ngôn ngữ giao diện)).
  - Mọi tên giao diện của macOS (System Settings, Keyboard, Input Sources, Allow, tên bàn phím…) hiện **đúng như macOS của người dùng đang hiện**, theo ngôn ngữ của macOS chứ không theo ngôn ngữ của app; lấy chữ từ chính chuỗi của hệ thống, không tự dịch (máy tiếng Anh: "System Settings › Keyboard › Input Sources"; máy tiếng Việt: "Cài đặt hệ thống › Bàn phím › Nguồn đầu vào"). Cùng tinh thần với tên bàn phím (`LayoutNames`).
  - Tên "Thùng rác" (Trash) trong các thông báo gỡ cài đặt cũng đọc từ chuỗi của macOS, không viết cứng; không đọc được thì dùng tên tiếng Anh.
  - Khi nói về khái niệm chung trong câu tiếng Việt, dùng thuật ngữ Apple tiếng Việt ("nguồn đầu vào", không phải "nguồn nhập liệu"); câu tiếng Anh dùng thuật ngữ Apple tiếng Anh ("input source").
  - Phạm vi D38: chữ người dùng thấy; tài liệu nội bộ có thể còn "nguồn nhập liệu".
  - **Vì sao:** hướng dẫn chỉ đúng khi tên khớp với thứ người dùng thấy; macOS tiếng Việt gọi Input Sources là "Nguồn đầu vào" (đọc từ chuỗi của System Settings 27.2).
- **D39. Ủng hộ dự án.**
  - Nhận ủng hộ tự nguyện qua GitHub Sponsors, và chuyển khoản trong nước bằng mã VietQR cho người không có thẻ thanh toán quốc tế.
  - Không đổi việc Dấu miễn phí trọn vẹn (D6 (Phát hành)): không có bản trả phí, không khoá tính năng, không quảng cáo.
  - Trang tải về có liên kết "Ủng hộ dự án" ở chân trang.
  - Tài khoản Sponsors của tổ chức `codefastlabs` và tài khoản ngân hàng nhận chuyển khoản do người dùng mở và lo phần thuế, pháp lý (việc cần tài khoản).
  - Còn mở: có đặt liên kết trong app hay không (canvas trước).
- **D40. Chữ dựng sẵn và phím z.** (ca thử của bộ gõ khác, `docs/research/EXTERNAL-TEST-INPUTS.md` mục 9)
  - Chữ tiếng Việt dựng sẵn đến như một phím (bàn phím khác, dán từng chữ) được coi là một chữ cái của từ đang gõ ("chuýên" → "chuyến").
  - Ký tự không thuộc bảng chữ (ß…) kết thúc từ.
  - Phím z (Telex) khi từ chưa có dấu thanh là chữ z, không bỏ mũ/móc ("kongoz" → "kongoz").
- **D41. Ngôn ngữ giao diện.** App chủ và bộ gõ có tiếng Việt và tiếng Anh.
  - **Chọn ngôn ngữ:** theo danh sách ngôn ngữ ưu tiên của macOS, lấy ngôn ngữ đầu tiên Dấu có bản dịch; không có ngôn ngữ nào thì tiếng Anh. Ngôn ngữ khác chỉ thêm khi có người nói thạo duyệt bản dịch (N5 (Chỉ hứa điều đã kiểm chứng)).
  - **String Catalog:** ngôn ngữ gốc là tiếng Anh (`developmentLanguage: en`), khoá là câu tiếng Anh, tiếng Việt là bản dịch và phải đủ mọi chuỗi (thiếu thì người dùng Việt thấy tiếng Anh).
  - **Tên nguồn đầu vào:** "Dấu – Tiếng Việt" trên macOS tiếng Việt, "Dấu – Vietnamese" trên macOS tiếng Anh (như "Vietnamese Telex" của Apple); macOS chọn tên theo ngôn ngữ của hệ thống, Dấu không đổi được; ID input mode không đổi (D24 (Tên và định danh), D37 (Cài đặt bộ gõ)).
    - Câu chữ của Dấu nhắc tên nguồn thì dùng đúng tên macOS đang hiện, theo ngôn ngữ của hệ thống chứ không theo ngôn ngữ của app, như tên giao diện ở D38 (Chữ trên giao diện).
    - "Dấu" giữ nguyên ở mọi ngôn ngữ (D24). Tên giao diện của macOS trong câu chữ vẫn theo D38.
  - **Đặt ngôn ngữ riêng cho Dấu:** dùng mục ngôn ngữ riêng từng ứng dụng của macOS (System Settings › General › Language & Region › Applications), Dấu không làm ô chọn riêng (N1 (Không làm lại việc hệ thống đã có)).
    - Đo trên Dấu thật (macOS 27.2): danh sách "+" của mục đó có Dấu.app; chọn tiếng Việt thì Dấu hiện tiếng Việt trên máy tiếng Anh, và macOS ghi khoá `AppleLanguages` vào miền cài đặt của app (`com.codefastlabs.dau`).
    - Để người dùng biết chỗ này, Cài đặt có một hàng "Ngôn ngữ" chỉ đọc: hiện ngôn ngữ Dấu đang dùng và nút "Đổi…" mở trang Language & Region, cùng kiểu hàng "Nhớ nguồn đầu vào theo từng cửa sổ" (tên mục của macOS theo D38); canvas trước, mã sau.
    - Đổi ngôn ngữ xong, macOS hỏi có mở lại app ngay không và không tự mở lại (đã đo). Chưa mở lại thì hàng ghi ngôn ngữ của lần mở sau và có nút "Mở lại Dấu" (Dấu tự thoát rồi mở lại, không ghi cài đặt).
    - Bộ gõ: chưa đo danh sách "+" có nhận bộ gõ không (xem câu hỏi mở); tới khi đo, menu bộ gõ theo ngôn ngữ hệ thống.
  - **Thứ tự:** phần nền (đổi khoá sang tiếng Anh kèm đủ bản tiếng Anh, bỏ việc ghim `vi` khi app khởi động, kiểm bản dịch đủ cả hai chiều) làm trước M7; phần còn lại ở M9 (đa ngôn ngữ) (`docs/ROADMAP.md`).
  - **Vì sao:**
    - Hai ngôn ngữ: người Việt dùng rộng rãi và người nước ngoài học tiếng Việt.
    - Khoá tiếng Anh: macOS tự lùi về ngôn ngữ gốc nên không cần cấu hình riêng; sửa câu tiếng Việt không đổi khoá; người dịch ngôn ngữ khác dịch từ tiếng Anh. Đã loại: khoá là câu tiếng Việt (phải đặt vùng phát triển khác ngôn ngữ gốc để lùi về tiếng Anh); khoá theo ngữ nghĩa (`onboarding.title`; Xcode không tự lấy chuỗi từ `Text("…")`, đọc mã không thấy chữ hiện ra).
    - Mục ngôn ngữ của macOS thay cho ô chọn riêng: đã loại ô chọn ngôn ngữ trong Cài đặt ghi khoá `AppleLanguages` ("Theo hệ thống", Tiếng Việt, English), vì làm lại việc macOS đã có; điều người dùng thiếu chỉ là biết chỗ đổi.

## Đã biết nhưng không làm

Tính năng người dùng có thể đã quen ở bộ gõ khác. Dấu biết và cố ý không làm; lý do nằm ở quyết định được dẫn, không chép lại ở đây. Muốn làm một mục thì sửa quyết định đó trước, như mọi quyết định khác. Cột "Bộ gõ khác có" theo `docs/OPENKEY-NOTES.md`, "—" là chưa đối chiếu.

| Tính năng | Bộ gõ khác có | Vì sao Dấu không làm |
|---|---|---|
| Macro, gõ tắt văn bản | OpenKey | D3 (macOS có Thay thế văn bản, N1) |
| Viết hoa chữ đầu câu | OpenKey | D3 |
| Bảng mã cũ (TCVN3, VNI-Windows, CP1258, Unicode tổ hợp), nhớ bảng mã theo ứng dụng | OpenKey | D3 (chỉ xuất Unicode dựng sẵn) |
| Công cụ chuyển mã, kể cả chuẩn hoá Unicode cho chữ dán vào | OpenKey | D3, N1 |
| Tự đổi Việt/Anh theo ứng dụng | OpenKey | D5, D2 |
| Từ điển tiếng Anh để giữ từ tiếng Anh | — | D4 |
| Quick Telex (cc → ch, nn → ng…) | OpenKey | Kích hoạt cả giữa từ nên phá từ tiếng Anh có phụ âm đôi ("connect" → "congect"); trùng mục đích với gõ tắt phụ âm (D21) |
| Phím chuyển Việt/Anh riêng (nhấn-nhả ⌃ hoặc ⇧), tiếng bíp khi chuyển | OpenKey | D2 |
| Tạm tắt bộ gõ hoặc kiểm tra chính tả bằng nhấn-nhả ⌃/⌘ | OpenKey | D2, D30 |
| Biểu tượng riêng trên thanh menu, mục "Thoát" | — | D2 (Dấu là một nguồn đầu vào của macOS), N1 |
| Thông báo nổi và âm thanh khi chuyển Việt/Anh | — | D17, N1 |
| Thống kê gõ phím, telemetry | — | D8 |
| Phát hành trên Mac App Store | — | D6, D37 |
| Tự thêm mũ/móc còn thiếu để từ thành hợp lệ ("thuocs" → "thuốc"), tự tách âm tiết giữa từ ("neeboo" → "nê" + "bô") | uvie-rs | D20 (không tự thêm biến đổi khác), D30 |

## Đã cân nhắc và loại bỏ

Cách làm (không phải tính năng; tính năng ở mục trên): Rust/WASM và đa nền tảng; thử gõ trên trang web; event tap + Backspace giả (cách của OpenKey); `NSSpellChecker` trong đường nóng; nhúng engine UniKey qua C++ interop; chạy engine OpenKey làm đáp án cho test (oracle); MIT/MPL tách riêng cho engine.

## Câu hỏi mở (phải kiểm chứng trên máy thật)

- **Bộ gõ trong mục ngôn ngữ riêng từng ứng dụng** (D41 (Ngôn ngữ giao diện)): danh sách "+" của System Settings › General › Language & Region › Applications có chọn được bộ gõ Dấu (`~/Library/Input Methods`) không, và chọn rồi thì menu bộ gõ ("Cài đặt Dấu…", tên kiểu gõ) có đổi theo không. Không được thì menu bộ gõ luôn theo ngôn ngữ hệ thống; hàng "Ngôn ngữ" trong Cài đặt nói rõ điều đó nếu cần.
- **Hộp thoại và đăng xuất khi bật bộ gõ:** `TISRegisterInputSource` / `TISEnableInputSource` trên macOS 14–27: có cần người dùng xác nhận không; lần cài đầu có phải đăng xuất không?
  - Hiện biết: trên macOS 27.2 (bản thử rồi Dấu thật) có hộp thoại xin phép, và không cần đăng xuất nếu làm theo D37 (Cài đặt bộ gõ).
  - Còn phải đo trên macOS 14–26 và bản ký Developer ID; không đo trên tài khoản macOS mới.
  - Cách làm hiện hành: sau "Bật Dấu" đọc lại trạng thái từ `com.apple.inputsources`, không tin TIS của chính tiến trình; chưa bật thì mở Cài đặt › Bàn phím và hướng dẫn bấm "+" (N4 (Không tự đổi cài đặt hệ thống), D37).
  - Nguồn: Apple DTS nói cần đăng xuất, một dự án khác nói không. Chi tiết: `docs/research/M5-INSTALL.md` mục 0, 2.2, 2.3.
- **Cài cho riêng mình hay cho cả máy** (làm sau M5 (onboarding, cài đặt, gỡ cài đặt)): cho người dùng chọn cài bộ gõ vào `~/Library/Input Methods` (như D16 (Bảo trì và gỡ cài đặt) hiện nay) hoặc `/Library/Input Methods` để mọi tài khoản trên máy dùng được. Chưa thiết kế; khi làm phải sửa D16, D37 (Cài đặt bộ gõ), có thể cả D6 (Phát hành) (`.pkg` hay app chủ xin quyền quản trị) và D7 (Cập nhật và loại bản dựng) (nâng cấp bản cả máy cần quyền quản trị). Cần trả lời: mỗi tài khoản vẫn phải tự bật bằng "+" không; bản ở hai thư mục cùng bundle ID thì macOS chạy bản nào; gỡ bản cả máy khi tài khoản khác còn bật; tài khoản đăng nhập sau khi cài có thấy nguồn ngay không. `docs/research/M5-INSTALL.md` mục 8.2 có một bước đo một phần các câu này.
- **Hộp thoại App Group:** truy cập App Group giữa app chủ và bộ gõ có phát sinh hộp thoại hệ thống không? Bản có Team ID: không có hộp thoại; còn phải kiểm lại với bản ký Developer ID ở M7.
- Ngưỡng hiệu năng (độ trễ p99, bộ nhớ): chốt sau khi đo, so với gõ bằng U.S.
- Độ ổn định của "Thêm dấu cho từ đã gõ" trên các web editor (Google Docs, Notion…).
- **Loại bản dựng** (D7 (Cập nhật và loại bản dựng), D25 (Nhận diện); chốt ở M7): kênh Beta có cần cask Homebrew riêng (`dau@beta`) không, hay chỉ bật trong app (đang nghiêng về chỉ bật trong app); tên app của bản phát triển có thêm chữ để phân biệt không; bản phát triển có kiểm tra và cài bản chính thức qua Sparkle không (cài thì bản đang thử bị thay bằng bản khác Team ID; artboard "Cập nhật & hỗ trợ (bản phát triển)" hiện vẫn vẽ phần Cập nhật như bản chính thức). Tên nguồn nhập liệu "Dấu – Tiếng Việt" giữ nguyên ở mọi bản cho tới khi đo được bộ đệm TIS có giữ tên cũ khi đổi tên giữa hai lần cài không (D37 (Cài đặt bộ gõ)).
- **Tên "Dấu":** tra nhãn hiệu (Cục Sở hữu trí tuệ VN), tên miền (cân nhắc tên miền tiếng Việt có dấu "dấu.vn" bên cạnh một bản không dấu), tên cask Homebrew và tên tổ chức GitHub. (Bundle ID, tên miền chính: đã chốt ở D24 (Tên và định danh); Team ID cho bản phát hành: M7.)

## Câu hỏi đã trả lời

- **Vị trí thay chữ: hỏi con trỏ ở mỗi phím hay tự tính** (xung đột giữa N3 (Ít lời gọi vào ứng dụng đích) và tính đúng đắn; tài liệu khác gọi đây là "câu hỏi A/B", cách A là hỏi ở mỗi phím, cách B là tự cộng dồn vị trí từ một vị trí gốc). `insertText(_:replacementRange:)` cần vị trí tuyệt đối của từ đang gõ.
  - **Trả lời:** hỏi `selectedRange` ở mỗi phím có thay chữ; ghi ở N3 và D11 (Kiểm tra ngữ cảnh).
  - Số đo M2 (bộ gõ tối thiểu; bản Debug, `scripts/selftest/typing`): `selectedRange` p50 ~0,17–0,62 ms. Tỉ lệ trong thời gian một phím có thay chữ (p50): gõ tay 6–8% ở TextEdit, Safari, Chrome và 17% ở Sublime Text; tự gõ 30 ms/phím 10% ở TextEdit, 35–42% ở Safari, Chrome, VS Code, Terminal (ở các app này cả phím chỉ mất ~0,6–1,5 ms). Số đo trên bản Debug, có thêm một lần hỏi chẩn đoán sau mỗi lần thay (`ReplaceDiag.swift`, không có ở Release). Số đo Telegram (thay cho Slack) và các số khác: `docs/history/LOG-M0-M4.md`.
  - TextEdit, Safari đúng ở mọi tốc độ; Chrome, VS Code, Terminal đúng khi phím cách nhau ≥ 20 ms nhưng sai khi phím dồn (< 10–20 ms) vì các app này áp phím bất đồng bộ nên `selectedRange` là ảnh chụp cũ. App chậm mà phím cách từ 50 ms: Dấu dùng vị trí tự theo dõi, kiểm bằng chữ đọc được (D11, M6). Phím dồn dưới 50 ms: chưa có cách, đang làm ở M6 (hiệu năng dưới tải).
- **App Group với bản ký ad-hoc** (không Team ID) trên macOS 27: **bị từ chối im lặng** (containermanagerd REJECTED, cfprefsd từ chối ghi), không có hộp thoại; cần Team ID (`scripts/selftest/app-group.sh`). **Bản có Team ID (Personal Team miễn phí, ký "Apple Development"): chạy được**, containermanagerd APPROVED, không hộp thoại, không cần hồ sơ cấp phép vì nhóm có tiền tố Team ID; bộ gõ nhận cài đặt qua thông báo Darwin, tiến trình app mới đọc lại được giá trị. `synchronize()` của suite App Group vẫn trả về false dù ghi thành công, nên không dùng làm dấu hiệu lỗi.
- **App chủ có sandbox được không** khi phải chép bundle bộ gõ vào `~/Library/Input Methods`? **Không sandbox (D37 (Cài đặt bộ gõ)).**
- **Chrome/Terminal có cần quyền Accessibility không?** Ít nhất một bộ gõ IMK khác (VietTelex) ghi trong README rằng phải bật Accessibility mới gõ được trong Terminal, iTerm và các trình duyệt Chromium. **Trả lời: không cần.** Bộ gõ không có quyền Trợ năng mà vẫn thay chữ đúng trong Chrome, VS Code, Terminal khi phím cách nhau từ 20 ms (Chrome gõ tay cũng đúng). Lỗi khi phím đến dồn là do các app này áp phím bất đồng bộ, không phải do thiếu quyền; hướng xử lý là sửa thay tại chỗ (D11, M6), gạch chân chỉ là đường lui cuối cùng (D13 (Gạch chân là đường lui cuối cùng)); Dấu không xin quyền Accessibility (N4 (Không tự đổi cài đặt hệ thống), bảo mật).
