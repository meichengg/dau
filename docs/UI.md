# Giao diện

Mỗi phần của giao diện có một nguồn:

- **Trông như thế nào:** canvas mockup https://claude.ai/artifact/B2xhNxL3voGwTkXkFV72Ln (mục, thứ tự, icon, trạng thái).
  - Canvas trên claude.ai là nơi sửa thiết kế. Sửa canvas trước mỗi thay đổi giao diện, người dùng duyệt rồi mới sửa mã (D9 (Giao diện)).
  - `docs/ui/canvas` là bản chụp chỉ đọc của canvas trong repo, sinh lại bằng `scripts/design/render-canvas.sh`:
    - `docs/ui/canvas/README.md`: mục lục.
    - `docs/ui/canvas/<Tên>.png`: ảnh từng artboard.
    - `docs/ui/canvas/src/<Tên>.dc.html`: nguồn của artboard (agent đọc file này).
  - Canvas có hai trang. "Thiết kế" là nơi sửa. "Lưu trữ 06/11 (không sửa)" giữ mockup gốc trước khi cập nhật theo giao diện đã dựng, chỉ để đối chiếu (artboard tên `Archive-…`).
- **Bố cục, khoảng cách, control:** System Settings của macOS hiện hành (D9).
  - Số đo ở `docs/research/SYSTEM-SETTINGS-REFERENCE.md`.
  - Mức đạt ở `scripts/selftest/settings-window/Reference.swift`.
- **Chữ:** String Catalog trong mã (`Localizable.xcstrings`), khoá là câu tiếng Anh, có bản tiếng Việt. Ngôn ngữ hiện ra theo D41 (Ngôn ngữ giao diện).
  - Canvas viết tiếng Việt.
  - Câu mới giao cho mã kèm câu tiếng Anh làm khoá.
- **File này:** chỉ ghi hành vi, trạng thái, quy tắc và lý do, tức những gì hình vẽ và mã không tự nói ra.
  - Không liệt kê chữ hay bố cục của phần đã có mã.
  - Phần chưa có mã (cuối file) tạm mô tả nội dung cho tới khi dựng.
  - Lịch sử (ngày duyệt, phiên bản canvas): `docs/history/DOCS-LOG.md`.

Khi các nguồn lệch nhau, `DECISIONS.md` quyết định; sửa bên sai cho khớp.

## Menu nguồn nhập liệu (hệ thống vẽ)

Artboard: [Menu nguồn đầu vào](ui/canvas/Main.png).

- Không có status item riêng.
- Dấu có một input mode (D2 (Chuyển Việt/Anh)). Gõ tiếng Anh bằng nguồn U.S. (hoặc nguồn tiếng Anh khác) của người dùng.
- Bộ gõ chỉ bổ sung qua `menu()` của IMK:
  - ba kiểu gõ (Telex, VNI, Telex đơn giản) và "Cài đặt Dấu…";
  - nằm dưới tiêu đề nhóm "Dấu" của hệ thống, không có tiêu đề riêng;
  - không có mục mở Cài đặt Bàn phím vì hệ thống đã có "Open Keyboard Settings…" (N1 (Không làm lại việc hệ thống đã có)).

## Onboarding

Chữ của Dấu nói về macOS:

- Mọi tên giao diện của macOS trong chữ của Dấu (System Settings, Keyboard, Input Sources, Edit…, Allow…) hiện đúng như macOS của người dùng, theo ngôn ngữ hệ thống (D38 (Chữ trên giao diện); `docs/ARCHITECTURE.md`, `SystemUINames`).
- Câu tiếng Việt nói "nguồn đầu vào", không nói "nguồn nhập liệu", và không dùng chữ "app".
- Tên bàn phím nào Dấu nêu (bàn phím tiếng Anh ở dòng phím tắt, bàn phím đã chuyển sang khi gỡ) viết như thanh menu của macOS.
  - Theo ngôn ngữ hệ thống, không theo ngôn ngữ giao diện của Dấu.
  - Không có bản dịch thì dùng tên hệ thống trả về (`docs/ARCHITECTURE.md`, `LayoutNames`).

Khung chung:

- Ba bước. Thanh bước bên trái có trạng thái xong / đang làm / chưa.
- Cuối thanh bước chỉ có dòng "Dấu không cần quyền điều khiển máy Mac." (không viết tên mục "Trợ năng" của macOS, D38) (đã đo 30/10/2026).
- Không hứa macOS hỏi mấy lần, vì "Thử lại" sau Don't Allow làm hộp thoại hiện lại (N5 (Chỉ hứa điều đã kiểm chứng)).

### Bước 1, tắt bộ gõ cũ

Artboard: [bước 1](ui/canvas/OnboardingConflict.png).

- Chỉ hiện khi phát hiện bộ gõ chặn phím đang chạy (bundle ID trong `docs/research/M5-INSTALL.md` mục 5). Lúc mở không có bộ gõ nào chạy thì bỏ qua bước này.
- Hướng dẫn tắt chỉ ghi tên menu đã kiểm chứng. App chưa kiểm thì ghi chung "Thoát <tên>" và đường dẫn Mục đăng nhập (N5).
- Tự kiểm tra lại khi cửa sổ được kích hoạt. Cho phép bỏ qua.
- **Đã tắt bộ gõ cũ** ([`OnboardingConflictDone`](ui/canvas/OnboardingConflictDone.png)): màn bước 1 khi người dùng bấm "Quay lại" ở bước 2 mà không còn bộ gõ cũ nào chạy.
  - Thẻ liệt kê các bộ gõ cũ đã phát hiện trong lượt onboarding này, mỗi bộ gõ có nhãn xanh "Đã tắt".
  - Nút duy nhất "Tiếp tục" sang bước 2; thanh bước vẫn ở bước 1.
  - Có bộ gõ cũ chạy lại (kiểm tra lại khi cửa sổ được kích hoạt) thì hiện lại màn tắt bộ gõ cũ.

### Bước 2, bật Dấu

- Chép bộ gõ vào `~/Library/Input Methods` và đăng ký.
- Chỉ bật nguồn nhập liệu khi người dùng bấm "Bật Dấu" (N4 (Không tự đổi cài đặt hệ thống), D37 (Cài đặt bộ gõ)).
- macOS hỏi người dùng có cho Dấu bật không (hộp thoại "Allow"), nên bước có nhiều màn: [`OnboardingEnable`](ui/canvas/OnboardingEnable.png), [`OnboardingEnableNotes`](ui/canvas/OnboardingEnableNotes.png), [`OnboardingEnableWaiting`](ui/canvas/OnboardingEnableWaiting.png), [`OnboardingEnableDone`](ui/canvas/OnboardingEnableDone.png), [`OnboardingEnableDoneNoShortcut`](ui/canvas/OnboardingEnableDoneNoShortcut.png), [`OnboardingEnableFailed`](ui/canvas/OnboardingEnableFailed.png), [`OnboardingEnableError`](ui/canvas/OnboardingEnableError.png).
- Mọi bước dùng chung một khung:
  - tiêu đề, mô tả và nội dung cuộn được;
  - hàng nút cố định ở đáy, có đường kẻ phía trên khi nội dung bị che;
  - nhờ vậy nội dung dài không tràn ra ngoài cửa sổ.
- Tên màn hình của macOS viết tiếng Anh như trên máy người dùng (System Settings › Keyboard › Input Sources).
- Kết quả đọc lại từ hệ thống, không báo thành công khi chưa thấy bật (N5).
- Không có Hoàn tác: app không tự tắt được Dấu (macOS chặn), chỉ người dùng bỏ Dấu trong System Settings.

**Quay lại** (D14 (Onboarding)): nút phụ kiểu hệ thống bên trái nút chính (D9).

- Có trên các màn trước khi Dấu được bật: trước khi bấm, đang chờ, lỗi cài.
- Chỉ có khi bước 1 đã hiện trong lượt onboarding này. Bước 1 không hiện (không có bộ gõ cũ) thì không có nút, để nút không dẫn tới một màn trống.
- Bấm thì:
  - huỷ lần chờ đang chạy (cùng cách "Thử lại" huỷ);
  - bỏ lỗi vừa gặp;
  - về bước 1, nơi kiểm tra lại bộ gõ cũ: còn chạy thì hiện màn tắt bộ gõ cũ, không còn thì hiện "Đã tắt bộ gõ cũ".
- Màn "đã bật" và "chưa bật được" giữ nút riêng như artboard, không có "Quay lại".

**Phím tắt chuyển nguồn** ở mọi câu của onboarding:

- Vẽ bằng keycap như trang Gõ phím, mỗi phím một keycap, đọc từ cài đặt hệ thống (N5).
- Không có dòng phụ nào nói phím tắt "hiện đúng trên máy".
- Câu gợi ý ở bước 3 dùng keycap nhỏ theo cỡ chữ gợi ý ([`OnboardingNotSelected`](ui/canvas/OnboardingNotSelected.png)).
- VoiceOver đọc cả câu, phím tắt viết bằng chữ.

**Trước khi bấm** ([`OnboardingEnable`](ui/canvas/OnboardingEnable.png)):

- Thẻ "Sau khi bật, bạn sẽ thấy".
- Thẻ nói trước điều sắp xảy ra (System Settings đóng rồi mở lại, hộp thoại hỏi), kèm hình thu nhỏ hộp thoại của macOS (minh hoạ, ẩn với VoiceOver).
- Phím tắt không đọc được thì hàng phím tắt là một dòng nói vậy kèm nút mở System Settings, không có keycap rỗng.
- Nhắc nhẹ (biểu tượng thông tin) khi có nguồn tiếng Việt kiểu IMK khác đang bật (D14), không chặn.

**Đang chờ** ([`OnboardingEnableWaiting`](ui/canvas/OnboardingEnableWaiting.png)): trong lúc `enable()` chờ mục lưu của Dấu.

- Thẻ trạng thái có vòng xoay.
- "Thử lại" huỷ lần chờ đang chạy rồi bật lại (macOS hỏi lại).
- "Quay lại" (nếu có, xem trên) cũng huỷ, không để lần chờ nào chạy tiếp.
- Màn tự chuyển sang "đã bật" khi macOS ghi mục.

**Đã bật** ([`OnboardingEnableDone`](ui/canvas/OnboardingEnableDone.png)): nút duy nhất "Tiếp tục".

- Câu chọn Dấu nêu **phím tắt thật** đọc từ cài đặt hệ thống, không viết cứng (N5), vẽ bằng keycap.
- Chưa đặt phím tắt thì nói vậy và có nút đặt phím tắt trong System Settings ([`OnboardingEnableDoneNoShortcut`](ui/canvas/OnboardingEnableDoneNoShortcut.png)).
- Không đọc được phím tắt thì chỉ nói chọn trong menu nhập liệu, không khẳng định gì về phím tắt, kèm cùng nút.
- Dưới thẻ có một dòng gợi ý: một ứng dụng chưa chọn được Dấu thì đăng xuất ( › Log Out) rồi đăng nhập lại một lần (D37).

**Chưa bật được** ([`OnboardingEnableFailed`](ui/canvas/OnboardingEnableFailed.png)): hết hạn chờ, hoặc macOS không liệt kê Dấu.

- Ba cách theo thứ tự: Thử lại; tự thêm trong System Settings; đăng xuất một lần.
- Không tự mở Cài đặt, có nút "Mở System Settings".
- Nếu sau đó Dấu xuất hiện (người dùng tự thêm), cửa sổ nhận ra và sang "đã bật".

**Lỗi cài** ([`OnboardingEnableError`](ui/canvas/OnboardingEnableError.png)): lỗi chép, kiểm chữ ký, đăng ký.

- Màn riêng "Chưa cài được Dấu", hai cách xử lý.
- Dòng "Chi tiết" là mô tả thật của lỗi (chọn được để chép).
- Nút "Thử lại" bật lại từ đầu.

### Bước 3, chọn kiểu gõ và gõ thử

Artboard: [bước 3](ui/canvas/Onboarding.png), [Dấu chưa là nguồn đang dùng](ui/canvas/OnboardingNotSelected.png).

- Ví dụ gõ thử phải đúng quy tắc của kiểu gõ đang chọn.
- Dấu chưa phải nguồn đang dùng thì có câu gợi ý cách chọn Dấu, kèm phím tắt thật bằng keycap nếu đọc được (N5).

## Cửa sổ Cài đặt

Artboard: các artboard "Cài đặt – …" ([Gõ phím](ui/canvas/SettingsTyping.png), [Thông minh](ui/canvas/SettingsSmart.png), [Ứng dụng](ui/canvas/SettingsApps.png), [Cập nhật & hỗ trợ](ui/canvas/SettingsAbout.png)).

- Thanh công cụ có cụm Lùi/Tiến trước tiêu đề trang, như System Settings.
  - Có lịch sử các mục đã xem.
  - Mở cửa sổ thì cả hai tắt.
  - Tiêu đề là tiêu đề hệ thống (D9).
- Sidebar cố định như System Settings (D9):
  - không kéo rộng hẹp, không thu gọn;
  - menu View không có mục ẩn/hiện sidebar.
- Edit › Find › Find… (⌘F) đưa con trỏ vào ô tìm của sidebar (D9).
- Ô tìm của sidebar khớp tên mục và mọi chữ nhìn thấy trong mục (tiêu đề hàng, tiêu đề nhóm, lựa chọn, nút), không phân biệt hoa thường, dấu, "đ"/"d" ([`SettingsSearchEmpty`](ui/canvas/SettingsSearchEmpty.png)).
  - Không mục nào khớp thì sidebar hiện trạng thái trống của hệ thống, trang đang mở giữ nguyên.
- Mô tả của một nhóm nằm dưới tiêu đề nhóm, trên thẻ (như System Settings).

### Gõ phím

- Thẻ xem trước tính bằng engine thật, cập nhật ngay theo kiểu gõ và vị trí dấu.
- Chuyển Việt ↔ Anh là chuyển nguồn nhập liệu.
  - Hàng phím tắt hiện phím tắt hệ thống hiện tại.
  - Nút "Đổi…" mở Cài đặt Bàn phím (N4).
  - Không có phím chuyển riêng (D2).

### Thông minh

Artboard: [Thông minh](ui/canvas/SettingsSmart.png), [mở "Nâng cao"](ui/canvas/SettingsSmartAdvanced.png).

- Tự khôi phục từ không phải tiếng Việt (D4 (Từ nước ngoài)).
  - Ví dụ trong ghi chú phải khớp hành vi engine: từ trùng thì tiếng Việt thắng, gõ đúp phím dấu để giữ chữ gốc.
- Thêm dấu cho từ đã gõ (D20 (Thêm dấu cho từ đã gõ)):
  - ghi chú nêu phạm vi (không áp dụng ở app có quy tắc gạch chân);
  - độ ổn định trên web editor để ô trống cho tới khi đo (N5).
- "Nâng cao" thu gọn, tóm tắt số tuỳ chọn và trạng thái.
  - "Gõ tắt phụ âm" và "Cho phép phụ âm z, f, w, j" loại trừ nhau, bật mục này tắt mục kia (D22 (Gõ tắt loại trừ z, f, w, j)).
  - Với Telex, w đầu từ luôn thành ư nên mục thứ hai chỉ tác dụng với z, f, j (D23 (w → qu chỉ ở VNI)).
  - Cả hai mặc định tắt.

### Ứng dụng

Artboard: [Ứng dụng](ui/canvas/SettingsApps.png), [chưa có quy tắc riêng](ui/canvas/SettingsAppsEmpty.png).

- "Nhớ nguồn nhập liệu theo từng cửa sổ" là tuỳ chọn của macOS.
  - Dấu chỉ đọc trạng thái, không ghi.
  - Không đọc được thì không hiện chữ (N5).
  - Nút "Đổi…" mở Cài đặt Bàn phím (D5 (Quy tắc theo ứng dụng), N4).
- "Quy tắc riêng": chỉ các quy tắc đã lưu.
  - Đặt về "Không gạch chân" vẫn giữ quy tắc.
  - Xoá quy tắc (menu chuột phải hoặc Delete) thì app đề xuất trở lại "Đề xuất".
- "Đề xuất": chỉ hiện khi có app trong danh sách tương thích (cờ `suggestUnderline`) đã cài mà chưa có quy tắc.
  - Bấm "Bật gạch chân" mới lưu quy tắc (nguồn đề xuất, giữ nhãn "Đề xuất"). Trước đó không lưu gì (D13 (Gạch chân là đường lui cuối cùng)).
  - Dòng phụ giống nhau ở mọi hàng.
  - Ghi chú trong danh sách tương thích là cho người bảo trì, không hiện (N5).
  - Ghi chú của mục chỉ nói khi nào nên chọn gạch chân, không hứa sửa được (số đo: D13).
- Ô tìm của trang lọc cả hai mục.

### Cập nhật & hỗ trợ

Artboard: [Cập nhật & hỗ trợ](ui/canvas/SettingsAbout.png).

- **Hàng "Ngôn ngữ"** (D41; artboard [theo macOS](ui/canvas/SettingsLanguage.png), [Dấu đặt riêng English, macOS tiếng Việt](ui/canvas/SettingsLanguageEn.png), [đã đổi sang English, chưa mở lại Dấu](ui/canvas/SettingsLanguagePending.png)):
  - Thẻ riêng ngay dưới thẻ phiên bản. Dấu chỉ đọc, không ghi.
  - Giá trị là ngôn ngữ Dấu đang hiện, viết bằng chính ngôn ngữ đó.
  - Câu phụ có hai dạng:
    - theo macOS (miền cài đặt của app không có khoá `AppleLanguages`): hướng dẫn bấm "Đổi…" rồi + ở mục Applications;
    - đặt riêng: nói là đặt riêng cho Dấu và cách đổi hoặc bỏ.
  - "Đổi…" mở trang Language & Region.
  - Chờ mở lại: khi ngôn ngữ của lần mở sau khác ngôn ngữ đang hiện.
    - Ngôn ngữ của lần mở sau tính từ khoá của app, không có thì từ danh sách của macOS.
    - Giá trị là ngôn ngữ của lần mở sau.
    - Câu phụ giữ phần đầu ("Đặt riêng cho Dấu." hoặc "Theo macOS.") rồi nói Dấu dùng ngôn ngữ đó sau khi mở lại.
    - Có thêm nút "Mở lại Dấu" trước "Đổi…".
  - Tên mục của macOS theo D38.
  - Không nhắc menu bộ gõ khi chưa đo (câu hỏi mở về bộ gõ, N5).
- Trạng thái kiểm tra cập nhật và cách cài bản mới để ô trống cho tới M7 (Phát hành) (N5).
- **Bản phát triển** (D7 (Cập nhật và loại bản dựng), D25 (Nhận diện); artboard [bản phát triển](ui/canvas/SettingsAboutDev.png)):
  - thẻ đầu trang dùng biểu tượng bản phát triển và thêm dòng "Bản phát triển · Debug" (hoặc "· Release");
  - dòng phiên bản cuối sidebar thêm "· Debug"/"· Release";
  - bản chính thức không có dòng này; Beta hiện số phiên bản dạng "1.3 beta 2".
- Nút gỡ cài đặt dùng dạng `role: .destructive` của hệ thống (D9).
- Chú thích quyền riêng tư giữ đúng nội dung D8 (Không telemetry) và N2 (Bộ gõ không có quyền mạng).

### Sheet thêm quy tắc (nút +)

Artboard: [thêm quy tắc](ui/canvas/SettingsAppsAdd.png), [chưa chọn](ui/canvas/SettingsAppsAddEmpty.png).

- Danh sách: ứng dụng chưa có quy tắc đã lưu. App trong danh sách tương thích mang nhãn "Đề xuất" và giữ nhãn khi thêm.
- "Thêm" chỉ bật khi ứng dụng đang chọn còn trong danh sách đang lọc. Gõ tìm làm ẩn ứng dụng đang chọn thì bỏ chọn.

## Trạng thái bổ sung

- **Dấu chưa được bật** (người dùng gỡ khỏi nguồn đầu vào; artboard [`SettingsNotEnabled`](ui/canvas/SettingsNotEnabled.png), [`SettingsBannerStates`](ui/canvas/SettingsBannerStates.png)): banner đầu mọi mục Cài đặt. "Bật lại" bật Dấu rồi đọc lại trạng thái (N4).
  - Đang chờ người dùng bấm Allow: banner có vòng xoay; "Thử lại" huỷ lần chờ rồi bật lại.
  - Bật được:
    - banner xác nhận nêu phím tắt thật (như onboarding, N5; không đọc được thì không nêu);
    - nút "Ẩn" ẩn banner trong phiên này;
    - không có Hoàn tác (app không tự tắt được Dấu).
  - macOS vẫn để tắt hoặc lỗi: banner nói chưa bật được, kèm cách tự thêm trong System Settings và "Thử lại" (không tự mở System Settings).
  - Chưa cài hoặc macOS chưa liệt kê Dấu: mở cửa sổ thiết lập.
- **Bộ gõ trên máy đã bị thay** (artboard [`SettingsTampered`](ui/canvas/SettingsTampered.png)): chữ ký của bộ gõ trong `~/Library/Input Methods` không hợp lệ hoặc không cùng Team ID với app; kiểm lúc mở app và mỗi lần app được đưa lên trước.
  - Banner đỏ đầu mọi mục Cài đặt, nút "Cài lại" chép bản gốc trong app (đã kiểm chữ ký) đè lên.
  - Cài lại không được thì banner nói vậy và hướng dẫn gỡ rồi cài lại từ bản tải về.
- **Chế độ tối** ([`SettingsDark`](ui/canvas/SettingsDark.png)): Cài đặt và onboarding đều có (màu hệ thống).
- **Gỡ cài đặt** (D16 (Bảo trì và gỡ cài đặt); artboard [`ConfirmDialogs`](ui/canvas/ConfirmDialogs.png), [`UninstallRemoveSource`](ui/canvas/UninstallRemoveSource.png)):
  - macOS chỉ cho người dùng tự bỏ một nguồn đầu vào, nên gỡ có ba bước.
  - Dấu không có trong nguồn đầu vào (chưa bật, hoặc người dùng đã tự bỏ) thì sau alert xác nhận gỡ luôn, không mở System Settings, không hiện sheet (D16).
  - Tên Thùng rác trong alert và sheet theo ngôn ngữ macOS (D38).
  - Alert xác nhận (hệ thống):
    - có tuỳ chọn xoá cả cài đặt và quy tắc;
    - nút xác nhận là "Tiếp tục gỡ", chưa xoá gì;
    - nội dung chỉ nói người dùng bỏ Dấu trong System Settings rồi Dấu được chuyển vào Thùng rác.
  - Sheet "Bỏ Dấu khỏi nguồn đầu vào" trên cửa sổ Cài đặt:
    - App không chuyển nguồn đầu vào nào (người dùng chọn).
    - App mở thẳng danh sách Input Sources của System Settings (đã mở sẵn sheet Edit…).
    - Sheet nêu một bước (chọn Dấu, bấm "–", Done) và chờ mục lưu của Dấu biến mất, không hết hạn.
    - Câu nhắc "nếu nút – bị mờ, chọn bàn phím khác" chỉ hiện khi Dấu đang là nguồn được chọn. Câu này đọc lại khi sheet hiện, khi cửa sổ thành key lại và khi nguồn đang chọn đổi, nên biến mất khi người dùng chuyển bàn phím.
    - "Huỷ gỡ cài đặt" (hoặc Esc, đóng sheet, hoặc gỡ lỗi giữa chừng) đóng sheet và không xoá hay đổi gì.
    - "Mở System Settings" chỉ mở trang.
  - Mục lưu biến mất thì: dừng bộ gõ, chuyển vào Thùng rác, xoá dữ liệu nếu đã tick, rồi alert nêu những gì đã làm (đọc lại từ hệ thống).
  - App không tự xoá chính nó, chỉ hướng dẫn kéo vào Thùng rác.
  - Bộ gõ không bao giờ bị xoá khi mục lưu còn: bundle mất trước thì mục còn lại không gỡ được.
- **Xác nhận quay về bản trước:** D19 (Quay về bản trước).
- **Khi gõ trong ứng dụng** (artboard [`TypingStates`](ui/canvas/TypingStates.png)):
  - không gạch chân (mặc định);
  - có gạch chân (từ đang gõ được gạch, chốt khi kết thúc từ);
  - gõ tiếng Anh bằng U.S. (chỉ báo của hệ thống);
  - thêm dấu cho từ đã gõ.

## Chưa có mã (mô tả nội dung tới khi dựng)

### Thẻ cập nhật (M7)

Artboard: [Trạng thái thẻ cập nhật](ui/canvas/UpdateStates.png).

Sáu trạng thái:

- đã mới nhất;
- đang kiểm tra;
- đang tải (thanh tiến trình, "Bạn vẫn gõ bình thường", nút Huỷ);
- chờ cài ("Sẽ cài khi bạn ngừng gõ", nút Cài ngay);
- không có mạng (nút Thử lại, "Dấu vẫn gõ bình thường");
- chữ ký không hợp lệ ("Đã huỷ bản cập nhật", nút Báo lỗi…).

Mọi câu hứa ở đây phải kiểm chứng ở M7 (N5).

### Thông báo cập nhật (M7)

Artboard: [Thông báo cập nhật](ui/canvas/Update.png).

- Icon app, "Đã có Dấu x.y.z", mô tả, "Có gì mới".
- Dòng "Đã xác minh chữ ký số của bản cập nhật".
- Checkbox "Tự động cài các bản sau".
- Nút: Cài đặt / Nhắc sau / Bỏ qua bản này.

### Báo ứng dụng gõ lỗi (M7)

Artboard: [Báo ứng dụng gõ lỗi](ui/canvas/Report.png).

- Đầu sheet có ô gợi ý "Ứng dụng không chọn được Dấu?": đăng xuất rồi đăng nhập lại một lần; thoát rồi mở lại ứng dụng thì chưa đủ; vẫn lỗi thì gửi báo lỗi (D37).
- Các trường: Ứng dụng (tự điền), Trang web (không bắt buộc), Loại lỗi (Mất chữ | Lặp chữ | Sai dấu | Khác), Ví dụ đã gõ.
- Mục "Gửi kèm" liệt kê phiên bản macOS, Dấu, kiểu gõ, phiên bản app, và câu "Không gửi nội dung bạn đã gõ."
- Ghi rõ issue GitHub là công khai.
- Nút: Huỷ / Sao chép nội dung / Mở trên GitHub (URL issue điền sẵn, không có backend, D8).

### Trang tải về (M8, Website)

Artboard: [máy tính](ui/canvas/Landing.png), [điện thoại](ui/canvas/LandingMobile.png).

- Phông Be Vietnam Pro, nền Giấy, màu nhấn Mực (D25, `docs/BRAND.md`).
- Một mã nguồn responsive cho máy tính và điện thoại.

Thứ tự mục:

1. **Thanh điều hướng:** logo, Tính năng / Bảng gõ / Hỏi đáp / GitHub (ẩn trên điện thoại), nút "Tải về".
2. **Hero:**
   - Dòng nhỏ chứa cụm "Bộ gõ tiếng Việt cho macOS" (cho tìm kiếm).
   - Tiêu đề "Gõ tiếng Việt trên Mac, tự nhiên như vốn có."
   - Nút "Tải về" + "Xem mã nguồn", dòng yêu cầu hệ thống.
   - Bên phải: **hoạt ảnh phát lại** chuỗi phím ra chữ có dấu kèm phím vừa gõ.
     - Là hoạt ảnh CSS dựng sẵn, không phải engine chạy trên web.
     - Tắt khi người dùng bật giảm chuyển động (`prefers-reduced-motion`).
3. **Vì sao có Dấu:** so sánh theo **loại** bộ gõ, chỉ mô tả cách làm.
   - Có sẵn: gạch chân.
   - Giả lập phím: xoá rồi gõ lại bằng phím giả; ảnh hưởng khi máy bận để ô trống tới khi đo ở M6 (hiệu năng dưới tải).
   - Dấu: thay chữ tại chỗ, kèm danh sách ứng dụng đã kiểm chứng.
   - Không gọi tên sản phẩm khác (N5).
4. **Tính năng:** 4 thẻ có minh hoạ: giữ nguyên từ nước ngoài, thêm dấu cho từ đã gõ, theo từng ứng dụng, như một phần của macOS.
5. **Bảng gõ Telex/VNI:** bảng thật (`<table>`), cột "Tên" ẩn trên điện thoại.
6. **Quyền riêng tư:** nền Mực, 3 cam kết (giữ đúng nội dung D8/N2).
7. **Đo được:** 4 ô số liệu để trống, chỉ điền từ kết quả test thật (N5).
8. **Tải về:**
   - phiên bản, ngày, dung lượng, yêu cầu hệ thống;
   - nút "Tải về (.dmg)", "Lịch sử phiên bản";
   - lệnh Homebrew (tên cask chưa chốt, D24 (Tên và định danh));
   - SHA-256;
   - không phải Mac thì nút chính thành "Sao chép liên kết" kèm câu "Dấu chỉ chạy trên Mac" (không có backend gửi email, D8).
9. **Góp sức:**
   - góp công (báo lỗi, dùng thử Beta, góp mã nguồn, giới thiệu);
   - ủng hộ qua VietQR và GitHub Sponsors (D39 (Ủng hộ dự án));
   - mục Cảm ơn (chỉ nêu tên khi người đó đồng ý).
10. **Hỏi đáp:** 8 câu dạng `<details>`.
    - Các câu: miễn phí, thu thập dữ liệu, quyền cần cấp, khác bộ gõ có sẵn, chuyển từ bộ gõ khác, vì sao không có gõ tắt/viết hoa đầu câu/chuyển mã, một ứng dụng không chọn được Dấu (D37), gỡ cài đặt.
    - Tên giao diện macOS ghi tiếng Việt của Apple kèm tiếng Anh trong ngoặc.
11. **Chân trang:** nền Than, logo có viền, liên kết mã nguồn, báo lỗi, lịch sử phiên bản, hướng dẫn gỡ, ủng hộ.

Không dùng logo Apple trên nút tải (nhãn hiệu của Apple); dùng biểu tượng mũi tên tải xuống.
