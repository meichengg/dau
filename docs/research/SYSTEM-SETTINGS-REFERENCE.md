## Hiện trạng (09/11/2026)

- **Chuẩn đối chiếu (đo 02/11/2026, macOS 27.2 build 26B123):** khi mockup và macOS khác nhau về bố cục, khoảng cách, cỡ chữ hay hình dáng control thì theo System Settings; mockup chỉ quy định nội dung (D9 (Giao diện)). Số đo ở các mục "Cửa sổ, thanh công cụ, tiêu đề", "Sidebar", "Cột chi tiết: Form dạng nhóm", "Hàng trong thẻ".
- **Mặc định SwiftUI khớp phần lớn số đo:** danh sách ở mục "Mặc định SwiftUI đã khớp".
- **Không khớp hoặc cần đặt tay (02/11/2026):**
  - Sidebar: mặc định 144, System Settings 232; đặt `navigationSplitViewColumnWidth(232)` thì mọi số sidebar trùng.
  - Lề trên form: 20 so với 12; Dấu giữ 20 (D9: không đè thông số hệ thống).
  - Thẻ của `Form(.grouped)` tối đa 704 pt (mục "Độ rộng tối đa của Form dạng nhóm").
  - Hàng chỉ có `Text` cao 36 so với 37,5; nút trong hàng chỉ có nút: SwiftUI căn trái, System Settings căn phải.
  - Chi tiết và việc đã giải quyết ở mục "Cần chỉnh / không khớp".
- **Sheet (đo 02/11/2026, sửa 03/11/2026 cho khớp mã):** nút trên `toolbar` cho đúng thanh nút của System Settings, thẻ `Form(.grouped)` cho đúng lề và khoảng cách thẻ; `List` trong `Form(.grouped)` bị tắt cuộn nên danh sách đặt trong `GroupBox`. Chi tiết ở mục "Sheet". Chiều cao thẻ danh sách (188) lấy từ mockup, giữ hay đổi là câu hỏi mở cho người dùng.
- **Icon ứng dụng trong hàng (02/11/2026):** khung 32 cho hàng có dòng phụ, 24 cho hàng một dòng kèm control; mục "Icon ứng dụng trong hàng".
- **Nút mở/thu kiểu "Nâng cao" (02/11/2026):** System Settings không có hàng mở/thu nào trong 13 pane đã rà; `DisclosureGroup` trong Form lệch cách vẽ hàng và không mở được qua Accessibility API, nên giữ nút + chevron; D9 đã ghi đúng lý do này. Mục "Nút mở/thu kiểu 'Nâng cao'".
- **Cụm Lùi/Tiến và sidebar cố định (05/11 và 06/11/2026):** `ControlGroup` với `.controlGroupStyle(.navigation)` giữ thanh 52 và tiêu đề hệ thống 15 đậm (đo 05/11/2026). Sidebar của System Settings cố định độ rộng (đo 05/11/2026); sidebar cố định của Dấu (từ 06/11/2026) chưa đo trên cửa sổ thật. Mục "Cần chỉnh / không khớp".
- **Cửa sổ System Settings cố định độ rộng 740, chỉ đổi được chiều cao (đo 09/11/2026):** mục "Cửa sổ có đổi rộng được không". Cửa sổ Cài đặt của Dấu làm theo: rộng cố định 740, chỉ đổi chiều cao (từ 09/11/2026).
- Tài liệu Apple không công bố các số 704, 20, 12, 37,5; mọi số trong file là số đo trên máy, có thể đổi theo phiên bản macOS (mục "Nguồn API").

## Chuẩn đối chiếu: System Settings (macOS 27.2)

Số đo phục vụ D9: khi mockup và macOS khác nhau về bố cục, khoảng cách, cỡ chữ hay hình dáng control thì theo System Settings.

Đo ngày 02/11/2026 trên macOS 27.2 (26B123), giao diện Tối (không đổi giao diện khi đo), màn Retina 2x. Đơn vị pt, gốc toạ độ ở góc trên trái cửa sổ.

**Cách đo.**
- System Settings:
  - Đọc khung phần tử bằng Accessibility API (role, x y w h) ở các pane Bàn phím, Giao diện, Âm thanh, Màn hình khoá, Desktop & Dock, Ngày & Giờ, Thông báo, Màn hình, Cài đặt chung, Bàn di chuột (chỉ mở bằng URL `x-apple.systempreferences:`, không bấm gì).
  - Chụp cửa sổ bằng `screencapture -l`, đọc mép, màu, bán kính góc theo pixel.
  - Cỡ chữ suy ra bằng cách so độ rộng nét chữ đo được với độ rộng tính bằng `NSFont.systemFont` ở các cỡ và độ đậm; độ đậm ghi "≈" khi hai mức sát nhau.
- "SwiftUI mặc định":
  - Một app thử ngoài repo: `NavigationSplitView` + `List` sidebar 4 hàng (ô icon 20 pt màu, chữ) + `Form { Section … }.formStyle(.grouped)` + `.navigationTitle`, không `listRowInsets`, không padding.
  - Chạy ở 820×600, 740×560 và rộng 1000–1400.
  - Số SwiftUI ở cột so sánh lấy ở cửa sổ 740×560 với `.searchable(placement: .sidebar)` và cột sidebar 232 khi có ghi; còn lại là mặc định thuần.

Lưu ý khi đọc số: máy đo đang hiện thanh cuộn kiểu cũ (luôn hiện), nên hàng sidebar của System Settings rộng 215 thay vì 232; app thử không có thanh cuộn ở sidebar.

### Cửa sổ, thanh công cụ, tiêu đề

| Thông số | System Settings | SwiftUI mặc định | Ghi chú |
|---|---|---|---|
| Kích thước cửa sổ | 740 × 560, mọi pane đều vậy | Theo `.defaultSize` của app | Không thấy khung cửa sổ lưu trong cài đặt của System Settings nên coi là mặc định (suy luận, cần kiểm chứng). Không đổi kích thước cửa sổ khi đo. Đổi được kích thước hay không: xem "Cửa sổ có đổi rộng được không". |
| Chiều cao thanh tiêu đề + công cụ | 52 | 52 | Khớp. |
| Nút đèn giao thông | x 18 / 41 / 64, y 18, 16×16 | Như hệ thống | Khớp. |
| Nút trên thanh công cụ | Lùi/Tiến (cụm 73×36 ở x 240, y 8) | Nút "Hide Sidebar" 44×52 ở mép phải cột sidebar | Khác. App thử bỏ nút này bằng `.toolbar(removing: .sidebarToggle)` đặt trên cột sidebar thì thanh công cụ co còn 32 và tiêu đề thành chữ tiêu đề cửa sổ nhỏ (đo ở màn 1x). |
| Tiêu đề trang: cỡ, độ đậm, màu | 15, đậm (bold ≈ semibold), màu chữ chính | 15, đậm, màu chữ chính | Khớp. |
| Tiêu đề trang: vị trí | Nét chữ bắt đầu x ≈ 324 (sau cụm Lùi/Tiến); chữ hoa từ y 20 đến 31 | Nét chữ bắt đầu ở mép cột chi tiết + ≈ 20 (x 252.5 khi sidebar 232) | Lệch x là do System Settings có cụm Lùi/Tiến; chiều dọc khớp. |

### Sidebar

| Thông số | System Settings | SwiftUI mặc định | Ghi chú |
|---|---|---|---|
| Độ rộng cột | 232 (đường chia 0.5 ở x 231.5) | **144** | Không khớp: phải đặt `navigationSplitViewColumnWidth(232)`. Đặt 232 thì mọi số bên dưới trùng System Settings. |
| Ô tìm kiếm | x 10, y 61, 212 × 28, dạng viên thuốc | Không có; với `.searchable(placement: .sidebar)`: x 10, y 61, 212 × 28 (cột 232) | Khớp khi dùng `.searchable(placement: .sidebar)`. Danh sách bắt đầu ở y 98 (không có ô tìm: y 52). |
| Chiều cao hàng | 32 | 32 | Khớp. |
| Vùng chọn | Đúng khung ô: x 10, rộng = cột − 20, cao 32 | x 10 → cột − 10, cao 32 | Khớp (System Settings đo được x 10..205 vì thanh cuộn chiếm chỗ; không có thanh cuộn thì suy ra 10..222, cần kiểm chứng). |
| Bán kính góc vùng chọn | ≈ 7 (khớp đường tròn theo pixel) | Trùng từng pixel với System Settings | Khớp. |
| Màu vùng chọn | Màu nhấn (xanh) | Màu nhấn khi có ô tìm sidebar; **xám** ở bản không có ô tìm (danh sách không giữ tiêu điểm) | Phụ thuộc tiêu điểm bàn phím, không phải thông số. |
| Ô icon | 20 × 20, x 19, giữa hàng theo chiều dọc | 20 × 20, x 19 | Khớp (ô 20 pt do app vẽ, xem D9 về màu). |
| Chữ: x | Nét chữ từ x ≈ 46 | x ≈ 46 | Khớp. |
| Khoảng icon → chữ | ≈ 7 (mép ô 39 → chữ 46) | ≈ 7 | Khớp. |
| Cỡ, độ đậm chữ | 13, thường; trắng hoàn toàn (255) | 13, thường; trắng (255) | Khớp. |
| Khoảng giữa hai nhóm | 13 | 13 (hai `Section` không tiêu đề) | Khớp. |
| Vùng đáy sidebar | Không có | Không có | |
| Nền sidebar / nền pane | ≈ (51, 51, 49) / (45, 45, 44) ở giao diện Tối | Như nhau | Khớp; màu nền phụ thuộc hình nền và giao diện. |

### Cột chi tiết: Form dạng nhóm

| Thông số | System Settings | SwiftUI mặc định | Ghi chú |
|---|---|---|---|
| Lề thẻ trái / phải | 20 / 20 (thẻ 252..720 trong pane 232..740) | 20 / 20 | Khớp. Thanh cuộn kiểu cũ nằm trong lề phải, không làm hẹp thẻ. |
| Lề trên (thanh công cụ → thẻ đầu, hoặc → tiêu đề nhóm đầu) | **12** (thẻ ở y 64; tiêu đề nhóm đầu ở y 64) | **20** (y 72) | Không khớp, lệch 8. `.contentMargins(.top, …, for: .scrollContent)` cộng thêm vào 20 chứ không thay (đặt 12 → 32), nên không dùng để giảm. |
| Bán kính góc thẻ | ≈ 11 | ≈ 11 (trùng từng pixel) | Khớp. |
| Màu thẻ / nền pane | (54, 54, 53) / (45, 45, 44) ở giao diện Tối | Như nhau | Khớp. |
| Khoảng giữa hai thẻ không tiêu đề | 10 | Chưa đo riêng (xem ghi chú) | App thử luôn có tiêu đề nhóm; suy luận là 10, cần kiểm chứng. |
| Thẻ trước → tiêu đề nhóm sau | 30 | 30 | Khớp. |
| Tiêu đề nhóm: chữ | 13, đậm vừa (semibold ≈), màu chữ chính, cao 17.5 | 13, semibold ≈, màu chữ chính | Khớp. |
| Tiêu đề nhóm: x, khoảng tới thẻ | x = mép thẻ + 10; cách thẻ 10 | x = mép thẻ + 10; cách thẻ 10 | Khớp. |
| Mô tả nhóm | Đặt **dưới tiêu đề, trên thẻ** (ví dụ pane Thông báo): 11, thường, màu chữ phụ, x = mép thẻ + 10, cách thẻ 10 | — | Trong 10 pane đã mở không gặp chú thích dưới thẻ. |
| Chú thích dưới thẻ (`footer:`) | Không gặp | 11, thường, màu chữ phụ, x = mép thẻ + 10, cách thẻ 10 | |
| Nút dưới form | Căn phải, cách thẻ cuối 20, cao 24; nút "?" 24 × 24 ở mép phải | — | Ví dụ "Phím tắt bàn phím…", "Tuỳ chọn trợ năng…". |
| Độ rộng nội dung tối đa | Không đo được: cửa sổ rộng 740 ở mọi pane, thẻ 468 | **Thẻ tối đa 704**, đặt giữa khi pane rộng hơn 744 | Xem mục dưới. |

### Hàng trong thẻ

| Thông số | System Settings | SwiftUI mặc định | Ghi chú |
|---|---|---|---|
| Lề trái / phải trong hàng | 10 / 10 | 10 / 10 | Khớp. |
| Chỉ nhãn | Không gặp hàng chỉ có nhãn; hàng nhãn + giá trị chữ: 37.5 | `Text` trơn: **36**; nhãn cạnh control: 37.5 | `Text` trơn cao 16 thay vì 17.5 nên hàng thấp hơn 1.5. |
| Nhãn + công tắc | 37.5 | 37.5 | Khớp. |
| Nhãn + pop-up | 37.5 | 37.5 | Khớp. |
| Nhãn + thanh trượt | 37.5 (Bàn phím) đến 38.5 (Âm thanh) | Chưa đo | |
| Nhãn + dòng phụ 1 dòng (+ control) | 55.5 (10 + 17.5 + 2 + 16 + 10) | 55.5 (`LabeledContent` hai `Text`) | Khớp. Dòng phụ 2 dòng: 71.5. |
| Nhãn + nút | **40** (Ngày & Giờ, Màn hình khoá); **44** (Bàn phím, "Nguồn đầu vào") | 40 (`LabeledContent` + `Button`) | Khớp với đa số pane; pane Bàn phím là ngoại lệ. |
| Hàng chỉ có nút | 44 (nút căn phải, "Phím tắt bàn phím…") | 44 (nút căn trái) | Cao khớp; vị trí nút khác: System Settings căn phải. |
| Nhãn + segmented | Hàng có thanh tab "Đầu ra / Đầu vào" (Âm thanh) không có nhãn, segmented rộng hết hàng | ≈ 40, segmented căn phải, các ô bằng nhau | Số SwiftUI đo ở màn 1x nên làm tròn. |
| Cỡ chữ nhãn | 13, thường, màu chữ chính, khung cao 17.5 | 13, thường, như nhau | Khớp. |
| Cỡ chữ dòng phụ / giá trị bên phải | 11 thường màu chữ phụ / 13 thường màu chữ phụ | 11 / 13, màu chữ phụ | Khớp. |
| Đường phân cách | Dày 1 (2 px), thụt 10 hai bên (theo lề chữ), nằm giữa hai hàng, màu ≈ (66, 66, 65) | Như nhau | Khớp. |
| Công tắc | 36 × 16 | 36 × 16 | Khớp. |
| Pop-up | Cao 24, không viền: chữ giá trị + nút tròn mũi tên lên/xuống | Cao 24, cùng hình dáng | Khớp. |
| Nút bấm | Cao 24, nền phẳng, góc ≈ 5, không viền; ví dụ "Đặt…" 55 × 24 | Cao 24, cùng hình dáng; "Đổi…" 55 × 24 | Khớp. |
| Segmented | Cao 24, góc ≈ 5, ô chọn nền màu nhấn | Cao 24, ô bằng nhau | Khớp về cao. |

### Sheet

Đo 02/11/2026, cùng máy, giao diện Tối. Sheet mở bằng AXPress trên nút của pane (mở bằng URL), đóng bằng "Xong"/"Huỷ"; không đổi cài đặt nào. Toạ độ tính từ góc trên trái sheet.

| Thông số | Màn hình › Nâng cao… | Bàn phím › Nguồn đầu vào › Sửa… | Bàn phím › Sửa… › + (AppKit cũ) | SwiftUI (`Form(.grouped)` + `searchable` + `toolbar` trong sheet) |
|---|---|---|---|---|
| Kích thước | 470 × 454 | 640 × 468 (sidebar 200 + Form) | 564 × 392 | Rộng theo `frame(width:)`, cao theo nội dung Form + thanh tìm 44 + thanh nút 65 |
| Thẻ của Form | x 20, rộng = sheet − 40, cách mép trên 20, thẻ cách thẻ 10, tiêu đề nhóm → thẻ 10 | Như cột trái (cách mép cột 20) | — (bảng có viền) | Như System Settings; có ô tìm thì Form bắt đầu dưới thanh tìm (y 44) và thẻ/tiêu đề đầu cách 20 |
| Thanh nút | Vạch ngăn dưới Form; "Xong" 64 × 24, nền màu nhấn, cách mép phải và mép dưới 20, cách đáy Form 21 | Như bên trái | "Huỷ", "Thêm" 72 × 26 (kiểu cũ), cách mép 19–20 | `ToolbarItem(.cancellationAction / .confirmationAction)`: vạch ngăn, nút tối thiểu 64 × 24, cách mép phải và dưới 20, cách đáy Form 21, hai nút cách nhau 8; `.automatic` đặt ở đầu trái thanh nút (x 20) |
| Ô tìm | Không có | Không có | Dưới trái, 226 × 26 (kiểu cũ) | `searchable` trong sheet: trên phải, 183 × 24, cách mép trên và phải 20 |
| Tiêu đề | Không có | Không có | Một dòng chữ 13 ở trên trái | `navigationTitle` không hiện (không có NavigationStack); có NavigationStack thì tiêu đề nằm hàng riêng dưới ô tìm, x 48 |

Sheet thêm quy tắc của Dấu (đo 02/11/2026, macOS 27.2):
- `List` đặt trong `Form(.grouped)` bị tắt cuộn: vùng cuộn bên trong không có thanh cuộn, lăn chuột không đổi hàng nào, `scrollDisabled(false)` và `\.isScrollEnabled` không bật lại.
  - Nên danh sách đặt ngoài Form, trong `GroupBox` (thẻ hệ thống); chỉ hàng "Khi đang gõ" còn trong Form.
- `searchable` luôn tạo thanh riêng ở đầu sheet và `ToolbarItem(.navigation / .principal)` không hiện trong sheet, nên không đặt được tiêu đề cùng hàng.
  - Dùng `NSSearchField` (control hệ thống) cùng hàng với tiêu đề, 183 × 24 như `searchable`, cách mép trên và phải 20.

Kết luận cho sheet của Dấu (sửa 03/11/2026 cho khớp mã):
- Nút trên `toolbar` cho ra đúng thanh nút của sheet System Settings; thẻ `Form(.grouped)` cho ra đúng lề và khoảng cách thẻ.
- Sheet của System Settings không có tiêu đề; nội dung của mockup có tiêu đề. `AddAppRuleSheet` đặt, từ trên xuống:
  - một hàng đầu gồm tiêu đề bên trái và `NSSearchField` bên phải (183 × 24, cách mép trên và phải 20, cỡ của `searchable` trong sheet);
  - danh sách trong `GroupBox`;
  - `Form(.grouped)` chỉ có thẻ "Khi đang gõ";
  - thanh nút.
- Chiều cao thẻ danh sách (188) lấy từ mockup, không có số System Settings tương ứng; giữ 188: không có số chuẩn nào để thay, và đổi không giúp gì cho người dùng.

### Độ rộng tối đa của Form dạng nhóm (lỗi "cột hẹp ở giữa")

- `Form.formStyle(.grouped)` giới hạn thẻ ở **704 pt** và đặt giữa pane. Ở cột chi tiết rộng ≤ 744 (thẻ = pane − 40) không thấy giới hạn; rộng hơn thì hai bên lề to dần. Đo được: pane 676 → thẻ 636; pane 856 → thẻ 704 (lề 76); pane 1256 → thẻ 704 (lề 276).
- `.frame(maxWidth: .infinity)` trên Form **không** gỡ giới hạn này; `.contentMargins(.horizontal, 20, for: .scrollContent)` cũng không.
- Với sidebar 232, cửa sổ rộng ≤ 976 thì không chạm giới hạn. Cửa sổ 740 như System Settings cho thẻ 468, trùng System Settings.
- System Settings có giới hạn tương tự hay không thì chưa biết vì không đổi kích thước cửa sổ khi đo (xem mục dưới).

### Icon ứng dụng trong hàng

Đo 02/11/2026, macOS 27.2, giao diện Tối, cửa sổ System Settings nằm trên màn **1x** (không di chuyển cửa sổ khi đo, nên số làm tròn tới 1 pt). Chỉ mở pane bằng URL, không bấm gì. Khung hàng đọc bằng Accessibility API; icon ứng dụng không phải phần tử trợ năng nên đo theo điểm ảnh: khung bao các điểm khác màu nền thẻ ("nét vẽ"). Icon ứng dụng macOS chỉ vẽ ≈ 80% khung (lưới icon 824/1024; icon của Dấu cũng vậy: 412/512), nên khung = nét vẽ ÷ 0,805.

| Pane (URL) | Loại hàng | Hàng | Nét vẽ icon | Khung suy ra | Chữ bắt đầu |
|---|---|---|---|---|---|
| Cài đặt chung › Mục đăng nhập & tiện ích mở rộng › Hoạt động nền (`com.apple.LoginItems-Settings.extension`) | Icon, tên + dòng phụ, công tắc | 57 | 26 × 26 từ x 265 | **32**, từ x 262 (mép thẻ + 10) | x 304 (sau khung 10) |
| Thông báo › Thông báo của ứng dụng (`com.apple.Notifications-Settings.extension`) | Icon, tên + dòng phụ, chevron | 56 | 26 × 26 từ x 264 | **32** | x 302 |
| Quyền riêng tư & Bảo mật › Trợ năng (`com.apple.preference.security?Privacy_Accessibility`; tiêu đề trên máy đo: "Device Control and Data Access") | Danh sách trong thẻ có +/−: icon, tên một dòng, công tắc | 42 | 20 × 20 từ x 263 (một app 22) | **24**, từ x 261 (nhãn cao 24) | x 294 |
| Mục đăng nhập › Mở khi đăng nhập (cùng pane) | Bảng có cột "Item / Kind" | 26 | 14 × 14 | 16 | — |
| Thẻ đầu pane: Thông báo, Siri (`com.apple.Siri-Settings.extension`) | Icon pane, tên + mô tả | thẻ 72 | 26 × 26 từ x 264 | Icon pane (ô vuông bo góc, vẽ kín khung): 26 | x 302 |

Không gặp hàng nào hiện icon ứng dụng 28 hay 48.

Áp dụng cho Dấu (`AppIcon`):
- Hàng "Quy tắc riêng" và danh sách của sheet thêm quy tắc (một dòng, kèm control): 24 như Trợ năng.
- Hàng "Đề xuất" (có dòng phụ): 32 như Hoạt động nền và Thông báo.
- Thẻ đầu "Cập nhật & hỗ trợ": 32, để nét vẽ icon app bằng 26 như icon ở thẻ đầu pane.
- Khoảng icon → chữ của Dấu giữ 8 (`HStack` mặc định); System Settings 9–10.
- Kiểm lại trên cửa sổ thật của Dấu (màn Retina, cùng ngày): nét vẽ icon hàng "Đề xuất" và thẻ đầu "Cập nhật & hỗ trợ" 26 × 26 từ x 265, trùng System Settings.

### Cửa sổ có đổi rộng được không

Đo 02/11/2026 trên cửa sổ System Settings đang mở (740 × 560), chỉ đọc, không đổi kích thước:

| Cách đọc | Kết quả |
|---|---|
| `AXUIElementIsAttributeSettable(window, kAXSizeAttribute)` | `true` (vị trí cũng `true`) |
| Nút phóng to (`AXZoomButton`) | Có, bật (`AXEnabled` = true), 64,18 16 × 16; không có `AXFullScreenButton` riêng |
| Vùng kéo (`AXGrowArea`) | Tên thuộc tính có trong danh sách nhưng không có giá trị (cửa sổ macOS hiện đại không có vùng kéo riêng) |
| Style mask qua `CGWindowListCopyWindowInfo` | Không đọc được: thông tin cửa sổ chỉ có `Alpha, Bounds, IsOnscreen, Layer, MemoryUsage, Name, Number, OwnerName, OwnerPID, SharingState, StoreType` |
| Khung lưu trong cài đặt (`defaults read com.apple.systempreferences`, container) | Không có khoá khung cửa sổ |

Kết luận:
- AppKit báo cửa sổ **đổi được kích thước** (kích thước ghi được, nút phóng to bật).
- Các cách đọc trên không tách được chiều ngang với chiều dọc: một cửa sổ chỉ đổi được chiều cao cũng cho đúng các kết quả này.
- Đo trực tiếp ngày 09/11/2026 (macOS 27.2, 26B123; System Settings mở ở pane mặc định, cửa sổ 740 × 765): đặt `AXSize` qua System Events rồi đọc lại.
  - Đặt rộng 940: đọc lại 740. Đặt rộng 590: đọc lại 740. Độ rộng **cố định ở 740**.
  - Đặt cao 915: đọc lại 876 (cao hơn 765, thấp hơn giá trị đặt, có lẽ do giới hạn của màn hình). Chiều cao **đổi được**.
  - Trả về 740 × 765 và vị trí cũ, rồi thoát System Settings (trước khi đo nó không chạy).
- Dấu làm theo từ 09/11/2026: cửa sổ Cài đặt rộng cố định 740 (`SettingsScene.minSize`), chỉ đổi chiều cao. Trước đó Dấu cho kéo rộng tới 976.

### Nút mở/thu kiểu "Nâng cao"

Rà 02/11/2026 bằng Accessibility API ở các pane Wi-Fi, Mạng, Bàn phím, Bàn di chuột, Chia sẻ, Desktop & Dock, Thanh menu, Màn hình khoá, Màn hình, Spotlight, Trợ năng, Âm thanh, Pin (mở bằng URL, không bấm): **không pane nào có hàng mở/thu** (`AXDisclosureTriangle` hay nút chevron xoay).

Tuỳ chọn nâng cao của System Settings nằm ở một trong ba chỗ:
- nhóm riêng có tiêu đề (Chia sẻ › "Advanced");
- sau nút mở sheet ("Nâng cao…" ở Màn hình, "Chi tiết…" ở Wi-Fi);
- nút "Show Detail" (i) ở cuối hàng.

Thử `DisclosureGroup(isExpanded:)` (nhãn `LabeledContent("Nâng cao") { tóm tắt }`, nội dung là hai công tắc) trong `Section` của Form dạng nhóm, cửa sổ thật 740 × 560 trên màn Retina, so với nút hệ thống + chevron đang dùng (D9). Bản thử build riêng, không đưa vào mã:

| | `DisclosureGroup` | Nút + chevron (hiện tại) |
|---|---|---|
| Thu gọn | Thẻ cao 45,5; chevron ở mép thẻ + 10, chữ "Nâng cao" từ x 273,5 (lùi 11,5 so với nhãn hàng khác ở x 262); tóm tắt bên phải | Gần như giống hệt: chevron x 262, chữ sau chevron 8 |
| Mở ra: thụt lề hàng con | **Không thụt**: nhãn "Gõ tắt phụ âm" x 262 như hàng thường | Không thụt (x 262) |
| Mở ra: hàng mở → hàng con đầu | **Không có vạch ngăn**; chữ "Nâng cao" kết thúc y 497,5, nhãn hàng con bắt đầu y 501,5 (sát 4 pt) | Có vạch ngăn của Form; nhãn hàng con y 513 (cách 21, lề 10 của hàng) |
| Trợ năng | `AXDisclosureTriangle` **không có action nào**; `AXDisclosing` không ghi được: không mở được qua Accessibility API (chưa thử bằng VoiceOver thật) | `AXButton` "Nâng cao" có `AXPress`, giá trị là tóm tắt, gợi ý "Mở rộng/Thu gọn" |

Kết luận:
- Trên macOS 27.2 lý do cũ trong D9 ("DisclosureGroup làm thụt lề sai bố cục") không còn đúng.
- Nhưng `DisclosureGroup` trong Form vẫn lệch cách System Settings vẽ hàng (không vạch ngăn, hàng con dính vào hàng mở) và không mở được qua trợ năng; System Settings cũng không có hàng mở/thu để làm mẫu.
- Giữ nút + chevron; lý do đã ghi trong D9.

### Mặc định SwiftUI đã khớp

- Thanh công cụ cao 52; tiêu đề trang 15 đậm.
- Sidebar: hàng 32, vùng chọn lề 10 và góc ≈ 7, ô icon 20 ở x 19, chữ 13 ở x ≈ 46, khoảng giữa nhóm 13. Ô tìm 212 × 28 ở (10, 61) khi dùng `.searchable(placement: .sidebar)`.
- Form dạng nhóm: lề thẻ 20, góc thẻ ≈ 11, màu thẻ và nền, tiêu đề nhóm (13 semibold, lề 10, cách thẻ 10, cách thẻ trước 30), lề trong hàng 10, đường phân cách 1 thụt 10.
- Chiều cao hàng: nhãn + công tắc/pop-up 37.5, nhãn + dòng phụ 55.5, nhãn + nút 40, hàng chỉ có nút 44.
- Control: công tắc 36 × 16, pop-up/nút/segmented cao 24, cùng hình dáng.
- Cỡ chữ: nhãn 13, dòng phụ và chú thích 11 màu chữ phụ, giá trị 13 màu chữ phụ.

### Cần chỉnh / không khớp

Đã giải quyết trong app (02/11/2026, d446a09):
- sidebar 232 + ô tìm `.searchable(.sidebar)`;
- lề trên giữ 20 (D9: không đè thông số hệ thống);
- nút sidebar bị gỡ như System Settings;
- cửa sổ rộng cố định 740 như System Settings, nên thẻ không bao giờ chạm giới hạn 704;
- nút trong hàng chỉ có nút căn phải.

Từ 05/11/2026 thanh công cụ có cụm Lùi/Tiến như System Settings nên tiêu đề hệ thống giữ 15 đậm (trước đó là `PageTitle` tự vẽ).

Chi tiết từng mục:

- **Độ rộng sidebar**: mặc định 144, System Settings 232. Mặc định làm cụt chữ "Cập nhật & hỗ trợ". Cách gần nhất: `navigationSplitViewColumnWidth(232)`; đặt rồi thì mọi số đo sidebar và lề form trùng System Settings.
- **Ô tìm ở sidebar**: mặc định không có; dùng `.searchable(placement: .sidebar)` là ra đúng khung của System Settings.
- **Lề trên form**: 20 so với 12. Chưa tìm được cách giảm bằng API công khai (`contentMargins` chỉ cộng thêm). Dấu giữ 20 theo D9 (không chỉnh thông số hệ thống); muốn khớp 12 thì phải đổi D9, việc của người dùng.
- **Nút trên thanh công cụ**: SwiftUI tự thêm nút ẩn/hiện sidebar; System Settings có Lùi/Tiến thay vào đó.
  - Bỏ nút bằng `.toolbar(removing: .sidebarToggle)` làm thanh công cụ co từ 52 xuống 32 và tiêu đề trang thành chữ tiêu đề cửa sổ; muốn giữ thanh 52 thì để nguyên nút.
  - Đã giải quyết (05/11/2026): cụm Lùi/Tiến bằng `ControlGroup { … }.controlGroupStyle(.navigation)` ở `.navigation` giữ thanh 52 và tiêu đề hệ thống 15 đậm.
  - Đo trên Dấu (`run.sh` 05/11/2026): nút Lùi 239.5,8 36×36, Tiến 275.5,8 37×36, khung tiêu đề x 316.5 (1x: 317).
  - System Settings đo cùng ngày: 240,8 36×36 và 276,8 37×36, vạch ngăn x 276, nét tiêu đề từ x 326.
  - Sidebar của System Settings (05/11/2026): kéo đường chia 200 pt sang hai bên và bấm đúp không đổi độ rộng, không thu được, con trỏ là mũi tên.
  - Sidebar của Dấu (từ 06/11/2026, D9): cố định bằng `NSSplitViewController` của app, chưa đo trên cửa sổ thật (đo trên app thử: `docs/research/SWIFTUI-WINDOW-API.md` mục 10).
- **Hàng chỉ có `Text`**: cao 36, không phải 37.5 như hàng nhãn + control (System Settings không có hàng nhãn trơn để so).
- **Hàng chỉ có nút**: SwiftUI căn nút trái; System Settings căn nút phải.
- **Form rộng**: thẻ không quá 704; cửa sổ rộng cố định 740 nên không ảnh hưởng.

### Nguồn API (tài liệu Apple)

- `formStyle(.grouped)`: https://developer.apple.com/documentation/swiftui/formstyle/grouped ("A form style with grouped rows", macOS 13+).
- `navigationSplitViewColumnWidth(_:)`: https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(_:) (macOS 13+).
- `SearchFieldPlacement.sidebar`: https://developer.apple.com/documentation/swiftui/searchfieldplacement/sidebar (macOS 12+).
- `toolbar(removing:)` và `ToolbarDefaultItemKind.sidebarToggle`: https://developer.apple.com/documentation/swiftui/view/toolbar(removing:), https://developer.apple.com/documentation/swiftui/toolbardefaultitemkind/sidebartoggle (macOS 14+, "The sidebar toggle toolbar item a NavigationSplitView adds by default").
- Tài liệu Apple không công bố các con số 704, 20, 12, 37.5. Mọi số trong mục này là số đo trên máy, không phải thông số Apple cam kết; có thể đổi theo phiên bản macOS.
