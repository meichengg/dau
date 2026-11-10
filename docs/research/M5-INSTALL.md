# M5 — Cài, bật, nâng cấp, gỡ bộ gõ; phát hiện bộ gõ cũ (nghiên cứu hợp nhất)

Hợp nhất ngày 03/11/2026 từ ba nghiên cứu phục vụ M5 (Onboarding, cài đặt, gỡ cài đặt):
- nghiên cứu cài, nâng cấp, gỡ (30/10);
- nghiên cứu lần cài đầu có tránh được đăng xuất không (02/11);
- nghiên cứu đăng ký, bật, gỡ trên macOS 26–27, chỉ ghi điều có nguồn (03/11).

Mỗi sự kiện chỉ ghi ở một chỗ. Mục 0 là bản tóm tắt kết luận hiện hành, chi tiết nằm ở các mục sau. Quan sát bằng Dấu thật nằm ở mục 9, câu hỏi còn mở ở mục 10. Mã nguồn dẫn tới mục này theo số mục (mục 1 đến 5).

Máy đọc: macOS 27.2 (build 26B123), Xcode 27.2 (SDK `MacOSX27.2.sdk`).
Mọi việc đọc hệ thống ở đây **chỉ đọc** (`strings`, `nm`, `otool`, `dyld_info`, `codesign -d`, `defaults read`, `/usr/bin/log show`, `ps`, `launchctl print`, `ls`, `gh`, `curl`).
Các phép đo chủ động (Dấu thật, bản thử) mang nhãn riêng.

## Nhãn nguồn

Mỗi khẳng định mang một nhãn. Chỗ không có nguồn ghi đúng "không tìm thấy nguồn", không điền bằng suy luận.

| Nhãn | Nghĩa |
|---|---|
| **[Apple]** | tài liệu, header SDK, ghi chú phát hành hoặc bài diễn đàn của Apple (kể cả DTS) |
| **[Ngoài]** | dự án hoặc diễn đàn khác: báo cáo, PR, README, hoặc mã nguồn của dự án đó (ghi "mã" nếu là mã) |
| **[Máy/hệ thống]** | đọc file hệ thống hoặc nhật ký trên máy này; ghi lệnh hoặc ngày |
| **[Máy/Dấu]** | đo bằng Dấu thật (nhật ký của `docs/PROGRESS.md` và `docs/history/LOG-M0-M4.md`, dẫn theo ngày) |
| **[Máy/bản thử]** | đo bằng bản thử, **không phải Dấu**; chỉ nằm ở mục 8, không rút kết luận |
| **[Diễn giải mã máy]** | người nghiên cứu đọc mã máy hoặc mã nguồn dự án khác và tự diễn giải; không có tài liệu Apple xác nhận |
| **[Suy luận, cần kiểm chứng]** | chưa ai đo |

Bản sao mã nguồn tham khảo (ngoài repo, không chép mã nào vào Dấu), hai đợt đọc:
- 30/10: Squirrel 46962d2, McBopomofo 18e2060, vChewing 7c82f5f, macSKK 539cce3, fcitx5-macos 3466612, Gureum 46c62e5, XKey 398e78e, goxkey b197c57, OpenKey 89c2fd3.
- 02/11 (`/tmp/dau-research/`): Squirrel d220b92, McBopomofo 257da53, vChewing-macOS 8c1bb72, macSKK c812585, Gureum 46c62e5, fcitx5-macos 3466612, XKey 398e78e.

## 0. Hiện trạng (05/11/2026, macOS 27.2)

Kết luận hiện hành, mỗi dòng có ngày và mục chứa bằng chứng.
Apple không có tài liệu công khai cho các hành vi này, nên mọi dòng có thể đổi theo từng bản macOS (mục 2.1).

**Lần cài đầu và danh sách "+"**
1. Bật lần đầu **không cần đăng xuất** để "+" thấy Dấu, nếu làm theo luồng D37 (Cài đặt bộ gõ): xoá bộ đệm `IntlDataCache.le*` của System Settings sau khi đăng ký, rồi bật; hộp thoại xin phép hiện, bấm "Allow".
   - Đo 04/11/2026 bằng bản thử (mục 8.1b), rồi bằng Dấu thật trên tài khoản đã từng cài Dấu (mục 9.9).
   - Chưa đo: macOS 14–26, bản ký Developer ID, tài khoản macOS mới (kế hoạch ở mục 7 đã bỏ, người dùng chốt 04/11/2026). Mục 2.3, 10.1.
2. Apple DTS (06/2026, FB23026482) nói không có cách tránh đăng xuất; lời này phù hợp với việc bộ đệm chỉ được dựng lại khi đăng nhập [Suy luận, cần kiểm chứng]. Mục 2.3.
3. Các dự án khác: Squirrel, macSKK, Gureum, fcitx5-macos, XKey, AquaSKK báo phải đăng xuất; msime (macOS 27.0) đo thấy phải đăng xuất; marinaMoji (máy ảo sạch macOS 27.0.1) báo nguồn hiện ngay trong "+". [Ngoài] Mục 2.3, 2.4.
4. Lần thử cài đầu của người dùng bằng Dấu thật (02/11) chạy trên máy không sạch (hai mục Dấu còn từ 30/10), nên không chứng minh gì về `TISEnableInputSource`. [Máy/Dấu] Mục 9.4, 9.5.

**Bật nguồn**
5. `TISEnableInputSource` với nguồn không thuộc hệ thống không bật trực tiếp: nó gửi Apple event tới System Settings rồi trả 0. [Diễn giải mã máy] Mục 2.2.
6. Hộp thoại `Allow “Dấu” to enable “Dấu”?` hiện trên máy này (27.2) khi làm theo D37, từ 04/11/2026. Tên thứ hai là tên của mục cha, không phải "Dấu – Tiếng Việt". [Máy/Dấu] Mục 9.9, 9.11; hình dạng hộp thoại ở mục 8.1b.
   - Trong các lần thử bằng bản thử, yêu cầu bật bị bỏ qua im lặng khi trang Keyboard của System Settings đang mở sẵn, hoặc khi System Settings không dựng lại được nguồn (nhật ký "Invalid value on inputSourceToBeEnabled"). [Máy/bản thử] Mục 2.2, 8.1b.
   - Hộp thoại có hiện trên bản macOS khác và với bản ký Developer ID đã notarize hay không: chưa biết. Mục 10.3.
7. Nút "Bật Dấu" không được hứa là bật được; luôn đọc lại trạng thái sau khi bật và giữ đường lui "mở Cài đặt › Bàn phím, bấm '+'" (N4 (Không tự đổi cài đặt hệ thống), N5 (Chỉ hứa điều đã kiểm chứng)). Mục 6.1.
8. Trạng thái "đã bật" của nguồn bên thứ ba nằm ở `com.apple.inputsources` › `AppleEnabledThirdPartyInputSources`, không ở `com.apple.HIToolbox`; cờ `kTISPropertyInputSourceIsEnabled` không đáng tin. [Máy/hệ thống, 02/11/2026] Mục 2.6.

**Bộ đệm riêng của app có sandbox**
9. Mỗi app có sandbox giữ một bộ đệm danh sách nguồn riêng và dùng nó mà không kiểm tra lại. Bộ đệm lệch (không có `DauInputMethod.app`) làm app đó không dùng được Dấu dù Dấu đã bật (Telegram, 04/11/2026). [Máy/Dấu] Mục 9.10, 10.10.
10. Xoá bộ đệm của các app ngay trước khi đăng ký sửa được ca này mà không cần mở lại app (04/11/2026), và đăng xuất rồi đăng nhập cũng làm mỗi app dựng lại bộ đệm ở lần đọc đầu (05/11/2026). [Máy/Dấu] Mục 9.11, 9.12; đo bằng bản thử ở mục 8.1b.

**Gỡ**
11. App không tự tắt được Dấu: `TISDisableInputSource` trả 0 nhưng System Policy chặn ghi `com.apple.inputsources` (02/11/2026, mục 9.7). Chỉ nút "–" trong System Settings gỡ được. Không có cách chính đáng và ổn định để app tự bỏ mục (04/11/2026, chỉ đọc).
    - Ghi `com.apple.inputsources` bị chính sách nền tảng của macOS chặn với mọi tiến trình thiếu entitlement riêng của Apple; trên máy này chỉ `KeyboardSettings` có entitlement đó, và bên thứ ba không xin được entitlement `com.apple.private.*` (Apple DTS). Đọc thì tiến trình nào cũng đọc được.
    - Arion (macOS 26.6.2) và msime (macOS 27) đo thấy như Dấu và chuyển sang bắt người dùng bấm "–" trước khi xoá bundle.
    - [Máy/Dấu, Apple, Ngoài, Máy/hệ thống] Mục 4, 4.1.
12. Đường gỡ chính là hướng dẫn người dùng bấm "–", bundle còn nguyên cho tới khi mục cha biến mất. Nếu bundle đã bị xoá trước thì mục thành ẩn; cài lại đúng bundle ID rồi bấm "–" dọn được (bản thử, 04/11/2026). [Máy/bản thử] Mục 4.1, 8.1b.
13. Khi Dấu đang được chọn, nút "–" vẫn bấm được và macOS tự chuyển sang U.S. (đo 04/11/2026 14:58 bằng Dấu thật). App vẫn chuyển bàn phím trước cho chắc. Mục 4, bước 1.

**Cài app, nâng cấp, bộ gõ cũ**
14. App chủ có sandbox không dùng được: file app tạo ra luôn bị quarantine và app không gỡ được, không dừng được app khác (Apple DTS, 2022 và 2026). D37 chọn app chủ không sandbox. [Apple] Mục 1.2, 1.3.
15. Trình tự nâng cấp (chép tạm rồi đổi chỗ cả khối, dừng bộ gõ cũ bằng thông báo, không đụng `imklaunchagent` và bộ đệm hệ thống) và danh sách định danh không được đổi giữa các bản: mục 3.
16. Danh sách bộ gõ tiếng Việt cũ cần phát hiện (bundle ID đọc 30/10/2026): mục 5.

**Công cụ thử**
17. Công cụ thử của mục 8 (`scripts/probe/`: dựng biến thể `DauProbe*`, `tis-probe`, `tis-act`, `step.sh`, `cleanup.sh`, `settings-ax.swift`) đã xoá khỏi repo ngày 09/11/2026 vì vòng thử đã xong; lấy lại bằng `git show 7877c92:scripts/probe/<file>`.

**Còn mở** (mục 10): đăng xuất ở các bản macOS khác; vì sao System Settings không dựng lại được nguồn; luật `.inputmethod.` trong bundle ID; bộ gõ notarize mang quarantine; bộ đệm riêng của app sau khởi động lại máy hoặc trong thư mục được bảo vệ.

## 1. App chủ có sandbox có chép được bộ gõ vào `~/Library/Input Methods` không?

### 1.1 Entitlement
- `com.apple.security.temporary-exception.files.home-relative-path.read-write`: giá trị là mảng đường dẫn tính từ `~`, bắt đầu bằng `/`, và **kết thúc bằng `/` nếu là thư mục**. Với Dấu sẽ là `/Library/Input Methods/`.
  - Apple gọi đây là ngoại lệ "tạm" và khuyên gửi báo lỗi; hướng dẫn kê khai trong App Store Connect chỉ áp dụng cho App Store. [Apple, Entitlement Key Reference, mục App Sandbox Temporary Exception Entitlements]
- **Notarize: được.**
  - Apple viết: "Notarization of macOS software is not App Review. The Apple notary service is an automated system…". Yêu cầu chỉ gồm ký Developer ID, Hardened Runtime, secure timestamp, không có `get-task-allow`. [Apple, trang "Notarizing macOS software before distribution"]
  - Dịch vụ notarize không xét entitlement sandbox: đây là suy luận từ danh sách yêu cầu đó, chưa thấy câu nào của Apple nói thẳng. [Suy luận, cần kiểm chứng ở M7 (Phát hành)]

### 1.2 Vướng mắc thật sự: quarantine và dừng tiến trình
- **Sandbox luôn gắn quarantine lên file app tạo ra.**
  - Một lệnh `move` cũng tính là tạo file mới. App trong sandbox **không** gỡ được nhãn này (Quinn, Apple DTS, 1/2026).
  - Một tiến trình sandbox "không thể tạo file thực thi không bị quarantine" (Quinn, 3/2022). [Apple, Developer Forums 811450, 701687]
  - Hệ quả: bản bộ gõ được chép sẽ mang quarantine. Lần đầu hệ thống chạy nó, Gatekeeper sẽ kiểm tra, và bộ gõ có thể bị **App Translocation** (chạy từ một đường dẫn ngẫu nhiên, chỉ đọc).
  - Bằng chứng gián tiếp: trình cài McBopomofo có mã riêng để chờ hết translocation của bộ gõ cũ (`BundleTranslocate.m`), còn vChewing gỡ quarantine bằng `xattr -drs com.apple.quarantine` sau khi chép. [Ngoài, mã hai dự án]
  - Bộ gõ đã notarize thì có chạy được không, có hiện hộp thoại "tải từ Internet" cho một tiến trình nền không, có bị translocate không: [Suy luận, cần kiểm chứng]. Chỉ thử được với bản ký Developer ID đã notarize (M7). Bản Personal Team chưa notarize nên khi bị quarantine nhiều khả năng bị chặn hẳn.
- **App sandbox không dừng được app khác.**
  - Tài liệu `NSRunningApplication.terminate()` và `forceTerminate()` ghi rõ: "Sandboxed applications can't use this method to terminate other applications". [Apple]
  - `kill()` sang tiến trình khác cũng bị sandbox chặn: [Suy luận, cần kiểm chứng].
  - D7 (Cập nhật và loại bản dựng) cần dừng tiến trình bộ gõ cũ sau khi cập nhật.
- `TISRegisterInputSource`/`TISEnableInputSource` gọi từ **app chủ** có sandbox: chưa ai đo.
  - Với **bộ gõ** có sandbox (30/10/2026), `TISSelectInputSource` đổi được nguồn nhưng bước báo cho app đang gõ bị chặn (`deny mach-lookup com.apple.tsm.portname`). [Máy/Dấu] Mục 9.2.

### 1.3 Các phương án

| Phương án | Được | Vướng |
|---|---|---|
| App chủ sandbox + temporary exception `/Library/Input Methods/` | Giữ sandbox | Bản chép mang quarantine, không gỡ được; không dừng được tiến trình cũ; chỉ kiểm được ở M7 |
| Người dùng tự chọn thư mục bằng `NSOpenPanel` (powerbox) + bookmark | Không cần ngoại lệ | `~/Library` bị ẩn, người dùng phải tìm đúng thư mục; file tạo ra vẫn bị quarantine (Quinn: `user-selected.executable` chỉ có tác dụng với vị trí chọn qua bảng *lưu*); vẫn không dừng được tiến trình |
| App chủ sandbox + XPC service không sandbox lo việc cài | Giữ sandbox cho phần có mạng | Thêm một tiến trình, giao thức XPC, ký riêng. Sparkle làm đúng kiểu này để "cài bản cập nhật bên ngoài sandbox của app" |
| App chủ **không** sandbox (bộ gõ vẫn sandbox, không mạng) | Đơn giản nhất: chép, kiểm chữ ký, gỡ quarantine, dừng tiến trình, gỡ cài đặt (kể cả tự chuyển app vào Thùng rác) đều làm trực tiếp; Sparkle không cần cấu hình XPC | Mất lớp sandbox ở app có kết nối mạng (Sparkle, danh sách tương thích) |
| Gói `.pkg` | Squirrel, macSKK, Gureum, fcitx5 dùng cách này (cài vào `/Library/Input Methods`, cần mật khẩu quản trị; Squirrel đặt `RequireLogout`) | Trái D6 (Phát hành) (DMG) và D16 (Bảo trì và gỡ cài đặt) (`~/Library/Input Methods`); Sparkle cài `.pkg` phải xin quyền quản trị |
| Cask `input_method` | Homebrew chuyển bundle vào `~/Library/Input Methods` | Bộ gõ nằm trong `Dấu.app`; rút nó ra làm hỏng chữ ký của app chủ [Suy luận]; trùng việc với app chủ và Sparkle (`auto_updates true`) |

Các bộ gõ khác: XKey (tiếng Việt) có app chủ **không sandbox** tự chép `XKeyIM.app` vào `~/Library/Input Methods`; khi chép lỗi, XKey chuyển sang hướng dẫn kéo-thả tay. Trình cài của McBopomofo và vChewing cũng không sandbox. **Không thấy dự án nào dùng phương án app chủ sandbox kèm ngoại lệ thư mục.** [Ngoài, entitlements và mã nguồn]

**Quyết định:**
- D37 chọn phương án app chủ không sandbox (Hardened Runtime, ký Developer ID, notarize).
- Bộ gõ giữ sandbox, App Group, không mạng (N2 (Bộ gõ không có quyền mạng)).
- `scripts/selftest/app-group.sh` đạt với app chủ không sandbox (30/10/2026). [Máy/Dấu] Mục 9.3.
- Phương án dự phòng nếu sau này muốn app chủ sandbox: XPC service không sandbox, không phải ngoại lệ thư mục.

### 1.4 Homebrew
- `input_method`: "Relative path to an Input Method that should be moved into the `~/Library/Input Methods` folder on installation".
  - `uninstall quit:` gửi Apple Event thoát. `signal:` chỉ dùng khi `quit` không có tác dụng. `zap` chỉ chạy khi gõ `--zap`. [Ngoài, Homebrew Cask Cookbook]
- Cask đề xuất (tên cask chọn sau, D24 (Tên và định danh)): chỉ `app "Dấu.app"` và `auto_updates true`.
  - `uninstall` gọi lệnh gỡ của chính app (ví dụ cờ `--uninstall-input-method`: tắt nguồn, dừng bộ gõ) rồi `trash "~/Library/Input Methods/DauInputMethod.app"`.
  - `zap` xoá Group Container `M58DANM3ZP.com.codefastlabs.dau.shared` (sẽ đổi theo Team ID của bản phát hành), các container, và các tuỳ chọn.
  - Không dùng stanza `input_method`.

## 2. `TISRegisterInputSource` / `TISEnableInputSource` / `TISSelectInputSource`

### 2.1 Tài liệu Apple và header
Apple không có trang tài liệu web cho họ hàm TIS (các URL đoán `documentation/carbon/tisenableinputsource(_:)`, `…/tisregisterinputsource(_:)`, `…/text_input_sources` trả 404 ngày 03/11/2026). Nguồn chính thức duy nhất là header.

`…/HIToolbox.framework/Headers/TextInputSources.h` trong SDK Xcode 27 (file nén, đọc bằng `grep -a`; header ký 2006–2008, file ngày 22/02/2026) [Apple]:
- `TISRegisterInputSource` chỉ đăng ký được bundle nằm trong `/Library/Input Methods/` hoặc `~/Library/Input Methods/`, nghĩa là **phải chép vào đó trước**.
  - Header ghi code gọi hàm này "is part of an application or service that has already been validated in some way (e.g. by the user)".
  - Đăng ký "so that a TISInputSourceRef can immediately be obtained for each of the new input source(s)"; hệ thống "perform any necessary cache rebuilds so that the installer can immediately call `TISCreateInputSourceList`".
  - Không nhắc đăng xuất và không bảo đảm giao diện hiện nguồn.
- `TISEnableInputSource` "is mainly intended for input methods, or for applications that supply their own input sources".
  - Nguồn phải `IsEnableCapable`; muốn bật input mode thì **input method cha phải được bật trước**; trả `paramErr` nếu không bật được, "else noErr". **Không nhắc hộp thoại xin phép.**
- `TISSelectInputSource` cần nguồn đã bật và chọn được (select-capable); với mode thì cha cũng phải đang bật.
- `TISDisableInputSource` gỡ nguồn khỏi giao diện hệ thống.
- Danh sách ASCII-capable là "a snapshot ... at the time the call was made"; thay đổi bật/tắt phát thông báo phân tán `kTISNotifyEnabledKeyboardInputSourcesChanged`. Đây là ảnh chụp theo từng lần gọi của một tiến trình.
- `grep -a -n "WithOptions\|FromSystem"` trên header: không có dòng nào. Nhưng `HIToolbox.tbd` của cùng SDK xuất ký hiệu `_TISEnableInputSourceWithOptions`: hàm có tuỳ chọn tồn tại, không được tài liệu hoá trong header.
- Header **không có** API làm mới giao diện hay báo hệ thống quét lại thư mục.

Các nguồn Apple khác đã tra:
- **Ghi chú phát hành macOS:** tải `https://developer.apple.com/documentation/macos-release-notes/<tên>.md` hoặc bản `.json` dưới `https://developer.apple.com/tutorials/data/documentation/macos-release-notes/`, rồi `grep -i "input method\|input source\|InputMethodKit\|TISEnable"`.
  - macOS 26, 26.1 đến 26.6, 27, 27.2 đều **0 dòng khớp** (03/11/2026).
  - macOS 27.1: trang trả khung HTML, chưa đọc được. Ghi chú bản beta riêng: không tìm thấy nguồn.
- **Trang `InputMethodKit`** (`https://developer.apple.com/tutorials/data/documentation/inputmethodkit.json`, 03/11/2026): chỉ có tóm tắt "Develop input methods and manage communication with client applications" cùng các lớp `IMKServer`, `IMKInputController`…; không có bài về cài đặt, bật, gỡ.
- **QA1810:** bundle chép vào `~/Library/Input Methods` không hiện trong Nguồn nhập liệu nếu là kiểu palette (từ Mavericks). Dấu là bộ gõ bàn phím nên không thuộc trường hợp này; ghi để loại trừ. [Apple, chưa đọc toàn văn; tóm tắt qua tìm kiếm]
- **Hướng dẫn người dùng macOS 26** "Add or remove input sources" (`support.apple.com/en-kz/guide/mac-help/mchl84525d76/26/mac/26`): chỉ thấy qua tóm tắt tìm kiếm, nói không nhắc hộp thoại xin phép; chưa đọc toàn văn.
- **WWDC 2025/2026:** một lượt tìm, không có phiên nào về cài hay bật bộ gõ bên thứ ba. Không tìm thấy nguồn.
- **Diễn đàn:** thread 775526 (mục 2.3). Bài diễn đàn Apple về hộp thoại "Allow … to enable …", về luật `.inputmethod.`, về nguồn hiện trong "+" không cần đăng xuất: không tìm thấy nguồn (ba lượt tìm web 03/11; công cụ tìm không lập chỉ mục sâu diễn đàn, nên là "không thấy", không phải "không có").

### 2.2 Hộp thoại xác nhận

**Chuỗi giao diện** [Máy/hệ thống, 27.2, 03/11]:
- Đối tượng là `/System/Library/ExtensionKit/Extensions/KeyboardSettings.appex` (CFBundleIdentifier `com.apple.Keyboard-Settings.extension`, CFBundleVersion 148.1.5, điểm mở rộng `com.apple.Settings.extension.ui`, `allowsXAppleSystemPreferencesURLScheme = true`).
- Lệnh: `plutil -convert json -o - …/Contents/Resources/Localizable.loctable` rồi lọc, và `strings -a …/Contents/MacOS/KeyboardSettings`.
- Khoá `en`: `Allow “%@” to enable “%@”?` → `Allow “%1$@” to enable “%2$@”?` (tiếng Việt: "Cho phép “%1$@” bật “%2$@”?").
  - Hai nút "Cho phép"/"Không cho phép".
  - Câu "The developer of the input source will be able to access anything you type with this input source…" (tiếng Việt: "Nhà phát triển của nguồn đầu vào sẽ có thể truy cập mọi thứ bạn nhập với nguồn đầu vào này…").
- Chú thích của Apple kèm chuỗi " to enable ": "The first parameter is an app or program name. The second parameter is an input method name." Nhãn "Installed Input Source" có chú thích "Headline for warning texts about third-party input methods."
- Ký hiệu: `handleOpenParameter(aeDesc:)`, `inputSourceToBeEnabled`, `localizedSenderName`, `_showingThirdPartyPrompt`, `_thirdPartyPromptTitle`, `thirdPartyInputSource`; nhập khẩu `_TISEnableInputSourceWithOptions` và `__CreateUnflattenedInputSource` (`dyld_info -imports`).
- Entitlement (`codesign -d --entitlements - …`): `com.apple.private.security.storage.inputsources`, `com.apple.security.app-sandbox`, sbpl `(allow user-preference* (preference-domain-regex #"^.*"))`, và `shared-preference.read-write` gồm `com.apple.inputsources`, `com.apple.HIToolbox`. Phù hợp với việc chỉ Cài đặt ghi được miền `com.apple.inputsources` (mục 2.6). [Diễn giải mã máy]

**Phía gọi** [Diễn giải mã máy].
- Lệnh: `dyld_info -arch arm64e -disassemble …/HIToolbox.framework/Versions/A/HIToolbox`; chuỗi: `strings -a -t x` trên `/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e.03`.
- Chuỗi trong thư viện: `TSMEnableInputSource %@ `, `/System/Applications/System Settings.app`, `tabID`, `inputSourceToBeEnabled`, `localizedSenderName`, `com.apple.IntlKeyboard`.
- `TISEnableInputSource` nạp tuỳ chọn **0** rồi nhảy vào `TSMEnableInputSourceWithOptions(nguồn, tuỳ chọn)`; `TISEnableInputSourceWithOptions` truyền tuỳ chọn của người gọi.
- Hàm đọc thuộc tính `kTISPropertyInputSourceIsFromSystem` (tên do `dyld_info` gắn). Nếu **bit 1 của tuỳ chọn (giá trị 2)** hoặc thuộc tính này đúng, gọi thẳng `_TSMSetInputSourceEnabled` (bật thật).
- Ngược lại:
  - lấy tên app đang gọi (`GetCurrentAppNameAsCFString`);
  - dựng từ điển ba khoá `tabID` (`com.apple.IntlKeyboard`), `inputSourceToBeEnabled` (nguồn đã "flatten" bằng `_CreateFlattenedInputSource`), `localizedSenderName`;
  - tuần tự hoá thành plist XML;
  - mở `System Settings.app` qua LaunchServices kèm sự kiện;
  - **rồi kết thúc với giá trị trả 0**.
  - Hệ quả khớp việc lệnh trả `noErr` mà không bật.
- `IsFromSystem` có thể nghĩa "đường dẫn bundle bắt đầu bằng `/System/`" (hàm `islcCacheElemIsFromSystem` so 8 byte với một chuỗi mà `dyld_info` liệt kê là `/System/`). [Suy luận, cần kiểm chứng; `dyld_info` liệt kê địa chỉ chuỗi lệch.]
- Cũng trong `HIToolbox`: chuỗi nhật ký "InputSourceFSEventCallback -> TISUpdateIntlFileCache" cùng danh sách thư mục theo dõi (`~/Library/Input Methods/`, `/Library/Input Methods/`, `~/Library/Keyboard Layouts/`…); thư viện tự dựng lại danh mục khi các thư mục này đổi. Việc này có tới được tiến trình Cài đặt không: không tìm thấy nguồn (DTS nói không).

**Phía nhận** (`handleOpenParameter(aeDesc:)`, arm64e, `otool -tV`) [Diễn giải mã máy]:
1. Đọc dữ liệu của sự kiện (`AEGetDescData`), giải plist thành từ điển.
2. Nếu có khoá `inputSourceToBeEnabled`: gọi `ksCreateUnflattenedInputSource` (bao `_CreateUnflattenedInputSource`). Trả NULL thì ghi lỗi "Invalid value on inputSourceToBeEnabled" và kết thúc nhánh.
3. Có nguồn thì lấy `kTISPropertyLocalizedName` ("Can't get localized name" nếu thiếu) và `localizedSenderName` ("Can't get localizedSenderName" nếu thiếu), ghép tiêu đề hộp thoại.
4. Một hàm nhỏ của lớp này gọi `TISEnableInputSourceWithOptions(nguồn, 2)` (`mov w1, #0x2` ngay trước nhánh tới ký hiệu); tên hàm bị lược; gần như chắc là hành động "Cho phép" [Suy luận, cần kiểm chứng].

- `_CreateUnflattenedInputSource` gọi `islGetInputSourceDictFromPrefsDescriptor` rồi `islGetInputSourceList`: nó tìm nguồn trong danh sách nguồn **của tiến trình gọi** (ở đây là Cài đặt); không thấy thì trả NULL.
- Kết hợp với mục 2.3: hộp thoại chỉ có thể hiện khi Cài đặt nhận sự kiện có `inputSourceToBeEnabled` hợp lệ **và** dựng lại được nguồn; %1 là tên app gọi (`localizedSenderName`), %2 là tên bộ gõ.

**Nhật ký Cài đặt khi Dấu thật bấm "Bật Dấu"** [Máy/Dấu + Máy/hệ thống].
- Lệnh: `/usr/bin/log show --last 7d --style compact --predicate 'process == "KeyboardSettings" AND eventMessage CONTAINS "inputSourceToBeEnabled"'`.
- 02/11/2026 16:41:23.957: `KeyboardSettings[73671] … KeyboardSettings.swift handleOpenParameter(aeDesc:) Invalid value on inputSourceToBeEnabled`, nằm sau một dòng mức mặc định `handleOpenParameter(aeDesc:)` của `SettingsViewScene.swift` cùng giây.
- Cùng giây, `Dau[73640]` ghi `event=installed`, `event=register status=0`, `event=enable id=com.codefastlabs.dau.inputmethod.Dau status=0` lúc 16:41:23.091–.140 (`/usr/bin/log show --predicate 'subsystem == "com.codefastlabs.dau"'`).
  - Đó là nút "Bật Dấu" của lần thử cài đầu 02/11 (mục 9.5); 0,8 s sau Cài đặt báo dòng lỗi.
  - Máy lúc đó còn mục Dấu cũ từ 30/10 (mục 9.4).
- Nghĩa: Cài đặt nhận yêu cầu "bật nguồn" mà không dựng được nguồn, nên theo mã không có hộp thoại.
  - Vì sao dựng lại không được: không tìm thấy nguồn.
  - Giả thuyết hợp với mã: nguồn chưa nằm trong danh sách nguồn của tiến trình Cài đặt lúc đó, liên quan tới chuyện DTS nói Cài đặt "không nhận nguồn mới" cho tới khi đăng xuất. [Suy luận, cần kiểm chứng]
  - Các lần thử 04/11/2026 sau khi xoá bộ đệm của System Settings không còn dòng lỗi này và hộp thoại hiện (mục 8.1b, 9.9).
- Truy vấn này cho thêm hai dòng lỗi cùng loại ngày 03/11 từ bản thử, ghi ở mục 8.

**Báo cáo từ dự án khác** [Ngoài]:
- McBopomofo (11/2025) ghi trong mã: "System Settings now asks the user whether to activate the IME", rồi cho trình cài tự đóng sau 60 giây (commit a21ba98; bản sao 257da53 vẫn còn dòng này). vChewing (macOS 12) cũng nói hộp thoại có hiện.
- low-talker (đo trên macOS 15.0.1, 9/2026): hộp thoại Allow hiện lại sau khi người dùng bấm "Không". PR #96.
- msime (macOS 27.0, 26A428, 27/09/2026): với nguồn kiểu `TISTypeKeyboardInputMode`, `TISEnableInputSource` **trả noErr nhưng mode vẫn tắt**; mode `SCIM.Shuangpin` của chính Apple cũng vậy, còn bàn phím `com.apple.keylayout.US` thì bật được. Họ đã bỏ nút "Bật", chỉ còn hướng dẫn mở Cài đặt. PR #2492, `platforms/macos/README.md`.
- marinaMoji (27.0.1): `TISEnableInputSource` mục cha trả 0 ba lần nhưng cha vẫn `enabled=0`; kết luận của họ: "adding a third-party input method is something macOS only lets the user do". Issue #66.
- Các báo cáo này mâu thuẫn bề ngoài (có hộp thoại, không có hộp thoại); chưa phân xử. Tới 03/11/2026 chưa ai thấy hộp thoại trên máy này; từ 04/11/2026 hộp thoại đã hiện khi làm theo D37 (mục 9.9). Trên bản macOS khác và với bản ký Developer ID: mục 10.3.

### 2.3 Lần cài đầu có phải đăng xuất không

Trên macOS 27.2, làm theo D37 thì không cần đăng xuất (Dấu thật, 04/11/2026; mục 9.9). Các bản macOS khác và bản ký Developer ID chưa đo (mục 10.1). Dưới đây là bằng chứng hai phía.

**Bên "phải đăng xuất":**
- Apple DTS (06/2026, Ziqiao Chen; FB23026482): "without the user logging off the system, System Settings doesn't pick up a new input source any more. I don't see anything that can avoid the logoff."
  - Người hỏi (gershnik, 02/2025): trên các macOS gần đây thêm hoặc sửa nguồn trong `<domain>/Library/Input Methods` thì "the user needs to logoff and log back in" để Cài đặt và menu nhập liệu thấy; hỏi có thông báo hay API làm mới không.
  - Thread không nêu tên hàm TIS, không nhắc hộp thoại hay `.inputmethod.`, không nêu cách thay thế. [Apple, diễn đàn 775526, đọc 03/11/2026]
- msime (macOS 27.0 và 27.0.1): ID chưa có trong danh sách nguồn lúc bắt đầu phiên đăng nhập thì không vào được danh sách trong phiên đó.
  - `TISRegisterInputSource` trả noErr nhưng `TISCreateInputSourceList` không thấy.
  - Khởi động lại `imklaunchagent`, `TextInputMenuAgent`, `TextInputSwitcher`, `keyboardservicesd`, chạy `lsregister -f` hay `lsregister -r -domain user` đều không giúp.
  - Đăng nhập lại một lần là được, và các bản cập nhật sau giữ ID đó thì không cần.
  - Sau cài/cập nhật họ dọn bộ đệm `IntlDataCache` của Cài đặt, thoát Cài đặt, dừng extension Bàn phím, `CursorUIViewService`, `TextInputSwitcher`: cách này chỉ sửa chuyện **mode mới của ID đã biết**.
  - Họ vẫn giữ thông báo đăng xuất cho ID mới, nêu là hạn chế ở mức sổ đăng ký, không đổi theo cách ký hay nội dung plist. [Ngoài; PR #3738, #2492, `platforms/macos/README.md`, `docs/macos-parity.md`]
- low-talker (macOS 15.0.1): bundle chép vào `~/Library/Input Methods` giữa phiên đăng ký được, nhưng chỉ bật được sau lần đăng nhập sau. [Ngoài]
- README hoặc hướng dẫn của:
  - Squirrel (`onConclusion="RequireLogout"`, "log out and log back in to complete installation");
  - macSKK (nếu không hiện ngay sau cài hoặc cập nhật không đổi thì "ログアウト & ログイン");
  - Gureum;
  - fcitx5-macos ("After the first time you execute `cmake --install`, you need to logout and login"; các lần sau chỉ cần "Restart" trong menu);
  - XKey ("Cần logout/login sau khi install lần đầu để macOS nhận diện");
  - AquaSKK ("You might need logout/login to start new AquaSKK process", không nêu bản macOS). [Ngoài, README và mã]
- Squirrel trên tracker (macOS 15.6, 26.1, 26.2; 12/2025 đến 01/2026): sau cài và đăng xuất/khởi động lại vẫn không thấy trong danh sách; người bảo trì lotem (18/12/2025) bảo vào Cài đặt thêm tay bằng nút "+" (#1083, #1082).
- XKey (macOS 26.1, 22/12/2025): bấm "Cài đặt XKeyIM" thì Cài đặt mở Nguồn nhập liệu nhưng không thấy XKey; người bảo trì bảo chép vào thư mục input sources, chưa nhận thì đăng xuất rồi đăng nhập (#75). [Ngoài]
- Bằng chứng gián tiếp: ở lần thử cài đầu 02/11 (mục 9.5), "+" và menu không có Dấu sau "Bật Dấu", và có sau lần đăng xuất/đăng nhập kế tiếp. Máy không sạch (mục 9.4) nên chỉ là một quan sát phù hợp, không phải phép đo. [Máy/Dấu]

**Bên "không cần / hiện ngay":**
- Dấu thật (04/11/2026, macOS 27.2): xoá `IntlDataCache.le*` sau khi đăng ký thì "+" có Dấu và bật được qua hộp thoại xin phép, không đăng xuất (mục 9.9, mục 8.1b). [Máy/Dấu]
- marinaMoji (máy ảo sạch macOS 27.0.1, `.pkg` vào `/Library/Input Methods`; `postinstall` chạy dưới tên người dùng):
  - `TISRegisterInputSource` → 0; `TISEnableInputSource` các mode → 0; `TISSelectInputSource` mode gốc → -50; cha vẫn `enabled=0`.
  - Nguồn **hiện ngay trong "+"**, người dùng tự thêm, dùng được, không đăng xuất.
  - Bản v0.0.14 (có plugin kích hoạt) cho kết quả như nhau. Chỉ thử macOS 27.
  - Có đính chính trong issue: lúc đầu đọc nhầm miền `HIToolbox`, giống Dấu. [Ngoài, issue #66, 15/10/2026]
- Header: đăng ký "so that a TISInputSourceRef can immediately be obtained" (mục 2.1). Đây là tài liệu 2006–2008; quan sát của tabulador (dưới) và msime lệch với câu "immediately". [Apple]
- McBopomofo: mã không đòi đăng xuất cho lần cài đầu.
  - Màn hình cuối "Installation Successful – ready to use"; chỉ cảnh báo đăng xuất khi **nâng cấp** mà bản cũ chưa thoát hẳn do translocation; README: kill tiến trình quá nhiều lần trong một phiên thì phải đăng xuất.
- vChewing: mã dừng `TextInputMenuAgent` rồi chờ 0,5 s với chú thích để "bộ gõ mới hiện trong menu mà không phải đăng xuất".
- **Cả hai không có số đo trên máy sạch macOS 27**; msime đo thấy cách của vChewing vô tác dụng với ID mới trên 27.0. [Ngoài, mã]

**Khác biệt chưa tách được:**
- marinaMoji cài ở `/Library/Input Methods`, nhưng Squirrel, macSKK, fcitx5 và Gureum cũng cài ở đó mà vẫn bảo đăng xuất.
- Các yếu tố có thể là thư mục, tiến trình gọi, thời điểm mở Cài đặt lần đầu, hay tên ID: [Suy luận, cần kiểm chứng].
- Squirrel (26.2) và marinaMoji (27.0.1) cùng nói người dùng thêm bằng "+" trong Cài đặt; nguồn Squirrel không tuyên bố nguồn có hiện trong "+" ngay sau cài hay không.

**Giả thuyết giải thích (chưa có bằng chứng, [Suy luận, cần kiểm chứng]):**
- Có hai tầng: sổ nguồn đã đăng ký cộng tuỳ chọn người dùng mà `TISCreateInputSourceList` trong một tiến trình mới ghép được; và **danh mục nguồn chụp lúc đăng nhập** mà menu nhập liệu, "+" và ⌃Space dùng. ID chưa có trong danh mục thì không hiện trong phiên đó.
- Quan sát phù hợp [Máy/hệ thống, 02/11]:
  - `$(getconf DARWIN_USER_CACHE_DIR)/com.apple.Keyboard-Settings.extension/com.apple.IntlDataCache.le.kbdx` có mtime 16:54:04, 17 giây sau khi `TextInputMenuAgent` khởi động (16:53:47), và `AppleInputSourceUpdateTime` là 16:54:30 (giờ +07), cùng lúc đăng nhập;
  - `TextInputMenuAgent` có ký hiệu `managerWithAllInputSources`, `fInputSources`, `handleEnabledInputSourcesChange` (`strings`);
  - `TextInputMenuAgent`, `TextInputSwitcher`, `imklaunchagent` đều là LaunchAgent của phiên đăng nhập (`launchctl print gui/501/…`, `runs = 1`).
- Phần của giả thuyết cũ cho rằng `TISEnableInputSource` từ app đã ghi tuỳ chọn người dùng **không còn đứng**: mã cho thấy Enable của bên thứ ba nhờ Cài đặt (mục 2.2), nhật ký cho thấy ghi miền đó bị chặn với Disable và `defaults import` (mục 2.6; với Enable chưa có số đo).

**Các bộ gõ khác nhắc ba chi tiết liên quan:**
- vChewing cho rằng dừng `TextInputMenuAgent` rồi chờ 0,5 s là khỏi đăng xuất. Không dùng cách này (là tiến trình hệ thống, mục 3).
- tabulador / Tab (PR #9): đăng ký rồi tra `TISCreateInputSourceList` ngay trong tiến trình app chạy lâu thì **trả NULL**; sửa bằng thử lại tối đa 20 lần cách nhau 0,5 s.
  - Bundle của họ đặt `ComponentInvisibleInSystemUI = true` làm nó biến mất khỏi "+" (đổi thành false).
  - Dấu **không** đặt khoá này (đã grep `Apps/DauInputMethod/Info.plist`, 02/11). [Ngoài; Máy/Dấu]
- `enable()` của Dấu bỏ qua mode vì danh sách `known` lấy từ ảnh chụp trong tiến trình app chủ, nên kết quả "enable mode" của app chủ không phản ánh trạng thái hệ thống. [Diễn giải mã máy, đọc mã Dấu 02/11; chưa kiểm]

### 2.4 Các bộ gõ khác làm gì ở lần chạy đầu [Ngoài, mã nguồn]

| Dự án | Chuỗi gọi (theo thứ tự) |
|---|---|
| Squirrel | `.pkg` vào `/Library/Input Methods`. `postinstall`: dừng tiến trình cũ; chạy chính app với `--register-input-source` (`TISRegisterInputSource`, **chỉ khi chưa có mode nào đang bật**); dựng dữ liệu; rồi bằng **tiến trình mới, dưới tên người dùng**, `--enable-input-source` (`TISEnableInputSource` cho **mode** `Hans`, chỉ khi cờ enabled đang false) và `--select-input-source` (`TISSelectInputSource`, chỉ khi đã enabled, chọn được, chưa chọn). Mỗi lệnh là một tiến trình riêng nên mỗi lần liệt kê `TISCreateInputSourceList(nil, true)` là mới. Không dừng tiến trình hệ thống, không chờ thông báo. `RequireLogout`. |
| McBopomofo | Trình cài riêng chép vào `~/Library/Input Methods` (Thùng rác bản cũ, `killall -9`, `cp -R`). Nếu `TISCreateInputSourceList` chưa thấy ID thì `TISRegisterInputSource`, liệt kê lại (không thấy: báo "Fatal Error"). Rồi **luôn** `TISEnableInputSource` cho **mục cha** (từ macOS 12, vì cờ enabled có thể báo sai). Không `Select`, không đụng tiến trình hệ thống; macOS hỏi xác nhận (mục 2.2). |
| vChewing | `.pkg` hoặc trình cài app: chép, bỏ quarantine (`xattr -drs`), dừng tiến trình cũ sau khi chép, rồi `killall TextInputMenuAgent`, chờ 0,5 s, rồi chạy chính IME với `install` bằng tên người dùng: nếu chưa có thì `TISRegisterInputSource`, rồi `TISEnableInputSource` cho **từng mode** (cha không gọi riêng). Không `Select`. Không có mode nào bật thì hiện cảnh báo; nếu không chắc thì báo đăng xuất. Không dừng `imklaunchagent` (app đang gõ mất kết nối tới khi mở lại). |
| XKey (tiếng Việt, IMK) | Chép `XKeyIM.app` vào `~/Library/Input Methods`, `TISRegisterInputSource`, **không enable**, mở Cài đặt › Bàn phím để người dùng tự thêm. |
| macSKK | `.pkg`; `postinstall` chỉ thoát app cũ bằng `osascript`; không gọi TIS; người dùng tự thêm trong Cài đặt. |
| Gureum (Hàn) | `.pkg`; không có script gọi TIS; README hướng dẫn tự thêm trong Cài đặt. |
| fcitx5-macos | `cmake --install` vào `/Library/Input Methods`; không gọi TIS lúc cài. |
| msime | Từng có nút "Bật"; đã bỏ vì trên macOS 27 nút này không có tác dụng; nay chỉ hướng dẫn + mở Cài đặt, kiểm lại mỗi 3 s. |
| marinaMoji (Mozc) | `.pkg` vào `/Library/Input Methods`; `postinstall` chạy dưới tên người dùng (mục 2.3). |
| tabulador / Tab | Đăng ký rồi thăm dò danh sách (mục 2.3). |

Ghi chú:
- Squirrel chỉ bật **mode**, vChewing chỉ bật **mode**, McBopomofo bật **mục cha**; Dấu bật cha rồi mode.
- Không dự án nào dùng `kTISNotifyEnabledKeyboardInputSourcesChanged` để chờ khi cài, và không dự án nào dừng `imklaunchagent`.
- Chỉ vChewing dừng `TextInputMenuAgent`; msime dừng `CursorUIViewService` và `TextInputSwitcher` sau cài.

So với các bộ gõ trên, cách của Dấu (chỉ bật khi người dùng bấm "Bật Dấu", có Hoàn tác; N4) **thận trọng hơn** Squirrel, McBopomofo, vChewing (bật, thậm chí chọn luôn, ngay khi cài) và **ngang** XKey, msime (chỉ hướng dẫn).

### 2.5 Mở đúng màn hình Cài đặt
- Các dự án dùng URL `x-apple.systempreferences:com.apple.Keyboard-Settings.extension` (Bàn phím) và `x-apple.systempreferences:com.apple.LoginItems-Settings.extension` (Mục đăng nhập).
- `KeyboardSettings.appex` trên macOS 27.2 khai báo `allowsXAppleSystemPreferencesURLScheme = true`. [Máy/hệ thống]
- Apple không công bố danh sách URL này, nên phải thử lại trên từng bản macOS [Suy luận].
- Tên trên giao diện tiếng Việt, macOS 27.2: "Bàn phím › Nhập văn bản › Nguồn đầu vào › Sửa…"; "Cài đặt chung › Mục đăng nhập & Phần mở rộng › Mở khi đăng nhập". [Máy/hệ thống, `.loctable`]

### 2.6 Trạng thái "đã bật" lưu ở đâu và cách đọc
- **Nơi lưu** [Máy/hệ thống, 02/11, macOS 27.2]:
  - `defaults read com.apple.inputsources` có `AppleEnabledThirdPartyInputSources` (với hai mục `Keyboard Input Method` cha và `Input Mode` `….Dau.vi` khi máy đang có Dấu từ 30/10).
  - `defaults read com.apple.HIToolbox` có `AppleEnabledInputSources` chỉ gồm nguồn của Apple (U.S., Telex của Apple, `CharacterPaletteIM`, …) và không có Dấu; `AppleInputSourceHistory` và `AppleSelectedInputSources` có Dấu.
  - Nguồn bên thứ ba **không** nằm ở `AppleEnabledInputSources`. Các dòng cũ (30/10) đọc `AppleEnabledInputSources` để kết luận "không có Dấu" đã đọc nhầm miền.
- **Ghi:** chỉ có số đo cho **Disable** và cho `defaults import` [Máy/Dấu, 02/11].
  - Log `System Policy: defaults deny user-preference-write com.apple.inputsources`, cfprefsd "rejecting write", dù `TISDisableInputSource` vẫn trả 0 (cả `probe-tis`, công cụ dòng lệnh ngoài repo, khi tắt cũng bị chặn).
  - `defaults import` từ script dọn máy bị từ chối dù lệnh trả 0.
  - Với **Enable** không có số đo "ghi bị chặn": theo mục 2.2, `TISEnableInputSource` của nguồn bên thứ ba không ghi miền này mà gửi yêu cầu cho Cài đặt rồi trả 0 [Diễn giải mã máy]. Việc nó trả 0 mà không bật khớp với cách đó, chưa phân biệt được với "bị chặn ghi" bằng phép đo.
  - Chỉ Cài đặt hệ thống (và dịch vụ nguồn nhập liệu) ghi được (người dùng gỡ bằng nút "–" thì file ghi lúc 18:07, mục rỗng). Đọc thì được.
- **Cờ `kTISPropertyInputSourceIsEnabled` không đáng tin:**
  - McBopomofo và vChewing đều ghi từ macOS 12 là cờ này có thể báo sai [Ngoài, mã];
  - marinaMoji ghi enabled=1 trong tiến trình cài mà không lưu [Ngoài];
  - trên máy này (30/10) mode Telex của Apple báo enabled=1 trong khi input method cha báo 0 [Máy/hệ thống];
  - sau khi Cài đặt gỡ Dấu bằng "–" (02/11), TIS trong tiến trình mới vẫn báo mode `enabled=true` [Máy/Dấu];
  - msime: sau khi thay bundle có khoảng vài phút danh sách TIS không ổn định [Ngoài].
- **Cách đọc đề xuất** (không có một con số duy nhất; đọc cả ba nơi):
  1. Tuỳ chọn lưu: `defaults export com.apple.inputsources -` (`AppleEnabledThirdPartyInputSources`; đọc thêm `com.apple.HIToolbox` cho nguồn của Apple) cho biết hệ thống đã nhận lệnh bật hay chưa.
  2. TIS trong **tiến trình mới** (không dùng lại tiến trình đã gọi `Register`), vài lần đọc cách nhau 1–3 s: `kTISPropertyInputSourceIsEnabled`, `IsEnableCapable`, `IsSelectCapable`, `IsSelected`.
  3. Giao diện thật: menu nhập liệu, "+" và danh sách bên trái trong Cài đặt, ⌃Space; hoặc gián tiếp bằng việc tiến trình `DauInputMethod` có chạy khi nguồn được chọn. Không có API công khai đọc tầng này; chỉ nhìn bằng mắt (hoặc chụp ảnh màn hình có sự đồng ý của người dùng).
  - [Suy luận, cần kiểm chứng]

### 2.7 Luật `.inputmethod.` trong bundle ID
- Chuỗi `.inputmethod.` có trong `HIToolbox`, ngay cạnh các nhật ký của `TISFileInterrogator` (quét bundle để dựng danh mục: "processing NSExtension-based input method", `InputMethodType`, `/Input Methods/`) và bảng nén ID (`sourceIDsubstringToKey`). [Máy/hệ thống; lệnh `strings`/`dyld_info -all_sections`]
  - Không xác định được chỗ nào dùng chuỗi đó (không tìm thấy tham chiếu mã trực tiếp), cũng không xác định được nó là điều kiện để TIS liệt kê một bundle IMK hay chỉ liên quan tới bộ gõ dạng NSExtension/nén ID.
  - Không tìm thấy nguồn Apple cho luật.
- Mẫu IMKit của ensan-hcl (README, ngày đẩy cuối 18/03/2024): "Create a new project with a bundle identifier that contains `.inputmethod.`", và thêm nguồn bằng Cài đặt › Bàn phím › Nguồn nhập liệu. Đây là lời dặn của một dự án mẫu, **không phải** quy định của Apple. [Ngoài]
- Mọi ID IMK đã gặp trong các tài liệu của Dấu đều chứa `.inputmethod.` (Apple, `org.mozc.inputmethod.Japanese`, `com.codetay.inputmethod.XKey`, và Dấu `com.codefastlabs.dau.inputmethod.Dau`): tương quan, không phải bằng chứng cho luật. [Ngoài]
- Quan sát bằng bản thử về ID có/không có chuỗi này: mục 8.1. Không dùng ở đây.

## 3. Nâng cấp (bộ gõ đang chạy)

Trình tự đề xuất, ráp từ McBopomofo, vChewing, XKey và D7:
1. App chủ khởi động lại sau khi Sparkle cập nhật. Nó so `CFBundleVersion` của bộ gõ nằm trong app với bản đã cài.
2. Chờ lúc người dùng không gõ (D7).
3. Kiểm chữ ký bản trong app: Team ID đúng, chữ ký hợp lệ.
4. Chép vào một thư mục tạm **trên cùng ổ đĩa** (trong `~/Library/Input Methods`, tên tạm không đuôi `.app` để TIS không quét), rồi **đổi chỗ cả khối** (`FileManager.replaceItemAt`, hoặc đổi tên cái cũ rồi đặt cái mới).
   - Không ghi đè từng file lên bundle đang chạy: tiến trình cũ còn đang ánh xạ các trang mã của nó [Suy luận, cần kiểm chứng; vChewing làm đúng kiểu chép tạm rồi move].
5. Gỡ quarantine của bản mới sau khi đã kiểm chữ ký (làm được vì app chủ không sandbox, D37).
6. Dừng tiến trình cũ (`DauInputMethod`). Hệ thống sẽ chạy bản mới ở phím gõ kế tiếp (đã thấy với `scripts/dev/install-input-method.sh`).
   - Cách hợp với cả hai phương án sandbox: app chủ phát thông báo Darwin, bộ gõ tự `exit(0)` khi không có từ đang gõ; quá thời hạn thì app chủ (không sandbox) mới `terminate`.
   - macSKK làm tương tự bằng cách gửi "quit" qua `osascript`.
   - Bộ gõ thoát khi nhận thông báo `quitRequested` đã làm ở 30/10/2026 (`docs/PROGRESS.md`).
7. Gọi lại `TISRegisterInputSource(url)` (Squirrel làm mỗi lần cài; vô hại). Không đụng tới trạng thái bật/chọn: ID giữ nguyên thì lựa chọn của người dùng còn nguyên.

**Không làm:**
- Không dừng `imklaunchagent`. vChewing ghi: dừng nó làm app đang gõ mất kết nối với mọi bộ gõ cho tới khi mở lại app đó. [Ngoài, chú thích trong mã vChewing]
- Không dừng `TextInputMenuAgent`, `CursorUIViewService`, `TextInputSwitcher`, không xoá bộ đệm của Cài đặt Bàn phím (`$(getconf DARWIN_USER_CACHE_DIR)/com.apple.Keyboard-Settings.extension/com.apple.IntlDataCache.le.kbdx`; msime xoá file này, macOS 27.0.1).
  - Đó đều là tiến trình và bộ đệm của hệ thống (tinh thần N4).
  - Giữ biểu tượng và tên không đổi thì không cần làm những việc đó. Nếu một bản có đổi biểu tượng/tên thì ghi trong ghi chú phát hành: "đăng xuất để thấy biểu tượng mới".
  - Dấu đã thấy cả hai bộ đệm ảnh (30/10/2026): ảnh cũ trong `TextInputMenuAgent` chỉ đổi sau khi khởi động lại tiến trình đó; `CursorUIViewService` giữ ảnh cũ. [Máy/Dấu]

**Không được đổi giữa các phiên bản** (đổi là phải đăng xuất, và có thể làm lệch bộ đệm TIS như đã gặp ngày 30/10, mục 9.1):
- `CFBundleIdentifier` của bộ gõ `com.codefastlabs.dau.inputmethod.Dau`, `TISInputSourceID`, ID mode `com.codefastlabs.dau.inputmethod.Dau.vi` (khoá trong `tsInputModeListKey`);
- `InputMethodConnectionName` (`…_Connection`, cũng nằm trong entitlement `mach-register`);
- tên file `DauInputMethod.app` và `CFBundleExecutable` `DauInputMethod` (dùng để tìm và dừng tiến trình);
- `TISIntendedLanguage` `vi` (quyết định nhóm ngôn ngữ trong danh sách thêm nguồn);
- nên giữ: tên hiển thị "Dấu – Tiếng Việt", tên file biểu tượng (bộ đệm chỉ làm mới khi đăng xuất).

## 4. Gỡ cài đặt (D16)

Trình tự đề xuất (người dùng bấm "Gỡ cài đặt…" và xác nhận):
1. Nếu Dấu đang được chọn: chọn trước một bàn phím khác.
   - Đích là `TISCopyCurrentASCIICapableKeyboardLayoutInputSource()` (theo header: bàn phím ASCII dùng gần nhất) nếu nó đang bật; không thì lấy nguồn ASCII đang bật đầu tiên. Gureum dặn người dùng tự chuyển sang bàn phím của hệ thống trước khi gỡ.
   - Người dùng báo (04/11/2026, chưa có ảnh hay nhật ký): trong System Settings không bỏ được nguồn đang được chọn bằng "–", nên luồng hướng dẫn bấm "–" (vì app không tự tắt được, bước 2) bắt buộc chuyển nguồn trước.
   - **Đo lại 04/11/2026 14:58 (Dấu thật, macOS 27.2, qua trợ năng):** khi Dấu đang được chọn, nút "–" vẫn bấm được và macOS tự chuyển sang U.S. sau khi bỏ; quan sát trước chưa lặp lại. App vẫn chuyển bàn phím trước cho chắc. [Máy/Dấu]
   - Chưa đo: người dùng chỉ bật mỗi Dấu thì không có gì để chuyển sang; tuỳ chọn "tự động chuyển sang nguồn của tài liệu" (D5 (Quy tắc theo ứng dụng)) bật thì cửa sổ System Settings có thể tự chọn lại Dấu.
   - Nếu không chọn trước, hệ thống sẽ tự đổi sang nguồn khác khi Dấu bị tắt, nhưng chưa biết đổi sang nguồn nào [Suy luận, cần kiểm chứng].
2. `TISDisableInputSource` cho mode `….Dau.vi`, rồi cho input method cha `com.codefastlabs.dau.inputmethod.Dau` (fcitx5 tắt cha).
   - **Đã đo trên macOS 27.2 [Máy/Dấu, 02/11]:** hai lệnh trả 0, nhưng System Policy chặn ghi `com.apple.inputsources`, hai mục Dấu vẫn lưu, TIS vẫn báo `enabled=true`; app **không tự tắt được** nguồn. Chỉ tắt bằng nút "–" trong Cài đặt có hiệu lực. Mục 9.7.
   - App đã đọc trạng thái thật từ `com.apple.inputsources`, thử tắt lại, và báo `stillEnabled` theo mục còn lưu (`docs/PROGRESS.md`, 02/11).
   - Cách onboarding/gỡ xử lý khi không tự tắt được: mục 6.
   - `TSMDisableInputSource` là cùng một đường, và các cách khác để app tự bỏ mục (công cụ con, quyền quản trị, sửa file, nhờ System Settings, hồ sơ cấu hình, tự động bấm "–") đều không dùng được hoặc không nên dùng: mục 4.1.
3. Dừng tiến trình `DauInputMethod` (như mục 3, bước 6). Đã làm: gỡ cài đặt chuyển vào Thùng rác trước rồi mới yêu cầu thoát (02/11/2026).
4. Chuyển `~/Library/Input Methods/DauInputMethod.app` vào Thùng rác (vChewing, McBopomofo dùng Thùng rác, có thể khôi phục).
5. Nếu tick "Xoá cả cài đặt và quy tắc ứng dụng": xoá dữ liệu trong Group Container của App Group.
   - Container riêng của bộ gõ (`~/Library/Containers/com.codefastlabs.dau.inputmethod.Dau`) để bộ gõ tự dọn tuỳ chọn của nó trước khi thoát.
   - App chủ đụng vào container của app khác có thể làm macOS 14+ hỏi quyền truy cập dữ liệu app khác [Suy luận, cần kiểm chứng].
6. Báo người dùng: tên "Dấu" có thể còn trong danh sách Nguồn đầu vào của Cài đặt tới lần đăng xuất sau.
   - Đã thấy: lần thử cài đầu 02/11 (mục 9.5), sau khi gỡ qua app, danh sách "+" còn một dòng trống tới khi đăng xuất. [Máy/Dấu]
   - Squirrel #1169 (macOS 26, 07–13/08/2026): xoá file mà Cài đặt vẫn liệt kê, lotem: "安裝程序要求重新登錄呢吧" (trình cài yêu cầu đăng nhập lại), "如果系統顯示還有，那就是操作系統的 BUG". [Ngoài]
   - Cho tới khi đăng xuất, đừng hứa là hết.
   - Cuối cùng, chuyển `Dấu.app` vào Thùng rác (làm được vì app chủ không sandbox) hoặc hướng dẫn người dùng tự kéo.

Câu "Bàn phím đang dùng trước đó được giữ nguyên" trong sheet xác nhận (`docs/UI.md`) chỉ đúng khi làm bước 1 trước bước 2. Phải kiểm bằng Dấu thật trước khi để câu này trên giao diện (N5). Kế hoạch kiểm trên máy sạch ở mục 7 đã bỏ; phép đo gần nhất là phép đo 04/11/2026 14:58 ở bước 1.

### 4.1 App có tự bỏ được mục của Dấu khỏi `AppleEnabledThirdPartyInputSources` không (04/11/2026, chỉ đọc)

Câu hỏi: đọc được mục ẩn thì có xoá được không?

Trả lời trên macOS 27.2: **không có cách chính đáng và ổn định.**
- Đọc miền `com.apple.inputsources` thì tiến trình nào cũng đọc được.
- Ghi thì macOS chặn bằng chính sách sandbox nền tảng ("System Policy"), áp cho cả tiến trình không sandbox, trừ tiến trình mang entitlement riêng của Apple.
- Đường dùng được là người dùng bấm "–" trong System Settings › Keyboard › Input Sources › Edit…: app mở đúng chỗ và chờ mục biến mất rồi mới xoá bundle (hướng "hướng dẫn người dùng bấm –" ở bảng các hướng dưới đây).

**Vì sao đọc được mà không ghi được**
- Nhật ký cfprefsd mỗi lần từ chối, 02/11/2026: `Couldn't write values for keys <private> in CFPrefsPlistSource<…> (Domain: com.apple.inputsources, User: kCFPreferencesCurrentUser, …): setting these preferences requires user-preference-write or file-write-data sandbox access`.
  - Năm dòng: `Dau` 16:20:51 và 17:30:59, `defaults` 17:35:18 và 17:57:18, `probe-tis` 18:04:43.
  - Lệnh: `/usr/bin/log show --start "2026-11-02 00:00:00" --end "2026-11-03 23:59:59" --style compact --predicate '(eventMessage CONTAINS "user-preference-write" OR eventMessage CONTAINS "rejecting" OR eventMessage CONTAINS "file-write") AND eventMessage CONTAINS "inputsources"'`.
  - Dòng `deny(1)` của sandbox cùng lúc không còn trong nhật ký (đã ghi ở mục 4 bước 2 hôm đó). [Máy/Dấu + Máy/hệ thống]
- Theo câu chữ đó, cfprefsd nhận ghi nếu tiến trình gọi có **một trong hai** quyền: ghi miền tuỳ chọn, hoặc ghi dữ liệu vào chính file plist; bị từ chối nghĩa là thiếu cả hai. Vậy cùng chính sách đó nhiều khả năng cũng chặn tiến trình ấy mở file để ghi. [Diễn giải nhật ký; Suy luận, cần kiểm chứng]
- Quét chuỗi `security.storage.inputsources` trong `/System/Library/{CoreServices,ExtensionKit,Frameworks,PrivateFrameworks,PreferencePanes,Input Methods}`, `/System/Applications`, `/usr/{bin,sbin,libexec}` và cryptex OS (`grep -rlas`, 04/11): chỉ `KeyboardSettings.appex` có (entitlement `com.apple.private.security.storage.inputsources`, mục 2.2).
  - Luật của System Policy biên dịch trong kernel, không đọc được, nên không loại trừ được tiến trình hệ thống khác được phép theo cách khác. [Máy/hệ thống]
- Bên thứ ba không thể có entitlement `com.apple.private.*`: "There's no way for a third-party developer to get a profile that authorises an Apple private entitlement" (Quinn, DTS, 06/2024, thread 756747; TN3125). [Apple]
- Miền `com.apple.inputsources` là miền tách riêng sau này.
  - `TextInputSourceUAU.bundle` (plugin cập nhật tài khoản, `/System/Library/CoreServices/UAUPlugins/`) có nhật ký "Running MigrateThirdPartyInputSourcesToNewDomain...", "Prefs in new domain exist. Skipping migration.", "Found third-party input sources. Writing the prefs..." (`strings`).
  - msime ghi bản macOS cũ để nguồn bên thứ ba trong `com.apple.HIToolbox` (ghi chú 19/10/2026).
  - Tách miền để khoá riêng danh sách nguồn bên thứ ba: [Suy luận, cần kiểm chứng]. [Máy/hệ thống; Ngoài]
- File `~/Library/Preferences/com.apple.inputsources.plist`: `-rw-------` của người dùng, có xattr `com.apple.macl` và `com.apple.quarantine` (`0086;…;com.apple.cfprefsd;`) (`ls -lO@e`, `xattr`, 04/11).
  - Quyền Unix cho người dùng ghi; chỗ chặn là chính sách sandbox, không phải quyền file.
  - Ghi lúc 12:44 (người dùng bấm "–" cho bản `DauProbeB3` ở vòng thử gỡ, mục 8.1b); lúc đó còn mục của `DauProbeC2`, `DauProbeC1` (ẩn) và Dấu. Sau các phép đo ở cuối mục này, miền chỉ còn mục của Dấu. [Máy/hệ thống]

**Mã máy HIToolbox** (`dyld_info -arch arm64e -disassemble` trên `HIToolbox` trong dyld cache 27.2, 04/11) [Diễn giải mã máy]:
- `TISDisableInputSource` chỉ khởi tạo một biến thời gian rồi nhảy thẳng sang `TSMDisableInputSource`: hai hàm là một đường; thử `TSMDisableInputSource` riêng không cho gì mới.
- `TSMDisableInputSource` → `_TSMSetInputSourceEnabled` → `TSMDisableInputSource_Internal` (gọi `TSMCanDisableInputSource`) → `islSetInputSourceEnabled` → `isPrefsSetInputSourceEnabled` (đọc danh sách kèm nguồn bên thứ ba bằng `GetInputSourceEnabledPrefsIncludingThirdParty`) → `TIS_CFPreferencesSetValue` → CFPreferences trong tiến trình (cfprefsd).
  - Không có Apple event tới System Settings, không có XPC tới dịch vụ khác.
  - Arion ghi đúng ngăn xếp này trong nhật ký bị từ chối của họ (dưới).
- Khác với Enable (mục 2.2): Enable của bên thứ ba có nhánh gửi yêu cầu cho System Settings để hỏi người dùng; Disable không có nhánh tương ứng, và `KeyboardSettings` chỉ nhận khoá `inputSourceToBeEnabled`.
- `com.apple.hiservices-xpcservice` (dịch vụ XPC trong `HIServices.framework`, không sandbox, không có entitlement storage) có các bộ chọn `HIS_XPC_CFPreferencesSetValue:`/`HIS_XPC_CFPreferencesCopyValue:` và danh sách tên miền/khoá gồm cả `com.apple.inputsources` và `AppleEnabledThirdPartyInputSources`.
  - Nó nhập `xpc_connection_get_pid` nhưng không thấy hàm kiểm entitlement người gọi.
  - Hàm `HIS_XPC_CFPreferencesSetValue` có trong `HIServices.tbd` của SDK nhưng không có header.
  - Chưa xác định danh sách đó dùng cho đọc hay ghi, và dịch vụ có bị chính System Policy chặn không.
  - Không theo hướng này (hướng dịch vụ XPC, bảng các hướng dưới đây).

**Dự án khác** [Ngoài]:
- **Arion** (`docs/research/input-source-onboarding.md`, macOS 26.6.2, 25G83): `System Policy: Arion deny(1) user-preference-write com.apple.inputsources (platform profile)`, ngăn xếp `arion_ime_disable → TSMDisableInputSource → islSetInputSourceEnabled → isPrefsSetInputSourceEnabled → TIS_CFPreferencesSetValue`; danh sách giữ cả hai mục. Họ bỏ gọi `TISDisableInputSource` khi gỡ; chưa xác định mục còn lại có vô hại không.
- **msime** (PR #3765, 05/10/2026, macOS 27, máy thật):
  - `TISDisableInputSource` trả noErr mà không đổi gì khi gọi từ tiến trình ngoài, từ chính binary bộ gõ (kiểu `--disable-input-source` của Squirrel) và từ chính tiến trình IMK đang chạy (kiểu fcitx5-macos).
  - `CFPreferencesSetAppValue` và `defaults import` bị từ chối "with or without the agent sandbox", cùng câu nhật ký cfprefsd như trên.
  - Cách mới: trước khi gỡ, nếu mục còn thì mở Keyboard settings, giữ nguyên bundle, bảo người dùng bấm "–" rồi xác nhận lại.
  - PR #3775: khi tiến trình bộ gõ bị chặn khởi động thì "–" "did nothing"; sau khi bỏ hết mục nhìn thấy còn một mục mode mồ côi (`.Cantonese`) không hiện ở đâu, không ai bỏ được, nên họ chỉ chờ mục cha.
  - Ghi chú 19/10/2026: "macOS 27 不允许输入法进程修改启用列表，bundle 消失后残留条目反而无法在系统设置中显示和删除" (macOS 27 không cho tiến trình bộ gõ sửa danh sách đang bật; bundle mất rồi thì mục còn lại không hiện và không xoá được trong System Settings).
- **ml-ime** (`notes/inputmethodkit.md`, `macos/ContextProbe/Tools/sweep.sh`, PR #90, 28/09/2026; Mac mini macOS 26.6.2 và máy ảo 26.5.2): `defaults write com.apple.inputsources AppleEnabledThirdPartyInputSources -array-add …` "takes effect at once", và họ đã xoá mục rồi thêm lại để kiểm; `TISDisableInputSource` "likewise a no-op".
  - **Mâu thuẫn** với Arion (cùng 26.6.2) và máy này (27.2, `defaults` bị từ chối). Chưa phân xử; khả năng: Terminal của họ có Full Disk Access, hoặc chặn với `defaults` mới có ở 27 [Suy luận, cần kiểm chứng].
- **qingjian** (`apps/macos/pkg/scripts/postinstall`, commit 96a021e, 29/10/2026): `postinstall` của `.pkg` (root) chạy `launchctl asuser <uid> sudo -u <user> defaults write com.apple.inputsources …` để **thêm** mục; commit tự ghi "macOS 27 上未验证" (chưa kiểm trên macOS 27); issue #209 (macOS 27.0 và 27.2) chưa có kết quả.
- **tisutil** (Divvun, `docs/spec/session.md`): khi chạy root cho người dùng không có phiên GUI, ghi `AppleEnabledThirdPartyInputSources` qua cfprefsd, "not by editing the plist file directly, so that the preferences cache does not overwrite it"; spec không ghi bản macOS đã đo.
- **Shanjie** (`docs/contracts/system-install.md`, máy ảo macOS 26.6.2, 21/10/2026): sau `sudo rm -rf` bundle ở `/Library/Input Methods`, TIS thôi liệt kê trong 5 giây nhưng hai mục trong `AppleEnabledThirdPartyInputSources` vẫn còn. Cùng máy ảo thấy hộp thoại `Allow "<caller>" to enable "Shanjie"?`.
- **Trình gỡ và Homebrew** (`formulae.brew.sh/api/cask/<tên>.json`, 04/11):
  - `uninstall`/`zap` của squirrel-app, macskk, mcbopomofo, gureumkim, aquaskk, xkey, keyman, google-japanese-ime, sogouinput, wetype, openkey, evkey chỉ xoá bundle, gói, file tuỳ chọn và bộ đệm của chính app, không cask nào đụng `com.apple.inputsources`.
  - Mã fcitx5-macos (`disableInputMethod` gọi `TISDisableInputSource` cho mục cha; `assets/uninstall.sh` chỉ `rm -rf` và `killall`), Squirrel (`--disable-input-source`), McBopomofo (`InputSourceHelper.disable`), vChewing (`Uninstaller` chỉ chuyển file vào Thùng rác) đều dùng `TISDisableInputSource` hoặc không gì, tức đường đã bị chặn trên 26.6.2 và 27.
  - Không tìm thấy nguồn cho cách làm của AppCleaner hay ứng dụng dọn dẹp khác.

**Diễn đàn và tài liệu Apple:** không tìm thấy bài nào về bỏ nguồn nhập liệu theo lập trình, về System Policy chặn `com.apple.inputsources`, hay về `TISDisableInputSource` trên macOS 26–27 (ba lượt tìm web và trang thẻ InputMethodKit, 04/11; công cụ tìm không lập chỉ mục sâu diễn đàn). Ghi chú phát hành: mục 2.1. Header chỉ nói `TISDisableInputSource` gỡ nguồn khỏi giao diện (mục 2.1). [Apple]

**Các hướng**

| Hướng | Khả thi trên 27.2 | Nguồn | Va chạm | Rủi ro |
|---|---|---|---|---|
| Tắt bằng `TISDisableInputSource`/`TSMDisableInputSource` từ app chủ, từ tiến trình con, hay từ chính bộ gõ | Không | Máy/Dấu 02/11; mã máy ở trên; Arion, msime | — | Trả 0 mà không làm gì: không được báo thành công (N5) |
| Ghi bằng `defaults`/CFPreferences từ tiến trình con, kể cả chạy root (`osascript … with administrator privileges`, `launchctl asuser … sudo -u`) | Không với tài khoản người dùng (đo 02/11); root chưa đo | 02/11; msime; root: không tìm thấy nguồn, chính sách sandbox nền tảng không xét theo uid [Suy luận, cần kiểm chứng] | N4; D6, D37 (Dấu không xin quyền quản trị) | `defaults` chạy root mà quên `sudo -u` ghi miền của root; ghi theo đường dẫn file có thể để lại file chủ root [Suy luận] |
| Sửa thẳng file plist (không qua cfprefsd) | Nhiều khả năng bị chặn; không nên kể cả khi được | Câu nhật ký cfprefsd ở trên; tisutil, logcg (mục 7.1, hướng dừng tiến trình hoặc sửa tay): cfprefsd giữ bộ đệm và có thể ghi đè file sửa ngoài | N4 | File còn chứa mục thật của Dấu và mọi nguồn khác: hỏng là mất cả danh sách |
| Nhờ System Settings: Apple event, URL `x-apple.systempreferences`, từ điển AppleScript, App Intents | Không: chỉ có đường xin **bật** | `KeyboardSettings` chỉ nhận `inputSourceToBeEnabled` (mục 2.2); `SettingsAppleScript.sdef` của System Settings chỉ có lớp `pane`, `anchor`, lệnh `reveal`, `authorize`, `timedLoad`; từ điển System Events không có thuật ngữ nào về nguồn nhập liệu, chỉ có lệnh gửi phím (`keystroke`, `key code`, `key down`, `key up`) dùng cho hướng tự động bấm "–" (`sdef`, 04/11); `KeyboardSettingsIntents` ba hành động không liên quan (đề bài) | — | — |
| Dịch vụ XPC `com.apple.hiservices-xpcservice` (`HIS_XPC_CFPreferencesSetValue`) | Không thử, không theo | Mã máy ở trên | Không chính đáng: API riêng không tài liệu, dùng dịch vụ hệ thống ghi hộ để vượt một lớp bảo vệ; nếu được thì là lỗi bảo mật để báo Apple, không phải tính năng | Vỡ bất cứ lúc nào |
| Hồ sơ cấu hình / MDM | Không | `profiles` từ macOS 11 không cài được hồ sơ cấu hình, phải cài trong System Settings (`man profiles`); người dùng tự mở và duyệt trong Privacy & Security › Profiles (Apple support mh35561), nhiều bước hơn "–"; khai báo `com.apple.configuration.keyboard.settings` (macOS 26.4, chỉ máy supervised) không có khoá nguồn nhập liệu (apple/device-management). Hồ sơ "custom settings" chỉ đặt giá trị bị quản lý đè lên, không xoá mục của người dùng [Suy luận] | N4 | — |
| Tự động bấm "–" (trợ năng hoặc GUI scripting qua System Events) | Kỹ thuật làm được, không nên | Cần quyền Accessibility cho Dấu.app (Privacy & Security › Accessibility, Apple support mh43185; `AXIsProcessTrustedWithOptions`) và, nếu qua System Events, quyền Automation (`NSAppleEventsUsageDescription`, entitlement `com.apple.security.automation.apple-events`) [Apple]. GUI scripting "inherently sensitive to changes in application interfaces from version to version" (người dùng, diễn đàn Apple 131014, 2020); System Settings làm vỡ script cũ từ Ventura (Late Night Software) [Ngoài] | N4 (quyền nhạy cảm, đổi cài đặt hệ thống thay người dùng); câu hỏi "Chrome/Terminal có cần quyền Accessibility không?" trong `DECISIONS.md` đã chốt không xin quyền này vì bảo mật | Bấm nhầm dòng (tên bản địa hoá, nguồn đang chọn không bỏ được), vỡ theo bản macOS; bộ gõ đã thấy mọi phím gõ, thêm quyền điều khiển máy là tăng rủi ro cho người dùng |
| Full Disk Access cho Dấu | Chưa biết | [Suy luận, cần kiểm chứng] từ mâu thuẫn ml-ime/Arion; chỉ đo để chẩn đoán (phép xem Full Disk Access của Terminal và phép chẩn đoán bằng khoá giả, bên dưới) | N4; xin Full Disk Access chỉ để dọn một mục là quá tay | — |
| Hướng dẫn người dùng bấm "–": app mở Keyboard settings, đọc lại `AppleEnabledThirdPartyInputSources` cho tới khi mục cha hết, rồi mới xoá bundle | **Có** | Lần thử gỡ có bấm "–" (mục 8.1b); msime | Đúng N4, D16 | Một thao tác của người dùng; xoá bundle trước thì mục thành ẩn (lần thử gỡ bản `DauProbeC1` không bấm "–", mục 8.1b) |
| Mục đã ẩn: cài lại đúng bundle ID để mục hiện lại, bấm "–", rồi xoá bundle | **Có** (bản thử, 04/11/2026: phép hồi sinh mục ẩn, kết quả cuối mục) | Suy ra từ lần thử gỡ bản `DauProbeC1` không bấm "–" (mục còn, chỉ không hiện vì thiếu bundle); đã đo bằng bản thử [Máy/bản thử] | Đúng N4 | msime #3775: "–" "did nothing" khi tiến trình bộ gõ bị chặn khởi động; bản thử không có tiến trình `DauProbeC1` mà "–" vẫn bỏ được (kết quả cuối mục) |

**Đề xuất xếp hạng** (của người nghiên cứu, 03/11/2026; không còn cần sau khi D37 (Cài đặt bộ gõ) chốt cách bật không đăng xuất):
1. Hướng dẫn người dùng bấm "–" làm đường chính của "Gỡ cài đặt".
2. Cài lại rồi bấm "–" làm đường cứu khi bundle đã bị xoá trước ("cài lại Dấu rồi gỡ bằng nút trong app"); phép hồi sinh mục ẩn đã đạt (kết quả cuối mục).
3. Không làm tám hướng còn lại (từ tắt bằng `TISDisableInputSource` tới Full Disk Access: mọi hướng trong bảng trừ hai hướng trên). Full Disk Access chỉ đo khi cần trả lời trọn câu hỏi đọc được thì có xoá được không, không đưa vào sản phẩm.

**Kế hoạch đo** (cho phiên chính hỏi người dùng rồi chạy; công cụ `scripts/probe/` nhắc dưới đây đã xoá ngày 09/11/2026, lấy lại bằng `git show` như mục 0, điểm 17). Mục tiêu là **mục ẩn của `DauProbeC1`** (bundle đã bỏ; `build/probe.noindex/C/DauProbeC1.app` còn trong thư mục build). Không đụng mục của Dấu thật.
Hai phép đã chạy (xem xét Full Disk Access của Terminal, hồi sinh mục ẩn); các phép còn lại chưa chạy.
Tên file và khoá giả trong lệnh giữ nguyên chữ K1, K2 của kế hoạch gốc (K1 là phép hồi sinh mục ẩn, K2 là phép chẩn đoán Full Disk Access).

- **Phép xem Full Disk Access của Terminal** (một phút, không ghi gì): người dùng xem System Settings › Privacy & Security › Full Disk Access có bật cho Terminal không. Nếu Terminal đã có Full Disk Access khi `defaults import` bị từ chối ngày 02/11 thì Full Disk Access không mở khoá miền này: đóng hướng Full Disk Access, bỏ phép chẩn đoán bằng khoá giả.
- **Phép hồi sinh mục ẩn, rồi bỏ bằng "–"** (khoảng 3 phút, chiếm màn hình; cũng là cách dọn `DauProbeC1` khỏi máy):
  1. Sao lưu để đối chiếu (chỉ đọc): `defaults export com.apple.inputsources ~/Desktop/dau-K1-before.plist`; `scripts/probe/cleanup.sh` (không tham số) để liệt kê.
  2. Chép lại: `ditto build/probe.noindex/C/DauProbeC1.app ~/Library/Input\ Methods/DauProbeC1.app` (`step.sh` từ chối ID đã dùng nên chép tay).
  3. `build/probe.noindex/bin/tis-act register ~/Library/Input\ Methods/DauProbeC1.app`; xoá `$(getconf DARWIN_USER_CACHE_DIR)/com.apple.Keyboard-Settings.extension/com.apple.IntlDataCache.le*`; `open "x-apple.systempreferences:com.apple.Keyboard-Settings.extension"` (như lần thử chỉ xoá bộ đệm, mục 8.1b).
  4. Ghi lại: "Dấu thử C1" có ở danh sách bên trái của Edit… và menu nhập liệu không (người dùng xem); `pgrep -fl DauProbeC1` (tiến trình có chạy không); `build/probe.noindex/bin/tis-probe`.
  5. Người dùng chọn "Dấu thử C1", bấm "–". Đọc `defaults export com.apple.inputsources -`: cả mục cha và mục mode `….DauProbeC1.vi` còn không (để ý mục mode mồ côi như msime).
  6. `scripts/probe/cleanup.sh --yes` (script tự dừng nếu mục còn trong khi bundle còn cài). Có thể dọn luôn `DauProbeC2` cùng lượt: bấm "–" cho "Dấu thử C2" trước bước này.
  - Đọc kết quả: `DauProbeC1` hiện lại và "–" bỏ được cả hai mục khi tiến trình không chạy → hướng cài lại rồi "–" dùng được, và "–" không cần tiến trình bộ gõ đang chạy. `DauProbeC1` không hiện → mục ẩn chỉ hết khi có cách khác (chưa biết); ghi lại, không thử thêm.
  - Trả lại: nếu không bỏ được thì `cleanup.sh --yes` đưa máy về đúng trạng thái trước phép này (mục ẩn, không bundle). Không `defaults import` bản sao lưu (miền này từ chối ghi; bản sao lưu chỉ để so).
- **Phép chẩn đoán Full Disk Access** (chỉ khi phép xem cho thấy Terminal chưa có Full Disk Access và người dùng muốn; đổi một cài đặt bảo mật trong vài phút). Dùng một **khoá giả**, không đụng danh sách nguồn: chính sách chặn theo cả miền (`user-preference-write com.apple.inputsources`), nên một khoá giả kiểm đúng quyền đó.
  1. Sao lưu: `cp -p ~/Library/Preferences/com.apple.inputsources.plist ~/Desktop/dau-K2-backup.plist`.
  2. Đối chứng, Terminal chưa có Full Disk Access: `defaults write com.apple.inputsources DauK2Probe -bool YES; echo $?`, rồi `defaults read com.apple.inputsources DauK2Probe` (tiến trình mới) và `/usr/bin/log show --last 2m --predicate 'eventMessage CONTAINS "inputsources"'`. Mong đợi: từ chối như 02/11.
  3. Người dùng bật Full Disk Access cho Terminal, mở lại Terminal, lặp bước 2.
  4. Nếu ghi được: `defaults delete com.apple.inputsources DauK2Probe`; so `defaults export com.apple.inputsources -` với bản sao lưu (chỉ khác khoá giả, đã xoá).
  5. Người dùng tắt lại Full Disk Access cho Terminal.
  - Biến thể (tuỳ chọn, hỏi mật khẩu quản trị): đường của qingjian, `osascript -e 'do shell script "launchctl asuser <uid> sudo -u <user> defaults write com.apple.inputsources DauK2Probe -bool YES" with administrator privileges'`, rồi đọc và xoá như trên.
  - Đọc kết quả: chỉ có Full Disk Access mới ghi được → giải thích ml-ime, hướng Full Disk Access vẫn không đưa vào Dấu. Ghi được cả khi không có Full Disk Access → máy đã khác 02/11, phải đo lại hướng ghi bằng `defaults` trước khi kết luận gì.
- **Ghi thẳng file**: không khuyến nghị trên tài khoản này (file chứa mục thật của Dấu; cfprefsd có thể ghi đè). Nếu cần, chỉ trên tài khoản thử của kế hoạch thử trên máy sạch (mục 7.2), cũng với khoá giả, sao lưu như phép chẩn đoán Full Disk Access.

**Kết quả (04/11/2026)** [Máy/bản thử]:
- **Phép xem Full Disk Access của Terminal:** Full Disk Access của Terminal.app đang **bật**; Ghostty.app có trong danh sách, **tắt** (ảnh của người dùng). Không biết `clean-dau.sh --yes` ngày 02/11 chạy trong ứng dụng nào, và `log show` không còn dòng từ chối của ngày đó, nên hướng Full Disk Access chưa đóng được bằng phép này.
- **Phép hồi sinh mục ẩn** (bỏ bước sao lưu 1 và phần nhìn menu của bước 4):
  - 13:58:12 chép lại `DauProbeC1`, `register` (0), xoá bộ đệm, mở Keyboard.
  - TIS tiến trình mới báo ngay cha và mode `enabled`, mode chọn được (mục ẩn làm `DauProbeC1` "đang bật" lại, không có hộp thoại xin phép); không có tiến trình `DauProbeC1`.
  - Người dùng bấm "–" ở "Dấu thử C1": `com.apple.inputsources` ghi lúc 14:02, không còn mục nào của `DauProbeC1` (cả cha và mode). → **hướng cài lại rồi "–" dùng được**, và "–" không cần tiến trình bộ gõ đang chạy.
  - Sau đó người dùng bỏ `DauProbeC2` bằng "–", `scripts/probe/cleanup.sh --yes` dọn mọi bản thử (A2–A4, B1, B2, C1, C2) khỏi `~/Library/Input Methods`, bộ đệm xoá; `cleanup.sh` báo "Không còn biến thể nào", miền chỉ còn mục của Dấu.
- Hệ quả: mục ẩn để lại vẫn dọn được về sau bằng cài lại cùng ID rồi "–"; cài lại cùng ID khi còn mục ẩn thì nguồn được bật ngay, không hỏi.
- **Đọc lại sau lần đăng xuất kế tiếp** (không tốn gì): nếu phép hồi sinh chưa chạy trước lần đăng xuất tự nhiên kế tiếp, sau khi đăng nhập lại đọc `defaults export com.apple.inputsources -` xem mục `DauProbeC1` còn không (msime và Shanjie cho thấy mục không tự mất, chưa đo trên máy này). Phép hồi sinh đã chạy và dọn `DauProbeC1`, nên phép này chỉ làm được nếu tạo lại một mục ẩn (mục 10.8).

## 5. Bộ gõ tiếng Việt cũ cần phát hiện (D14 (Onboarding) bước 1)

Bundle ID lấy từ `Info.plist` của bản phát hành tải về từ URL trong cask Homebrew. Chỉ giải nén hoặc mount chỉ đọc, không chạy. [Ngoài, Info.plist bản phát hành, 30/10/2026]

| Bộ gõ | Bundle ID app chính | Tiến trình | Bản | Thoát | Tự chạy khi đăng nhập |
|---|---|---|---|---|---|
| OpenKey | `com.tuyenmai.openkey` | `OpenKey` | 2.0.5 | biểu tượng trên thanh menu › "Thoát" (⌘Q) | tuỳ chọn "Khởi động cùng macOS" trong "Bảng điều khiển…"; helper `com.tuyenmai.OpenKeyHelper` (`SMLoginItemSetEnabled`), thêm `com.tuyenmai.OpenKeyUpdate` |
| EVKey | `com.lamquangminh.evkey` (file `EVKeyMac.app`) | `EVKey` | 3.3.10 | có chuỗi "Quit EVKey" | helper `com.lamquangminh.evkeyhelper` trong `Contents/Library/LoginItems` |
| GoTiengViet | `com.trankynam.GoTiengViet` | `GoTiengViet` | 2.4 (có sandbox) | có chuỗi "Quit GoTiengViet" | chưa rõ |
| XKey | `com.codetay.XKey`; kèm bộ gõ IMK `com.codetay.inputmethod.XKey` (tiến trình `XKeyIM`, cài vào `~/Library/Input Methods`) | `XKey` | 1.2.25 | "Thoát XKey" | tuỳ chọn "Khởi động cùng hệ thống" |
| PHTV | `com.phamhungtien.phtv` | `PHTV` | 3.7.1 | có chuỗi "Quit PHTV" | tuỳ chọn "Khởi động cùng macOS" (`SMAppService`) |
| Gõ Nhanh | `org.gonhanh.GoNhanh` | `GoNhanh` | 1.0.165 | chưa rõ nhãn | có "Launch at login" |
| GoKey (goxkey) | `com.goxkey.app` (theo `Cargo.toml`, chưa kiểm bản build) | — | 0.3.1 | — | — |
| Bộ gõ tiếng Việt của Apple | `com.apple.inputmethod.VietnameseIM`; mode `….VietnameseTelex`, `….VietnameseSimpleTelex`, `….VietnameseVNI`, `….VietnameseVIQR`; bàn phím `com.apple.keylayout.Vietnamese` | là nguồn nhập liệu, không phải app chạy nền | — | — | — |

- **UniKey:** không có app macOS. Engine của nó được tặng Apple năm 2006 và nằm trong bộ gõ tiếng Việt có sẵn của macOS [Ngoài, unikey.org/en/apple.html].
- **VietKey:** không tìm thấy bản macOS. **Laban Key:** chỉ có Android, iOS và tiện ích ChromeOS [Ngoài, tìm kiếm 30/10/2026]. Không đưa ba cái này vào danh sách.
- Cask `openkey` và `evkey` đang ở trạng thái disabled trên Homebrew, nhưng người dùng cũ vẫn còn cài nên vẫn phải phát hiện.
- OpenKey, EVKey, GoTiengViet không phải IMK mà chặn phím bằng event tap; không đăng ký nguồn nhập liệu nên không có gì để so ở mục 2.
  - Tracker của EVKey, GoTiengViet (mã đóng): không có báo cáo cài/bật/gỡ trên macOS 26/27; tracker OpenKey, vChewing: không thấy trong kết quả tìm.
  - Kawa, InputSourcePro chỉ chuyển nguồn, không cài bộ gõ, không đọc. Không tìm thấy ghi chú cài đặt của MacishType.
- **Cách phát hiện:**
  - Bộ gõ chặn phím bằng event tap (OpenKey, EVKey, GoTiengViet, XKey, PHTV, Gõ Nhanh, GoKey) biến đổi phím **bất kể nguồn nhập liệu nào đang được chọn**, nên gõ chồng với Dấu. Đây là xung đột thật.
    - Tìm bằng `NSWorkspace.shared.runningApplications`, so `bundleIdentifier`, và chỉ tính tiến trình của người dùng hiện tại (OpenKey tự lọc theo uid vì có chế độ chuyển nhanh người dùng).
    - Đối chiếu bằng bundle ID, không bằng tên tiến trình.
  - Bộ gõ IMK khác (Telex của Apple, `XKeyIM`) chỉ xử lý phím khi chính nó đang được chọn, nên không gõ chồng.
    - Tìm bằng TIS: nguồn đang bật có ngôn ngữ `vi`, khác Dấu.
    - Chỉ nên nhắc nhẹ ("có thể bỏ khỏi danh sách cho gọn"), không chặn bước 1. Máy 30/10 đang bật Telex của Apple.
  - Mục đăng nhập của app khác: không có API công khai để đọc. Chỉ hướng dẫn.
- **Hướng dẫn tắt (N4):**
  1. Trong app đó, tắt "Khởi động cùng macOS/hệ thống" nếu có. Phải làm trước khi thoát, vì helper sẽ bật lại tuỳ chọn và mở lại app ở lần đăng nhập sau.
  2. Bấm biểu tượng trên thanh menu › "Thoát".
  3. Nếu vẫn tự chạy lại: Cài đặt chung › Mục đăng nhập & Phần mở rộng, tắt app đó.
  - Kiểm tra lại khi cửa sổ onboarding được kích hoạt (`docs/UI.md`).
  - Không tự thoát app của người khác: trái N4, và cũng không làm được nếu app chủ có sandbox.

## 6. Hệ quả cho Dấu và tình trạng các đề xuất cho DECISIONS

### 6.1 Điều onboarding và gỡ cài đặt có thể dựa vào
Chỉ liệt kê điều có nguồn ở trên; nối về D và N chỉ để tra, không đổi quyết định.
1. **Nút "Bật Dấu" không thể hứa là bật được** (N4, N5): `TISEnableInputSource` của bên thứ ba nhờ Cài đặt hỏi và trả 0 (mục 2.2); marinaMoji cha vẫn `enabled=0`; Squirrel (26.2) người dùng thêm bằng "+".
   - Bắt buộc đọc lại trạng thái sau khi bật (mục 2.6), và có đường lui "mở Cài đặt › Bàn phím, bấm '+'" luôn đúng.
2. **Không hứa có hộp thoại "Cho phép" trên mọi máy**: trên máy này nó chỉ hiện khi làm theo D37 (mục 9.9, 8.1b).
   - Nhật ký cho thấy Cài đặt bỏ qua yêu cầu mà không hỏi khi không dựng lại được nguồn, hoặc khi trang Keyboard đang mở sẵn (mục 2.2, 8.1b).
3. **Không dùng cờ "enabled" từ tiến trình của chính app làm bằng chứng** (mục 2.6). Người dùng chuyển sang Dấu bằng phím tắt của hệ thống; app không chọn Dấu sau khi bật.
   - N4 (`docs/DECISIONS.md`) không có câu cấm "tự chọn nguồn": N4 chỉ cho đổi cài đặt hệ thống khi người dùng bấm đúng nút ("Bật Dấu", "Gỡ cài đặt"), luôn có Hoàn tác hoặc xác nhận, và không bao giờ tự làm.
   - Mã hiện chọn một bàn phím ASCII khi Dấu đang được chọn, ngay trước khi gỡ cài đặt và trước Hoàn tác (`selectOtherKeyboardIfDauIsCurrent` trong `InputMethodInstaller.swift`). Việc đó nằm trong nút "Gỡ cài đặt" hoặc "Hoàn tác" mà người dùng đã bấm, nhưng có tính là "đổi cài đặt hệ thống" theo N4 hay không là điều chờ người dùng quyết.
4. **Đăng xuất:**
   - Trên macOS 27.2, bật lần đầu không cần đăng xuất khi làm theo D37 (mục 2.3, 9.9); đăng xuất rồi đăng nhập là đường lui khi một app vẫn không chọn được Dấu (mục 9.12). Các bản macOS khác chưa đo (mục 10.1).
   - Cho tới khi có số đo trên bản macOS khác và bản ký Developer ID, chữ trên giao diện về đăng xuất chỉ nói điều đã đo (N5); cách an toàn là "nếu không thấy Dấu trong '+', đăng xuất rồi đăng nhập" như phương án chờ.
   - Artboard `OnboardingLogout` được vẽ theo kết luận "bắt buộc đăng xuất" đã bỏ; nó không còn trên trang Thiết kế của canvas (`docs/ui/canvas/README.md`).
   - App không tự đăng xuất (N4) và phải nhớ đang ở bước 2 để lần mở sau làm tiếp; macOS có tuỳ chọn "Reopen windows when logging back in" nên app đang mở có thể được mở lại [Suy luận, cần kiểm chứng].
   - Nút "Đăng xuất…" mở hộp thoại hệ thống cần cách gọi mà không đòi quyền Tự động hoá (AppleScript tới System Events cần quyền đó: chưa kiểm); nếu không thì chỉ hướng dẫn "menu Apple › Đăng xuất…".
5. **Gỡ:** tắt từ Cài đặt (nút "–") có hiệu lực; `TISDisableInputSource` từ app bị chặn ghi (mục 4), và app không có cách chính đáng nào khác để bỏ mục (mục 4.1).
   - Vì vậy bundle phải còn cho tới khi mục cha hết khỏi `AppleEnabledThirdPartyInputSources`; xoá bundle trước thì mục thành ẩn và người dùng không bỏ được nữa (lần thử gỡ bản `DauProbeC1` không bấm "–", mục 8.1b; cài lại cùng ID rồi "–" dọn được, mục 4.1).
   - Tên có thể còn trong Cài đặt sau khi xoá file; đừng hứa là hết.
6. **Không có hợp đồng công khai:** mọi thứ có thể đổi theo bản macOS. Ghi bản macOS đã thử bên cạnh mỗi câu hướng dẫn.
7. **Dựng lại ảnh chụp trong tiến trình** (mục 7.1, hướng dựng lại ảnh chụp): sau `Register`, tra bằng tiến trình con mới và thăm dò đến 20 giây (kiểu Squirrel/tabulador) rồi đọc lại bằng tiến trình mới; không đụng hệ thống, chi phí nhỏ, nên đọc đúng trạng thái dù kết quả thử có thế nào. [Suy luận, cần kiểm chứng]

### 6.2 Đề xuất cho DECISIONS từ nghiên cứu ngày 30/10, tình trạng đọc ngày 03/11/2026
- App chủ không sandbox: đã vào **D37**.
- N4 cho D14 bước 2 (chép/đăng ký là phần cài đặt; bật chỉ khi người dùng bấm, có Hoàn tác; đọc lại trạng thái): **N4** đã sửa 30/10/2026.
  - Câu "không tự chọn nguồn" của đề xuất cũ **không** nằm trong N4 (xem mục 6.1 điểm 3).
  - Phương án thay thế giống msime (bỏ nút bật, chỉ hướng dẫn) còn mở.
- Danh sách định danh không đổi giữa các bản (mục 3): đã vào **D37**.
- Cask chỉ có `app`, `uninstall` gọi lệnh gỡ của app, `zap` xoá container (mục 1.4): đã vào **D37** (cask chỉ khai `app`); chi tiết `uninstall`/`zap` chưa thấy trong `DECISIONS.md`.
- **Chưa thấy trong `DECISIONS.md`:**
  - D14 bước 1 chỉ coi bộ gõ chặn phím đang chạy là xung đột, bộ gõ IMK tiếng Việt khác chỉ nhắc nhẹ (mục 5);
  - D7 thay bộ gõ bằng chép tạm rồi đổi chỗ cả khối, dừng bằng thông báo Darwin, không đụng `imklaunchagent` và bộ đệm hệ thống, chấp nhận biểu tượng cũ còn tới khi đăng xuất (mục 3);
  - D16 trình tự gỡ ở mục 4.
  - Cần người dùng chốt.
- Hướng dẫn trên giao diện (N5): câu về đăng xuất, hộp thoại "Cho phép", và "Bàn phím đang dùng trước đó được giữ nguyên" để dạng ô trống cho tới khi kiểm xong bằng Dấu thật (lần thử trên máy sạch ở mục 7 đã bỏ).

## 7. Kế hoạch thử lại bằng Dấu thật trên máy sạch (một lần đăng xuất)

**Hiện trạng (04/11/2026): bỏ, người dùng chốt không làm lần thử trên máy sạch này.** Phần còn giá trị của mục này đã được trả lời bằng Dấu thật trên tài khoản đang dùng (mục 9.9–9.11). Phần dưới giữ làm tham khảo.

Mục đích: trả lời câu hỏi mở về lần cài đầu có phải đăng xuất để "+" thấy ID mới (mục 10.1), bằng Dấu thật, **nhìn danh sách "+" bằng mắt**. Cần người dùng vì đổi nguồn nhập liệu, chiếm màn hình, đăng xuất.

### 7.1 Các hướng có thể làm hiện nguồn không cần đăng xuất (ước lượng, chưa đo)

Xếp hạng là ước lượng của người nghiên cứu từ bằng chứng ở mục 2, **chưa đo**. "Khả năng" là khả năng làm Dấu hiện ra không cần đăng xuất.
- Ba hướng đầu (cài vào `/Library/Input Methods`, làm mới tiến trình và bộ đệm giao diện, dựng lại ảnh chụp trong tiến trình) nằm trong vòng thử bằng bản thử (mục 8.2).
- Hướng chọn nguồn bằng TIS để chẩn đoán.
- Hướng dừng tiến trình hệ thống hoặc sửa tay không bao giờ vào Dấu.

| Hướng | Khả năng | Bằng chứng | Va chạm sổ quyết định |
|---|---|---|---|
| **Cài vào `/Library/Input Methods`** (cần quyền quản trị: `.pkg` hoặc `osascript … with administrator privileges`) rồi đăng ký | Trung bình (đáng thử nhất vì có một bằng chứng dương duy nhất) | marinaMoji (mục 2.3); nhưng Squirrel, macSKK, fcitx5, Gureum cũng cài ở đó mà vẫn bảo đăng xuất. Rủi ro: hộp thoại mật khẩu quản trị, gỡ cũng cần quản trị, Homebrew/Sparkle phải xử lý quyền | **D16** (`~/Library/Input Methods`), **D6** (DMG, không `.pkg`), **D37**; cần người dùng chốt nếu thành công |
| **Làm mới tiến trình/bộ đệm giao diện** sau khi đăng ký và bật: dừng `TextInputMenuAgent` (chờ 0,5 s), `TextInputSwitcher`, `CursorUIViewService`, thoát Cài đặt, dừng extension Bàn phím, xoá `com.apple.IntlDataCache.le*` | Thấp tới trung bình cho **menu**; thấp cho "+" với ID mới | vChewing (mã, không số đo); msime đo trên 27.0/27.0.1: không giúp ID mới, giúp mode mới của ID đã biết. LaunchAgent tự dựng lại tiến trình bị dừng. Đụng tiến trình và bộ đệm hệ thống, thoát Cài đặt có thể làm mất trạng thái đang mở, không có API chính thức, có thể vỡ ở bản macOS sau | **N4** (chỉ chạy khi người dùng bấm một nút rõ ràng, "Làm mới danh sách", có xác nhận); mục 3 ("Không làm") và D37 tránh việc này (đọc 03/11/2026; từ 04/11/2026 D37 xoá bộ đệm của System Settings khi "Bật Dấu", mục 9.9) |
| **Dựng lại ảnh chụp trong tiến trình**: sau `Register`, tra bằng tiến trình con mới (kiểu Squirrel: mỗi lệnh một tiến trình) và thăm dò đến 20 giây (kiểu tabulador); bật cha, đợi mode xuất hiện, bật mode, đọc lại bằng tiến trình mới | Thấp để làm hiện giao diện, nhưng nên làm để đọc đúng trạng thái | tabulador sửa lỗi tương tự bằng thử lại; Squirrel mỗi lệnh một tiến trình. Không đụng hệ thống | Không |
| **"Đã bật, chờ đăng xuất" làm đường chính** (đề xuất 03/11/2026, không chọn; D37 chốt cách bật không đăng xuất): ghi nhớ trạng thái; mở lại Dấu sau đăng nhập; nút hoặc hướng dẫn đăng xuất | Đúng nếu Apple DTS đúng; không tránh được đăng xuất (câu hỏi mở về đăng xuất còn mở lúc đó, D37 ghi "có thể") | Mục 2.3 | **N4**; artboard `OnboardingLogout` (trên canvas, không có trong `docs/UI.md`) chờ duyệt, vẽ theo kết luận "bắt buộc đăng xuất" đã bỏ |
| **Chọn nguồn bằng TIS** (`TISSelectInputSource`) sau khi bật, để `imklaunchagent` dựng tiến trình bộ gõ | Rất thấp | marinaMoji: `-50` (paramErr) dù mode đã bật | **N4** không có câu cấm riêng việc chọn nguồn (mục 6.1 điểm 3); chọn Dấu sau khi bật không gắn với nút nào hiện có, nên chỉ đo như chẩn đoán |
| **Dừng tiến trình hệ thống, sửa tay**: dừng `imklaunchagent` hoặc `keyboardservicesd`, `killall cfprefsd`, sửa tay `AppleEnabledThirdPartyInputSources` hay `com.apple.HIToolbox` | Rất thấp | msime: không giúp. vChewing: dừng `imklaunchagent` làm app đang gõ mất kết nối. logcg (blog, Mojave): sửa plist rồi dừng `cfprefsd` "thường không được". Nguy hiểm | **N4** vi phạm rõ; **không làm** |

Thứ tự **đề xuất** (của người nghiên cứu, 03/11/2026; đã thay bằng D37):
- Làm hướng dựng lại ảnh chụp và hướng "đã bật, chờ đăng xuất" vì rẻ và không va chạm quyết định nào; đề xuất đưa vào M5.
  - Hướng chờ đăng xuất chỉ nên thành đường chính nếu lần thử trên máy sạch cho thấy phải đăng xuất (D37 ghi "có thể", mục 6.1 điểm 4).
- Chạy vòng thử bằng bản thử ở mục 8.2 trước (người dùng chốt 04/11/2026: mục tiêu là tránh đăng xuất) để xem hướng nào trong ba hướng đầu có tác dụng, rồi thử lại bằng Dấu thật trên máy sạch (mục này).
- Nếu hướng cài vào `/Library/Input Methods` cho kết quả "hiện ngay, không đăng xuất", đó là thay đổi D16/D6/D37 và phải qua người dùng.
- Nếu hướng làm mới tiến trình/bộ đệm làm menu hiện ra mà không cần "+", cân nhắc nút "Làm mới danh sách" (vẫn trong N4), kèm ghi chú phát hành cho từng bản macOS.

### 7.2 Chuẩn bị (một lần)
1. Tạo tài khoản macOS mới (chưa từng cài Dấu hay biến thể nào; `docs/PROGRESS.md` 02/11/2026: chỉ dịch vụ nguồn nhập liệu ghi được `com.apple.inputsources`, nên muốn máy sạch thật thì dùng tài khoản mới, mục 2.6), đăng nhập, chờ khoảng một phút cho phiên ổn định. Không cài gì vào `~/Library/Input Methods` trước.
2. Chạy `scripts/dev/clean-dau.sh` (không tham số, chỉ liệt kê) làm mốc "không có Dấu".
3. Mở Terminal thứ hai chạy nhật ký liên tục, ghi vào file có giờ:
   `/usr/bin/log stream --info --debug --style compact --predicate 'process IN {"imklaunchagent","TextInputMenuAgent","TextInputSwitcher","keyboardservicesd","CursorUIViewService","cfprefsd","KeyboardSettings"} OR eventMessage CONTAINS[c] "inputsource" OR eventMessage CONTAINS[c] "codefastlabs.dau"' > ~/dau-t4-log.txt`
   - Tên tiến trình và bộ lọc [Suy luận, cần kiểm chứng]: chỉnh khi chạy; dữ liệu `<private>` bị che nếu không cài hồ sơ ghi nhật ký.
   - `KeyboardSettings` thêm vào để bắt dòng "Invalid value on inputSourceToBeEnabled", mục 2.2.
   - Tên file `~/dau-t4-log.txt` giữ nguyên như kế hoạch gốc ("t4" là tên cũ của lần thử trên máy sạch này).
4. Ghi giờ đồng hồ vào một file ghi chú mỗi khi bắt đầu một bước, để đối chiếu với nhật ký.

### 7.3 Các bước thử
Mục 7 có hai bước (đối chứng bằng Dấu thật, và đăng xuất); các bước của vòng thử bằng bản thử có bảng riêng ở mục 8.2.
Mỗi bước: cài, làm đúng chuỗi, chờ 10 giây, rồi chạy bảng kiểm 7.4. Đặt kết quả là `HIỆN` (xuất hiện trong menu/"+"/danh sách bên trái) hoặc `KHÔNG`.

| Bước | ID | Chuỗi gọi | Mục đích | Mức xâm lấn |
|---|---|---|---|---|
| Đối chứng | **Dấu thật** | **Đối chứng**: đúng luồng "Bật Dấu" của app hiện tại (chép bằng đổi tên nguyên khối, `Register`, đợi 1 s, bật cha, đọc lại cùng tiến trình). **Nhìn "+" bằng mắt**, cả menu, danh sách trái, ⌃Space. Chụp `defaults export com.apple.inputsources -` trước và sau lệnh bật | Tái hiện lần thử cài đầu 02/11 (mục 9.5) trên máy sạch; trả lời câu hỏi mở về đăng xuất (mục 10.1) cho Dấu | Không |
| Đăng xuất | (tất cả) | **Đăng xuất, đăng nhập lại (lần duy nhất).** Chạy `scripts/dev/clean-dau.sh` (không tham số) ngay khi vào, rồi nhìn giao diện | Xác nhận đối chứng: ID nào hiện sau đăng nhập, ID nào đã được bật sẵn | Không |

### 7.4 Bảng kiểm sau mỗi bước
1. Cài đặt › Bàn phím › Nguồn nhập liệu › Sửa…: danh sách bên trái, và hộp thoại "+" (tìm "Dấu" ở nhóm tiếng Việt và ô tìm kiếm) (chụp ảnh). **Nhìn bằng mắt.**
2. Menu nhập liệu trên thanh menu, và công tắc ⌃Space (hoặc phím chuyển nguồn): có "Dấu" không (chụp ảnh).
3. Có hộp thoại "Cho phép … bật …?" của hệ thống hiện không; Cài đặt có tự mở không; hiện ở đâu; bấm gì (ghi lại cả khi không hiện).
4. `scripts/dev/clean-dau.sh` (không tham số): mục Dấu trong `com.apple.inputsources`, tiến trình, bundle, đăng ký LaunchServices. Ghi thêm `AppleInputSourceUpdateTime` từ `defaults export com.apple.inputsources -`.
5. Nhật ký `/usr/bin/log stream` trong khoảng giờ của bước: các dòng của `imklaunchagent`, `TextInputMenuAgent`, `cfprefsd`, `KeyboardSettings` (nhất là "Invalid value on inputSourceToBeEnabled") và nhật ký `com.codefastlabs.dau` của app (`event=register`, `event=enable`).

Mẫu ghi một dòng cho mỗi bước: `bước | mã trả về Register/Enable | "+" | menu | ⌃Space | hộp thoại / Cài đặt tự mở | tuỳ chọn có (Y/N) | ghi chú`.

### 7.5 Cách đọc kết quả
- **Đối chứng đã HIỆN ngay (không đăng xuất):** câu trả lời cho Dấu là "không cần" trên bản macOS đó; ghi bản macOS.
- **Chỉ bước đăng xuất làm hiện:** xác nhận kết luận của Apple DTS cho Dấu; đề xuất làm hướng dựng lại ảnh chụp và hướng "đã bật, chờ đăng xuất" (mục 7.1, chờ người dùng quyết) và đóng việc này.
- **Đối chứng hiện trong "+" nhưng nguồn vẫn không bật được** (bật từ app trả 0, mục cha còn `enabled=0`, hoặc người dùng thêm bằng "+" rồi vẫn không dùng được): đây là hành vi của Enable ở mục 2.2, không phải câu trả lời cho câu hỏi về đăng xuất.
  - Ghi riêng hai kết quả ("có hiện trong '+'" và "bật được"), và nút "Bật Dấu" vẫn không được hứa bật được (mục 6.1 điểm 1).
- **Máy vẫn còn mục Dấu cũ** (`scripts/dev/clean-dau.sh` không tham số báo `AppleEnabledThirdPartyInputSources` còn mục Dấu, hoặc Dấu "tự có sẵn" ngay sau đăng nhập): kết quả không dùng được để trả lời câu hỏi về đăng xuất, vì chỉ tài khoản macOS mới là sạch thật (mục 7.2, 2.6); làm lại trên tài khoản mới.

### 7.6 Việc còn lại ngoài vòng thử
- Gỡ bản Debug rồi chép lại, **cùng ID** và giữa phiên: TIS có thấy ngay không? Chưa đo.
- (M7) Bản ký Developer ID đã notarize có quarantine: bộ gõ có chạy không, có bị translocate không; và hộp thoại "Cho phép … bật …?" có hiện với bản đó không.
- `TISDisableInputSource` lên mode đang được chọn: hệ thống chuyển sang nguồn nào (mục 4, bước 1).
- Lần thử trên máy sạch (tài khoản macOS mới): đã bỏ, không đo (D37). Vòng thử bằng bản thử (mục 8.2) đã chạy thay.

## 8. Quan sát bằng bản thử (không phải Dấu, không kết luận)

Mọi quan sát ở mục này đo bằng bản thử, **không phải Dấu**: không rút kết luận về Dấu từ đây; kết luận về Dấu chỉ nằm ở mục 0 và mục 9. Công cụ thử đã xoá khỏi repo (mục 0, dòng "Công cụ thử").

### 8.1 Quan sát (03/11/2026)

Bản thử là bản sao `DauInputMethod.app` Release, đổi bundle ID, ID mode, tên kết nối và tên hiển thị, ký Apple Development. Chưa kiểm bản thử có tái hiện đúng hành vi của Dấu không.
Trạng thái đọc bằng `TISCreateInputSourceList` trong một tiến trình dòng lệnh mới (cách đọc từng sai, mục 2.6), trừ chỗ ghi "người dùng xem".
Ngày 03/11/2026, macOS 27.2, mỗi biến thể một bản ở `/Library/Input Methods` và một bản ở `~/Library/Input Methods`. Đã gỡ hết bản thử khỏi máy. [Máy/bản thử]

- ID không chứa `.inputmethod.` (`com.codefastlabs.dau.probe.…`): TIS không liệt kê, trước và sau một lần đăng nhập; danh sách "+" không có (người dùng xem).
- ID `com.codefastlabs.dau.inputmethod.Probe…`: TIS liệt kê ngay sau `TISRegisterInputSource`. Danh sách "+" chưa xem.
- `TISEnableInputSource` cho bản thử trả 0, mục cha vẫn tắt, `com.apple.inputsources` không đổi.
  - Gọi từ công cụ dòng lệnh hay từ một app thử có bundle (không sandbox) đều không có hộp thoại xin phép; với app thử, Cài đặt hệ thống tự mở mục Bàn phím (người dùng xem).
- Nhật ký `KeyboardSettings` (cùng truy vấn `/usr/bin/log show` ở mục 2.2):
  - 03/11 08:42:17.603 "Invalid value on inputSourceToBeEnabled" sau lệnh `probe-tis enable` lúc 08:42:16;
  - 08:44:56.610 cùng lỗi sau lần app thử có bundle gọi bật lúc 08:44:55;
  - cùng truy vấn còn thấy hai lần `handleOpenParameter` không kèm lỗi (03/11 08:43:23 và 08:46:12), chưa phân biệt nguồn.

### 8.1b Các vòng thử cài, bật, gỡ (04/11/2026, `scripts/probe/`, tài khoản đang dùng, không đăng xuất)

Mỗi bản thử có tên `DauProbe<chữ><số>` (hiển thị "Dấu thử <chữ><số>"); chữ chỉ vòng thử dựng ra nó, số là thứ tự trong vòng.
Các vòng thử:
- **Vòng cài, đăng ký, bật và làm mới bộ đệm của System Settings:** `DauProbeA1`–`A4`.
- **Vòng tách từng thao tác làm mới bộ đệm:** `DauProbeB1`–`B3`.
- **Vòng bật ngay sau khi xoá bộ đệm:** `DauProbeC1`, `C2`.
- **Vòng gỡ:** bản `A1`, `B3`, `C1` ở trên.
- **Vòng từ chối hộp thoại rồi thử lại:** `DauProbeD1`.
- **Vòng bộ đệm riêng của app có sandbox:** bản thử `E1`–`E4` và một app thử có sandbox.

**Vòng cài, đăng ký, bật và làm mới bộ đệm.**
Bản thử `DauProbeA1`–`A4` dựng từ bản Release `22948d9` (Dấu ngày 02/11), đổi ID theo mục 8.2, ký Apple Development; chép vào `~/Library/Input Methods`.
Trạng thái đọc bằng `tis-probe` (tiến trình mới); "+" là người dùng xem (System Settings › Keyboard › Input Sources › Edit… › "+" › Vietnamese).
Nhật ký từng lệnh: `build/probe.noindex/logs/A-steps.log` (không vào repo). [Máy/bản thử]

| Lần thử | Bản | Lời gọi (mã trả về) | TIS tiến trình mới | `com.apple.inputsources` | "+" |
|---|---|---|---|---|---|
| 09:41, chỉ đăng ký | A1 | `Register` (0) | cha và mode có, liệt kê ngay | rỗng | không có (người dùng xem) |
| 09:46, đăng ký rồi bật cha và mode trong một tiến trình | A2 | `Register`, cha liệt kê ở lần hỏi đầu, `Enable` cha (0), mode (0); 0,3 s | có | rỗng | không có A1, A2 |
| 09:46, ba tiến trình | A3 | ba tiến trình: `Register` (0), `Enable` cha (0), mode (0); `KeyboardSettings` ghi "Invalid value on inputSourceToBeEnabled" 1,5 s sau | có | rỗng | không có A1–A3 |
| 10:14, làm mới bộ đệm của System Settings | A4 | `Register` (0), `Enable` cha (0); thoát System Settings; xoá `IntlDataCache.le*` (giờ ghi trước đó 08:47); `pkill` extension (lúc đó chỉ `KeyboardSettingsIntents` chạy); mở lại Keyboard. Bộ đệm được dựng lại 10:14:38.969 | có | rỗng | **có A1, A2, A3, A4** (ảnh của người dùng) |
| 10:20, bật từ app có tên ngay sau lần làm mới | A4 | `Enable` cha từ `TisAct.app` (tên "Dấu thử") (0); `KeyboardSettings` ghi `handleOpenParameter`, `TCCAccessLaunchDisclosurePromptIfNeeded`, **không** có "Invalid value"; hộp thoại xin phép hiện, người dùng bấm "Allow" | cha và mode `enabled` | **có cả hai mục A4** (cha và mode `….A4.vi`) | — |

**Vòng tách từng thao tác làm mới bộ đệm** (04/11/2026): tách lần làm mới 10:14 của vòng trên thành từng thao tác (các lần thử của `scripts/probe/step.sh`, mỗi lần một ID mới, System Settings đang mở ở Keyboard trước mỗi lần):

| Lần thử | Bản | Làm mới | Bộ đệm `IntlDataCache.le*` | "+" |
|---|---|---|---|---|
| 10:24, chỉ thoát System Settings | B1 | `Register` (0); chỉ thoát System Settings, mở lại Keyboard sau 1,5 s | không dựng lại (giờ ghi giữ 10:14:38) | không có B1 |
| 10:27, chỉ xoá bộ đệm | B2 | `Register` (0); chỉ xoá bộ đệm, System Settings vẫn mở; mở lại Keyboard | dựng lại 10:27:13, `.kbdx` 139.252 → 142.540 byte | **có B1, B2** |
| 10:29, chuỗi cài thử trọn vẹn | B3 | `Register` (0); xoá bộ đệm; mở Keyboard; 3 s sau `Enable` cha từ `TisAct.app` (0) | dựng lại 10:29:25 | **có B3** |

Lần thử chuỗi cài trọn vẹn, phần bật:
- Lần gửi đầu (10:29:28, 3 s sau khi mở lại Keyboard) không để lại dòng `handleOpenParameter` nào trong nhật ký `KeyboardSettings`, không có hộp thoại, `com.apple.inputsources` không có B3 sau 25 s, dù mã trả về 0.
- Gửi lại từ `TisAct.app` lúc 10:31:45 (chạy lại bước gửi yêu cầu bật của `step.sh` cho bản B3): `handleOpenParameter` 10:31:46, hộp thoại xin phép hiện, người dùng bấm "Allow", `com.apple.inputsources` có B3 lúc 10:32:03.
- Một dòng `handleOpenParameter` lúc 10:31:02 không do script gửi, chưa rõ nguồn.
- Chưa ghi câu chữ đúng của hộp thoại.

**Vòng bật ngay sau khi xoá bộ đệm** (04/11/2026): `Register`, xoá bộ đệm, rồi `Enable` cha từ `TisAct.app` ngay, không tự mở System Settings trước (`TISEnableInputSource` tự mở System Settings kèm yêu cầu, mục 2.2):

| Giờ | Bản | System Settings trước lệnh bật | Nhật ký `KeyboardSettings` | `com.apple.inputsources` |
|---|---|---|---|---|
| 10:36:59 | C2 | đang mở ở Keyboard, có sheet Edit/"+" đang mở | không có `handleOpenParameter` | không có C2 |
| 10:39:30 | C2 (gửi lại) | đang mở ở Keyboard, đã đóng sheet | không có `handleOpenParameter` | không có C2 |
| 10:40:34 | C2 (gửi lại) | đã thoát (`osascript … quit`) | extension mới pid 32724: `TCCAccessLaunchDisclosurePromptIfNeeded` 10:40:35.086, `handleOpenParameter` 10:40:35.392; hộp thoại hiện (ảnh của người dùng), bấm "Allow" | có C2 lúc 10:40:51 |
| 10:41:02 | C1 (ID mới) | đã thoát | extension mới pid 32891: `handleOpenParameter` 10:41:03.852; hộp thoại hiện, bấm "Allow" | có C1 lúc 10:41:19 |

Hộp thoại (ảnh của người dùng, macOS 27.2, giao diện tiếng Anh):
- Tiêu đề `Allow “Dấu thử” to enable “Dấu thử C2”?` (tên app gọi, rồi tên bộ gõ), thân "The developer of the input source will be able to access anything you type with this input source…", hai nút "Don't Allow" và "Allow"; hiện giữa cửa sổ System Settings ở trang Keyboard.
- Hình dạng (đo 04/11/2026 18:59 bằng bản thử F1, trợ năng và ảnh chụp, macOS 27.2, giao diện tối) [Máy/hệ thống]:
  - sheet rộng 260 pt, cao 234 pt, nằm giữa cửa sổ System Settings;
  - không có biểu tượng; tiêu đề đậm, canh trái, xuống dòng khi dài;
  - thân bài canh trái, hiện đủ (6 dòng ở bề rộng này, không cắt);
  - hai nút hình viên thuốc rộng bằng nhau (112 × 30 pt) nằm ngang ở đáy, "Don’t Allow" xám bên trái, "Allow" xanh (nút mặc định) bên phải.

Quan sát xuyên các vòng:
- Mọi lần System Settings xử lý yêu cầu bật (`handleOpenParameter`, 10:20:51, 10:31:46, 10:40:35, 10:41:03) đều đi cùng một tiến trình extension `KeyboardSettings` có pid mới và dòng `TCCAccessLaunchDisclosurePromptIfNeeded` cùng lúc.
- Mọi lần lệnh bật trả 0 mà không có dòng nào (lần gửi đầu của chuỗi cài trọn vẹn 10:29:28, và vòng bật ngay lúc 10:36:59 và 10:39:30) đều là lúc trang Keyboard đang mở sẵn.
- Chưa thử: System Settings mở ở trang khác Keyboard.

**Vòng gỡ** (04/11/2026): bỏ bundle khỏi `~/Library/Input Methods` (`lsregister -u` trước, rồi chuyển ra ngoài), có hoặc không có "–", rồi xoá `IntlDataCache.le*`; System Settings đang mở; "+" và các danh sách là người dùng xem, sheet đóng rồi mở lại.

| Lần thử | Bản | Trước khi bỏ bundle | Ngay sau khi bỏ bundle | Sau khi xoá bộ đệm |
|---|---|---|---|---|
| 12:41, bỏ bundle khi chưa bật | A1 | đã cài, chưa bật | TIS tiến trình mới vẫn liệt kê A1; "+" › Vietnamese có một dòng không tên (ảnh của người dùng) | TIS không còn A1; bộ đệm dựng lại 12:43 khi mở "+", `.kbdx` 144.712 → 144.164 byte; dòng không tên mất |
| 12:44, bỏ bằng "–" rồi bỏ bundle | B3 | đang bật; người dùng bỏ bằng "–" (`com.apple.inputsources` không còn B3) | TIS vẫn liệt kê B3 | vài giây sau TIS không còn B3; "+" và danh sách bên trái của Edit… sạch |
| 12:50, bỏ bundle khi đang bật, không bấm "–" | C1 | đang bật, **không** bấm "–" | — | TIS không còn C1; `com.apple.inputsources` **vẫn còn** hai mục của C1 (không ai ghi được miền này ngoài System Settings); menu nhập liệu, danh sách bên trái của Edit…, "+" › Vietnamese và ⌃Space đều không có C1 hay dòng trống |

- Tìm trong binary `KeyboardSettings` (macOS 27.2): chỉ có `inputSourceToBeEnabled`, không có đường nhận yêu cầu tắt/bỏ nguồn; `TISDisableInputSource` chỉ nhảy sang `TSMDisableInputSource`, cùng đường ghi bị chặn (mục 4.1).
- Chưa đo sau lần thử bản C1: mục ẩn của C1 có ảnh hưởng gì ở lần đăng nhập sau (phép đọc lại sau đăng xuất, mục 4.1 và 10.8).
- Cài lại cùng ID thì macOS bật lại ngay không hỏi: đã đo bằng phép hồi sinh mục ẩn (mục 4.1, kết quả).

**Vòng từ chối hộp thoại rồi thử lại** (04/11/2026): phiên chính tự bấm qua trợ năng (`scripts/probe/settings-ax.swift`), không cần người dùng:

| Giờ | Bước | Kết quả |
|---|---|---|
| 14:47:34 | gửi yêu cầu bật lần đầu: `Register`, xoá bộ đệm, System Settings đã thoát, `Enable` cha từ `TisAct.app` (bản `DauProbeD1`) | hộp thoại `Allow “Dấu thử” to enable “Dấu thử D1”?` hiện (đọc qua trợ năng) |
| 14:47:52 | bấm "Don’t Allow" | `com.apple.inputsources` không có `DauProbeD1`; nhật ký `KeyboardSettings` không có dòng nào báo từ chối (chỉ có dòng `handleOpenParameter` lúc nhận yêu cầu) → app không biết người dùng đã từ chối, chỉ thấy "chưa bật" |
| 14:48:16 | thoát System Settings, gửi lại yêu cầu (như "Thử lại") | hộp thoại hiện lại sau 4 s (macOS không nhớ lần từ chối) |
| 14:48:21 | bấm "Allow" | `DauProbeD1` vào `com.apple.inputsources` ngay (cả hai mục) |
| 14:48:41 | System Settings đang mở sheet Input Sources, gọi `NSRunningApplication.terminate()` như app | System Settings thoát trong < 5 s dù sheet đang mở |
| 14:48:51 | mở `?InputSources`, chọn `DauProbeD1`, bấm "–", Done (qua trợ năng) | `DauProbeD1` ra khỏi danh sách; dọn bằng `cleanup.sh --yes` |

**Vòng bộ đệm riêng của app có sandbox** (04/11/2026, 16:58–17:08). Mục đích: kiểm tra ca Telegram (mục 9.10) với một nguồn mới, đo khi nào app thấy nguồn đó.

Cách đo:
- Công cụ: một app thử (ký ad-hoc, có sandbox, mỗi lần một bundle ID mới), in danh sách nguồn TIS mà nó thấy và giờ ghi bộ đệm `com.apple.IntlDataCache.le.kbdx` của nó. Có ba chế độ: in một lần, theo dõi khi đang chạy (đọc lại khi có thông báo TIS và mỗi 2 s), mở cửa sổ có ô nhập.
- Bộ đệm của app có sandbox nằm ở `$(getconf DARWIN_USER_CACHE_DIR)<bundle ID>/`. Tiến trình không sandbox dùng bộ đệm chung ở gốc thư mục đó.
- Bản thử E1–E4 bật theo cách của vòng bật ngay sau khi xoá bộ đệm (Allow bấm qua trợ năng), trừ khi ghi khác. Bỏ bằng "–" qua trợ năng rồi `cleanup.sh --yes`.

| Giờ | Bước | Kết quả |
|---|---|---|
| 16:59:19 | E1 bật theo cách trên, Allow | app đang chạy (bộ đệm 16:59:10) nhận `EnabledKeyboardInputSourcesChanged` nhưng **không thấy E1**; app mở lại có bộ đệm cũ (16:58:54) **không thấy E1**; app mới thấy E1; tiến trình không sandbox thấy E1 (bộ đệm chung tự dựng lại lúc 16:59:29) |
| 17:00:03 | xoá bộ đệm của app đang chạy (E1 đã bật xong), rồi đổi nguồn đang chọn hai lần | app vẫn không thấy E1, không dựng lại bộ đệm (`cache=none`) |
| 17:00:11 | xoá bộ đệm của app đã thoát, mở lại | thấy E1 |
| 17:03:00 | app mới chạy với bộ đệm cũ chép từ app khác (không có E3, E3 đã cài) | dùng bộ đệm đó, không thấy E3: bộ đệm có sẵn thì được dùng, không bị kiểm tra lại |
| 17:03:29 → 17:03:36 | xoá bộ đệm của app đó khi đang chạy; 7 s sau gọi `TISRegisterInputSource` cho một nguồn đã cài | sau khi xoá: không đọc lại. Sau khi đăng ký: dựng lại bộ đệm từ đĩa, **thấy E3 khi vẫn đang chạy** |
| 17:04:24 | hai app có ô nhập, cùng bộ đệm cũ, cùng đang chạy; chép E4, xoá bộ đệm của **một** app, đăng ký E4, bật E4, Allow | app bị xoá bộ đệm: bộ đệm mới (17:04:27) có E4, chọn "Dấu thử E4" từ menu nhập liệu được, gõ từng phím ra đúng "việt". App giữ bộ đệm: chọn E4 từ menu không đổi (vẫn U.S.), gõ ra "vieetj", như Telegram ở mục 9.10 |

Thêm:
- **E2:** lượt đầu không hiện hộp thoại vì System Settings còn mở từ E1 (cách bật của vòng bật ngay không thoát nó). Thoát rồi gửi lại thì hiện.
- **Sai sót thiết kế ở lượt E3:** app thử tự đọc TIS mỗi 2 s nên dựng lại bộ đệm (vẫn cũ) ngay sau khi bị xoá, trước khi E3 được cài. Một app thật gọi TIS vào lúc bất kỳ, nên khoảng giữa lúc xoá bộ đệm và lúc đăng ký cần ngắn nhất có thể.
- **Thông báo đổi nguồn lạ:** lúc 17:03:21 và 17:03:26 có hai thông báo đổi nguồn đang chọn không do lệnh nào của vòng thử.
- **Bấm "–" qua trợ năng:** trong một lần mở trang Input Sources, chỉ lần "–" đầu tiên được ghi vào `com.apple.inputsources`. Các lần sau làm dòng biến mất nhưng không ghi. Mở lại System Settings cho từng mục thì ghi đủ. Chưa biết có xảy ra khi người dùng tự bấm hay không.
- **Gõ nhanh khi chưa ổn định:** lần gõ nhanh đầu tiên ở app có ô nhập (chuỗi System Events) ra ô trống; gõ từng phím thì đúng.

Chưa chạy: lần thử chỉ dừng extension của System Settings (lần chỉ xoá bộ đệm đã đủ và nhẹ hơn).
Chưa ghi:
- Người dùng có thoát hẳn System Settings khi xem "+" ở ba lần thử đầu (09:41, 09:46 hai lần) hay không;
- câu chữ đúng của hộp thoại ở vòng đầu;
- menu nhập liệu có A4 không;
- gõ được không.

Lỗi bộ thử đã sửa sau lần làm mới bộ đệm 10:14: `pkill -f KeyboardSettings` dừng nhầm cả `log stream` (bộ lọc chứa chữ đó), nên nhật ký liên tục của lần đó dừng ở 10:14:37.

Các quan sát này không trả lời câu hỏi lần cài đầu có phải đăng xuất không; việc đó trả lời bằng Dấu thật (mục 9.9), xem cả danh sách "+". Kế hoạch thử trên máy sạch ở mục 7 đã bỏ.

### 8.2 Kế hoạch vòng thử bằng bản thử (tìm cách không phải đăng xuất)

Công cụ `scripts/probe/` nhắc trong mục này đã xoá ngày 09/11/2026 khi vòng thử xong; lấy lại bằng `git show` như mục 0, điểm 17.

Không thuộc lần thử trên máy sạch (mục 7) và chạy **trước** nó (người dùng chốt 04/11/2026: mục tiêu là tìm cách để lần cài đầu không phải đăng xuất; ba hướng đầu và hướng chọn nguồn bằng TIS ở mục 7.1).
Chạy trên tài khoản đang dùng, vì mỗi bước dùng một ID mới (nguyên lý dưới).
Kết quả là quan sát về bản thử, không phải về Dấu; hướng nào có vẻ được thì phải thử lại bằng Dấu thật trên tài khoản mới (mục 7) trước khi đưa vào sản phẩm.
Các bước chỉ đăng ký, thăm dò, kiểu Squirrel, làm mới bộ đệm và bật từ app có tên có kết quả ở vòng đầu (mục 8.1b); các bước còn lại không có kết quả trong file này.

Nguyên lý:
- Điều kiện đáng đo là "**ID chưa từng có trong danh mục đăng nhập của phiên**".
  - Mỗi ID chỉ dùng được **một lần** cho mỗi tài khoản: sau khi đăng xuất và đăng nhập, ID đó đã "bị cháy". Dấu thật là một ID.
  - Để thử thêm hướng nào trong **cùng** phiên đăng nhập, mỗi hướng dùng **một biến thể bộ gõ có ID riêng**.
- Mỗi vòng dựng một bộ biến thể mới từ bản Release của `DauInputMethod.app`.
  - Mỗi biến thể đổi: tên file `.app`, `CFBundleIdentifier`, `TISInputSourceID` ở mức bundle, khoá mode và `TISInputSourceID` của mode (`….DauProbeA1.vi`), `InputMethodConnectionName`, tên hiển thị (để phân biệt trong menu), và `mach-register` trong entitlement, rồi ký lại bằng cùng danh tính Apple Development như bản Release (như bản thử 03/11, mục 8.1).
  - ID giữ dạng của Dấu, `com.codefastlabs.dau.inputmethod.<Tên>`, để chỉ đổi một biến số (luật `.inputmethod.` còn mở, mục 2.7).
  - Script ném đi trong `scripts/probe/` (không đưa vào bản phát hành), không sửa mã app; nó ghi lại mọi ID đã tạo và từ chối dùng lại.
- Cần một **công cụ đọc** `tis-probe` (`scripts/probe/tis-probe.swift`, chạy bằng tiến trình mới mỗi lần):
  - in một dòng JSON gồm giờ, danh sách mọi nguồn có `TISInputSourceID` chứa `dau.inputmethod` (id, bundle, loại, enabled, enableCapable, selectCapable, selected), kết quả `defaults export com.apple.inputsources -` và `com.apple.HIToolbox` (`AppleEnabledInputSources`, `AppleInputSourceUpdateTime`), và `pgrep -fl DauProbe`;
  - có thêm chế độ `--watch` đăng ký `kTISNotifyEnabledKeyboardInputSourcesChanged` và in mỗi lần nhận;
  - công cụ dòng lệnh `probe-tis` đã dùng ở 02–03/11 nằm ngoài repo; chưa kiểm có trùng không.
- **Thứ tự: từ ít xâm lấn đến nhiều**, và **chép biến thể vào `~/Library/Input Methods` ngay trước khi thử nó, không chép trước**.
  - Các bước sau có thể làm tiến trình giao diện nạp lại danh mục và vô tình làm hiện cả biến thể trước đó (và Dấu thật).
  - Vì vậy sau **mỗi** bước phải chạy lại `tis-probe` và nhìn giao diện cho **mọi ID đã cài**, không chỉ ID đang thử. Nếu một ID cũ bỗng hiện ra sau bước N, bước N là thủ phạm (ghi lại).

Các bước (bảng kiểm như mục 7.4, thêm: một công cụ đọc `tis-probe` chạy bằng tiến trình mới: ID nào có, enabled / enableCapable / selectCapable / selected, ba lần cách nhau 3 s; `pgrep -fl DauProbe`; thông báo `kTISNotifyEnabledKeyboardInputSourcesChanged` qua `tis-probe --watch`).
- Cần mật khẩu quản trị ở bước cài vào `/Library/Input Methods` (người dùng tự gõ).
- Dừng tiến trình của phiên ở ba bước làm mới (LaunchAgent, macOS tự chạy lại), người dùng cho phép lúc chạy.
- Bước trần trên chỉ trên tài khoản thử.
- Công cụ, script biến thể và script chạy từng bước nằm trong `scripts/probe/`, không gắn vào bản phát hành.
- Biến thể đặt tên `DauProbe<chữ vòng><số>` (vòng đầu: `DauProbeA1`…), tên hiển thị "Dấu thử A1"…:

| Bước | Chuỗi gọi | Mục đích | Mức xâm lấn |
|---|---|---|---|
| **Chỉ đăng ký** | Chép vào `~/Library/Input Methods`, `Register` từ một tiến trình, không gì thêm; nhìn "+". (03/11 bản thử có `.inputmethod.` được TIS liệt kê ngay sau `Register` nhưng chưa ai xem "+", mục 8.1) | Mốc: có cần làm gì thêm sau `Register` không | Không |
| **Đăng ký rồi thăm dò** | `Register` rồi **thăm dò** `TISCreateInputSourceList` mỗi 0,5 s đến 20 s cho đến khi thấy cha; bật cha; thăm dò đến 20 s cho đến khi thấy mode; bật mode; đọc lại bằng tiến trình mới | Hướng dựng lại ảnh chụp trong tiến trình (chờ) | Không |
| **Kiểu Squirrel** | Tiến trình 1 chỉ `Register` rồi thoát; tiến trình 2 mới bật cha rồi thoát; tiến trình 3 mới liệt kê và bật mode rồi thoát | Hướng dựng lại ảnh chụp trong tiến trình (mỗi lệnh một tiến trình) | Không |
| **Làm mới bộ đệm của System Settings** | `Register`, bật cha, rồi **chỉ** thoát Cài đặt, xoá `$(getconf DARWIN_USER_CACHE_DIR)/com.apple.Keyboard-Settings.extension/com.apple.IntlDataCache.le*`, dừng extension Bàn phím (tên tiến trình: tra bằng `pgrep -fl Keyboard` lúc Cài đặt đang mở), mở lại Cài đặt › Bàn phím › Nguồn nhập liệu. **Không** dừng gì khác | Hướng làm mới tiến trình/bộ đệm giao diện, phần "+" (msime) | Nhẹ: bộ đệm của chính tài khoản này |
| **Bật từ app có tên sau khi làm mới** | Ngay sau bước làm mới, cùng biến thể: gọi bật mục cha từ một app có tên (`TisAct.app`, không phải công cụ dòng lệnh); xem hộp thoại "Allow “…” to enable “…”?" có hiện không, bấm "Allow" thì có bật thật không (đọc `com.apple.inputsources`) | Giả thuyết mục 2.2: Cài đặt báo "Invalid value" vì danh sách nguồn của nó chưa có ID; bước làm mới làm nó thấy ID thì có thể dựng được hộp thoại. Nếu được: bật một chạm, không đăng xuất | Như bước làm mới |
| **Kiểu vChewing** | Dừng `TextInputMenuAgent`, chờ 0,5 s, sau đó `Register`, bật mode (rồi cha nếu cần), đọc lại. Rồi một lần thử thứ hai: đã `Register` xong, dừng `TextInputMenuAgent` lần nữa và nhìn menu | Hướng làm mới tiến trình/bộ đệm giao diện, phần menu | Vừa: LaunchAgent của phiên, tự dựng lại |
| **Dừng ba tiến trình giao diện cùng lúc** | `Register`, bật cha, rồi dừng **cùng lúc** `TextInputSwitcher`, `CursorUIViewService`, `TextInputMenuAgent` (ba lần cách nhau 0,5 s) | Làm mới tối đa, không đụng `imklaunchagent` | Vừa |
| **Cài vào `/Library/Input Methods`** | `sudo` chép vào **`/Library/Input Methods/`** (chủ sở hữu root), `Register` từ tiến trình người dùng, bật cha, bật mode. Đo thêm cho câu hỏi mở "cài cho riêng mình hay cho cả máy" (`docs/DECISIONS.md`): có tài khoản thứ hai thì đăng nhập vào đó xem "+" có biến thể này ngay không; nếu người dùng thêm biến thể này bằng "+" rồi chép thêm cùng biến thể vào `~/Library/Input Methods`, tiến trình chạy từ đường dẫn nào | Hướng cài vào `/Library/Input Methods`; cài cho cả máy | Cần mật khẩu quản trị (người dùng tự gõ); bản ở `/Library` gỡ cũng cần mật khẩu |
| **Chọn nguồn bằng TIS** | Như bước đối chứng ở mục 7.3 rồi, **sau cùng**, `TISSelectInputSource` cho mode: ghi mã trả về, xem biến thể có chạy không (`pgrep`), `TISCopyCurrentKeyboardInputSource` đổi không | Hướng chọn nguồn bằng TIS, chẩn đoán | Nhẹ; chỉ để đo, không đưa vào Dấu (N4) |
| **Trần trên** (không có biến thể riêng) | **Chỉ chẩn đoán, không bao giờ vào Dấu**: sau khi mọi bước trên đã đo, dừng `imklaunchagent` và `keyboardservicesd` rồi nhìn lại mọi ID | Biết có cách làm hiện mà không đăng xuất hay không, và xem tiến trình nào là chủ | Cao: có thể làm hỏng gõ phím trong tài khoản thử; làm cuối cùng |

Cách đọc:
- **Bước chỉ đăng ký mà HIỆN:** `Register` là đủ trên bản macOS đó; các bước sau chỉ còn để xem bật có được không. Ca 03/11 (app không gọi `Register`, `docs/PROGRESS.md`) khi đó là lỗi của app, không phải giới hạn của macOS.
- **Bước bật từ app có tên có hộp thoại và bấm "Allow" thì bật thật:** đường tốt nhất cho onboarding (một nút, một lần xác nhận, không đăng xuất), nhưng bước làm mới trước nó xoá bộ đệm và dừng extension của hệ thống: cần người dùng quyết theo N4.
- **Bước cài vào `/Library/Input Methods` HIỆN, các bước còn lại KHÔNG:** hướng cài vào thư mục của cả máy đáng cân nhắc; mở câu hỏi D16/D6/D37 cho người dùng.
- **Bước làm mới bộ đệm làm "+" HIỆN mà menu thì không:** có thể hướng dẫn thêm thủ công (đúng chữ N4) và vẫn không cần đăng xuất; menu sẽ sau.
- **Bước kiểu vChewing hoặc dừng ba tiến trình làm menu HIỆN:** cân nhắc nút "Làm mới danh sách" với xác nhận.
- **Một ID cũ bỗng HIỆN sau một bước sau:** ghi bước nào, rồi lặp lại bước đó riêng trên ID mới ở vòng sau (mỗi vòng dùng bộ ID mới `DauProbeB1…`).

## 9. Quan sát bằng Dấu thật (macOS 27.2 trừ khi ghi khác)

Mục này gom các phép đo và quan sát bằng Dấu thật. Nhãn nguồn [Máy/Dấu] (và [Máy/hệ thống] khi đọc nhật ký).

Tên cũ của các tiểu mục: trước khi viết lại (09/11/2026) chúng nằm ở mục 0 dưới nhãn (b)1 đến (b)12; tiểu mục 9.N là (b)N. Các tài liệu và chú thích trong mã dẫn "(b)N" thì đọc là mục 9.N.

### 9.1 30/10: cài đè cùng đường dẫn với bundle ID khác
- Cài đè cùng đường dẫn `~/Library/Input Methods/DauInputMethod.app` với bundle ID khác làm bộ đệm TIS lệch.
  - ID nguồn mới nhưng `kTISPropertyBundleID` vẫn là ID cũ; lần đối chiếu với miền `HIToolbox` ngày đó đọc nhầm miền (mục 2.6).
  - Thêm nguồn không kích hoạt được; đăng xuất rồi đăng nhập thì đúng ID mới.
- Đây là đổi ID tại chỗ, **không phải** cài lần đầu trên máy sạch. [Máy/Dấu] Mục 3.

### 9.2 30/10: bộ gõ có sandbox gọi `TISSelectInputSource`
- Từ bộ gõ có sandbox, `TISSelectInputSource` đổi được nguồn nhưng bước báo cho app đang gõ bị chặn (`deny mach-lookup com.apple.tsm.portname`). [Máy/Dấu] Mục 1.2.

### 9.3 30/10: App Group với app chủ không sandbox
- `scripts/selftest/app-group.sh` đạt với app chủ không sandbox. [Máy/Dấu] Mục 1.3.

### 9.4 Máy không sạch từ 30/10
- Hai mục Dấu (cha và mode `….Dau.vi`) trong `com.apple.inputsources` có từ ngày 30/10.
  - File sửa lần cuối 30/10 16:18, trùng ngày người dùng đăng xuất/đăng nhập và bật lại nguồn "Dấu – Tiếng Việt"; không phải do lần "Bật Dấu" 02/11.
  - macOS từ chối `defaults import` của script ghi miền này (và `TISDisableInputSource` của Dấu, mục 4).
- Vì vậy ở lần thử cài đầu 02/11 (mục 9.5), việc Dấu "tự có sẵn" sau đăng nhập không chứng minh điều gì về `TISEnableInputSource`. [Máy/Dấu, 02/11] Mục 2.6.

### 9.5 02/11: lần thử cài đầu của người dùng (Release 22948d9)
- Sau khi dọn tay và đăng xuất, "Bật Dấu" chép, đăng ký (`status=0`), bật mục cha (`status=0`); danh sách "+" và menu **không** có Dấu.
- Sau đăng xuất/đăng nhập Dấu có sẵn, đang được chọn, bộ gõ chạy. [Máy/Dấu] Mục 2.3.

### 9.6 02/11 16:41:23: Cài đặt ghi lỗi sau "Bật Dấu"
- Cài đặt ghi lỗi "Invalid value on inputSourceToBeEnabled" 0,8 s sau khi Dấu ghi `event=enable … status=0`; theo mã thì khi đó không dựng hộp thoại.
- Cài đặt có hiện lên màn hình hay không: không ghi lại. [Máy/Dấu + Máy/hệ thống] Mục 2.2.

### 9.7 02/11: `TISDisableInputSource` từ app
- `TISDisableInputSource` từ app trả 0 cho mục con và mục cha, nhưng System Policy chặn ghi `com.apple.inputsources` (`Dau deny(1) user-preference-write com.apple.inputsources`; cfprefsd "rejecting write").
- Hai mục Dấu còn nguyên, TIS tiến trình mới vẫn báo `enabled=true`.
- Chỉ nút "–" trong Cài đặt gỡ được (file ghi lúc 18:07, mục rỗng). [Máy/Dấu] Mục 4.

### 9.8 Chưa có phép đo trên tài khoản macOS mới
- Chưa có phép đo trên tài khoản macOS mới, nhìn danh sách "+" bằng mắt, với Dấu thật. Mục 7.

### 9.9 04/11: "Bật Dấu" theo D37 mới, không đăng xuất
Bản Debug (mã `83baa29`), tài khoản đã từng cài Dấu nhưng lúc đó không cài Dấu và `com.apple.inputsources` không có mục nào của Dấu. [Máy/Dấu] Mục 8.1b (cùng cách, đo trước bằng bản thử).
1. Chép, đăng ký (0), xoá 2 file `IntlDataCache.le*`, System Settings thoát, bật mục cha (0) lúc 10:49:57.214.
2. `KeyboardSettings` `handleOpenParameter` 10:49:58.364.
3. Hộp thoại `Allow “Dấu” to enable “Dấu”?` (ảnh của người dùng); tên thứ hai là tên của mục cha, không phải "Dấu – Tiếng Việt". Người dùng bấm "Allow".
4. `com.apple.inputsources` có mục cha và mode `….Dau.vi` lúc 10:50:02 (`event=enable-stored waited=4s`).
5. Tiến trình bộ gõ chạy; menu nhập liệu có "Dấu – Tiếng Việt", gõ "vieetj" ra "việt" (người dùng xem). Không đăng xuất.

### 9.10 04/11: Telegram không dùng được Dấu dù Dấu đã bật
Telegram: `ru.keepcoder.Telegram` 13.1, có sandbox.
- **Triệu chứng:**
  - Chọn "Dấu – Tiếng Việt" từ menu nhập liệu trong Telegram không đổi được nguồn. U.S. và Telex thì đổi được.
  - Vòng ⌃⌥Space trong Telegram chỉ có Telex và U.S. TextEdit, Finder và Sublime Text đi đủ ba nguồn.
  - Chọn Dấu bằng TIS từ một tiến trình khác thì TIS báo Dấu, nhưng Dấu không nhận phím nào (signpost `handle` bằng 0), phím vẫn tới Telex.
  - Thoát rồi mở lại Telegram không đổi gì.
- **Nguyên nhân:** bộ đệm riêng của Telegram, `$(getconf DARWIN_USER_CACHE_DIR)ru.keepcoder.Telegram/com.apple.IntlDataCache.le*`, ghi lúc 10:16:41.
  - Lúc đó `~/Library/Input Methods` chỉ có các bản thử `DauProbeA1–A4` của vòng đầu ở mục 8.1b, nên bộ đệm liệt kê các bản thử mà không có `DauInputMethod.app`.
  - Lần mở lại lúc 16:36 không ghi lại bộ đệm này.
  - Bộ đệm của TextEdit và của một app thử có sandbox, dựng sau khi cài Dấu, thì có `DauInputMethod.app`.
- **Đã sửa được:** thoát Telegram, chuyển hai file đó ra chỗ khác, mở lại. Bộ đệm mới có `DauInputMethod.app`; chọn Dấu bằng menu và bằng ⌃⌥Space đều được; Dấu nhận 11/11 phím.
- Ngày 30/10, Dấu gõ đúng trong Telegram (nhật ký 30/10).
- **Đã đo để loại trừ:**
  - Sandbox nói chung: app thử có sandbox, ký ad-hoc, có và không có hardened runtime, đều để Dấu nhận phím.
  - Secure Event Input: không tiến trình nào giữ.
  - Telegram không gọi `allowedInputSourceLocales` hay `TISSelectInputSource`.

[Máy/Dấu] Mục 10.10.

### 9.11 04/11, 17:35–17:38: luồng bật theo D37 đã sửa, ca Telegram
Dựng lại đúng ca lỗi của mục 9.10, và lần này luồng bật sửa được (bản Debug).
- **Chuẩn bị:**
  - Bỏ Dấu bằng "–" qua trợ năng.
  - Đặt lại cho Telegram bộ đệm cũ lúc 10:16 (không có `DauInputMethod.app`), mở Telegram. Telegram chạy suốt, không mở lại (cùng pid).
- **Bật:** mở Dấu.app, cửa sổ thiết lập ở bước 2, bấm "Bật Dấu".
  - App xoá 107 file bộ đệm. 5 thư mục được hệ thống bảo vệ không liệt kê được: ba thư mục WebKit, hai thư mục bộ đệm của Shortcuts. Nhật ký kernel ghi `System Policy: Dau deny file-read-metadata`, không có yêu cầu nào tới TCC, không có hộp thoại xin quyền.
  - Sau đó đăng ký (0) và bật mục cha (0).
  - Hộp thoại `Allow “Dấu” to enable “Dấu”?` hiện; bấm Allow. macOS ghi mục sau 3 s.
  - Lượt quét lại đọc 20 bộ đệm đã dựng lại, không bộ đệm nào thiếu Dấu.
- **Kết quả ở Telegram (vẫn chạy suốt):**
  - Bộ đệm của Telegram được dựng lại lúc 17:37:47 và có `DauInputMethod.app`.
  - Chọn "Dấu – Tiếng Việt" từ menu nhập liệu được.
  - Dấu nhận 6/6 phím ở ô tìm kiếm, ra "việt".
  - ⌃⌥Space đi qua cả Dấu.
- Quét lại toàn bộ thư mục cache: không còn bộ đệm riêng nào lệch so với bộ đệm chung.

[Máy/Dấu] Mục 10.10.

### 9.12 05/11, 09:44–09:48: đăng xuất rồi đăng nhập có làm mới bộ đệm riêng của từng app không
Dấu thật đã bật; app thử có sandbox `local.probe.cacheL1`, ký ad-hoc, dựng trong `build/probe.noindex/L/`; máy chạy liên tục từ 29/10, không khởi động lại.
- **Trước khi đăng xuất:**
  - Thay bộ đệm của app thử bằng một bộ đệm cũ (04/11 08:47, không có `DauInputMethod.app`). Chạy app thử: nó dùng bộ đệm đó, giờ ghi giữ nguyên, **không thấy Dấu** (09:45:08).
  - Chụp 26 bộ đệm (bộ đệm chung và từng app; giờ ghi, inode, có Dấu không): 25 có Dấu, chỉ bộ đệm của app thử không có. Bộ đệm của Telegram ghi lúc 04/11 17:56:37. Telegram đang chạy.
- **Người dùng đăng xuất và đăng nhập lại (09:46).** Chụp lại lúc 09:47:26, trước khi mở app nào:
  - Bộ đệm chung và bộ đệm của 12 tiến trình chạy lúc đăng nhập (MenuBarAgent, notificationcenterui, PressAndHold…) được ghi mới (09:46:41–09:46:52, inode mới), đều có Dấu.
  - Bộ đệm của app thử và của Telegram (chưa chạy) **còn nguyên**: cùng inode, cùng giờ ghi. Đăng xuất không xoá bộ đệm.
- **Mở app sau khi đăng nhập:**
  - App thử: lần chạy đầu (09:47:35) dựng lại bộ đệm (inode mới) và **thấy Dấu**. Lần chạy sau (09:48:12) dùng lại bộ đệm 09:47:35.
  - Telegram (mở ở chế độ nền, 09:47:49): bộ đệm cũng được dựng lại ngay khi mở (inode mới), có Dấu.
- **Tóm lại:** sau một lần đăng nhập mới, mỗi app có sandbox dựng lại bộ đệm của nó ở lần đầu đọc nguồn đầu vào, kể cả khi bộ đệm cũ không có Dấu.
  - Trước đăng xuất, mở lại app không làm điều này (mục 9.10, vòng bộ đệm riêng ở mục 8.1b).
  - Vì vậy đăng xuất rồi đăng nhập sửa được ca Telegram của mục 9.10 mà không cần xoá bộ đệm bằng tay.
  - Chưa đo: khởi động lại máy, macOS 14–26.
  - Vì sao hệ thống coi bộ đệm cũ là hết hạn sau khi đăng nhập thì chưa biết: trước đăng xuất, bộ đệm chung cũng mới hơn bộ đệm của app thử mà app thử vẫn dùng bộ đệm cũ.

[Máy/Dấu] Mục 10.10.

## 10. Câu hỏi mở

Tên cũ của các tiểu mục: trước khi viết lại (09/11/2026) chúng nằm ở mục 0 dưới nhãn (d)1 đến (d)10; tiểu mục 10.N là (d)N. Các tài liệu và chú thích trong mã dẫn "(d)N" thì đọc là mục 10.N.

### 10.1 Lần cài đầu có phải đăng xuất để danh sách "+" thấy ID mới
- Trên macOS 27.2: không, nếu xoá bộ đệm `IntlDataCache.le*` của System Settings sau khi đăng ký (mục 8.1b bằng bản thử; mục 9.9 bằng Dấu thật trên tài khoản đã từng cài Dấu).
- Còn phải đo: macOS 14–26, bản ký Developer ID. Tài khoản macOS mới không đo: kế hoạch ở mục 7 đã bỏ, người dùng chốt 04/11/2026.
- Lời khuyên đăng xuất của Apple DTS phù hợp với việc bộ đệm này chỉ được dựng lại khi đăng nhập [Suy luận, cần kiểm chứng]. Mục 2.3.

### 10.2 Vì sao Cài đặt không dựng lại được nguồn
- Câu hỏi: vì sao Cài đặt không dựng lại được nguồn ("Invalid value"), kể cả với Dấu thật. Không tìm thấy nguồn. Mục 2.2.

### 10.3 Hộp thoại "Allow … to enable …?" trên các bản macOS khác
- Hộp thoại hiện khi nào trên các bản macOS khác, và bản ký Developer ID đã notarize có khác không.
- Trên máy này (27.2) đã thấy từ 04/11 khi làm theo D37 (mục 9.9, mục 8.1b); Shanjie thấy trên máy ảo macOS 26.6.2 (mục 4.1, nguồn). Mục 2.2.

### 10.4 Luật `.inputmethod.` trong bundle ID
- Luật `.inputmethod.` trong bundle ID có do Apple quy định không. Không tìm thấy nguồn Apple. Mục 2.7.

### 10.5 Bộ gõ đã notarize nhưng mang quarantine
- Bộ gõ đã notarize nhưng mang quarantine (chép từ app sandbox) có chạy không, có bị translocate không; chỉ thử được ở M7. Mục 1.2.
- Chỉ liên quan tới các phương án app chủ sandbox (ba phương án đầu ở mục 1.3); D37 chọn app chủ không sandbox.

### 10.6 Ghi chú phát hành macOS 27.1, ghi chú beta, tracker
- Ghi chú phát hành macOS 27.1 và ghi chú bản beta chưa đọc được; tracker fcitx5-macos và aquaskk không rà được. Mục 2.1.

### 10.7 `TISDisableInputSource` lên mode đang được chọn
- Hệ thống đổi sang nguồn nào khi Dấu bị tắt: đã đo 04/11 khi bỏ Dấu bằng "–": macOS chuyển sang U.S. (kế hoạch thử trên máy sạch đã bỏ). Mục 4.

### 10.8 Mục ẩn
- Mục ẩn (bundle đã xoá, mục còn trong `AppleEnabledThirdPartyInputSources`): dọn được bằng cài lại đúng ID rồi bấm "–", không cần tiến trình bộ gõ chạy (phép hồi sinh mục ẩn, bản thử, 04/11, mục 4.1).
- Còn mở: mục ẩn có hiện lại ở đâu sau một lần đăng xuất/đăng nhập không (phép đọc lại sau đăng xuất, mục 4.1). Mục ẩn của `DauProbeC1` đã bị dọn trong phép hồi sinh, nên cần tạo lại một mục ẩn để đo.

### 10.9 Vì sao ml-ime ghi được miền `com.apple.inputsources`
- Vì sao ml-ime ghi được miền này bằng `defaults write` trên macOS 26.5.2/26.6.2 trong khi Arion (26.6.2) và máy này (27.2) bị chặn; Full Disk Access có mở khoá không.
- Chưa đo; kế hoạch (phép xem Full Disk Access của Terminal và phép chẩn đoán bằng khoá giả) ở mục 4.1, chỉ để chẩn đoán.

### 10.10 Bộ đệm `IntlDataCache.le*` riêng của từng app có sandbox
(Mục 9.10; vòng bộ đệm riêng ở mục 8.1b, bản thử.)
- **Đã đo bằng bản thử:**
  - Bộ đệm có sẵn thì được dùng mà không kiểm tra lại. Mở lại app hay nhận thông báo đổi nguồn đều không làm nó dựng lại.
  - Xoá bộ đệm của app đã thoát thì lần mở sau dựng lại.
  - Xoá bộ đệm của app đang chạy thì nó dựng lại ở lần đăng ký nguồn tiếp theo. Thứ tự "chép → xoá bộ đệm của app → đăng ký → bật" làm app đang chạy dùng được nguồn mới mà không cần mở lại.
  - Tiến trình không sandbox dùng bộ đệm chung, và bộ đệm này tự dựng lại.
- **Đã đo bằng Dấu thật (mục 9.11):** luồng bật theo D37 đã sửa làm Telegram đang chạy, với bộ đệm cũ, dùng được Dấu mà không cần mở lại. 5 thư mục được hệ thống bảo vệ thì bỏ qua, không có hộp thoại xin quyền.
- **Đã đo bằng Dấu thật, đăng xuất (mục 9.12):** đăng xuất không xoá bộ đệm của từng app, nhưng sau khi đăng nhập lại, mỗi app dựng lại bộ đệm ở lần đầu đọc nguồn đầu vào và thấy Dấu (app thử có bộ đệm cũ không có Dấu; Telegram).
- **Còn mở:**
  - Khởi động lại máy có làm như đăng xuất không.
  - Các tiến trình nằm trong 5 thư mục được bảo vệ (WebKit, bộ đệm của Shortcuts) có giữ bộ đệm cũ không, và có ô nhập chữ nào bị ảnh hưởng không.
  - Sau khi gỡ, các bộ đệm cũ còn `DauInputMethod.app` thì có hậu quả gì.
  - Đo trên macOS 14–26 và bản ký Developer ID (không đo trên tài khoản macOS mới: kế hoạch ở mục 7 đã bỏ, người dùng chốt 04/11/2026).

## Nguồn

**Apple**
- Header SDK: `/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Headers/TextInputSources.h` (`TISRegisterInputSource`, `TISEnableInputSource`, `TISDisableInputSource`, `TISSelectInputSource`, `TISCopyCurrentASCIICapableKeyboardLayoutInputSource`) và `HIToolbox.tbd` cùng SDK.
- Apple Developer Forums, thread 775526 "Avoiding logoff when installing new/modified InputMethodKit input source" (DTS, 06/2026): https://developer.apple.com/forums/thread/775526
- Apple Developer Forums, sandbox và quarantine (Quinn): https://developer.apple.com/forums/thread/811450 , https://developer.apple.com/forums/thread/701687
- Apple, App Sandbox Temporary Exception Entitlements: https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AppSandboxTemporaryExceptionEntitlements.html
- Apple, Notarizing macOS software before distribution: https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- Apple, `NSRunningApplication.terminate()` / `forceTerminate()`: https://developer.apple.com/documentation/appkit/nsrunningapplication/terminate() ; https://developer.apple.com/documentation/appkit/nsrunningapplication/forceterminate()
- Apple, `NSWorkspace.runningApplications`: https://developer.apple.com/documentation/appkit/nsworkspace/runningapplications
- Apple, `LSFileQuarantineEnabled`: https://developer.apple.com/documentation/bundleresources/information-property-list/lsfilequarantineenabled
- Ghi chú phát hành macOS: https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes ; `…/macos-27_2-release-notes` ; `…/macos-26-release-notes` ; `…/macos-26_1-release-notes` đến `…/macos-26_6-release-notes` (bản `.json` dưới `https://developer.apple.com/tutorials/data/documentation/macos-release-notes/`)
- Apple, trang InputMethodKit: https://developer.apple.com/documentation/inputmethodkit
- Apple, QA1810: https://developer.apple.com/library/archive/qa/qa1810/_index.html
- Apple, hướng dẫn macOS 26 về nguồn nhập liệu (chỉ qua tóm tắt tìm kiếm): https://support.apple.com/en-kz/guide/mac-help/mchl84525d76/26/mac/26
- Apple Developer Forums, entitlement riêng của Apple (Quinn, DTS, 06/2024): https://developer.apple.com/forums/thread/756747 ; TN3125 Inside Code Signing: Provisioning Profiles: https://developer.apple.com/documentation/technotes/tn3125-inside-code-signing-provisioning-profiles
- Apple, Apple Events Entitlement: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.automation.apple-events ; `NSAppleEventsUsageDescription`: https://developer.apple.com/documentation/bundleresources/information-property-list/nsappleeventsusagedescription ; `AXIsProcessTrustedWithOptions(_:)`: https://developer.apple.com/documentation/applicationservices/1459186-axisprocesstrustedwithoptions
- Apple Support, Allow accessibility apps to access your Mac: https://support.apple.com/guide/mac-help/allow-accessibility-apps-to-access-your-mac-mh43185/mac ; cài hồ sơ cấu hình: https://support.apple.com/guide/mac-help/mh35561/mac
- Apple, `man profiles` (macOS 27.2): từ macOS 11 công cụ không cài được hồ sơ cấu hình.
- Apple, device-management, khai báo Keyboard Settings: https://github.com/apple/device-management/blob/release/declarative/declarations/configurations/keyboard.settings.yaml
- Apple Developer Forums (người dùng, 2020), GUI scripting nhạy với thay đổi giao diện: https://developer.apple.com/forums/thread/131014

**Hệ thống macOS 27.2 (đọc trên máy)**
- `/System/Library/ExtensionKit/Extensions/KeyboardSettings.appex/Contents/Resources/Localizable.loctable`, `…/LoginItems.appex/…`, `…/GeneralSettings.appex/…`; binary `KeyboardSettings`.
- `HIToolbox` trong dyld cache `/System/Volumes/Preboot/Cryptexes/OS/System/Library/dyld/dyld_shared_cache_arm64e*`.
- `/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/HIServices.framework/Versions/A/XPCServices/com.apple.hiservices-xpcservice.xpc` (chuỗi, nhập khẩu, entitlement); `/System/Library/CoreServices/UAUPlugins/TextInputSourceUAU.bundle` (chuỗi); `/System/Applications/System Settings.app/Contents/Resources/SettingsAppleScript.sdef`; nhật ký cfprefsd 02/11/2026 (mục 4.1).

**Ngoài**
- Homebrew Cask Cookbook: https://docs.brew.sh/Cask-Cookbook ; cask JSON: https://formulae.brew.sh/api/cask/{openkey,evkey,gotiengviet,xkey,phtv,gonhanh}.json
- Sparkle, Sandboxing: https://sparkle-project.org/documentation/sandboxing/
- Squirrel: https://github.com/rime/squirrel (`sources/InputSource.swift`, `scripts/postinstall`, `package/Distribution`, `package/conclusion.html`, `README.md`); issue #1083 https://github.com/rime/squirrel/issues/1083 , #1082 https://github.com/rime/squirrel/issues/1082 , #1169 https://github.com/rime/squirrel/issues/1169
- McBopomofo: https://github.com/openvanilla/McBopomofo (`Source/Installer/AppDelegate.swift`, `Packages/InputSourceHelper`, `README.markdown`)
- vChewing: https://github.com/vChewing/vChewing-macOS (`Packages/vChewing_InstallerAssembly4Darwin/…/InstallerVMProtocol.swift`, `ValueAdd/PKGInstallerAssets/pkgPostInstall.sh`, `Packages/vChewing_IMKUtils/…/TISInputSourceExtension.swift`). Commit "Fix IME activation issues on macOS 12" (bản sao): https://testgitea.trustie.net/floraachy/vChewing-macOS/commit/883dc6144662b19f11ca0838a37ba258af5114d1 (không đọc được nội dung vì trang yêu cầu đăng nhập; chỉ dùng tóm tắt từ kết quả tìm kiếm cho ý "cờ enabled có thể báo sai trên macOS 12", đã có mã tương ứng trong McBopomofo)
- macSKK: https://github.com/mtgto/macSKK (`docs/guide/install.md`, `docs/guide/uninstall.md`, `script/scripts/postinstall`)
- fcitx5-macos: https://github.com/fcitx-contrib/fcitx5-macos (`src/config/about.swift`, `assets/uninstall.sh`, `README.md`)
- Gureum: https://github.com/gureum/gureum (`README.md`, `OSX/Gureum.entitlements`)
- XKey: https://github.com/xmannv/xkey (`XKey/Utilities/IMKitHelper.swift`, `XKey/App/XKeyIMUpdateManager.swift`, `XKeyIM/README.md`); issue #75 https://github.com/xmannv/xkey/issues/75
- AquaSKK: https://github.com/codefirst/aquaskk (README)
- msime: https://github.com/metasequoiaime/msime — PR #2492 https://github.com/metasequoiaime/msime/pull/2492 , PR #3738 https://github.com/metasequoiaime/msime/pull/3738 , PR #2481 https://github.com/metasequoiaime/msime/pull/2481 , `platforms/macos/README.md`, `docs/macos-parity.md`
- marinaMoji, issue #66: https://github.com/marinaMoji/marinaMoji/issues/66
- tabulador, PR #9: https://github.com/glrodasz/tabulador/pull/9
- low-talker PR #96: https://github.com/brandon-fryslie/low-talker/pull/96
- Mẫu IMKit của ensan-hcl: https://github.com/ensan-hcl/macOS_IMKitSample_2021
- logcg, kích hoạt bộ gõ không cần khởi động lại (Mojave): https://www.logcg.com/en/archives/3263.html
- OpenKey: https://github.com/tuyenvm/OpenKey (`Sources/OpenKey/macOS/ModernKey/AppDelegate.m`, `OpenKeyHelper/AppDelegate.m`); goxkey: https://github.com/huytd/goxkey (`Cargo.toml`)
- UniKey trên macOS: https://www.unikey.org/en/apple.html
- msime, gỡ trên macOS 27: PR #3765 https://github.com/metasequoiaime/msime/pull/3765 , PR #3775 https://github.com/metasequoiaime/msime/pull/3775 , ghi chú `.agents/notes/implemented/bug-fix/2026-10-19-macos-uninstall-stale-input-list.md`
- Arion, `docs/research/input-source-onboarding.md`: https://github.com/AstraFoundry/Arion
- ml-ime, `notes/inputmethodkit.md`, `macos/ContextProbe/Tools/sweep.sh` (nhánh `dev`), PR #90: https://github.com/lexoliu/ml-ime/pull/90
- qingjian, `apps/macos/pkg/scripts/postinstall` (commit 96a021e), issue #209: https://github.com/qingjian-team/qingjian/issues/209
- tisutil (Divvun), `docs/spec/session.md`: https://github.com/divvun/tisutil
- Shanjie, `docs/contracts/system-install.md`: https://github.com/Nanako0129/shanjie
- Homebrew cask JSON (04/11/2026): https://formulae.brew.sh/api/cask/{squirrel-app,macskk,mcbopomofo,gureumkim,aquaskk,xkey,keyman,google-japanese-ime,sogouinput,wetype,openkey,evkey}.json
- Late Night Software, AppleScript và System Settings trên Ventura: https://forum.latenightsw.com/t/applescripts-not-working-on-new-system-settings-on-macos-ventura/3986
