# Ma trận tương thích

Bảng ghi kết quả thử Dấu trong từng ứng dụng, thuộc M3 (Độ tin cậy). Khung lập ngày 30/10/2026 trên máy phát triển: macOS 27.2 (26B123), Apple M1 Pro; kết quả được điền cùng ngày. Dòng nào chưa thử ghi "chưa thử"; không điền ô nào bằng phỏng đoán.

## Hiện trạng (09/11/2026)

- **Thay chữ tại chỗ sai khi trang Chrome bận, cả ở nhịp gõ bình thường** (đo 09/11/2026, `docs/PROGRESS.md` nhật ký M6): trang thử chặn luồng chính 300 ms mỗi giây, phím cách nhau 100 ± 30 ms, thay tại chỗ sai ở phần lớn các lượt (cả bản Release), gạch chân đúng; Chrome trả vị trí con trỏ cũ khi chưa áp xong phím trước. Các app khác chưa đo khi bận.
- **Kết quả trình duyệt trước 09/11/2026 chưa chắc là gõ vào ô của trang:** script tự gõ khi đó chỉ kiểm tiêu đề cửa sổ; khi thanh địa chỉ có focus, phím vào thanh địa chỉ và lượt vẫn đạt (⌘A ⌘C chép cùng chữ). Từ 09/11/2026 script chỉ gõ khi ô của trang có focus. Các dòng trình duyệt của mục 5 cần đo lại ở M6.
- **Khi trang rảnh, thay chữ tại chỗ chỉ sai khi phím đến dồn dưới 10 ms** (đo 29–30/10/2026): Chrome, Edge, VS Code, Firefox, Terminal sai ở 0 ms; từ 10 ms đúng, trừ VS Code: ở 10 ms sai lượt 29/10 (câu mẫu cũ) và đúng lượt 30/10 (câu mẫu mới), từ 20 ms đúng mọi lượt (mục 6.2). TextEdit, Safari đúng ở mọi tốc độ đã đo; Notes đúng ở 30 và 0 ms; Telegram mới đo ở 30 ms (đúng). Bằng chứng: mục 5 (bảng kết quả) và mục 6.2.
- **Khi trang Chrome bận** (trang chặn luồng chính 300 ms mỗi giây, phím cách 100 ± 30 ms; M6, 09–10/11/2026): thay tại chỗ sai 3/3 lượt vì Chrome trả vị trí và chữ cũ hơn phím vừa gõ; từ bcd4e54 đúng 3/3 (D11 (Kiểm tra ngữ cảnh), ý "App trả lời chậm"). Chưa đo VS Code, Firefox, phím dồn khi app bận. Nhật ký: `docs/PROGRESS.md`.
- **Gạch chân (D13 (Gạch chân là đường lui cuối cùng))** sửa được lỗi phím dồn ở Chrome, Edge, VS Code, Firefox (đúng ở 0 ms); Terminal vẫn sai ở 0 ms nên không đề xuất. Danh sách đề xuất hiện hành (VS Code, app Electron/Chromium, Firefox) và tiêu chí: mục 1 và mục 7.
- **Backspace (D32 (Backspace)) trong Chromium/Electron:** lỗi xoá hai lần đã sửa ngày 30/10/2026 (82d9ecc); kết quả đo lại ở 6 ứng dụng: mục 6.4.
- **Terminal không gửi ⌫ cho bộ gõ**, nên D32 không giữ được ở đó và D20 (Thêm dấu cho từ đã gõ) sau ⌫ không chạy. Chưa kiểm chứng lại sau lần phát hiện đầu: mục 6.5.
- **Tự sửa chính tả của macOS 27.2** có thể đè lên chữ đã giữ, kể cả khi gõ bằng U.S. (D4 (Từ nước ngoài)): mục 6.1.
- **Ô mật khẩu:** macOS giữ bàn phím U.S., Dấu không nhận phím; hành vi của hệ thống: mục 6.3.
- **Biểu tượng nguồn nhập liệu** (thanh menu nhiều màn hình, bong bóng ⌃Space) đã sửa ngày 30/10/2026 bằng cờ `TISIconIsTemplate` ở cấp input mode: mục 6.6 và mục 6.7.
- **Phạm vi đã thử:** 11 trong 42 dòng của mục 3 có số đo (nhiều dòng mới chỉ ở 30 ms); phần còn lại làm ở M6 (Hiệu năng dưới tải): mục 7.

## 1. Mục đích

- Biết Dấu gõ đúng hay sai trong từng ứng dụng, ở tốc độ nào, và vì sao.
- Là nguồn duy nhất cho **danh sách tương thích**: ứng dụng nào cần gạch chân (marked text, D13) thì vào danh sách theo bundle ID.
  - Danh sách có sẵn trong bản build: `Apps/Dau/Resources/CompatibilityList.json`, model `CompatibilityList` trong DauShared (việc làm danh sách tương thích có sẵn trong bản build ở M3).
  - Về sau danh sách được cập nhật riêng bằng file JSON có chữ ký do app chủ tải (D7 (Cập nhật và loại bản dựng)); tiến trình bộ gõ không tải gì (N2 (Bộ gõ không có quyền mạng)).
  - Trong trang Ứng dụng, các quy tắc đến từ danh sách hiện nhãn "Đề xuất" (D5 (Quy tắc theo ứng dụng); `AppRule` nguồn `suggested`).
- Ai vào danh sách: theo D13 (chốt 30/10/2026, sửa 10/11/2026).
  - Danh sách đề xuất ban đầu là VS Code, các app Electron/Chromium và Firefox.
  - App chưa đo được xếp theo công nghệ giao diện (mục 2, mục 3); app đã đo thì theo số đo ở mục 5.
  - Terminal không đề xuất.
  - Mặc định mọi app không gạch chân; nhãn "Đề xuất" chỉ gợi ý, người dùng tự bật.
- Bảng này không phải lời hứa (N5 (Chỉ hứa điều đã kiểm chứng)).
  - Không chép kết quả lên giao diện hay website ("chạy tốt trong mọi app", danh sách logo ứng dụng…) trước khi phiên chính tổng hợp.
  - Website giữ ô trống như `[Kết quả bài test tải nặng]`.

Tiêu chí nhãn "Đề xuất": D13 (30/10/2026, sửa 10/11/2026). Gạch chân chỉ là đề xuất, không tự bật; nhãn chỉ giữ cho app mà thay tại chỗ còn sai ở tốc độ gõ thật và chưa sửa được.

- Theo số đo M3, thay tại chỗ chỉ sai khi phím cách nhau dưới 10 ms; từ 10 ms đều đúng.
- App sai ở 0–5 ms mà gạch chân sửa được thì được đề xuất (Firefox thêm theo cách này). Các nhãn này xét lại khi M6 sửa xong lỗi phím dồn.
- Terminal sai ở 0 ms cả khi gạch chân nên không đề xuất.

## 2. Vì sao ghi công nghệ giao diện

Dấu thay chữ tại chỗ: ở phím có thay chữ, hỏi `selectedRange` một lần rồi gọi `insertText(_:replacementRange:)`.

- Đây là phương án "hỏi vị trí con trỏ ở mỗi phím có thay chữ", đã chốt ở D11 (Kiểm tra ngữ cảnh) và N3 (Ít lời gọi vào ứng dụng đích). Phương án còn lại, "tự cộng dồn vị trí từ một vị trí gốc", đã bị bỏ (mục 6.2).
- Cách này cần ứng dụng trả vị trí con trỏ đúng **ngay lúc hỏi**.

Các dữ kiện chi phối:

- Header `IMKInputSession.h` (HIToolbox, SDK macOS 27.0):
  - Nếu client không hỗ trợ TSMDocumentAccess thì `selectedRange` trả `NSNotFound` và `replacementRange` bị bỏ qua.
  - Header cũng ghi client như vậy "cực kỳ hiếm" và hệ thống văn bản Cocoa có hỗ trợ.
  - Bộ gõ đếm trường hợp này là `unsupported`.
  - Trang tài liệu web của `IMKTextInput` trả 404 (đã ghi ở `docs/OPENKEY-NOTES.md` mục 5).
  - Phía ứng dụng: https://developer.apple.com/documentation/appkit/nstextinputclient/selectedrange() và https://developer.apple.com/documentation/appkit/nstextinputclient/inserttext(_:replacementrange:)
- Lỗi đã đo được ở M2 (Bộ gõ tối thiểu) không phải `unsupported` mà là **ứng dụng áp phím bất đồng bộ**.
  - Chrome, VS Code, Terminal trả một vị trí cũ khi phím đến dồn (mục 6.2).
  - Vì vậy công nghệ giao diện là dấu hiệu dự đoán tốt nhất trước khi thử: Chromium/Electron và terminal dễ gặp lỗi này; AppKit/WebKit (TextEdit, Safari) thì chưa thấy.
  - Đây là suy luận từ 5 ứng dụng, cần kiểm chứng trên từng ứng dụng.
- Gạch chân dùng `setMarkedText(_:selectionRange:replacementRange:)`; theo cùng header, chuỗi thường sẽ được gạch chân mặc định.
  - Gạch chân có giải được lỗi bất đồng bộ không: lượt đo gạch chân (30/10/2026, D13, `docs/history/LOG-M0-M4.md` nhật ký 30/10) cho thấy sửa được Chrome và VS Code ở 0 ms.
  - Terminal ở 0 ms vẫn lỗi (còn vẽ marked text cũ).
  - Kết quả từng app ở mục 5.

Cách ghi công nghệ ở mục 3:

- Đọc từ bundle trên máy này (thư mục `Contents/Frameworks`, `otool -L` của file chạy; chỉ đọc, không mở app) khi app có trên máy.
- App không có trên máy thì ghi theo hiểu biết chung và đánh dấu "suy luận".

## 3. Danh sách ứng dụng

"Máy này": tra ngày 30/10/2026 trong `/Applications`, `~/Applications`, `/System/Applications`, `/System/Library/CoreServices` và `mdfind kMDItemCFBundleIdentifier == '…'` (đã thử đối chứng: `mdfind` tìm ra Zalo và Edge). Phiên bản là `CFBundleShortVersionString` lúc tra. "web" = không có app, thử trong trình duyệt.

| Nhóm | Ứng dụng | Bundle ID | Máy này | Công nghệ giao diện | Rủi ro dự đoán (suy luận) |
|---|---|---|---|---|---|
| Hệ thống | TextEdit | `com.apple.TextEdit` | có (1.21) | AppKit (NSTextView) | thấp; có tự sửa chính tả của hệ thống |
| Trình duyệt | Safari | `com.apple.Safari` | có (27.2) | WebKit | thấp (lượt thử M2 đúng ở mọi tốc độ) |
| Trình duyệt | Chrome | `com.google.Chrome` | có (156.0) | Chromium | bất đồng bộ (đã đo, mục 6.2) |
| Trình duyệt | Firefox | `org.mozilla.firefox` (Nightly: `org.mozilla.nightly`) | có (158.0.1; Nightly 160.0a1) | Gecko, không dùng Chromium | chưa biết; nhân xử lý nhập liệu riêng |
| Trình duyệt | Edge | `com.microsoft.edgemac` | có (155.0) | Chromium (`Microsoft Edge Framework`) | như Chrome |
| Trình duyệt | Arc | `company.thebrowser.Browser` | không | Chromium (suy luận) | như Chrome |
| Trình duyệt | Brave | `com.brave.Browser` | không | Chromium (suy luận) | như Chrome |
| Soạn mã | VS Code | `com.microsoft.VSCode` | có (1.144.0) | Electron | bất đồng bộ (đã đo, mục 6.2) |
| Soạn mã | Cursor | `com.todesktop.230313mzl4w4u92` | có (3.24.12) | Electron (bản dựng từ VS Code) | như VS Code |
| Soạn mã | Zed | `dev.zed.Zed` | có (1.23.2) | tự vẽ bằng Metal (GPUI, Rust), vỏ AppKit | chưa biết; tự cài đặt phía nhập liệu |
| Soạn mã | Sublime Text | `com.sublimetext.4` | có (Build 4215) | tự vẽ, vỏ Cocoa/AppKit | chưa biết (M2 chỉ có số đo gõ tay) |
| Soạn mã | JetBrains IDE | `com.jetbrains.WebStorm`; khác: `com.jetbrains.intellij`, `com.jetbrains.intellij.ce`, `com.jetbrains.pycharm`, `com.jetbrains.goland`, `com.google.android.studio` | WebStorm có (2026.2.3, `~/Applications`); các ID khác không | Java (JetBrains Runtime, có thư mục `jbr`) | chưa biết; nhập liệu qua lớp Java |
| Soạn mã | Xcode | `com.apple.dt.Xcode` | có (27.1) | AppKit, trình soạn mã riêng | chưa biết; có gợi ý hoàn thành mã |
| Terminal | Terminal | `com.apple.Terminal` | có (2.15) | AppKit, chờ shell in lại chữ | bất đồng bộ (đã đo, mục 6.2) |
| Terminal | iTerm2 | `com.googlecode.iterm2` | không | AppKit (suy luận) | như Terminal (suy luận) |
| Terminal | Warp | `dev.warp.Warp-Stable` | không | tự vẽ bằng Metal, Rust (suy luận) | chưa biết |
| Terminal | Ghostty | `com.mitchellh.ghostty` | có (1.4.0) | AppKit + SwiftUI, vẽ bằng Metal | như Terminal (suy luận) |
| Chat | Zalo | `com.vng.zalo` | có (26.10.10) | Electron | như VS Code (suy luận) |
| Chat | Messenger | web (`messenger.com`, `facebook.com`) | web | trình duyệt | theo trình duyệt. Meta đã ngừng app Messenger cho Mac từ 15/12/2025 và chuyển người dùng sang web ([TechCrunch](https://techcrunch.com/2025/10/16/meta-to-shut-down-messenger-desktop-apps-for-mac-and-windows/), [AppleInsider](https://appleinsider.com/articles/25/12/15/facebook-messenger-for-macos-departs-the-desktop)); ID cũ `com.facebook.archon` không có trên máy |
| Chat | Telegram | `ru.keepcoder.Telegram` | có (13.1.0) | AppKit, Swift (bản "Telegram for macOS") | thấp (lượt thử M2 đúng ở 30 ms) |
| Chat | Telegram Desktop | `org.telegram.desktop` | không | Qt (suy luận) | chưa biết; đại diện nhóm Qt |
| Chat | Discord | `com.hnc.Discord` | có (0.0.415) | Electron | như VS Code (suy luận) |
| Chat | Slack | `com.tinyspeck.slackmacgap` | không | Electron (suy luận) | như VS Code (suy luận) |
| Chat | Microsoft Teams | `com.microsoft.teams2` (bản cũ `com.microsoft.teams`) | không | web view (suy luận, cần kiểm chứng) | chưa biết |
| Văn phòng | Word | `com.microsoft.Word` | không | vỏ AppKit, bộ soạn chữ riêng (suy luận) | chưa biết |
| Văn phòng | Excel | `com.microsoft.Excel` | không | như Word (suy luận) | chưa biết; ô bảng tính có chế độ sửa riêng |
| Văn phòng | PowerPoint | `com.microsoft.Powerpoint` | không | như Word (suy luận) | chưa biết |
| Văn phòng | Pages | `com.apple.Pages` (bản "Creator Studio" 15.4) và `com.apple.iWork.Pages` (14.5) | có, cả hai bản | AppKit, bộ soạn chữ riêng của iWork | chưa biết. Hai bản khác bundle ID: quy tắc phải ghi cả hai |
| Văn phòng | Numbers | `com.apple.Numbers` (Creator Studio 15.4); ID cũ `com.apple.iWork.Numbers` không có trên máy | có | như Pages | chưa biết; ô bảng tính |
| Văn phòng | Keynote | `com.apple.Keynote` (Creator Studio 15.4); ID cũ `com.apple.iWork.Keynote` không có trên máy | có | như Pages | chưa biết |
| Văn phòng | Google Docs | web | web | trình duyệt; Docs vẽ bằng canvas từ 2021 ([Google Workspace Updates](https://workspaceupdates.googleblog.com/2021/05/Google-Docs-Canvas-Based-Rendering-Update.html)), chữ nhập qua một ô ẩn (suy luận) | cao (suy luận); D20 trên web editor là câu hỏi mở trong `DECISIONS.md` |
| Văn phòng | Google Sheets | web | web | trình duyệt | chưa biết |
| Văn phòng | Notion | `notion.id` | có (7.41.1) | Electron | như VS Code (suy luận) |
| Văn phòng | Obsidian | `md.obsidian` | không | Electron (suy luận) | như VS Code (suy luận) |
| Apple | Ghi chú (Notes) | `com.apple.Notes` | có (4.13) | AppKit | thấp (suy luận); có tự sửa chính tả |
| Apple | Mail | `com.apple.mail` | có (16.0) | AppKit; khung soạn thư dùng WebKit (suy luận: file chạy có liên kết WebKit) | thấp (suy luận); có tự sửa chính tả |
| Apple | Tin nhắn (Messages) | `com.apple.MobileSMS` | có (26.0) | Mac Catalyst (UIKit qua `iOSSupport`) | chưa biết |
| Apple | Spotlight | `com.apple.Spotlight` | có | giao diện hệ thống | chưa biết; ô tìm có gợi ý tự hoàn thành |
| Apple | Finder (đổi tên tệp) | `com.apple.finder` | có (27.2) | AppKit | thấp (suy luận) |
| Khác | Figma | `com.figma.Desktop` | có (126.11.7) | Electron, nội dung vẽ bằng canvas | cao (suy luận) |
| Khác | Raycast | `com.raycast.macos` | không | AppKit (suy luận) | chưa biết; ô tìm có gợi ý |
| Khác | Alfred | `com.runningwithcrayons.Alfred` | không | AppKit (suy luận) | chưa biết; ô tìm có gợi ý |

Tổng (42 dòng): 26 có trên máy, 13 không có, 3 chỉ có bản web (Messenger, Google Docs, Google Sheets).

Ngoài danh sách chính, máy này còn các app thử được nếu cần thêm mẫu:

- Electron: Claude (`com.anthropic.claudefordesktop`), GitHub Desktop (`com.github.GitHubClient`), Postman (`com.postmanlabs.mac`), Antigravity (`com.google.antigravity`), LM Studio (`ai.elementlabs.lmstudio`), Polypane (`com.firstversionist.polypane`).
- Trình duyệt Blisk (`org.blisk.Blisk`).
- Zoom (`us.zoom.xos`).

Bundle ID mà bộ gõ thật sự nhận có thể khác cột trên (ví dụ tiến trình con của trình duyệt). Khi thử, lấy ID từ `scripts/perf/perf-report.sh` (mục 4.4) và sửa cột nếu khác.

## 4. Cách thử một ứng dụng

### 4.1 Chuẩn bị

1. Thoát các bộ gõ tiếng Việt khác đang chạy (OpenKey, EVKey, GoTiengViet…), kể cả trong Mục đăng nhập.
2. Trong Terminal, ở thư mục repo, chạy `scripts/dev/install-input-method.sh`. Script build bản Debug, chép `DauInputMethod.app` vào `~/Library/Input Methods`, dừng tiến trình bộ gõ cũ và in các bước bật nguồn nhập liệu.
3. Làm theo các bước script in ra.
   - Lần đầu trên máy: bật bằng nút "Bật Dấu" của app chủ rồi Allow, không cần đăng xuất (D37 (Cài đặt bộ gõ)).
   - Thêm tay (System Settings › Keyboard › "All Input Sources" › "+" › Vietnamese › "Dấu – Vietnamese" › Add; máy tiếng Việt hiện tên tiếng Việt, D38 (Chữ trên giao diện)) có thể không thấy Dấu vì danh sách đọc bộ đệm cũ; khi đó đăng xuất rồi đăng nhập lại (`docs/research/M5-INSTALL.md` (b)9, (b)12).
   - Dấu chỉ có nguồn này (D2 (Chuyển Việt/Anh)); gõ tiếng Anh bằng U.S. của macOS, nên giữ U.S. (hoặc một nguồn tiếng Anh khác) trong danh sách.
   - Nếu còn "Dấu – Tiếng Anh" từ bản cũ thì bỏ nó.
4. Chọn "Dấu – Tiếng Việt" ở menu nguồn nhập liệu trên thanh menu.
   - Nếu máy bật "Automatically switch to a document’s input source" (System Settings › Keyboard › "All Input Sources"), mỗi ứng dụng hoặc cửa sổ nhớ nguồn riêng.
   - Khi đó chọn lại Dấu **sau khi** chuyển sang ứng dụng cần thử, và nhìn biểu tượng V trên thanh menu trước khi gõ.
5. (Tuỳ chọn, để xem lỗi nếu bộ gõ không chạy) mở một cửa sổ Terminal riêng: `/usr/bin/log stream --predicate 'process == "DauInputMethod"'`. Trong zsh, `log` là một lệnh có sẵn khác, nên phải gõ đường dẫn đầy đủ.
6. Muốn có số đo (mục 4.4): bật nhật ký từng phím **trước khi gõ** bằng `defaults write -g DauPerfLog -bool true`.
   - Chỉ bản Debug có nhật ký này, bản Release không có (D8 (Không telemetry)).
   - Không bật thì `perf-report.sh` không có dòng nào để đọc.
   - Khi bật, bản Debug ghi một dòng log cho mỗi phím, category `perf`, chỉ gồm loại sự kiện, thời gian (ns) và bundle ID của ứng dụng đang gõ, **không** ghi chữ bạn gõ (D8).
   - Tự kiểm: `/usr/bin/log show --last 5m --predicate 'category == "perf"' --style compact`.
   - Nhớ tắt sau khi đo (mục 4.4).
7. Ghi lại: ngày, commit của Dấu, phiên bản ứng dụng, phiên bản macOS, chế độ gạch chân của ứng dụng đó (Không / Có).
8. Chỉ gõ vào ô nháp: tài liệu mới không lưu, Saved Messages của Telegram, ô soạn tin không gửi. Không gửi tin nhắn, không lưu tệp nếu người dùng chưa cho phép (như M2).

### 4.2 Gõ câu mẫu

Câu mẫu (Telex), kết thúc bằng một dấu cách:

```
windows carr tooi yeeu tieengs Vieetj, Sunrise␣
```

Mong đợi: `windows car tôi yêu tiếng Việt, Sunrise␣` (D4, D26 (Gõ đúp phím dấu), D30 (Kiểm tra chính tả)).

- "carr" đứng trước câu tiếng Việt để tránh tự sửa chính tả của macOS (mục 6.1).
- Số đo ngày 29/10 dùng câu mẫu cũ `tooi yeeu tieengs Vieetj, windows Sunrise carr␣`.

Cách chạy:

- **Ứng dụng có trong script** (`safari`, `chrome`, `vscode`, `terminal`; TextEdit đã bỏ khỏi script vì tự lưu tài liệu thử lên iCloud Drive, kết quả TextEdit dưới đây là số đo cũ; lượt chạy ma trận thêm `edge`, `firefox`, `notes`, `mail`): chạy lần lượt
  `scripts/selftest/typing/run.sh --delay 30 <app>` và `scripts/selftest/typing/run.sh --delay 0 <app>`.
  - Script cần quyền Trợ năng cho tiến trình chạy nó (gửi phím qua System Events).
  - Script tự mở cửa sổ trống, gõ, đọc lại, đóng không lưu, in ✓/✗ cho từng app và số đo.
  - `--delay 0` gửi cả chuỗi trong một lệnh (khoảng 1–2 ms/phím): đây là bài thử phím dồn, nhanh hơn người gõ.
  - Có thể thêm `--delay 5`, `--delay 10`, `--delay 20` để tìm ngưỡng.
- **Ứng dụng khác:** script chưa hỗ trợ.
  - Gõ tay (tốc độ bình thường, rồi gõ nhanh hết sức), hoặc tự gõ qua System Events như cách đã làm với Telegram ngày 30/10.
  - Ghi rõ cách thử vào cột "Cách thử".

### 4.3 Những gì cần kiểm tra

| Kiểm tra | Cách làm | Mong đợi |
|---|---|---|
| Chữ đúng | so từng ký tự với câu mong đợi | khớp hoàn toàn |
| Gạch chân | nhìn từ đang gõ | chế độ thường: không gạch chân. Chế độ gạch chân: từ đang gõ có gạch, hết gạch khi kết thúc từ hoặc reset |
| Nhảy chữ | nhìn trong lúc gõ | không lặp, mất, đảo chữ; con trỏ không nhảy; không thay sai chỗ |
| Backspace (D32) | gõ `hoaf` rồi ⌫ | "hoà" rồi "hò" |
| Click reset (D4, D11) | gõ `tooi`, click vào chỗ khác trong văn bản (sau dấu cách hoặc đầu dòng), gõ `s` | chỉ thêm "s" ở chỗ mới, "tôi" cũ không đổi. Click ngay sau một chữ thì D20 có thể đặt dấu vào chữ đó (D4 × D20) |
| Mũi tên reset (D4, D4 × D20) | gõ `tooi`, nhấn ←, nghỉ một nhịp, gõ `s` | D20 bật (mặc định): "tối". ← chỉ xoá bộ đệm, không chặn D20: phím dấu đặt dấu vào chữ ngay trước con trỏ ("tô" → "tố"), chữ "i" sau con trỏ giữ nguyên. D20 tắt: phím đi thẳng, thêm "s" tại con trỏ ("tôsi"). Ghi chú M2: lần ← đầu sau từ gõ dở có thể bị ứng dụng nuốt (TextEdit, cả với U.S.) |
| Thêm dấu cho từ đã gõ (D20) | gõ `hoc`, dấu cách, ⌫, nghỉ một nhịp (≥ 50 ms, gõ tay là đủ), rồi `j`. Tự gõ: `run.sh --delay 120 --keys "hoc ⌫j tooi ⌫s carr ⌫s hoc ⌫f viet ⌫j xin chao ⌫f " --expect "học tối cars hocf vietj xin chào "` | "học". Phím dồn dưới 50 ms thì D20 cố ý không chạy ("hocj"). App gạch chân (D13): không có D20, ra "hocj". Terminal: ⌫ không tới bộ gõ nên ra "hocj" (ARCHITECTURE.md) |
| Tự sửa chính tả (D4) | gõ `tooi yeeu tieengs Vieetj, Sunrise carr␣` | Dấu trả "car". Nếu sau dấu cách chữ thành "cả": gõ lại câu bằng U.S. (`… Sunrise car␣`). U.S. cũng bị sửa thì đó là macOS, ghi "có" ở cột Tự sửa; không tắt tự sửa hộ người dùng (N4 (Không tự đổi cài đặt hệ thống)) |

### 4.4 Số đo cần ghi

Ngay sau khi gõ xong:

```
scripts/perf/perf-report.sh --last 5m --app <tên app hoặc một phần bundle ID>
```

`--app` không phân biệt hoa thường, không nhận PID; không ra số thì script in danh sách app có số đo. Ghi vào bảng mục 5:

- `selectedRange_us` p50 / p99 (chi phí của việc hỏi vị trí con trỏ ở mỗi phím).
- `insertText_us`, `handle_replace_us` p50 / p99 (ghi ở cột Ghi chú nếu có).
- `count_mismatch` (vị trí con trỏ khác dự đoán), `count_unsupported` (ứng dụng trả `NSNotFound`, dấu hiệu cần gạch chân), `count_replace`, `count_pass`.
- `event_client-changed`: số lần client đổi dưới cùng một controller. Tăng theo từng phím thì là lỗi (bộ gõ sẽ không bỏ dấu được).
- `event_client-not-text-input`: client không trả lời được giao thức nhập văn bản.
- Hai dòng `event_client-…` khác 0 thì báo lại ngay.

Về độ tin cậy của số đo:

- Số đo lấy từ bản Debug, có thêm một lần hỏi chẩn đoán sau mỗi lần thay (`ReplaceDiag.swift`), nên không phải số của bản Release.
- Cần p99 đáng tin thì gõ thêm vài trăm phím có dấu trong cùng ứng dụng rồi chạy lại.
- Đo xong thì tắt nhật ký từng phím: `defaults delete -g DauPerfLog` (nhật ký có giờ và app của từng phím, D8).

## 5. Kết quả

Cách đọc bảng:

- "30 ms", "0 ms": tự gõ bằng `scripts/selftest/typing/run.sh` hoặc System Events.
- Số µs là `selectedRange` ở 30 ms/phím, phím có thay chữ, trừ khi ghi khác.
- "—": chưa đo mục đó.
- Phiên bản ứng dụng lúc đo M2 không được ghi lại.

Nguồn của các cột:

- Gạch chân ở 0 ms của Chrome, VS Code, Terminal, TextEdit, Safari: lượt đo gạch chân (30/10/2026, gạch chân ép bằng `DauDebugForceUnderline`, `docs/history/LOG-M0-M4.md` nhật ký 30/10).
- Thêm dấu cho từ đã gõ (D20): lượt đo D20 (30/10/2026, chuỗi kiểm tra ở 120 ms, `docs/PROGRESS.md` "Số đo" 30/10) cho TextEdit, Safari, Chrome, VS Code, Terminal; lượt chạy ma trận (mục 5.1) cho Firefox, Edge, Notes.

| Ứng dụng | Ngày | Cách thử | 30 ms | 0 ms | Gõ tay | Gạch chân / nhảy chữ | Backspace, click reset, mũi tên reset | Thêm dấu cho từ đã gõ (D20) | Tự sửa chính tả | `selectedRange` p50 / p99 µs | mismatch / unsupported | Cần gạch chân? | Nguồn |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| TextEdit | 29–30/10/2026 | script + gõ tay | đúng | đúng; gạch chân 0 và 30 ms: đúng (lượt đo gạch chân) | đúng | không / không | ĐẠT (mũi tên reset theo mong đợi cũ, xem dưới bảng) | ĐẠT (lượt đo D20, 120 ms) | chưa ghi riêng | 327 / 606 | 0 / — | chưa thấy lỗi | PROGRESS "Số đo" 29/10; `docs/history/M2-TESTING.md` mục 2, 4; `docs/history/LOG-M0-M4.md` nhật ký 30/10 (script PASS sau đổi bundle ID; lượt đo gạch chân và lượt đo D20) |
| Safari | 29/10/2026; Backspace 30/10/2026 | script + gõ tay | đúng | đúng; gạch chân 0 và 30 ms: đúng (lượt đo gạch chân) | đúng | không / không | Backspace ĐẠT ("hò", 30 ms) | ĐẠT (lượt đo D20, 120 ms) | — | 622 / 1.057 | 0 / — | chưa thấy lỗi | PROGRESS "Số đo" 29/10, 30/10; `docs/history/M2-TESTING.md` mục 2 |
| Chrome | 29/10/2026; Backspace, lượt đo gạch chân, lượt đo D20 30/10/2026 | script + gõ tay | đúng | **sai** (mismatch 3–4, thay nhầm vùng ở lần thay đầu của từ); 5 và 10 ms đúng; 0 ms gạch chân: **đúng** (lượt đo gạch chân) | đúng | không / không ở 30 ms | Backspace **SAI** ở cbb8179 ("h", 120 ms); đã sửa: ĐẠT ("hò" ở 120 ms và chạy lại ở 30 ms, mục 6.4) | ĐẠT (lượt đo D20, 120 ms) | — | 415 / 694 | 0 / — (ở 30 ms) | có, đề xuất (D13: sai ở 0 ms, gạch chân sửa được) | PROGRESS "Số đo" 29/10, 30/10; `docs/history/LOG-M0-M4.md` nhật ký 30/10 (lượt đo gạch chân); `docs/history/M2-TESTING.md` mục 2 |
| Firefox | 30/10/2026 | script (158.0.1, trang thử cục bộ, `spellcheck=false`) | đúng | **sai**, chữ nhảy chỗ ("ar ấki tj, Hangs Vieu tiei yeoindows ca", mismatch 4); 5 ms sai (mismatch 1); 10 ms đúng; 0 ms gạch chân: **đúng** (mark 38) | — | — / **có nhảy chữ ở 0 ms** | Backspace ĐẠT ("hò"); click reset, mũi tên reset chưa thử | ĐẠT ("học", 120 ms) | không (trang thử tắt kiểm tra chính tả) | 265 / 1.174 | 0 / 0 (30 ms) | có, đề xuất (sai ở 0–5 ms, gạch chân sửa được; vào danh sách ở 61daeec) | lượt chạy ma trận 30/10/2026 (mục 5.1). `insertText` 752 / 3.365 µs; `handle` phím có thay 1.171 / 4.113 µs; replace 12, pass 33 |
| Edge | 30/10/2026 | script (155.0, trang thử cục bộ, `spellcheck=false`) | đúng | **sai** ("ưấrndows ca toi yeu tiengs Vietj, Suni", mismatch 4); 5 ms sai (mismatch 1); 10 ms đúng; 0 ms gạch chân: **đúng** | — | không / không ở 30 ms | Backspace **SAI** ở cbb8179 ("h": mất 2 chữ) ở 30 và 120 ms; đã sửa: ĐẠT ("hò", 120 ms, mục 6.4); gạch chân: ĐẠT. Click reset, mũi tên reset chưa thử | ĐẠT ("học", 120 ms) | không (trang thử tắt kiểm tra chính tả) | 369 / 6.828 | 0 / 0 (30 ms) | có (đã trong danh sách; nay có số đo) | lượt chạy ma trận 30/10/2026 (mục 5.1). `insertText` 1.184 / 8.661 µs; `handle` phím có thay 1.527 / 15.851 µs (n=12, p99 là một lần chậm); replace 12, pass 33 |
| Arc | chưa thử | | | | | | | | | | | | |
| Brave | chưa thử | | | | | | | | | | | | |
| VS Code | 29/10/2026; Backspace, lượt đo gạch chân, lượt đo D20 30/10/2026 | script | đúng | **sai**; 5 ms sai. 10 ms: M2 (29/10/2026) sai ("ôoi"), lượt đo gạch chân sau đó (30/10/2026, câu mẫu đã đổi) đúng; từ 20 ms đúng. Gạch chân 0 và 5 ms: **đúng** (lượt đo gạch chân) | — | không / không ở 30 ms | Backspace **SAI** ở cbb8179 ("h", 30 ms); đã sửa: ĐẠT ("hò" ở 120 ms và chạy lại ở 30 ms, mục 6.4) | ĐẠT (lượt đo D20, 120 ms) | — | 230 / 885 | 0 / — (ở 30 ms) | có, đề xuất (D13: sai ở 0 và 5 ms, gạch chân sửa được) | PROGRESS "Số đo" 29/10, 30/10; `docs/history/LOG-M0-M4.md` nhật ký chẩn đoán 29/10 và nhật ký 30/10 (lượt đo gạch chân) |
| Cursor | chưa thử | | | | | | | | | | | | |
| Zed | chưa thử | | | | | | | | | | | | |
| Sublime Text | 29/10/2026 | gõ tay | — | — | có số đo; kết quả chữ không được ghi | — | — | — | — | 334 / 3.718 (gõ tay, n=35, sơ bộ) | — | chưa đủ dữ liệu | PROGRESS "Số đo" 29/10; DECISIONS mục "Vị trí thay chữ: hỏi con trỏ ở mỗi phím hay tự tính" (selectedRange 17% thời gian phím) |
| JetBrains IDE | chưa thử | | | | | | | | | | | | |
| Xcode | chưa thử | | | | | | | | | | | | |
| Terminal | 29/10/2026; lượt đo gạch chân, lượt đo D20 30/10/2026 | script | đúng | **sai**; 5 và 10 ms đúng. Gạch chân 0 ms: **vẫn sai** (chữ chốt đúng nhưng Terminal còn vẽ marked text cũ tới phím sau); gạch chân 5–30 ms đúng (lượt đo gạch chân) | — | không / không ở 30 ms | — | ra "hocj…" (lượt đo D20: ⌫ không tới bộ gõ, mục 6.5) | — | 408 / 637 | 0 / — (ở 30 ms) | không đề xuất (D13: gạch chân không sửa được ở 0 ms) | PROGRESS "Số đo" 29/10, 30/10; `docs/history/LOG-M0-M4.md` nhật ký 30/10 (lượt đo gạch chân, lượt đo D20) |
| iTerm2 | chưa thử | | | | | | | | | | | | |
| Warp | chưa thử | | | | | | | | | | | | |
| Ghostty | chưa thử | | | | | | | | | | | | |
| Zalo | chưa thử | | | | | | | | | | | | |
| Messenger (web) | chưa thử | | | | | | | | | | | | |
| Telegram | 30/10/2026 | System Events, 30 ms, Saved Messages, không gửi | đúng (câu mẫu cũ) | — | — | không / không | — | — | — | 240 / 1.670 | 0 / 0 | chưa thấy lỗi | PROGRESS "Số đo" 30/10; `docs/history/M2-TESTING.md` mục 2. `insertText` p50 1.830 / p99 3.491 µs; cả phím có thay p50 2.171 / p99 5.313 µs; replace 12, pass 34. `docs/history/M2-TESTING.md` mục 4 dòng 3 (Return ngay sau từ) bỏ qua vì không gửi tin |
| Telegram Desktop | chưa thử | | | | | | | | | | | | |
| Discord | chưa thử | | | | | | | | | | | | |
| Slack | chưa thử | | | | | | | | | | | | |
| Microsoft Teams | chưa thử | | | | | | | | | | | | |
| Word | chưa thử | | | | | | | | | | | | |
| Excel | chưa thử | | | | | | | | | | | | |
| PowerPoint | chưa thử | | | | | | | | | | | | |
| Pages | chưa thử | | | | | | | | | | | | |
| Numbers | chưa thử | | | | | | | | | | | | |
| Keynote | chưa thử | | | | | | | | | | | | |
| Google Docs | chưa thử | | | | | | | | | | | | |
| Google Sheets | chưa thử | | | | | | | | | | | | |
| Notion | chưa thử | | | | | | | | | | | | |
| Obsidian | chưa thử | | | | | | | | | | | | |
| Ghi chú (Notes) | 30/10/2026 | script (4.13, ghi chú mới trong iCloud, xoá trắng sau khi đọc) | đúng | đúng (mismatch 0) | — | — / không | Backspace ĐẠT ("hò"); click reset, mũi tên reset chưa thử | ĐẠT ("Học": Notes tự viết hoa chữ đầu) | không: "…Sunrise carr␣" giữ "car" (chữ đầu "Tôi" do Notes viết hoa) | 330 / 1.135 | 0 / 0 | chưa thấy lỗi | lượt chạy ma trận 30/10/2026 (mục 5.1). `insertText` 3.799 / 10.207 µs; `handle` phím có thay 4.274 / 8.003 µs (cao nhất trong các app đã đo, vẫn đúng ở 0 ms) |
| Mail | 30/10/2026 | script (16.0, thư mới, gõ vào thân thư, ô Đến để trống, không gửi; đóng "Don’t Save") | đúng ("Windows…": Mail tự viết hoa chữ đầu) | — | — | — / — | chưa thử | chưa thử | chưa thử | 375 / 1.245 | 0 / 0 | chưa đủ dữ liệu (chỉ 30 ms) | lượt chạy ma trận 30/10/2026 (mục 5.1), dừng theo yêu cầu người dùng sau khi kiểm chữ đúng ở 30 ms. `insertText` 471 / 2.536 µs; `handle` phím có thay 926 / 2.979 µs |
| Tin nhắn (Messages) | chưa thử | | | | | | | | | | | | |
| Spotlight | chưa thử | | | | | | | | | | | | |
| Finder (đổi tên tệp) | chưa thử | | | | | | | | | | | | |
| Figma | chưa thử | | | | | | | | | | | | |
| Raycast | chưa thử | | | | | | | | | | | | |
| Alfred | chưa thử | | | | | | | | | | | | |

Ghi chú về TextEdit (backspace, click reset, mũi tên reset):

- Nguồn: `docs/history/M2-TESTING.md` mục 4 dòng 1, 4, 5, 6 (30/10/2026, agent tự gõ qua System Events).
- Backspace chạy lại bằng script ngày 30/10/2026 (lượt chạy ma trận, 120 ms): ĐẠT.
- Mũi tên reset ĐẠT theo mong đợi cũ (thêm "s", không bỏ dấu), trước khi có D20; mong đợi mới theo D4 × D20 ("tối" khi D20 bật) chưa chạy lại.
- Các app khác chưa chạy click reset và mũi tên reset: làm tiếp ở M6 (Hiệu năng dưới tải; mục 7).

### 5.1 Lượt chạy ma trận ngày 30/10/2026

- Máy: macOS 27.2, Apple M1 Pro; bộ gõ Debug đã cài ở HEAD 96a3e41.
- Tự gõ bằng `scripts/selftest/typing/run.sh` (thêm `edge`, `firefox`, `notes`, `mail` trong lượt này).
- Phím chỉ gửi khi app thử đứng trước; không nhấn Return ở đâu; không gửi thư hay tin nhắn.
- Mỗi app:
  - Chữ đúng: câu mẫu ở 30 ms và 0 ms; app sai ở 0 ms (hoặc trong danh sách đề xuất) thử thêm 0 ms với `--underline`, 5 và 10 ms.
  - Backspace: `--keys "hoaf⌫ " --expect "hò "` (30 ms).
  - Thêm dấu cho từ đã gõ: `--delay 120 --keys "hoc ⌫j " --expect "học "`.
  - Tự sửa chính tả: `--keys "tooi yeeu tieengs Vieetj, Sunrise carr " --expect "tôi yêu tiếng Việt, Sunrise car "` (30 ms).
  - Số µs lấy từ báo cáo `perf-report.sh` mà script in cho lượt 30 ms (p50 / p99).
- Trình duyệt thử trên trang cục bộ có `spellcheck="false"`, nên phép thử tự sửa chính tả ở đây không nói gì về tự sửa của trình duyệt khi gõ trên web thật.
- Người dùng dừng lượt thử sau Mail (kiểm chữ đúng ở 30 ms).
  - Chưa thử trong lượt này: Mail (phần còn lại), Messages, Pages, Numbers, Zalo, Discord, Ghostty, Zed, Xcode, WebStorm.
  - Kiểm chứng lại Terminal không gửi ⌫ cho bộ gõ (mục 6.5) cũng chưa chạy.
  - Các việc này làm tiếp ở M6 (người dùng chốt 30/10/2026, mục 7).
- Dọn dẹp:
  - Tab thử đã đóng.
  - Ghi chú thử trong Notes đã xoá trắng và Notes bỏ ghi chú trống (đếm 53 ghi chú trước và sau).
  - Thư nháp đóng bằng "Don’t Save".
  - Notes, Mail, Firefox đã thoát; Edge (do lượt thử mở) còn chạy, không cửa sổ.
  - Nguồn nhập liệu và clipboard được script khôi phục; khoá `DauDebugForceUnderline` đã xoá.

## 6. Giới hạn đã biết

### 6.1 Tự sửa chính tả của macOS đè lên chữ đã giữ (D4) — ghi ngày 30/10/2026

- Hiện tượng: từ macOS 27.2, ở ứng dụng bật tự sửa chính tả, khi phía trước là câu tiếng Việt, hệ thống có thể sửa chữ tiếng Anh vừa gõ thành chữ tiếng Việt ("…Sunrise car␣" → "cả"), **kể cả khi gõ bằng bàn phím U.S.**.
  - Việc này xảy ra sau khi Dấu đã trả đúng "car", nên đè lên kết quả gõ đúp ("carr" → "car").
- Bằng chứng:
  - `docs/DECISIONS.md` D4 (đoạn "Giới hạn đã biết").
  - `docs/history/LOG-M0-M4.md` nhật ký 30/10/2026: câu mẫu `scripts/selftest/typing/run.sh` đổi thành "windows carr tooi yeeu tieengs Vieetj, Sunrise " để né, 3/3 ĐẠT.
  - Chú thích đầu `scripts/selftest/typing/run.sh`.
  - Nguồn không ghi ứng dụng cụ thể đã quan sát; lượt chạy ma trận điền cột "Tự sửa" cho từng app bằng phép thử tự sửa chính tả.
- Dấu không tắt tự sửa của hệ thống (N4). Người dùng hoàn tác bằng ⌘Z hoặc bấm vào chữ bị sửa.
- Tự sửa là thuộc tính của từng ô soạn thảo do ứng dụng quyết định (ví dụ `NSTextView.isAutomaticSpellingCorrectionEnabled`, https://developer.apple.com/documentation/appkit/nstextview/isautomaticspellingcorrectionenabled), nên ứng dụng không dùng hệ thống văn bản của Apple có thể không bị (suy luận, cần kiểm chứng bằng phép thử tự sửa chính tả).

### 6.2 Ứng dụng áp phím bất đồng bộ — ghi ngày 29/10/2026

- Hiện tượng: Chrome, VS Code, Terminal đúng khi phím cách nhau từ 20 ms, nhưng sai khi phím đến dồn.
  - Ngưỡng sai: dưới khoảng 10 ms ở Chrome, Terminal; dưới khoảng 20 ms ở VS Code (số đo 29/10/2026; lượt đo gạch chân ngày 30/10/2026 với câu mẫu mới cho VS Code đúng từ 10 ms).
  - Các app này áp phím bất đồng bộ (Chromium/Electron; Terminal chờ shell in lại chữ), nên `selectedRange` trả ảnh chụp cũ; bộ gõ thấy lệch (`mismatch`), reset từ đang gõ, chữ ra thiếu dấu hoặc thay nhầm vùng.
  - Ảnh chụp không cập nhật trong lúc `handle` đang chạy (hỏi lại 10 lần, cách 2 ms, vẫn y nguyên).
- Ví dụ lượt tự gõ đầu tiên ngày 29/10: VS Code ra "arroi yeu tiengs Vietj, ?indows Suni c", Terminal ra "tôi yêu tiêngs Viêtj, windows Sủnise car".
- Không phải do thiếu quyền Trợ năng (bộ gõ không có quyền đó mà vẫn đúng ở 20 ms trở lên).
- Phương án tự cộng dồn vị trí (thay cho việc hỏi ở mỗi phím) cũng không cứu được, vì vị trí gốc cũng là ảnh chụp cũ và VS Code đổi gốc toạ độ.
- Đã thử và bỏ: chờ ứng dụng rồi hỏi lại; so chữ trước con trỏ bằng `attributedSubstring` (Safari trả chữ cũ nên hỏng cả Safari).
- Bằng chứng:
  - `docs/DECISIONS.md` mục "Vị trí thay chữ: hỏi con trỏ ở mỗi phím hay tự tính" (đã chốt hỏi ở mỗi phím) và mục câu hỏi Chrome/Terminal.
  - `docs/PROGRESS.md` mục "Số đo" (dòng "Cách A theo tốc độ gõ"; "cách A" là hỏi vị trí ở mỗi phím).
  - `docs/history/LOG-M0-M4.md` nhật ký 29/10 (chẩn đoán VS Code/Terminal).
- Hướng xử lý: M3 thử gạch chân (D13) theo bundle ID, đo ở 0, 5, 10 ms rồi chốt. Đã làm (30/10/2026): kết quả ở D13 và mục 5.
- Người gõ tay hiếm khi có hai phím cách nhau dưới 10 ms, nhưng phím lặp khi giữ phím, máy đang tải nặng hay ứng dụng tạm đứng có thể làm phím đến dồn (suy luận; M6 đo dưới tải).

### 6.3 Ô mật khẩu — ghi ngày 30/10/2026

Ở ô nhập bảo mật (ví dụ ô mật khẩu trong Safari), macOS giữ bàn phím `com.apple.keylayout.US` và Dấu không nhận phím nào. Đây là hành vi của hệ thống, không phải lỗi. Nguồn: `docs/history/M2-TESTING.md` mục 4 dòng 17.

### 6.4 Backspace thay chữ tại chỗ bị xoá hai lần trong Chromium/Electron (D32) — ghi ngày 30/10/2026, đã sửa cùng ngày

- Hiện tượng (bản cbb8179): ở Chrome, Edge, VS Code, gõ `hoaf` ("hoà") rồi ⌫ ra "h" thay vì "hò", ở cả 30 và 120 ms/phím.
  - Không gặp ở TextEdit, Safari, Firefox, Notes; chế độ gạch chân (D13) ở Edge đúng.
- **Nguyên nhân (đã kiểm chứng):** ứng dụng Chromium tự chạy lệnh xoá của mình cho phím ⌫ dù bộ gõ đã nuốt phím. Không phải `selectedRange` cũ, không phải đường đọc D20.
  - Log `diag`/`perf` của lượt chạy ma trận (Debug, 120 ms/phím, chỉ số):
    - Phím ⌫ ở Chrome là `key kind=replace … read_ns=-1` và `replace kind=replace del=2 sel=3,0 expected=3 rep=1,2 ins_len=1 after=3,0 after_expected=2`; VS Code (30 ms) và Edge giống hệt.
    - Vị trí hỏi được đúng bằng dự đoán (`sel=3` = `expected=3`), vùng thay đúng (`rep=1,2` = "oà" → "ò"), không có lần đọc D20 (`read_ns=-1`, không có kind `seed*`).
    - TextEdit, Safari, Notes cùng dòng đó trừ `after=2,0` (ứng dụng áp ngay).
    - Firefox `after=3,0` (bất đồng bộ) mà vẫn ra "hò", nên bất đồng bộ không phải nguyên nhân.
    - Kết quả "h" = "hò" mất thêm đúng một chữ.
  - Mã Chromium (`content/app_shim_remote_cocoa/render_widget_host_view_cocoa.mm`, `keyEvent:`, nhánh chính hiện tại):
    - Sau `interpretKeyEvents:`, nếu không có marked text và chữ chờ chèn không quá 1 ký tự, Chromium **luôn** gửi phím gốc (RawKeyDown) cho trang bằng `ForwardKeyboardEventWithCommands`, không xét bộ gõ có nuốt phím hay không.
    - `insertText` có `replacementRange` thì được gửi ngay (`ImeCommitText`), tức là trước phím gốc.
    - Với chữ cái, RawKeyDown không làm gì; với ⌫, trang xoá một chữ.
    - Khi có marked text, Chromium gửi phím giả VKEY_PROCESSKEY thay cho phím gốc, nên gạch chân không bị.
- **Cách sửa (M3, `InPlaceComposer`):** ⌫ cần đặt lại dấu thì **không nuốt phím ở mọi ứng dụng**.
  - Lệnh xoá của chính ứng dụng bỏ chữ cuối, còn bộ gõ thay phần còn lại và trả chữ cuối về đúng chỗ để lệnh xoá đó lấy đi ("hoà": thay "oà" bằng "òà" → ứng dụng xoá "à" → "hò").
  - Vẫn một `selectedRange` và một `insertText` như trước (N3); D32 giữ nguyên.
  - Cần thứ tự: chữ của bộ gõ được áp trước lệnh xoá. Ứng dụng AppKit áp `insertText` trước khi `handle` trả về; Chromium gửi `ImeCommitText` trước phím gốc (mã trên); Safari, Firefox: đo trên máy (kết quả bên dưới).
  - Nếu thứ tự ngược ở một ứng dụng nào đó, phím có thay chữ kế tiếp thấy lệch (D11) và reset.
- Kết quả sau khi sửa (Debug, 30/10/2026, 82d9ecc):
  - `hoaf⌫ ` → "hò" ở 120 ms: TextEdit, Safari, Chrome, VS Code, Edge **PASS** (replace 2, mismatch 0).
  - Chạy lại khi máy rảnh (phiên chính), ở 30 ms: `hoaf⌫ ` → "hò", `vieetj⌫⌫ ` → "vị", `tieengs⌫⌫ ` → "tiế" **PASS** ở cả 6 app (TextEdit, Safari, Chrome, VS Code, Edge, Firefox); câu mẫu ở 30 ms **PASS** ở cả 6 app.
  - `vieetj⌫s ` → "việs" ở 120 ms **PASS** (TextEdit, Chrome, Firefox).
  - ⌫ không còn là lý do đề xuất gạch chân; lý do còn lại là gõ dồn dưới 10 ms (mục 5).
- Test: `InPlaceComposerTests` có client giả kiểu Chromium (`deletesConsumedBackspace`: luôn xoá sau `insertText`) và kiểu AppKit, chạy cùng các chuỗi ⌫; thêm ca ảnh chụp cũ (phím cách 10 ms, ứng dụng trễ 50 ms): D11 bắt lệch, chỉ mất dấu, không mất chữ.

### 6.5 Terminal không gửi ⌫ cho bộ gõ (D32) — ghi ngày 30/10/2026

Phát hiện ở lượt đo D20 của M3 (`docs/history/LOG-M0-M4.md` nhật ký 30/10/2026): Terminal xử lý ⌫ mà không đưa phím cho bộ gõ, nên D32 không giữ được ở đó (phép thử thêm dấu cho từ đã gõ ra "hocj", ARCHITECTURE.md). Lượt chạy ma trận chưa kiểm chứng lại bằng `hoaf⌫␣` vì lượt thử dừng sớm; làm ở M6 (mục 7).

### 6.6 Biểu tượng nguồn nhập liệu trên máy nhiều màn hình — ghi ngày 30/10/2026, đã sửa cùng ngày

- Triệu chứng: trên máy hai màn hình, thanh menu tối ở màn hình phụ (biểu tượng hệ thống màu trắng) vẫn hiện ô V của Dấu màu đen.
- Nguyên nhân: lúc đầu tưởng là giới hạn của macOS với ảnh template của bộ gõ bên ngoài; thực ra cùng nguyên nhân với 6.7: `TISIconIsTemplate` chỉ khai ở cấp bundle, cờ của input mode là false.
- Kết quả: sau b4f2cbe (cờ ở cấp mode), chụp cả hai màn hình: ô V xám trên thanh menu sáng, trắng trên thanh menu tối, giống các biểu tượng hệ thống bên cạnh.

### 6.7 Chỉ báo ⌃Space dưới con trỏ trống — ghi ngày 30/10/2026, đã sửa cùng ngày

- Hiện tượng (đến 7a6f087): chuyển nguồn bằng ⌃Space, bong bóng xanh dưới con trỏ hiện "A" cho U.S. nhưng **trống** cho Dấu.
- Nguyên nhân (đọc bằng lldb và gọi thử lớp riêng `KLInputSourceIconManager` của `KeyboardLayouts.framework`, macOS 27.2):
  - Bong bóng do `CursorUIViewService` (TextInputUIMacHelper) vẽ, lấy ảnh từ `indicatorImageForInputSource:`.
  - Nhãn chữ ("A", "VI", "VI TX") lấy từ bảng `KLDynamicInputSourceIconTable` dựng sẵn trong framework, khoá theo ID nguồn của Apple (291 mục); `TISIconLabels` trong Info.plist không được đọc cho bộ gõ bên ngoài.
  - Nguồn không có trong bảng thì dùng ảnh TIS `TSMInputSourcePropertyIconImage` và cờ `TSMInputSourcePropertyIconShouldBeTemplate`.
  - Cờ này của input mode `….Dau.vi` là `false` dù `TISIconIsTemplate` đặt ở cấp bundle (nguồn cấp bundle thì `true`); với ảnh không phải template, bong bóng trống.
- Cách sửa: thêm `TISIconIsTemplate = true` vào từ điển của input mode.
  - Cờ TIS đổi ngay khi cài lại, không cần đăng xuất.
  - Bong bóng hiện ô V trắng khoét chữ (cùng ảnh thanh menu), không phải chữ trần như "A": hệ thống không cho bộ gõ bên ngoài nhãn chữ.
- Kiểm chứng (TextEdit, ⌃Space Dấu → U.S. → Dấu, chụp 0,25 s sau phím):
  - Có khoá ở mode: hiện V.
  - Bỏ khoá (đối chứng, cùng cách khởi động lại dịch vụ): trống.
  - Thanh menu hai màn hình vẫn đúng.
  - `CursorUIViewService` giữ ảnh cũ trong bộ nhớ đệm và bỏ qua SIGTERM: máy đã cài bản cũ thấy V sau khi đăng xuất, hoặc `killall -9 CursorUIViewService` (dịch vụ tự chạy lại).
- Không thử (không cần sau khi tìm ra nguyên nhân): ảnh PDF, `TISIconLabels` cấp bundle, nhãn bản địa hoá. Chuyển sang IMK extension (`.appex`) có lẽ cũng không cho nhãn chữ, vì bảng nhãn khoá theo ID của Apple (suy luận, chưa thử).

## 7. Còn mở

- Phần còn lại của ma trận làm tiếp ở M6 (Hiệu năng dưới tải; người dùng chốt 30/10/2026):
  - Ứng dụng: Zalo, Discord, Messages, Pages, Numbers, Ghostty, Zed, Xcode, WebStorm (và phần còn lại của Mail).
  - Kiểm chứng lại Terminal không gửi ⌫ cho bộ gõ (mục 6.5).
  - Click reset và mũi tên reset cho phần lớn app (mũi tên reset theo mong đợi mới D4 × D20).
- Đã xong: danh sách đề xuất theo số đo lượt chạy ma trận.
  - **Thêm Firefox** (`org.mozilla.firefox`; sai ở 0 và 5 ms, chữ nhảy chỗ, gạch chân sửa được) vào `CompatibilityList.json` ở 61daeec.
  - Edge giữ, nay có số đo (sai ở 0 và 5 ms, ⌫ xoá hai lần — nay đã sửa ở thay tại chỗ, mục 6.4 — gạch chân sửa cả hai).
  - Notes không đề xuất (đúng ở 0 ms).
- Đã xong: tiêu chí đưa một ứng dụng vào danh sách gạch chân đã chốt ở D13 (mục 1): chỉ đề xuất; thay tại chỗ chỉ sai dưới 10 ms.
- `scripts/selftest/typing/run.sh` biết 8 ứng dụng (thêm Edge, Firefox, Notes, Mail ở lượt chạy ma trận). Thử nhiều ứng dụng ở 0 ms cần thêm ứng dụng vào script (mở ô trống, đọc lại chữ) hoặc chấp nhận gõ tay.
- Pages có hai bundle ID trên cùng máy (`com.apple.Pages` và `com.apple.iWork.Pages`); Numbers, Keynote bản mới đổi ID (`com.apple.Numbers`, `com.apple.Keynote`). Nếu các app này cần quy tắc, danh sách tương thích phải ghi đủ các ID.
