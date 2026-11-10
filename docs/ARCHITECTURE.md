# Kiến trúc

Tài liệu này tả cấu trúc: thành phần nào làm gì, gọi nhau ra sao, luồng một phím đi qua đâu. Số đo không nằm ở đây: số đo theo ngày ở `docs/PROGRESS.md` (bảng Số đo; mốc đã đóng ở `docs/history/`), số đo giao diện ở `docs/research/SYSTEM-SETTINGS-REFERENCE.md`. Lịch sử các thay đổi của tài liệu: `docs/history/DOCS-LOG.md`.

## Các thành phần

```
dau/
├─ .claude/agents/             # subagent: researcher, engine-dev, imk-dev, app-ui-dev, release-eng, web-dev, auditor
├─ .claude/commands/           # /milestone, /audit
├─ project.yml                 # XcodeGen → Dau.xcodeproj
├─ Packages/
│  ├─ DauEngine/               # Swift package thuần, không Foundation/AppKit
│  │  ├─ Sources/DauEngine/    # VietEngine, bảng nguyên âm/dấu, quy tắc chính tả
│  │  └─ Tests/                # Swift Testing: ca Telex/VNI theo quy tắc chính tả, ca biên, test hiệu năng
│  └─ DauShared/               # model cài đặt chung (phụ thuộc DauEngine), lưu trữ App Group + Darwin notification, xem trước bằng engine thật, model danh sách tương thích; sau này (M7 (Phát hành)): kiểm chữ ký danh sách tải về
├─ Apps/
│  ├─ DauInputMethod/          # bundle input method (IMK), sandbox, KHÔNG có quyền mạng (N2 (Bộ gõ không có quyền mạng))
│  └─ Dau/                     # app chủ SwiftUI, KHÔNG sandbox (D37 (Cài đặt bộ gõ)): Cài đặt, onboarding, cài/nâng cấp/gỡ bộ gõ, cập nhật (Sparkle), báo lỗi
└─ docs/                      # gồm OPENKEY-NOTES.md, viết ở mốc M1 (Engine)
```

### DauEngine

- `struct VietEngine: Sendable` giữ từ đang gõ trong bộ đệm dung lượng cố định.
  - Bộ đệm là `TextBuffer`: tối đa 32 scalar, lưu trong `SIMD32<UInt32>` (`InlineArray` cần macOS 26).
  - Không cấp phát mỗi phím (số đo: `docs/PROGRESS.md`, bảng Số đo, 29/10/2026).
- API: mọi hàm `mutating`, trả `Action`.
  - `handle(_ key: Unicode.Scalar)`:
    - chữ cái/chữ số nối vào từ;
    - ký tự in ra khác (Space, Enter, Tab, dấu câu) kết thúc từ (D4 (Từ nước ngoài)) và nằm luôn trong `insert`;
    - ký tự điều khiển, 0x7F và phím chức năng 0xF700–0xF8FF chỉ `reset()`.
  - `backspace()` (D32 (Backspace)): IMK phải gọi hàm này cho phím xoá, **không** đưa 0x7F vào `handle`.
  - `endWord()`: kết thúc từ không chèn ký tự, cho Return/Tab/Enter bàn phím số (0x03) khi IMK muốn để app tự xử lý phím.
  - `seed(displayed:) -> Bool` (D20 (Thêm dấu cho từ đã gõ)): nạp từ đọc được từ ứng dụng; nhận NFC hoặc NFD.
  - `seedOverflow(shown:)` (ngoại lệ "từ có sẵn không phải tiếng Việt" của D20, và D33 (Độ dài từ)): với từ có sẵn mà `seed` không nhận (không phải tiếng Việt), vào trạng thái đi thẳng của D33 cho phần còn lại của từ.
  - `reset()`, `isComposing`.
- `Action` là `.passThrough` (IMK trả `false`) hoặc `.replace(deleteCount:insert: TextBuffer)`.
  - `.replace` xoá `deleteCount` **scalar** trước con trỏ và chèn `insert` trong một lần `insertText` (N3 (Ít lời gọi vào ứng dụng đích)).
  - Chữ Việt dựng sẵn đều nằm trong BMP nên số scalar bằng độ dài UTF-16.
  - Ngoại lệ: từ được seed từ NFD, khi đó IMK tự đo chuỗi đã seed.
- Tuỳ chọn `EngineOptions`:
  - kiểu gõ (`telex`, `simpleTelex`, `vni`);
  - vị trí dấu (`modern`/`classic`);
  - bỏ dấu tự do (D28 (Bỏ dấu tự do));
  - tự khôi phục (D4, D30 (Kiểm tra chính tả), D33);
  - `advanced: .off | .consonantShortcuts | .allowZFWJ`: một enum nên hai mục loại trừ nhau (D22 (Gõ tắt loại trừ z, f, w, j)).
- Đường nóng không dùng `String`, `any Protocol`, closure, không import Foundation.
- Engine dựng thẳng ký tự NFC từ bảng (D3 (Không macro, chỉ Unicode dựng sẵn)), không chuẩn hoá lúc chạy.

### DauShared

- Phụ thuộc DauEngine: để đổi cài đặt sang `EngineOptions` và chạy engine thật cho phần xem trước. Không dùng trong đường nóng của engine.
- `DauSettings`: Sendable, Codable, mặc định theo D15 (Cài đặt mặc định). `advanced` là một enum nên D22 không thể bật cả hai.
- `AppRule` (D5 (Quy tắc theo ứng dụng), D13 (Gạch chân là đường lui cuối cùng)):
  - gồm bundle ID, tên hiển thị, gạch chân, nguồn "Đề xuất"/người dùng;
  - không có chế độ Việt/Anh.
- Giải mã `DauSettings` và `AppRule` dễ dãi (D18 (Phòng thủ với IMK)):
  - khoá lạ hoặc khoá cũ (`rememberModePerApp`, `mode` của quy tắc) bị bỏ qua;
  - quy tắc cũ giữ lựa chọn gạch chân;
  - lần lưu sau không ghi lại các khoá đó.
- Hệ quả: quy tắc cũ chỉ có "Tiếng Anh" trở thành quy tắc không làm gì (không gạch chân), và Dấu gõ tiếng Việt ở app đó. Người dùng không được báo. Chấp nhận vì chưa có bản phát hành nào.
- `SettingsStore`:
  - lưu cả cài đặt thành một JSON dưới khoá `settings` trong UserDefaults suite = App Group (`DauAppGroupIdentifier` trong Info.plist, giá trị `$(TeamIdentifierPrefix)$(BUNDLE_ID_PREFIX).shared`);
  - sau mỗi lần lưu phát Darwin notification `<suite>.settingsDidChange`;
  - `observeChanges` cho bộ gõ áp dụng ngay.
- `CompatibilityList` (D7 (Cập nhật và loại bản dựng), D13): danh sách app được gắn nhãn "Đề xuất".
  - Mỗi mục có: các bundle ID của một app (một app có thể có nhiều ID), tên, cờ `suggestUnderline`, ghi chú cho người bảo trì (không hiện lên giao diện, N5 (Chỉ hứa điều đã kiểm chứng)). Cả danh sách có `version`.
  - Giải mã dễ dãi (D18): khoá lạ bị bỏ qua; mục hỏng hoặc không có bundle ID bị bỏ mà không mất các mục khác; file hỏng thành danh sách rỗng.
  - Bản có sẵn là `Apps/Dau/Resources/CompatibilityList.json` trong app chủ.
    - Nội dung ở M3 (Độ tin cậy): VS Code, các app Electron/Chromium của `docs/COMPATIBILITY.md` và Firefox (61daeec), không có Terminal (D13).
    - Test trong DauShared đọc chính file này.
  - `DauSettings.suggestions(from:isInstalled:)` dựng các hàng mục "Đề xuất":
    - là app đề xuất đã cài mà chưa có quy tắc đã lưu, theo thứ tự danh sách;
    - **không lưu** gì;
    - "Bật gạch chân" gọi `acceptSuggestion`, lưu quy tắc "Có gạch chân" nguồn `suggested` vào cuối "Quy tắc riêng".
  - "Quy tắc riêng" là đúng `appRules` đã lưu.
    - `setUnderline(_:for:)` đổi popup mà giữ quy tắc và nguồn; đặt về "Không gạch chân" vẫn là quy tắc.
    - Mọi quy tắc đã lưu, kể cả người dùng tự thêm, đưa app ra khỏi "Đề xuất"; xoá quy tắc thì app trở lại.
  - Bộ gõ **không** đọc danh sách: gạch chân chỉ theo quy tắc đã lưu (D13).
  - Ở M7: app chủ tải bản JSON có chữ ký cùng định dạng vào container App Group (bộ gõ không tải, N2).
    - Kiểm chữ ký, rồi dùng bản hợp lệ có `version` cao hơn giữa bản tải về và bản có sẵn.
    - Chỉ cần thay chỗ `SettingsModel` lấy danh sách (`CompatibilityList.bundled()`).
- `TypingPreview`/`TypingExample`: chạy engine thật như bộ gõ.
  - App chủ dùng chúng để dựng mọi ví dụ "phím → kết quả" trên giao diện (`SettingsSamples` trong `Apps/Dau`, có test ở `scripts/snapshot-settings`).
  - Nên mọi ví dụ đều do engine tính (N5).

### DauInputMethod (input method)

#### Điều khiển và hai chế độ ghi chữ

- Lớp con `IMKInputController`, mỗi client một instance và một `VietEngine` riêng. Không có trạng thái toàn cục (khác OpenKey).
- `handle(_:client:)` đưa phím vào engine qua `InPlaceComposer` (thay tại chỗ) hoặc `MarkedComposer` (gạch chân). Cả hai là kiểu giá trị thuần, test bằng client giả.
- Thay tại chỗ:
  - nếu `replace`: hỏi `selectedRange` một lần để có vị trí tuyệt đối, rồi gọi `insertText(_:replacementRange:)` đúng một lần;
  - phím đi thẳng không hỏi gì;
  - đây là cách đã chốt trong `DECISIONS.md` (mục "Vị trí thay chữ: hỏi con trỏ ở mỗi phím hay tự tính"; N3);
  - bản Debug có thêm một lần hỏi sau khi thay để chẩn đoán (`ReplaceDiag.swift`); số đo M2 (Bộ gõ tối thiểu) làm trên Debug có lời gọi thừa này.
- Reset engine khi:
  - click chuột;
  - `activateServer`/`deactivateServer`, `commitComposition`;
  - phím di chuyển con trỏ;
  - `selectedRange` khác dự đoán (trừ khi app chỉ trả lời chậm, mục dưới);
  - nguồn nhập liệu đổi mà IMK không báo (xem "Đổi nguồn nhập liệu không qua `activateServer`").

#### App trả lời chậm (M6, `CursorTracker.known`, `CursorTracker.rebuild`)

- Hiện tượng:
  - Chrome trang bận: app áp phím theo thứ tự nhưng trả `selectedRange` và `attributedSubstring` từ chữ cũ, chưa có vài phím gần nhất. Lần thay đầu của một từ dùng vị trí cũ đó nên thay nhầm chữ đứng trước ("bạn" ra "ạnn"); D11 (Kiểm tra ngữ cảnh) không bắt được vì vị trí dự đoán (`expected`) chỉ có trong một từ.
  - Phím dồn (Chrome, VS Code, Firefox, `docs/COMPATIBILITY.md` mục 6.2): cùng hiện tượng, app chậm cả loạt phím vừa gõ.
- Chromium (mã nguồn, chưa đo trên bản đã cài):
  - thay với `replacementRange` trong ô thường giữ con trỏ và dời nó theo độ dài đổi (`ReplaceTextAndKeepSelection`); với EditContext (VS Code dùng mặc định, tuỳ chọn `editor.editContext`) con trỏ về cuối vùng vừa thay (`EditContext::CommitText`);
  - lời gọi của bộ gõ và phím đi qua cùng giao diện `WidgetInputHandler` và vào cùng hàng đợi `MainThreadEventQueue` của trang (chặng qua luồng compositor của phím chưa đọc);
  - `selectedRange` và `attributedSubstring` trả từ bộ đệm phía trình duyệt (`_textSelectionRange`, `_availableText` trong `render_widget_host_view_cocoa.mm`), không hỏi trang;
  - mỗi `insertText` với NSNotFound (phím đi thẳng, bộ gõ chèn tại con trỏ) được ghi ngay vào bộ đệm đó ở vị trí con trỏ trang báo lần trước (cái sau đứng trước cái trước), và con trỏ trong bộ đệm thành vị trí đó cộng độ dài cái mới nhất; `insertText` có vùng thay thì không ghi.
- Firefox (mã nguồn, chưa đo): `selectedRange` và chữ trả từ bộ đệm của tiến trình cha (`ContentCacheInParent`, `IMEInputHandler::mSelectedRange`), chỉ cập nhật khi tiến trình nội dung báo; thay với vùng thay là chọn vùng rồi chèn, con trỏ về cuối vùng vừa thay (`InsertTextAsCommittingComposition`).
- Cách xử lý:
  - `CursorTracker` theo vị trí con trỏ qua ranh giới từ (`known`), cùng các thao tác gần nhất bộ gõ đã làm hoặc để đi thẳng (`edits`, đánh dấu thao tác chèn tại con trỏ `atCaret`) và chữ chính nó đã gõ ngay trước con trỏ (`tail`).
    - Mất vị trí khi reset (click, mũi tên, phím tắt, Return/Tab, đổi client), và khi ⌫ đi thẳng mà không biết chữ bị xoá.
    - `known` không thay cho `expected`: ở đầu từ, vị trí khác `known` vẫn có thể là app tự sửa chữ (tự sửa chính tả, gạch ngang thông minh).
    - `burst`: số thao tác gần nhất do các phím đến liền nhau dưới 50 ms (`settleInterval`) tạo ra; composer báo cho tracker ở mỗi phím (`keyInBurst`).
  - Ở phím thay chữ, nếu `selectedRange` khác `known`, ở mọi tốc độ: đọc chữ trước vị trí app trả một lần (lần đọc của D11 khi lệch, N3).
    - App chậm được chứng minh khi chữ đó, ở một trong hai dạng, cộng các thao tác app chưa áp ra đúng từ trong engine, mỗi thao tác xoá phải gặp đúng chữ nó xoá (`rebuild`): (a) chữ như trước các thao tác đó (Firefox; Chrome khi không có thao tác chèn tại con trỏ); (b) chữ đó cộng thao tác chèn tại con trỏ mới nhất trong số đó (bộ đệm Chromium).
    - Số thao tác app được chậm: tối đa `lateLimit`, cộng `burst`. Vượt `lateLimit` thì chữ app trả trước các thao tác đó cũng phải là chữ bộ gõ đã gõ ở đó (`tail`), so ít nhất hai đơn vị chữ của app (một, khi phần đọc bắt đầu từ đầu văn bản).
    - Hoặc chữ đó là chữ bộ gõ đã gõ (`tail`) thiếu đúng số đơn vị app chậm, trong vài đơn vị gần nhất, so ít nhất hai đơn vị (tối đa `lateLimit`).
    - Khi đó thay ở vị trí `known` (kind `late` trong log perf). Vùng thay luôn kết thúc ở `known`: ở app đưa con trỏ về cuối vùng thay (EditContext, Firefox), vùng kết thúc trước con trỏ làm phím sau rơi vào giữa từ.
    - Lần thay đầu của từ, app chậm tối đa `lateLimit` mà không chứng minh được, và trước vị trí app trả không có đủ cả từ: vẫn thay ở `known` (kind `late_guess`). App sửa chữ trước từ (gạch ngang thông minh) thì trước vị trí nó trả có đủ cả từ, nên vị trí của app được tin.
    - Còn lại như cũ: trong từ là lệch (D11; dùng lại chữ vừa đọc để dựng lại chỉ khi phím trước đủ 50 ms), đầu từ thì tin `selectedRange`.
    - Vị trí lấy từ một `selectedRange` có thể cũ không còn ghi đè `known` trong các ca trên (lượt 1d: ghi đè làm lần trả lời chậm sau trùng với `known` sai, "kóo").
  - Cùng cách chứng minh ở phép kiểm từ đã hết hợp lệ (`checkLockedWord`) và ở lần đọc của D20 sau ⌫ (`addMarks`, thao tác chưa áp phải là xoá đã biết chữ); hai chỗ này vẫn chỉ đọc khi phím trước đủ 50 ms.
- Giới hạn: app chậm hơn số thao tác trên mà không chứng minh được thì như trước. Ở đầu văn bản, khi app chưa áp phím nào của loạt phím dồn, không có chữ của app để chứng minh: từ đầu tiên có thể sai và vị trí bị mất cho các từ sau. Kiểm bằng client giả trong `LateAnswerTests` và `RapidKeysTests` (mô hình Chrome, VS Code, Firefox theo mã nguồn; thời gian của app chọn cho khớp số đo M3, không phải số đo).

#### Backspace thay tại chỗ (D32)

- `backspace()` trả `passThrough` thì ⌫ đi thẳng.
- `backspace()` trả `replace` (dấu phải dời, "hoà" ⌫ → "hò") thì vẫn **không nuốt phím**:
  - một `selectedRange`, một `insertText` thay phần chữ cần đổi **kèm lại chữ cuối** ("oà" → "òà");
  - rồi lệnh xoá của chính ứng dụng bỏ chữ cuối đó (`VietEngine.lastShown`).
- Lý do: Chromium/Electron luôn gửi phím ⌫ gốc cho trang sau chữ của bộ gõ, dù bộ gõ đã nuốt phím, nên nuốt phím làm mất thêm một chữ ("h"; `docs/COMPATIBILITY.md` mục 6.4).
- Cách này cần ứng dụng áp `insertText` trước lệnh xoá.
  - AppKit: trong lúc `handle`. Chromium: theo mã nguồn.
  - Thứ tự ngược thì phím thay chữ kế tiếp thấy lệch (D11 (Kiểm tra ngữ cảnh)) và reset.
- Chữ cuối là dấu kết hợp (NFD) thì không đoán: reset, ⌫ đi thẳng.

#### Đổi nguồn nhập liệu không qua `activateServer` (thêm ở M3)

- Hiện tượng: chọn U.S. rồi chọn lại Dấu bằng `TISSelectInputSource` từ tiến trình khác thì IMK không gọi `deactivateServer`/`activateServer`, từ đang gõ dở bị gõ tiếp.
- Cách xử lý:
  - mỗi controller nghe thông báo phân tán `kTISNotifySelectedKeyboardInputSourceChanged` (bộ gõ có sandbox vẫn nhận được);
  - khi nhận thì reset từ đang gõ (D4; chế độ gạch chân thì chốt chữ đang hiện).
- Thông báo đến trong 0,5 s sau `activateServer` của chính controller được coi là tiếng vọng của lần chuyển bằng phím tắt/menu và bị bỏ qua, để phím gõ ngay sau khi chuyển không mất từ.
- Kịch bản kiểm: `scripts/selftest/typing/run.sh --keys "to⇄cj " safari` (không có `--expect` nên script so với câu mẫu mặc định và báo ✗; thứ cần xem là dòng log `source-changed-reset`).
  - `⇄` là chọn U.S. rồi Dấu bằng `TISSelectInputSource` từ tiến trình của script; log `source-changed-reset`.
  - Kết quả có và không có bộ nghe: `docs/PROGRESS.md`, bảng Số đo, 30/10/2026.
- Kịch bản `to` ⇄ `o` không còn phân biệt được: sau reset, D20 đọc lại "to" và `o` cho "tô" đúng như D20 định.

#### "Thêm dấu cho từ đã gõ" (D20), `InPlaceComposer.addMarks`

- Chỉ đọc chữ của ứng dụng khi **mọi** điều kiện sau đúng:
  - công tắc bật (`addMarksToTypedWords`, mặc định bật theo D15; đọc lúc `activateServer` và khi cài đặt đổi, không đọc theo phím);
  - engine không có từ;
  - phím là phím dấu/biến đổi của kiểu gõ (`isMarkKey`), hoặc chữ cái ASCII khác (`isLetter`, trường hợp "Chữ cái gõ sát chữ có sẵn" của D20):
    - Telex, Telex đơn giản: `s f r x j z a e o w d`, hoa hay thường;
    - VNI: chữ số;
  - chưa biết chữ trước con trỏ là gì: đầu phiên, sau reset, click, ⌫ hay Return/Tab ra khỏi từ (sau một ký tự kết thúc từ gõ ở đây thì đã biết không phải chữ cái nên không đọc);
  - phím hay click trước đó trên client này cách ít nhất 50 ms (`settleInterval`).
- Khi đó, các bước đọc:
  - một `selectedRange` (phải là con trỏ, không có vùng chọn);
  - một `attributedSubstring` tối đa 16 đơn vị UTF-16 ngay trước con trỏ, lấy dãy chữ cái/dấu kết hợp/chữ số cuối cùng;
  - `seed(displayed:)`;
  - rồi đưa phím vào engine.
- Sau khi đưa phím vào engine:
  - `replace`: một `insertText` thay đúng vùng chữ đã đọc (đếm UTF-16; mọi ký tự engine nhận đều thuộc BMP nên số scalar bằng số UTF-16, kể cả chữ NFD);
  - `passThrough`: phím đi thẳng và engine giữ từ để gõ tiếp (mốc khôi phục D4 = chữ đã đọc).
- Phím có nối vào từ đã đọc hay không được quyết định trong `seedWord` theo D20 ("Chữ cái gõ sát chữ có sẵn" và ba ngoại lệ).
  - Quyết định chỉ dựa trên từ chữ đã đọc và trạng thái engine, trước khi gửi gì cho ứng dụng. Nên phím không nối chỉ tốn đúng lần đọc (N3).
  - Từ không phải tiếng Việt (ngoại lệ về từ nước ngoài, thắng ngoại lệ về chữ hoa giữa từ): phím được nhận nguyên văn tới hết từ, hoa hay thường.
    - Từ đã khoá chính tả D30 thì giữ seed.
    - Từ toàn chữ cái mà `seed` không nhận (dài hơn 7 chữ, dài hơn phần đọc, hay có chữ engine không biết) thì `continueForeignWord` gọi `seedOverflow`.
  - Trên từ tiếng Việt, chữ hoa sau chữ thường (`startsNewWord`, ngoại lệ về chữ hoa giữa từ) bắt đầu từ mới, trừ phím dấu/biến đổi có thay chữ trong từ.
  - Từ tiếng Việt mà sau phím không còn là tiền tố hợp lệ (`isValidPrefix`: khoá chính tả D30, hoặc quá 7 chữ D33):
    - với chữ cái thường, và với phím dấu/biến đổi đi thẳng không áp dụng được (ngoại lệ về phím dấu không áp dụng được; gõ đúp D26 (Gõ đúp phím dấu) là áp dụng),
    - thì bỏ từ đã đọc, reset engine và xử lý phím như phím đầu của từ mới.
- Từ seed đã khoá chính tả là chữ thật của app nên không kiểm lại theo D11 (`checkedLockedWord`).
- Đọc lại để đồng bộ của D11 dùng cùng `seedWord` nhưng không áp các luật này (`SeedRule.resync`).
- Lỗi đọc (D18):
  - client trả `NSNotFound` hoặc `nil`: thôi đọc tới lần `activateServer` sau;
  - chuỗi sai độ dài, không có chữ, từ có chữ số mà `seed` không nhận, có vùng chọn: không seed, phím xử lý như phím đầu của từ mới.
- Chỉ xét chữ trước con trỏ: con trỏ giữa từ ("hoc|tap" + `j`) thì chỉ phần trước con trỏ đổi ("họctap").
- Vì sao chờ 50 ms:
  - app áp phím bất đồng bộ (Chromium, Electron, terminal) trả `selectedRange`/chữ từ ảnh chụp cũ khi phím dồn (số đo: D13, N3);
  - chữ đọc từ ảnh chụp cũ có thể bị thay sai chỗ.
  - Đã thử không chờ (`settleInterval` = 0): kết quả ở `docs/PROGRESS.md`, bảng Số đo, 30/10/2026 (mục Phạm vi của D20, ý chờ 50 ms).
  - Vẫn giữ 50 ms làm biên an toàn vì người quay lại sửa từ không gõ nhanh như vậy.
  - Phím dồn dưới 50 ms thì D20 không áp dụng, phím đi thẳng.
  - Phép kiểm app trả lời chậm (mục "App trả lời chậm") không chờ: nó không dựng từ từ chữ đọc được, chỉ thay ở vị trí bộ gõ tự theo dõi khi chữ đọc được chứng minh app chậm.
- Chi phí thêm:
  - số đo theo app ở D20 và `docs/PROGRESS.md`, bảng Số đo, 30/10/2026;
  - chỉ tốn ở phím chữ cái hoặc phím dấu đầu tiên ngay sau reset/⌫;
  - gõ liền qua dấu cách không đọc thêm lần nào, tối đa một lần ở phím đầu của phiên (test `sample`, `InPlaceComposerLetterTests.sentence`).
- Log perf:
  - kind `seed` (đã thay), `seed_pass` (đọc, seed, phím đi thẳng), `seed_none` (đọc, không có từ, hoặc chữ cái không nối được), trường `read_ns`;
  - bản Debug thêm `d20=mark|letter|none`, `seeded=0|1`, `diff=0|1|-` (từ đã seed khác với khi không đọc);
  - `scripts/perf/perf-report.sh` đếm các trường này.
- Chế độ gạch chân (D13) **không** dùng D20.
  - Chế độ này dành cho app có ảnh chụp vị trí không tin được và không bao giờ hỏi `selectedRange`, còn biến từ đã chốt thành marked text thì cần vị trí tuyệt đối.
  - Ở app gạch chân, phím dấu sau reset bắt đầu từ mới như khi tắt D20 (mục Phạm vi của D20, ý không áp dụng ở app gạch chân).
- Terminal không chuyển phím ⌫ cho bộ gõ (`docs/COMPATIBILITY.md` mục 6.5).
  - Nên ở Terminal D20 sau ⌫ không bao giờ chạy, và ⌫ giữa từ không qua D32.
  - Ví dụ: "hoaf⌫␣" ra "ho " thay vì "hò "; "tooi⌫s" ra "tôs" (bộ theo dõi con trỏ D11 bắt lệch).
  - Đã ghi vào ma trận tương thích.

#### Chế độ gạch chân (D13), `MarkedComposer.swift`

- Bật khi quy tắc của app có `underline`.
- Từ đang gõ hiện bằng `setMarkedText` (app tự vẽ gạch chân), chốt bằng `insertText` khi kết thúc từ.
- Mọi lời gọi dùng `replacementRange` = NSNotFound (vùng marked hoặc con trỏ của app), nên **không bao giờ hỏi `selectedRange`** và không cần vị trí tuyệt đối. Đó là lý do chế độ này đúng với app áp phím bất đồng bộ.
- Lời gọi mỗi phím (tối đa một, N3):
  - chữ cái/chữ số trong từ, Backspace trong từ (D32): một `setMarkedText` với cả từ (chuỗi rỗng = xoá marked text khi xoá hết từ);
  - ký tự kết thúc từ (D4): một `insertText` gồm từ (đã khôi phục nếu D4 bảo vậy) + ký tự đó, phím được nuốt;
  - Return, Tab, Enter bàn phím số: một `insertText` của từ rồi để app xử lý phím (ứng dụng chat vẫn gửi tin);
  - mũi tên, Esc, tổ hợp ⌘/⌃/⌥ và các sự kiện reset (click, `deactivateServer`, `commitComposition`, đổi nguồn/mode, đổi client, đổi cài đặt):
    - một `insertText` của **đúng chữ đang hiện**, không khôi phục (D4), không làm mất chữ; rồi phím đi tiếp tới app;
    - chốt vào client đã nhận marked text nếu nó còn, không thì client của sự kiện;
    - không còn client nào thì bỏ trạng thái (D18);
  - không có từ đang gõ: không gọi gì, phím đi thẳng (không có D20, xem trên).
- Gõ đúp (D26), khôi phục (D4), độ dài từ (D33) giống hệt chế độ thay tại chỗ.
  - `MarkedComposer` giữ bản sao chữ engine đang hiển thị và áp nguyên `Action` lên đó (test so khớp ngẫu nhiên với thay tại chỗ).
  - Chuỗi chữ dài hơn 32 ký tự không dấu cách (chỉ xảy ra sau D33) được chốt sớm, phần còn lại của từ đi thẳng.
- Kiểm bằng `scripts/selftest/typing/run.sh --underline`; số đo theo app và tốc độ gõ: D13.

#### Đầu vào từ IMK (D18)

Mọi điểm vào và cách xử lý giá trị lạ:

- `handle(_:client:)`:
  - event nil hoặc kiểu khác keyDown/mouseDown → `false`;
  - client nil hoặc không phải `IMKTextInput` → reset, `false`;
  - `characters` nil, rỗng, nhiều scalar, ký tự điều khiển → chỉ reset (`KeyRouter`);
  - `selectedRange` `NSNotFound`, âm, có vùng chọn, ít chữ hơn số cần xoá → không thay (`CursorTracker`);
  - `attributedSubstring` nil, sai độ dài, ký tự ngoài BMP → không seed.
- `activateServer`/`deactivateServer`/`commitComposition` với client nil:
  - reset (gạch chân: chốt vào client đã nhận marked text nếu còn, không thì bỏ);
  - `activateServer(nil)` không giữ bundle ID của app trước.
- `setValue(_:forTag:client:)`: giá trị nil không chuyển cho `super`; giá trị lạ chỉ reset.
- `inputControllerWillClose`: reset, bỏ hai bộ nghe (cài đặt, nguồn nhập liệu).
- `menu()` và hành động menu: không chạy ngoài main thread (`onMain` trả nil thay vì dừng chương trình); tham số của hành động không được dùng.
- Thông báo cài đặt và nguồn nhập liệu: chỉ chạy trên main thread, tham chiếu yếu tới controller.

#### Input mode, quy tắc theo app, cài đặt

- Một input mode duy nhất "Dấu – Tiếng Việt" (`….Dau.vi`), khai báo trong Info.plist (`ComponentInputModeDict`).
  - Để ID nguồn đã bật không đổi và nguồn nằm trong nhóm Tiếng Việt (D2 (Chuyển Việt/Anh)).
  - Gõ tiếng Anh bằng nguồn U.S. của macOS (hoặc nguồn tiếng Anh khác).
  - Bộ gõ không giữ trạng thái chế độ: IMK báo mode nào (kể cả `….Dau.en` còn sót từ bản cũ) cũng xử lý như tiếng Việt.
  - `setValue(_:forTag:client:)` chỉ reset từ đang gõ (D4, D18).
  - Không tự đổi nguồn nhập liệu theo app, không nhớ chế độ theo app (D5), không tự thông báo VoiceOver (D17 (Trợ năng)).
- Quy tắc theo app:
  - lựa chọn gạch chân đọc lúc `activateServer` và khi cài đặt đổi, không đọc theo phím;
  - đổi chế độ giữa chừng một từ thì chốt từ trước;
  - bundle ID của app lấy từ client lúc `activateServer`; Chrome đôi khi đưa client có `bundleIdentifier()` nil, khi đó dùng app đang ở trước (`NSWorkspace.frontmostApplication`);
  - bản Debug có thêm khoá `DauDebugForceUnderline` (mảng bundle ID, miền global `defaults write -g`) để ép gạch chân khi thử mà không đụng cài đặt người dùng; bản Release không đọc khoá này.
- Đọc cài đặt từ App Group; nghe thay đổi để áp dụng ngay. Không đọc danh sách tương thích: gạch chân chỉ theo quy tắc đã lưu (D13).

#### Thoát theo yêu cầu của app chủ (nâng cấp, gỡ; D7, D16 (Bảo trì và gỡ cài đặt))

- `main.swift` nghe thông báo Darwin `<bundle ID>.quitRequested` (`InputMethodLifecycle`).
- Phát `DauQuitRequested` trong tiến trình để mỗi controller đang hoạt động chốt từ như một lần reset (gạch chân: chốt marked text vào client).
- Rồi `exit(0)` ở vòng chạy kế tiếp.
- Kiểm bằng `notifyutil -p com.codefastlabs.dau.inputmethod.Dau.quitRequested` → log `event=quit-requested` (kết quả: `docs/PROGRESS.md`, nhật ký 30/10/2026).

#### Khởi chạy bộ gõ: người dùng hay hệ thống (`LaunchOrigin.swift`, `InputMethodAppDelegate.swift`)

Bundle là `LSBackgroundOnly` nên người dùng mở nó (nháy đúp trong Finder) thì không thấy gì. Đo trên macOS 27.2 (`log` của LaunchServices và Apple event ở `applicationDidFinishLaunching`), có bốn trường hợp:

- *Hệ thống* (imklaunchagent nhờ LaunchServices chạy khi một client cần bộ gõ; cờ `dontSwitch`, không có launch event):
  - app không nhận Apple event nào;
  - trong `applicationDidFinishLaunching` event hiện tại là `aevt/oapp` do AppKit tự tạo, người gửi là chính tiến trình;
  - `NSApplicationLaunchIsDefaultLaunchKey` = 1, cha là launchd (pid 1), `XPC_SERVICE_NAME` cùng dạng `application.<bundle ID>.…` ở mọi đường: không phân biệt được.
- *Finder* (Mở/nháy đúp):
  - LaunchServices gửi `aevt/oapp` thật, người gửi là tiến trình khác;
  - → mở app chủ (`HostApp`), rồi thoát nếu chưa client nào kích hoạt bộ gõ trong lúc đó (`DauClientActivated`).
- *Mở lại khi đang chạy* (Finder, `open`, `NSWorkspace`, có hay không `dontSwitch`):
  - không có tiến trình mới, tiến trình đang chạy nhận `aevt/rapp`;
  - → mở app chủ, **không** thoát (có thể đang phục vụ gõ);
  - bỏ qua `rapp` trong 1 s đầu sau khởi chạy (phòng hờ hệ thống xin chạy hai lần; chưa thấy xảy ra).
- *`open` trong Terminal khi bộ gõ chưa chạy*:
  - không có Apple event, giống hệt hệ thống (chỉ LaunchServices thấy cờ khởi chạy; biến môi trường là của tiến trình gọi `open`, không tin được);
  - → coi là hệ thống, chạy tiếp, không mở gì;
  - không chắc thì luôn chạy tiếp.

Cách tìm app chủ:

- Tìm như mục "Cài đặt Dấu…" (`HostApp`): bản đang chạy, bản chứa bộ gõ, bản cùng phiên bản ưu tiên thư mục Applications, rồi tìm thẳng trong /Applications khi LaunchServices chưa biết bản chép vào.
- Sandbox của bộ gõ không đọc được Info.plist của bản nằm trong thư mục nhà (đo: `deny file-read-data` với bản ở DerivedData).
- Nên bản build chưa chạy và không nằm ở /Applications không được chọn (log `host-app-not-found known=… readable=…`).

#### Biểu tượng, ký và entitlements của bundle

- **Biểu tượng của bundle** (Finder):
  - dùng chung `Apps/Dau/Resources/Assets.xcassets` (AppIcon) với app chủ (`project.yml`), ra `CFBundleIconName`/`Assets.car` giống Dấu.app;
  - tên hiển thị vẫn là "Dấu" (D24 (Tên và định danh)).
- Biểu tượng nguồn nhập liệu (ô V trên thanh menu, chỉ báo ⌃Space) không đổi: vẫn là TIFF template khai trong Info.plist (`docs/COMPATIBILITY.md` 6.6, 6.7).
  - Đã kiểm lại TIS (`kTISPropertyIconImageURL` = `ModeVietnamese.tiff`, cờ template = 1 ở cả bundle và mode) và ảnh thanh menu sau khi cài.
- Bản Release không có `get-task-allow` (`CODE_SIGN_INJECT_BASE_ENTITLEMENTS: NO`), nên không tiến trình nào gắn debugger vào bộ gõ để đọc từ đang gõ.
  - Bản Debug có, chỉ dùng khi thử (`scripts/dev/install-input-method.sh --release` cho việc gõ hằng ngày).
- Entitlements: App Sandbox, App Group, tạm thêm `temporary-exception.mach-register.global-name` cho tên kết nối IMK (theo mẫu IMK có sandbox).
  - Chưa thử bỏ đi để biết có cần không: hoãn sang M7, xét cùng lượt rà entitlement trước khi notarize.
  - **Không** `com.apple.security.network.client`.
- Khoá Info.plist đang dùng (chạy được trên macOS 27 ở M2):
  - `InputMethodConnectionName`, `InputMethodServerControllerClass`, `LSBackgroundOnly`, `TISInputSourceID`, `TISIntendedLanguage`;
  - `ComponentInputModeDict` (một mode `.vi`, icon template V), `tsInputMethodIconFileKey`, `TISIconIsTemplate`;
  - `CFBundleIconName` do actool thêm từ catalog chung;
  - `DauHostAppBundleIdentifier`, `DauAppGroupIdentifier` của riêng Dấu.

### Dau (app chủ)

#### Cửa sổ Cài đặt

- Là scene SwiftUI `Window` (không dùng scene `Settings`), cửa sổ chính của app. ⌘, mở lại cửa sổ.
- Cỡ và giới hạn cỡ theo System Settings, đặt trong `SettingsScene` (`SettingsWindow.swift`).
  - Chiều rộng tối đa giữ cột chi tiết dưới ngưỡng `Form(.grouped)` bắt đầu giới hạn thẻ và căn giữa.
  - Số đo trong `docs/research/SYSTEM-SETTINGS-REFERENCE.md`.
- Điểm vào là `main.swift`.
- Ngôn ngữ giao diện theo danh sách ngôn ngữ của macOS (D41 (Ngôn ngữ giao diện)); tham số `-AppleLanguages` vẫn chọn được ngôn ngữ khi chạy kiểm.
- Bố cục (D9 (Giao diện), sidebar cố định):
  - nội dung của scene là `SettingsSplitViewController` (`NSSplitViewController` do app tạo, bọc bằng `NSViewControllerRepresentable`);
  - mục sidebar không thu gọn được, độ dày tối thiểu bằng tối đa, đường chia không có vùng kéo chuột;
  - trạng thái chung của hai cột (`SettingsWindowState`: lịch sử, chuỗi tìm, sheet đang mở) là một đối tượng `@Observable`;
  - sidebar và trang là view SwiftUI trong hai `NSHostingController`; môi trường của scene được chuyển vào hai cột bằng `SettingsEnvironment` (kể cả `openWindow` của scene).
- Sidebar:
  - là `List` kiểu `.sidebar` với 4 mục `Label`;
  - ô tìm `NSSearchField` cỡ lớn ở đầu cột (`searchable` của sidebar chỉ có trong `NavigationSplitView`);
  - danh sách nhận tiêu điểm khi mở cửa sổ (`FocusState` đặt khi danh sách hiện; `defaultFocus` không có tác dụng trong hosting controller này);
  - Edit › Find › Find… (⌘F, từ `TextEditingCommands` trong `DauApp`) đưa tiêu điểm vào ô tìm: split view controller xử lý `performFindPanelAction` (SwiftUI không ghi menu Find gửi hành động nào; binary của nó chỉ dùng selector này);
  - ô icon vẽ theo SVG của mockup, màu hệ thống.
- Mỗi trang là `SettingsPage` = `Form(.grouped)` với `Section`, control hệ thống và thông số mặc định (D9: theo System Settings, số đo trong `docs/research/SYSTEM-SETTINGS-REFERENCE.md`).
  - Mảnh nội dung riêng của mockup (thẻ xem trước, chip, nhãn "Mới", phím, ô banner) nằm trong các section.

#### Header

- Thanh công cụ có cụm Lùi/Tiến: `ControlGroup` kiểu `.navigation` ở `ToolbarItemPlacement.navigation`.
  - Gắn quanh trang chứ không trong trang, để Lùi/Tiến bấm được qua trợ năng.
- Tiêu đề trang là `navigationTitle` của hệ thống (D9).
- Cả thanh công cụ và tiêu đề đến từ `NSHostingController` của cột trang, đưa lên cửa sổ bằng `sceneBridgingOptions`; cột sidebar không đưa gì.
- Lịch sử mục đã xem: `SectionHistory`; lệnh Lùi ⌘[ / Tiến ⌘] ở menu View (`focusedSceneValue`).
- Không có nút hay lệnh ẩn/hiện sidebar, như System Settings (D9): không dùng `SidebarCommands`; hành động `toggleSidebar` của AppKit bị tắt.
- Mục Ứng dụng có nút "+" rồi ô tìm (`.searchable(placement: .toolbar)`, thứ tự do macOS đặt), ngăn bằng `ToolbarSpacer(.flexible)`.

#### Cuộn

- Form tự cuộn và lấp cột chi tiết; không tính độ rộng bằng tay.
- Trên macOS 26+, nội dung cuộn dưới header được che bằng `scrollEdgeEffectStyle(.hard, for: .top)`.
- Thanh cuộn theo cài đặt hệ thống.
  - Kiểu When scrolling không chiếm chỗ.
  - Kiểu Always chỉ hiện ở mục cần cuộn; mục đó hẹp hơn đúng độ rộng thanh cuộn, còn vị trí mọi thứ giữ nguyên (xem `docs/UI-CHECKS.md`).

#### Control hệ thống được bọc, sheet

- `SegmentedPicker` bọc `NSSegmentedControl`, chỉ còn ở cửa sổ onboarding: `Picker(.segmented)` trên macOS 14–15 giữ độ rộng nội tại và căn giữa, không trải theo khung như mockup.
- Cửa sổ Cài đặt dùng `Picker(.segmented)` (macOS 26+: `buttonSizing(.flexible)`).
- **Sheet thêm quy tắc** (`AddAppRuleSheet`), theo sheet của System Settings (D9, số đo trong `docs/research/SYSTEM-SETTINGS-REFERENCE.md`, mục Sheet):
  - hàng đầu gồm tiêu đề bên trái và ô tìm hệ thống (`NSSearchField`) bên phải;
  - danh sách ứng dụng là `List(selection:)` cao cố định trong `GroupBox` ngoài Form (`List` lồng trong `Form(.grouped)` không cuộn được), để "Khi đang gõ" luôn trong tầm nhìn;
  - "Khi đang gõ" là thẻ của một `Form(.grouped)`;
  - nút trên `toolbar` (`cancellationAction`, `confirmationAction`; "Chọn ứng dụng khác…" là `.automatic`, nằm đầu trái thanh nút).

#### Cờ chạy của bản Debug

Bản Debug có ba nhóm cờ:

- chạy không mở cửa sổ (`--print-…`);
- chụp cần dịch vụ giả (`--capture-onboarding`, `--capture-uninstall`);
- cho lần mở app thật để đo từ ngoài (`--settings-window`, `--appearance`).

`scripts/selftest/settings-window` dùng các cờ này để kiểm giao diện (`docs/UI-CHECKS.md`).

#### Không sandbox (D37)

- Entitlement chỉ còn App Group; hardened runtime bật.
- Các ngoại lệ chỉ có nghĩa trong sandbox đã bỏ:
  - `temporary-exception.shared-preference.read-only` (`com.apple.symbolichotkeys`, `com.apple.HIToolbox`, để đọc phím tắt nguồn nhập liệu và tuỳ chọn "Tự động chuyển…");
  - `files.user-selected.read-only` (bảng chọn app).
- App vẫn chỉ **đọc** các tuỳ chọn hệ thống đó (N4 (Không tự đổi cài đặt hệ thống)).
- Bộ gõ giữ sandbox, App Group, không mạng (N2).
- Kiểm bằng `scripts/selftest/app-group.sh` (kết quả với app không sandbox: `docs/PROGRESS.md`, nhật ký 30/10/2026).

#### Onboarding

Onboarding 3 bước (`OnboardingFlow`, `OnboardingWindow`); sheet báo lỗi: M7 (xem `docs/UI.md`).

#### Cài, bật, nâng cấp, gỡ bộ gõ

`InputMethodInstaller.swift`, theo `docs/research/M5-INSTALL.md` mục 2–4.

- `SystemInputMethodInstaller` đi qua năm giao diện hẹp để test bằng đồ giả (`scripts/snapshot-settings/Tests/…/InputMethodInstallerTests.swift`):
  - `InputMethodFiles`: bundle trong app và bản ở `~/Library/Input Methods`;
  - `TextInputSources`: TIS;
  - `InputMethodProcesses`: tiến trình bộ gõ;
  - `SystemSettingsControl`: bộ đệm và tiến trình Cài đặt hệ thống;
  - `InputSourceCaches`: bộ đệm danh sách nguồn nhập liệu của từng app (bản thật `UserInputSourceCaches` nhận thư mục gốc làm tham số nên test chạy trên thư mục tạm).

**Cài** (onboarding bước 2, trước khi bật):

- chép `Contents/Library/Input Methods/DauInputMethod.app` vào thư mục tạm ẩn, không đuôi `.app`, cùng thư mục đích (`.DauInputMethod-staging-<uuid>`);
- gỡ `com.apple.quarantine`;
- kiểm chữ ký bản tạm (hợp lệ mọi kiến trúc, cùng Team ID với app chủ);
- đổi chỗ vào `DauInputMethod.app` bằng một lần `renamex_np(RENAME_SWAP)` (chưa có thì `RENAME_EXCL`);
- xoá bản cũ;
- dừng tiến trình cũ nếu đang chạy;
- `TISRegisterInputSource`;
- không bật, không chọn nguồn nào.

**Bật** (chỉ khi người dùng bấm "Bật Dấu" hoặc "Bật lại", N4; D37, `docs/research/M5-INSTALL.md` mục 9.10, mục 10.10 và 8.1b):

- Mỗi lần gọi, ngay trước `TISRegisterInputSource`, xoá bộ đệm danh sách nguồn nhập liệu:
  - xoá `com.apple.IntlDataCache.le*` trong mọi thư mục con trực tiếp của `DARWIN_USER_CACHE_DIR` (qua `InputSourceCaches.clearAll`);
  - mỗi app có sandbox giữ bộ đệm riêng ở đó, extension Bàn phím của Cài đặt hệ thống là một trong số đó;
  - file ở gốc thư mục là bộ đệm chung, tự làm mới, không đụng;
  - thư mục không liệt kê được hay file không xoá được thì bỏ qua, đếm là lỗi, ghi nhật ký; không bao giờ làm `enable()` thất bại.
- Rồi luôn `TISRegisterInputSource`: app đang chạy dựng lại bộ đệm từ đĩa ở lần đăng ký này. TIS không liệt kê Dấu sau đó → `notListed`.
- Mode `.vi` đã nằm trong mục lưu → `enabled` ngay (sau lượt kiểm bộ đệm ở dưới).
- Không thì yêu cầu Cài đặt hệ thống thoát (`terminate()`, không ép; không thoát được thì đi tiếp), rồi `TISEnableInputSource` cho mục cha (mode do macOS ghi theo).
- Sau đó **đọc lại** mục lưu theo chu kỳ tới khi có mode `.vi` (mặc định tối đa 60 s, để người dùng đọc và bấm Allow):
  - có → `enabled`;
  - hết hạn → `notEnabled` (giao diện hiện màn "Chưa bật được"; nếu sau đó macOS ghi mục, cửa sổ nhận ra và sang "đã bật").
- Mỗi lần ra `enabled` (cả đường đã bật sẵn) có đúng một lượt kiểm `InputSourceCaches.removeCaches(notMentioning:)`:
  - đọc `com.apple.IntlDataCache.le.kbdx` đọc được của từng thư mục con;
  - file nào không chứa chuỗi UTF-8 `Input Methods/DauInputMethod.app` (lấy từ đường dẫn bản đã cài) thì xoá bộ đệm của thư mục đó;
  - có ít nhất một bộ đệm như vậy thì `TISRegisterInputSource` thêm một lần;
  - đây là phỏng đoán trên định dạng không có tài liệu; lượt kiểm không ném lỗi và không đổi kết quả của `enable()`.
- Gỡ cài đặt chỉ xoá bộ đệm của Cài đặt hệ thống (`SystemSettingsControl.clearKeyboardCache`), không đụng bộ đệm của các app.
- Vòng chờ kiểm huỷ task mỗi lượt: `OnboardingFlow` giữ task của `enable()` và "Thử lại"/"Quay lại" huỷ nó (lần chạy bị thay không đụng trạng thái).
- Mã trả về của TIS không bao giờ được coi là bằng chứng.

**Không có Hoàn tác:** `TISDisableInputSource` từ app bị macOS chặn (`docs/research/M5-INSTALL.md` mục 4), nên app không tự tắt được Dấu; chỉ người dùng bỏ Dấu trong System Settings.

**Trạng thái "đã bật"** (`status()`, banner qua `InputSourceStatus.query`, onboarding):

- là mode `.vi` nằm trong `com.apple.inputsources` › `AppleEnabledThirdPartyInputSources` (D37);
- không theo cờ enabled của TIS: cờ này báo true ngay sau khi đăng ký.

**Kiểm bộ gõ đã cài** (D37):

- mỗi lần mở app và mỗi lần app được đưa lên trước, `InputMethodActions.checkInstalled` hỏi `installedIsGenuine` (`CodeSignature.isValidAndSameTeam`: chữ ký hợp lệ và cùng Team ID với app chủ);
- không khớp thì `TamperedBanner` hiện banner "Cài lại", bấm thì cài lại bản nhúng trong app (chữ ký bản mới cũng được kiểm trước khi đổi chỗ).

**Nâng cấp** (D7, lúc app mở):

- bản cài cùng bundle ID và `CFBundleVersion` của bản trong app lớn hơn (so số) → chép tạm + đổi chỗ như trên, dừng tiến trình cũ, đăng ký lại;
- không đụng trạng thái bật/chọn;
- khác bundle ID thì bỏ qua (D37: định danh không đổi);
- chưa cài thì không làm gì (lần cài đầu do người dùng bấm);
- chưa chờ "lúc không gõ" (D7): app vừa được mở nên người dùng không gõ ở app khác; bộ gõ vẫn chốt từ trước khi thoát;
- Sparkle (M7) sẽ gọi đúng hàm này.

**Dừng bộ gõ:**

- app chủ phát thông báo Darwin `<bundle ID bộ gõ>.quitRequested` (`InputMethodLifecycle` trong DauShared);
- bộ gõ (`main.swift`) báo cho mọi controller chốt từ đang gõ (gạch chân: chốt marked text) rồi `exit(0)`; macOS chạy lại bundle trên đĩa ở phím kế tiếp;
- quá 2 s mà còn chạy (bộ gõ bản cũ chưa nghe thông báo) thì `forceTerminate` đúng tiến trình bộ gõ của Dấu (`NSRunningApplication` theo bundle ID);
- không dừng tiến trình hệ thống nào (`imklaunchagent`, `TextInputMenuAgent`…);
- ai cũng phát được thông báo Darwin này, nên tiến trình khác có thể làm bộ gõ thoát; chấp nhận vì macOS chạy lại ngay ở phím sau, thông báo không mang dữ liệu.

**Gỡ** (D16, "Gỡ cài đặt…"): ba bước của `SystemInputMethodInstaller` do `InputMethodActions.performUninstall` điều phối.

1. `prepareUninstall`:
   - mở thẳng danh sách Input Sources (`SystemSettings.openInputSources`, URL `…Keyboard-Settings.extension?InputSources`): đo trên macOS 27.2, mở sẵn sheet Edit…; các nút khác vẫn mở trang Keyboard thường;
   - không chọn bàn phím nào, không tắt gì (nút "–" dùng được cả khi Dấu đang được chọn, macOS tự chọn bàn phím khi Dấu biến mất, đo trên macOS 27.2);
   - sheet đọc lại `InputMethodStatus.selected` khi hiện, khi cửa sổ sheet thành key lại và khi nguồn đang chọn đổi (thông báo TIS), để hiện hoặc ẩn câu nhắc "–" có thể mờ.
2. `waitUntilRemovedFromInputSources`: thăm dò mục lưu của Dấu (`storedEnabledIDs`) tới khi rỗng, huỷ được; trong lúc đó `UninstallRemoveSheet` hiện trên cửa sổ Cài đặt.
3. `finishUninstall`:
   - chỉ chạy khi mục lưu rỗng (không thì `stillListed`, không đụng gì);
   - dừng bộ gõ;
   - chuyển `~/Library/Input Methods/DauInputMethod.app` vào Thùng rác;
   - nếu tick ô thì xoá suite App Group (`removePersistentDomain`) và phát thông báo đổi cài đặt;
   - đọc lại để báo kết quả.

Quy tắc kèm theo khi gỡ:

- Huỷ hoặc lỗi không xoá gì và không đổi nguồn nhập liệu nào (Dấu không chuyển gì trước đó).
- Không đụng container riêng của bộ gõ (`~/Library/Containers/com.codefastlabs.dau.inputmethod.Dau`): app khác đụng container có thể làm macOS hỏi quyền.
- App không tự xoá chính nó, chỉ hướng dẫn rồi thoát.

#### Tên bàn phím hiện cho người dùng (`LayoutNames`)

- Đúng như thanh menu của macOS ("U.S." trên máy tiếng Anh), không phải tên TIS trả cho tiến trình của app.
- Lý do: `kTISPropertyLocalizedName` theo ngôn ngữ của tiến trình, có thể khác ngôn ngữ hệ thống (ngôn ngữ riêng của app hoặc tham số `-AppleLanguages`, D41), khi đó máy tiếng Anh vẫn ra "Mỹ".
- `LayoutNames` làm như sau:
  - đọc ngôn ngữ ưu tiên thật của hệ thống (`AppleLanguages` ở miền toàn cục);
  - tra bảng `InfoPlist.loctable` của `AppleKeyboardLayouts.bundle` (ngôn ngữ → tên → tên đã dịch, khoá là ID nguồn bỏ tiền tố `com.apple.keylayout.`);
  - thử ngôn ngữ cụ thể trước rồi bỏ dần phần vùng, rồi sang ngôn ngữ ưu tiên kế;
  - không khớp thì dùng tên TIS.
- Dùng ở `englishLayoutName` (dòng phím tắt) và `InputSourceEntry.name` của bàn phím (sheet gỡ "Đã chuyển sang …", alert gỡ xong).
- Chỉ đọc (N4); bảng đọc một lần, danh sách ngôn ngữ đọc mỗi lần gọi.

#### Tên giao diện của macOS trong chữ của Dấu (`SystemUINames`, D38 (Chữ trên giao diện))

- Các tên hiện đúng như macOS của người dùng:
  - System Settings, General, Login Items & Extensions, Keyboard, Input Sources, Edit…, Add, Done, Allow, Don’t Allow, Log Out, Applications;
  - tên tuỳ chọn "Automatically switch to a document’s input source", tên ngôn ngữ "Vietnamese", hộp thoại "Allow … to enable …?";
  - tên nguồn của chính Dấu ("Dấu – Vietnamese"/"Dấu – Tiếng Việt", D41; `dauInputSource`): đọc `InfoPlist.strings` của bộ gõ đã cài, chưa cài thì bản trong app, khoá là ID input mode.
- Ngôn ngữ lấy như `LayoutNames` (`AppleLanguages` toàn cục, không phải ngôn ngữ của tiến trình app).
- Chữ lấy từ bảng của chính hệ thống:
  - đường dẫn trong `SystemUINames.tableURLs`: `.loctable` của System Settings, `KeyboardSettings.appex`, `GeneralSettings.appex`, `loginwindow.app`, và `SystemFolderLocalizations` cho "Applications"; tên ngôn ngữ từ `Locale`;
  - tìm khoá bằng cách khớp giá trị tiếng Anh;
  - ngôn ngữ đầu là tiếng Anh thì dùng tiếng Anh; không khớp ở mọi ngôn ngữ ưu tiên thì tiếng Anh.
- Câu chữ của Dấu dùng `%@` cho các tên này.
- Khái niệm chung dùng thuật ngữ Apple của từng ngôn ngữ ("input source", "nguồn đầu vào"; bảng `docs/GLOSSARY.md`).
- Bộ gõ không dùng hai file này: menu nhập liệu không có tên giao diện nào của macOS.

#### Chuỗi giao diện (D41)

- Mỗi target có `Localizable.xcstrings` và `InfoPlist.xcstrings`.
- Ngôn ngữ gốc tiếng Anh, khoá là câu tiếng Anh viết thẳng trong mã (`Text("…")`, `String(localized:)`), tiếng Việt là bản dịch.
- `scripts/check-l10n/check.sh` kiểm mọi khoá có đủ `en` và `vi` đã dịch, cùng các `%@`/`%lld`.
- Ô tìm của sidebar so với chữ đang hiện (`SettingsSection.matches`), nên tìm được bằng ngôn ngữ đang dùng.

#### Danh sách tương thích, bộ gõ cũ

- Danh sách tương thích có sẵn trong app (`Resources/CompatibilityList.json`, xem DauShared); M7: Sparkle 2 + tải danh sách có chữ ký (D7).
- Phát hiện bộ gõ cũ (D14 (Onboarding)):
  - bộ gõ chặn phím đang chạy trong phiên người dùng (`NSWorkspace.shared.runningApplications`, so bundle ID trong `KnownInputMethods`) là xung đột, hiện bước 1;
  - nguồn tiếng Việt kiểu IMK khác đang bật (Telex/VNI của Apple, XKeyIM; đọc TIS, ngôn ngữ `vi`, khác Dấu) chỉ được nhắc nhẹ ở bước 2.

## Build

- Debug lệnh trơn chỉ build arm64 (Xcode build package local theo kiến trúc máy).
  - Debug universal dùng `-destination 'generic/platform=macOS'`; Release luôn universal.
  - CI phải dùng destination này.
- ID input mode viết cứng ở ba nơi: `Apps/DauInputMethod/Info.plist`, `Apps/DauInputMethod/Resources/InfoPlist.xcstrings` (Xcode không thay biến trong khoá plist) và `SystemUINames.location` (tên nguồn của Dấu).
  - Đổi Bundle ID phải sửa cả ba (D37: không đổi giữa các bản).
- Mã commit của bản build: `scripts/build/stamp-build-commit.sh` ghi `build/generated/BuildCommit.txt`.
  - Thêm "+" khi còn thay đổi chưa commit.
  - Chạy lúc `xcodegen generate` (preGenCommand) và ở mỗi lần build bộ gõ.
  - Cả Dấu.app và bộ gõ chép file này vào Resources nên bản build được ký lại khi mã đổi.
  - App hiện "Dấu x.y.z (mã)" ở đáy sidebar và thẻ đầu Cập nhật & hỗ trợ.
  - `scripts/dev/dau-version.sh` so mã của bộ gõ đã cài, Dấu.app và repo, và cho biết tiến trình bộ gõ đang chạy có phải bản đã cài không.

## Luồng một phím (chế độ Tiếng Việt)

1. IMK gọi `handle(event, client)` trên main thread. Bỏ qua event nil/bất thường (D18).
2. Phím điều khiển (mũi tên, ⌘-tổ hợp, Esc…) → reset engine, trả `false` cho hệ thống xử lý. Không khôi phục từ ở bước này (D4).
   - Backspace → engine bỏ chữ cuối đang hiển thị và đặt lại dấu (D32).
   - Thay tại chỗ luôn trả `false` để ứng dụng tự xoá chữ cuối (khi dấu phải dời, bộ gõ thay phần trước nó trong cùng phím, xem mục DauInputMethod).
3. Ký tự → `engine.handle(scalar)`:
   - `passThrough` → trả `false`.
   - `replace(n, s)` → `client.insertText(s, replacementRange: vùng n ký tự trước con trỏ)`, trả `true`.
   - Engine rỗng, phím dấu/biến đổi hoặc chữ cái, chưa biết chữ trước con trỏ → D20: đọc từ trước con trỏ, `seed`, rồi như trên; phím chỉ nối theo D20 và ba ngoại lệ của nó (xem mục DauInputMethod).
4. Ký tự kết thúc từ (Space, dấu câu, Enter, Tab — D4) → nếu từ không phải âm tiết tiếng Việt hợp lệ thì khôi phục phím gốc (D4), commit, reset.

Ở chế độ gạch chân (D13), bước 3–4 khác:

- chữ của từ đi vào marked text (`setMarkedText`) thay cho thay chữ tại chỗ, không hỏi `selectedRange`;
- kết thúc từ và mọi sự kiện reset chốt marked text bằng một `insertText` (xem mục DauInputMethod).

## Đo lường

- `os_signpost` quanh `engine.handle` và quanh lệnh gọi client; xem bằng Instruments.
- Nhật ký từng phím (category `perf`, `diag`) và signpost chỉ có ở bản Debug, bị loại khỏi bản Release lúc build (D8 (Không telemetry)).
  - Ở bản Debug chỉ ghi khi khoá `DauPerfLog` được đặt trong global domain: dù không có chữ, giờ và app của từng phím là siêu dữ liệu về cách gõ (D8).
  - `scripts/selftest/typing/run.sh` tự bật lúc chạy và khi xong trả khoá về đúng như cũ (xoá nếu trước đó không có).
  - Đo tay thì bật, đo, rồi xoá (`scripts/perf/perf-report.sh`).
  - Mỗi dòng phím có `t_ns` (lúc `handle` bắt đầu, đồng hồ `CLOCK_UPTIME_RAW`) và `ev_ns` (thời điểm của chính sự kiện phím); `perf-report.sh` dựng từ đó khoảng cách giữa các phím và độ trễ từ lúc tạo phím tới bộ gõ, cho bài test tải nặng (`scripts/selftest/load/run.sh`).
- Test hiệu năng engine trong CI. Bài test tải nặng: xem mốc M6 (Hiệu năng dưới tải) trong `ROADMAP.md`.
