# Kiểm tra giao diện

Danh sách phải chạy hết trước khi báo xong bất kỳ thay đổi giao diện nào của app Dấu.

- Mỗi mục là một lỗi người dùng đã gặp, kèm cách kiểm và điều kiện đạt.
- **File này không ghi số.**
  - Mọi số đạt nằm ở `scripts/selftest/settings-window/Reference.swift`, kèm nguồn của từng số.
  - Số đo System Settings gốc ở `docs/research/SYSTEM-SETTINGS-REFERENCE.md` (D9 (Giao diện)).
- Lịch sử (ngày phát hiện lỗi, bài học): `docs/history/DOCS-LOG.md`.

## Lệnh

### 1. Build Debug

```
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project Dau.xcodeproj -scheme Dau -configuration Debug -destination 'generic/platform=macOS' -derivedDataPath build/DerivedData.noindex build
```

### 2. Kiểm trên cửa sổ thật

Lệnh: `scripts/selftest/settings-window/run.sh <thư-mục-ra>`.

- **Chiếm màn hình:** hỏi người dùng giờ chạy trước (CLAUDE.md).
- Cần quyền Trợ năng và Ghi màn hình cho Terminal.
- Không đổi cài đặt hệ thống nào:
  - kiểu thanh cuộn (`-AppleShowScrollBars`, vào miền đối số của app) là đối số của riêng lần mở đó;
  - giao diện (`--appearance`, chỉ bản Debug) cũng vậy.
- Gồm sáu lần mở app, lần lượt như dưới đây.

**Chụp trong app** (lần 1 đến 3): cần dịch vụ giả.

- Chạy trên bản chép ký lại không entitlement, nên không có App Group và không đụng cài đặt của người dùng.
- Cửa sổ hiện giữa màn hình chính vài giây.

1. `--capture-onboarding` → `onboarding/`.
   - Dịch vụ giả: OpenKey đang chạy, Dấu đã cài chưa bật.
   - Các ảnh theo bước:
     - bước 1;
     - bước 2 trước khi bấm (`2`);
     - bước 1 sau "Quay lại" khi OpenKey đã tắt (`1-done`);
     - bước 2 khi không đọc được phím tắt và có nguồn tiếng Việt khác (`2-notes`);
     - bước 2 đang chờ Allow (`2-waiting`);
     - bước 2 chưa bật được (`2-failed`);
     - bước 2 lỗi cài (`2-error`);
     - bước 2 đã bật (`2-done`);
     - bước 2 đã bật khi chưa đặt phím tắt (`2-done-noshortcut`);
     - bước 3.
   - Mỗi ảnh ở hai giao diện, sáng và tối.
   - Kèm `onboarding-<bước>-accessibility.txt` (cây trợ năng đọc qua AX API).
2. `--capture-onboarding --shortcut none` → `onboarding-no-shortcut/`.
3. `--capture-uninstall` → `uninstall/`.
   - Ảnh: `uninstall-confirm-*`, `uninstall-done-*`, `uninstall-remove-*` (Dấu không được chọn), `uninstall-remove-hint-*` (Dấu đang được chọn: có câu nhắc nút "–"), mỗi loại ở hai giao diện.
   - Dựng alert và sheet "Bỏ Dấu khỏi nguồn đầu vào" mà không gỡ gì.
   - Nền alert đặt trên màu nền cửa sổ.

**Cửa sổ thật** (lần 4 đến 6):

- Mở chính bản Debug như người dùng mở: `open -n Dau.app --args … --settings-window`.
  - Cờ này chỉ giữ onboarding đóng và không đụng bộ gõ đã cài.
  - Luôn đứng cuối; lý do ở chú thích trong `run.sh`.
- `ax-check.swift`:
  - đọc khung phần tử bằng Accessibility API từ tiến trình ngoài;
  - chọn mục qua trợ năng của sidebar (không bấm chuột);
  - chụp bằng `screencapture -l` chỉ cửa sổ (sheet đang mở nằm trong ảnh).
- Mỗi lượt đo tự đặt cửa sổ về cỡ mặc định trước khi đo, nên cỡ lúc mở không quan trọng.
- Khung cửa sổ đã lưu (bộ kiểm di chuyển và đổi cỡ cửa sổ, app lưu lại) được trả như cũ khi xong.
- Mỗi lần một bảng `<thư-mục>.txt`.

4. Thanh cuộn When scrolling (`WhenScrolling`) → `real/`, `real.txt`.
   - Tiêu điểm lúc mở (trang `launch-focus`, ảnh `launch-focus.png`, mục 18), trang và Lùi/Tiến lúc mở.
   - Rồi trên **từng màn hình** (mỗi hệ số điểm ảnh một lượt, nhãn `2x`/`1x`): 4 mục so với `Reference.swift`, ảnh `<mục>-<2x|1x>.png`.
   - Chỉ trên màn hình chính:
     - tìm ở sidebar với chuỗi không khớp (`sidebar-search-empty-*.png`);
     - sheet thêm quy tắc: AXPress nút "+", thử danh sách, ô tìm, chọn hàng, rồi "Huỷ" qua trợ năng; không thêm quy tắc nào; ảnh `apps-add-sheet-*.png`, `-bottom`, `-selected`.
   - Rồi kéo cỡ cửa sổ qua trợ năng để đọc giới hạn cỡ (rộng cố định 740, chỉ chiều cao đổi được).
   - Cuối cùng là vỏ cửa sổ (D9):
     - Lùi/Tiến bằng AXPress trên nút, rồi bằng phím ⌘[ ⌘] (sự kiện phím), cả khi sheet đang mở;
     - độ rộng sidebar ở cửa sổ rộng nhất và hẹp nhất (đổi cỡ qua trợ năng).
5. Thanh cuộn Always (`Always`) → `always/`, `always.txt`.
   - Màn hình chính; kiểm (a) và chụp từng mục.
   - Mục tràn (`Reference.scrollingSection`) cuộn bằng giá trị thanh cuộn qua trợ năng, kiểm (d) phần khung, chụp `<mục>-scrolled-*.png`.
6. Giao diện hệ thống đang không dùng (`--appearance light|dark`), thanh cuộn Always → `always-<light|dark>/`.
   - Đối số `-AppleInterfaceStyle` truyền như đối số không đổi được giao diện cửa sổ (đo 02/11/2026), nên dùng `--appearance`.
   - Kiểm: tiêu điểm lúc mở, Tab và ⌘F vào ô tìm, tìm ở sidebar (mục 18, 15, ở giao diện còn lại).
   - Rồi như lần 5, thêm ảnh sheet chưa chọn và đã chọn một hàng (không kiểm lại sheet).

Lượt nhanh chỉ cho tiêu điểm và ô tìm sidebar: `run.sh --focus <thư-mục-ra>`.

- Hai lần mở app thật (mỗi giao diện một lần, `focus-<light|dark>/`).
- Không chụp trong app, không kiểm điểm ảnh của `check.swift`.
- Vẫn chiếm màn hình (gửi phím Tab, ⌘F).

Không chạy kiểu `Automatic`: hệ thống quy nó về When scrolling hoặc Always, cả hai đã có.

**Kiểm điểm ảnh:** `check.swift` → `check.txt`.

- Kiểm (b) đến (e) trên ảnh màn hình chính của `real/`, `always/`, `always-<…>/`.
- Kiểm (f), (g) trên ảnh chụp trong app.
- Điểm dò tính theo điểm (pt) rồi nhân hệ số của ảnh.
- Màn hình chính là 1x thì bảng ghi rõ (vị trí dò trong `Reference.swift` đặt trên màn 2x).

**Kết quả mỗi hàng:**

- `ok`.
- `FAIL`: giao diện không hiện thứ phải hiện, hiện sai trạng thái hoặc lệch `Reference.swift`. Ví dụ:
  - thiếu thẻ, tiêu đề, nút, "+", ô tìm, thanh cuộn;
  - danh sách không ổn định hay trống;
  - bấm "+" mà không có sheet.
- `HARNESS`: chỉ khi bộ kiểm không chạy được. Ví dụ:
  - thiếu quyền Trợ năng;
  - app không mở, không có cửa sổ;
  - lời gọi Accessibility lỗi hay quá thời gian;
  - hệ thống không cho chụp;
  - thiếu file đầu vào của `check.swift`;
  - một trạng thái bộ kiểm cần để đo tiếp không đến trong thời hạn (hàng `wait: …`).
- Thoát với mã 0 chỉ khi mọi hàng đạt.

**Cách bộ kiểm chờ và thử lại:**

- Chờ trạng thái, không chờ một khoảng cố định. Trạng thái chờ gồm: trang đổi tiêu đề, khung cửa sổ hay số hàng không đổi qua vài lần đọc, sheet đóng, menu mở.
- Chờ cố định chỉ còn ở chỗ không có gì để đọc (giữa các sự kiện chuột, phím tổng hợp; khi kiểm rằng không có gì đổi), mỗi chỗ có chú thích lý do.
- Không có kết quả bỏ qua: mọi phép tìm phần tử không thấy đều ghi một hàng `FAIL` hoặc `HARNESS`.
- Phép thử lại chỉ có ở chỗ có lý do đo được, và hàng ghi số lần thử.

**Kiểm theo chữ cái:**

- (a) `always*.txt`:
  - thẻ đầu đúng x, mục đầu đúng y;
  - trang không có thanh cuộn thì thẻ rộng đủ cột trừ lề Form;
  - trang có thanh cuộn thì thanh rộng đúng thanh cuộn Always của hệ thống và thẻ rộng đủ cột hoặc hụt đúng một thanh (quy tắc thanh cuộn ở cuối file).
- (b) `check.txt`:
  - màu nền trang tới mép phải (hoặc tới thanh cuộn nằm ở đó);
  - thanh cuộn chạm mép cửa sổ;
  - dải thanh công cụ một màu từ giữa tới mép phải (trừ trang Ứng dụng, nơi có "+" và ô tìm).
- (c) `check.txt`:
  - lề phải của Form không có điểm khác màu nền;
  - áp dụng cho mọi ảnh When scrolling, và ảnh Always chỉ ở trang không có thanh cuộn (thanh Always lấp dải dò, trang đó đã có (a) và (b)).
- (d) `always*.txt`: mục tràn có thanh cuộn, cuộn được bằng thanh cuộn, thanh nằm trong làn lề phải và dưới thanh công cụ.
  - `check.txt`: vùng thanh công cụ bên phải tiêu đề gần như không đổi so với lúc chưa cuộn.
- (e) `check.txt`: nút "+" trang Ứng dụng vẽ tròn.
  - Khung trợ năng của nút là khung mục thanh công cụ (cao hơn rộng), nên đo hình vẽ bằng điểm ảnh.
- (f) `check.txt`: onboarding.
  - Cửa sổ không hiện chữ tiêu đề ("window title hidden", đọc `titleVisibility` của cửa sổ lúc chụp; `.hiddenTitleBar`, không mã nào với vào `NSWindow`).
  - Tên app, tiêu đề, thẻ, cụm nút ở chỗ của mockup ở mọi bước, cả hai giao diện:
    - nội dung cuộn được, hàng nút cố định nên vị trí không phụ thuộc độ dài nội dung;
    - thẻ rộng đủ cột, hoặc hụt đúng một thanh cuộn Always của hệ thống và chỉ khi nội dung cuộn, tức là đường kẻ trên hàng nút có khung (cùng quy tắc với cửa sổ Cài đặt);
    - thanh cuộn do cài đặt hệ thống lúc chụp quyết định (`Automatic` với chuột cho thanh Always); độ rộng đọc từ `NSScroller` của hệ thống, không viết cứng.
  - View vắng trong một ảnh (không có khung) là `FAIL` (app bỏ khung của view khi view biến mất).
- (g) `check.txt`: đủ 8 ảnh của gỡ cài đặt (2 alert, 2 sheet, mỗi loại hai giao diện), không bị cắt.

**Quy tắc đo cửa sổ Cài đặt:**

- Cửa sổ Cài đặt chỉ được đo trên cửa sổ thật.
- `layoutProbe` (vật dò bố cục) chỉ còn cho ảnh chụp onboarding và bảng so mockup:
  - luôn cùng một cấu trúc view dù có probe hay không;
  - chỉ đặt trên nội dung hàng hoặc cả control, không bọc ngoài modifier của hàng list (`listRowInsets`).
  - Lý do: probe đặt ngoài `listRowInsets` làm ảnh chụp ngoài màn hình lệch so với cửa sổ thật mà các kiểm vẫn đạt (mục 13).

### 3. So với mockup (chỉ để đối chiếu nội dung, D9)

Lệnh: `swift run --package-path scripts/snapshot-settings SnapshotSettings <ra> <thư-mục-artboard> [<ra-run.sh>/real]`.

- Ghi ảnh ghép mockup | app (`*-compare-*.png`, sidebar 4×, segmented 3×, header Ứng dụng 3×) và bảng khung phần tử.
- Với `<ra-run.sh>/real`:
  - phía app ở giao diện lúc chạy `run.sh` dùng ảnh và khung của cửa sổ thật (`frames.json` do `ax-check` ghi);
  - giao diện còn lại dùng cửa sổ dựng tay của công cụ.
- Sheet thêm quy tắc: `apps-add-sheet-{light,dark}.png` và `apps-add-compare-light.png` dựng bằng `.sheet` thật trên cửa sổ ngoài màn hình.
  - Ảnh vẽ lại bằng `cacheDisplay` nên không có thanh nút (nằm trên thanh công cụ của sheet) và control có thể khác cửa sổ thật.
  - Chỉ dùng để xem nội dung; số đo lấy từ `real.txt`.
- Bố cục và số đo theo System Settings, không theo mockup: bảng này không có tiêu chí đạt.
- Đối số thứ tư `<thư-mục-chụp-onboarding>` (vd. `<ra-run.sh>/onboarding`) ghi thêm `onboarding-<bước>-compare-{light,dark}.png`.
  - So với artboard [OnboardingConflict](ui/canvas/OnboardingConflict.png), [OnboardingConflictDone](ui/canvas/OnboardingConflictDone.png), [OnboardingEnable](ui/canvas/OnboardingEnable.png), [OnboardingEnableNotes](ui/canvas/OnboardingEnableNotes.png), [OnboardingEnableWaiting](ui/canvas/OnboardingEnableWaiting.png), [OnboardingEnableFailed](ui/canvas/OnboardingEnableFailed.png), [OnboardingEnableError](ui/canvas/OnboardingEnableError.png), [OnboardingEnableDone](ui/canvas/OnboardingEnableDone.png), [OnboardingEnableDoneNoShortcut](ui/canvas/OnboardingEnableDoneNoShortcut.png), [Onboarding](ui/canvas/Onboarding.png).
  - Không có artboard tối: mockup sáng cạnh app tối.

### 4. Test

Lệnh: `swift test --package-path scripts/snapshot-settings`.

- Gồm: ví dụ do engine tính, phím tắt, ô tìm sidebar, ô tìm và chọn của sheet thêm quy tắc, vỏ cửa sổ, banner "Dấu chưa được bật".
- Lệnh 3 và 4 cần `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (Command Line Tools không có plugin macro SwiftUI).

### Cách đọc bảng

- Toạ độ tính bằng pt, gốc ở góc trên-trái cửa sổ.
- "Như System Settings" nghĩa là khớp số trong `Reference.swift` trong sai số của nó. "Mặc định hệ thống" là chỗ không có số để so.
- Tên kiểm trong mục "Cách kiểm" là tên hàng trong bảng (`real.txt` khi không ghi bảng khác).
- "Mỗi mục" nghĩa là có một hàng cho từng mục và từng màn hình.

## Danh sách

Mỗi mục có ba dòng: lỗi đã gặp, cách kiểm, đạt khi.

### 1. Nội dung co thành cột hẹp, căn giữa

- **Lỗi:** `Form(.grouped)` giới hạn độ rộng thẻ và căn giữa khi cột chi tiết quá rộng.
- **Cách kiểm:** "first card" (mỗi mục); "max window width", "min window width", "min window height"; (a) trong `always*.txt`.
- **Đạt khi:**
  - cửa sổ rộng cố định 740 như System Settings, nên Form không bao giờ giới hạn thẻ;
  - thẻ đầu lấp cột chi tiết trừ lề của Form;
  - kéo cửa sổ dừng đúng ở giới hạn cỡ (chỉ chiều cao đổi được).

### 2. Nhảy bố cục khi đổi mục

- **Lỗi:** toolbar đổi cao, tiêu đề đổi chỗ.
- **Cách kiểm:** "toolbar height", "close button", "back button", "forward button", "title text", "title x", "title center y", "first item y", "first card" (mỗi mục, so cùng một số nên giống nhau giữa các mục); (a) trong `always*.txt`.
- **Đạt khi:**
  - thanh công cụ, nút đóng, cụm Lùi/Tiến, tiêu đề, mục đầu và thẻ đầu ở cùng chỗ ở 4 mục, cả hai màn hình;
  - tiêu đề là tiêu đề hệ thống (`navigationTitle`, một chữ tĩnh trên thanh công cụ mang tên cửa sổ), không phải view tự vẽ;
  - độ rộng chỉ được hụt đúng bằng thanh cuộn Always của hệ thống, và chỉ ở mục đang hiện thanh cuộn.

### 3. Màu không theo HIG

- **Lỗi:** tự pha nền, chữ cố định.
- **Cách kiểm:** `grep -nE "Color\(red\|#[0-9a-fA-F]{6}\|\.opacity\(\|gradient\|blended" Apps/Dau/Sources`.
- **Đạt khi:** không có kết quả (D9: chỉ màu hệ thống, kể cả ô icon sidebar).

### 4. Mất đèn giao thông

- **Cách kiểm:** "close button" (mỗi mục).
- **Đạt khi:** nút đóng có mặt ở mọi mục, vị trí như System Settings.

### 5. Icon sidebar sai

- **Lỗi:** glyph, màu, cỡ, sát chữ.
- **Cách kiểm:** "sidebar search", "sidebar row 0…3", "sidebar icon x", "sidebar icon height", "sidebar text x" (mỗi mục); `sidebar-compare-*.png`.
- **Đạt khi:**
  - ô tìm, hàng, vệt chọn, ô icon và chữ như System Settings;
  - màu ô `systemBlue` / `systemPurple` / `systemOrange` / `systemGreen`;
  - glyph nét trắng theo SVG mockup (nội dung).

### 6. Segmented "Kiểu gõ" hẹp, căn giữa

- **Cách kiểm:** "segmented "Kiểu gõ" spans its row"; "RadioGroup … height", "PopUpButton … height", "Button … height", "switch …" (mỗi mục).
- **Đạt khi:**
  - segmented không nhãn trải hết hàng như System Settings (macOS 26+, `buttonSizing(.flexible)`);
  - segmented, nút, pop-up, công tắc đúng cỡ hệ thống.

### 7. Ô tìm và "+" dính nhau thành một khối glass

- **Cách kiểm:** "+ right of the title", "+ before the search field", "search field right inset", "search field height" (trang Ứng dụng); `apps-header-compare-*.png`.
- **Đạt khi:** control hệ thống: nút "+" rồi ô tìm của `searchable` ở mép phải thanh công cụ (thứ tự do hệ thống đặt), tách khỏi tiêu đề, không tràn mép phải.

### 8. Nút "+" méo (bầu dục)

- **Cách kiểm:** (e) "+ drawn round" trong `check.txt`.
- **Đạt khi:** nút "+" vẽ ra rộng bằng cao (nút thanh công cụ của hệ thống).

### 9. Header không che nội dung khi cuộn

- **Cách kiểm:** (d) "page scrolls with its bar" trong `always*.txt`; (d) "header when scrolled" trong `check.txt`.
- **Đạt khi:**
  - trang cuộn thật;
  - vùng thanh công cụ bên phải tiêu đề gần như không đổi so với ảnh chưa cuộn (mép cuộn kiểu cứng của hệ thống, `scrollEdgeEffectStyle(.hard)`).

### 10. Thiếu thanh cuộn (nằm ngoài cửa sổ)

- **Cách kiểm:** (d) "scroll bar of the page that overflows", "scroll bar lane" trong `always*.txt`; (b) "scroll bar ends at the window edge" trong `check.txt`.
- **Đạt khi:** mục tràn có thanh cuộn, nằm trong lề phải của Form, trong cửa sổ, dưới thanh công cụ.

### 11. Dải hở ở mép phải

- **Lỗi:** cột thanh cuộn chừa sẵn.
- **Cách kiểm:** (b) "page color at the right edge", "toolbar color at the right edge", (c) "right margin is page color" trong `check.txt`; (a) trong `always*.txt`.
- **Đạt khi:**
  - màu nền trang ở mép phải trùng màu lề trái của Form;
  - thanh công cụ cùng màu tới mép phải;
  - lề phải của Form không có điểm khác màu nền, trừ thanh cuộn;
  - không chừa chỗ cho thanh cuộn ở trang không có thanh.

### 12. Onboarding lệch mockup

- **Cách kiểm:** (f) trong `check.txt`.
- **Đạt khi:** tên app, tiêu đề, thẻ, cụm nút ở cùng chỗ ở mọi bước, cả hai chế độ; không ảnh nào thiếu view.

### 13. Ảnh chụp ngoài màn hình khác cửa sổ thật

- **Lỗi:** lệch mà vẫn đạt.
- **Cách kiểm:** cửa sổ Cài đặt chỉ được đo trên cửa sổ thật: mọi hàng của `real.txt` (các mục trên cả hai màn hình); `swift test` "Not-enabled banner".
- **Đạt khi:**
  - trên cả màn Retina và 1x, mọi số trong `real.txt` đạt: thanh công cụ, tiêu đề trang, sidebar, mục đầu trang (lề trên mặc định của SwiftUI, giữ có chủ ý), tiêu đề nhóm và khoảng cách thẻ, control như mục 6;
  - hàng "Nâng cao" là nút trơn kèm chevron (D9), không so chiều cao;
  - banner "Dấu chưa được bật" là thẻ đầu của mọi trang khi Dấu chưa bật, ở từng trạng thái sau "Bật lại" (chờ Allow, chưa bật được, đã bật);
  - banner không hiện khi đã bật hay không đọc được (N5 (Chỉ hứa điều đã kiểm chứng); `swift test`, dựng split view thật trong cửa sổ không hiện).

### 14. Sheet thêm quy tắc

- **Lỗi:**
  - danh sách không cuộn được;
  - danh sách thiếu ứng dụng (một lần chỉ có vài dòng, không thanh cuộn);
  - ô tìm hay chọn hàng không nối với nút.
- **Cách kiểm:**
  - trang `add-sheet` (màn hình chính): "sheet opened by +", "app list settles", "search prompt", "header", "segmented label", "Thêm without selection", "list overflows its card", "list vertical scroll bar", "list scrolls with the wheel", "lists "<app>"", "last app visible at the end", "Khi đang gõ in view while scrolled", "search with no match", "search cleared", "Thêm with selection", "Thêm after search hides selection", "Thêm after search cleared", "Huỷ closes the sheet";
  - `AddAppRuleSheetTests` ("Add-rule sheet search");
  - ảnh ở giao diện còn lại trong `always-<…>/`.
- **Đạt khi:**
  - "+" mở sheet; tiêu đề, gợi ý ô tìm, segmented "Khi đang gõ" đúng chữ; có "Chọn ứng dụng khác…", "Huỷ", "Thêm";
  - danh sách ổn định trong thời hạn (bảng ghi thời gian), tràn thẻ và có thanh cuộn dọc;
  - cuộn được bằng lăn chuột thật (bảng ghi số lần thử);
  - có các ứng dụng luôn có của macOS trong `Reference.alwaysInstalledApps` (thiếu thì có thể vì đã có quy tắc cho ứng dụng đó);
  - kéo thanh cuộn tới cuối thì ứng dụng cuối hiện trọn trong thẻ, "Khi đang gõ" vẫn trong sheet;
  - ô tìm nối với danh sách: chuỗi không khớp thì không còn hàng, xoá thì đủ lại số hàng lúc ổn định (lọc thế nào: `AddAppRuleSheetTests`);
  - "Thêm" tắt khi chưa chọn, bật khi chọn; chọn một hàng rồi gõ tìm làm ẩn hàng đó thì "Thêm" tắt, xoá ô tìm vẫn tắt;
  - "Huỷ" đóng sheet;
  - vị trí và cỡ các phần trong sheet không đo trên cửa sổ thật.

### 15. Tìm ở sidebar không khớp mục nào

- **Lỗi:** sidebar trống, trang cũ vẫn hiện như chưa tìm.
- **Cách kiểm:** trang `sidebar-search` (màn hình chính): "rows without a match", "empty state", "toolbar height", "rows after clearing"; `swift test` "Sidebar search".
- **Đạt khi:**
  - ô tìm nhận tiêu điểm rồi đặt chuỗi không khớp (không có tiêu điểm thì SwiftUI không đọc giá trị) thì sidebar không còn hàng và có trạng thái trống hệ thống nêu chuỗi tìm (`ContentUnavailableView.search`), thanh công cụ không đổi;
  - xoá ô tìm thì đủ 4 hàng;
  - mỗi chữ nhìn thấy trong mục tìm ra mục đó, không phân biệt hoa thường, dấu, "đ"/"d" (`swift test`);
  - ảnh `real/sidebar-search-empty-<2x\|1x>.png` (hệ số của màn hình chính).

### 16. Thanh công cụ co, tiêu đề vẽ tay, thiếu Lùi/Tiến

- **Lỗi:** thanh công cụ co còn thanh tiêu đề nhỏ, tiêu đề vẽ tay lệch tiêu đề hệ thống; không có Lùi/Tiến như System Settings (D9, "Vỏ cửa sổ Cài đặt").
- **Cách kiểm:**
  - trang `launch`: "page at launch", "Lùi at launch", "Tiến at launch";
  - trang `history`: "page after selecting smart", "Lùi after selecting another section", "Tiến after selecting another section", "page after Lùi", "Tiến after Lùi", "page after Tiến", "Lùi after Tiến", "Tiến after Tiến", "page after ⌘[", "page after ⌘]";
  - trang `history-under-sheet`: "page before the sheet", "page under the sheet after ⌘[", "sheet after ⌘[", "page under the sheet after ⌘]", "sheet after ⌘]", "menu item \"Lùi\" under the sheet", "menu item \"Tiến\" under the sheet", "page after the sheet closed";
  - mục 2;
  - `swift test` "Settings history", "Settings window shell" ("AppKit's Show/Hide Sidebar action stays off").
- **Đạt khi:**
  - lúc mở cửa sổ cả Lùi và Tiến tắt; chọn mục khác thì Lùi bật, Tiến tắt;
  - Lùi, Tiến (nút và ⌘[ ⌘]) đi đúng giữa các mục đã xem;
  - hành động ẩn/hiện sidebar của AppKit luôn tắt (D9; `swift test`);
  - khi sheet đang mở (thêm quy tắc), ⌘[ ⌘] không đổi trang phía sau, sheet vẫn mở, mục Lùi/Tiến trong menu View tắt; đóng sheet thì bật lại;
  - lịch sử (gồm bước nhảy của ô tìm sidebar) đúng như test.

### 17. Sidebar kéo thu lại được

- **Lỗi:** sidebar kéo thu lại được, kéo bị giật; System Settings không cho kéo (D9, "Sidebar cố định như System Settings").
- **Cách kiểm:** trang `sidebar-fixed`: "sidebar width at the start", "sidebar width at the widest window", "sidebar width at the narrowest window"; `swift test` "Settings window shell" (sidebar cố định, đường chia không có vùng chuột).
- **Đạt khi:**
  - sidebar giữ đúng độ rộng cột của System Settings khi đổi cỡ cửa sổ;
  - split view không cho thu sidebar, độ rộng tối thiểu và tối đa bằng nhau;
  - đường chia không có vùng chuột (không kéo, không con trỏ đổi cỡ; `swift test`).

### 18. Mở cửa sổ mà danh sách sidebar không có tiêu điểm

- **Lỗi:** hàng đang chọn vẽ xám (không nhấn) thay vì màu nhấn như canvas.
- **Cách kiểm:**
  - trang `launch-focus`: "sidebar list has the focus at launch", "search field without focus at launch", "selected row drawn with the accent selection (light\|dark)";
  - trang `search-keyboard`: "Tab from the list reaches the search field", "Edit › Find › Find… before ⌘F" (tên mục đọc từ chuỗi hệ thống, phím tắt, bật hay tắt), "⌘F from the list focuses the search field";
  - `swift test` "Settings window shell";
  - ảnh `real/launch-focus.png`, `always-<light\|dark>/launch-focus.png`.
- **Đạt khi:**
  - lúc mở, trước mọi thao tác: danh sách sidebar có tiêu điểm, ô tìm không;
  - nền hàng đang chọn gần màu nhấn của hệ thống hơn màu chọn xám, ở cả hai giao diện;
  - từ danh sách, Tab (hoặc Shift-Tab) và ⌘F đưa tiêu điểm vào ô tìm.

## Quy tắc thanh cuộn

Hệ thống quyết định cách hiện thanh cuộn.

- **When scrolling:** không chiếm chỗ.
- **Always** (`Always`, hoặc `Automatic` khi có chuột):
  - chỉ mục thực sự cần cuộn mới có rãnh thanh cuộn ở mép phải;
  - mục đó hẹp hơn đúng độ rộng thanh cuộn của hệ thống;
  - vị trí x, y của mọi thứ giữ nguyên.
- Không chừa sẵn khoảng trống cho thanh cuộn: cách đó sinh lỗi 11.
