# Cửa sổ Cài đặt: API SwiftUI/AppKit cho sidebar, thanh công cụ, tiêu đề (tra tài liệu Apple)

Nghiên cứu cho cửa sổ Cài đặt của app chủ (`Apps/Dau/Sources/SettingsWindow.swift`), theo yêu cầu người dùng 05/11/2026: học API trước, không vá vì thiếu hiểu biết.

Nguồn chỉ dùng loại chính thức của Apple:
- tài liệu developer.apple.com (đọc qua dạng JSON `https://developer.apple.com/tutorials/data/documentation/…json`);
- Human Interface Guidelines (HIG);
- bản ghi lời các phiên WWDC;
- giao diện Swift của SDK trong Xcode trên máy (`SwiftUI.swiftinterface`, macOS SDK 27.2).

Phần tra tài liệu (mục 1 đến 9) không chạy app, không mở cửa sổ nào, không sửa mã.

Nhãn dùng trong file:

| Nhãn | Nghĩa |
|---|---|
| **[Tài liệu]** | Câu có trong trang tài liệu API của Apple (link kèm theo). |
| **[HIG]** | Câu có trong Human Interface Guidelines. |
| **[WWDC]** | Câu nói trong một phiên WWDC (bản ghi lời trên trang video). |
| **[SDK]** | Đọc từ `SwiftUI.swiftinterface` của SDK trên máy (chỉ chứng minh API có hay không, không nói hành vi). |
| **[Suy luận, cần kiểm chứng]** | Suy ra từ các nguồn trên, Apple không viết thẳng. |
| **[Phải đo]** | Chỉ trả lời được bằng cách chạy cửa sổ thật (hỏi người dùng giờ chạy, CLAUDE.md). |
| **[Đo trên app thử]** | Đo trên app thử ném đi (`build/probe-fixed-sidebar/`, ID riêng, không phải Dấu); chỉ là quan sát, chưa phải kết luận về Dấu. |
| **[Đo của Dấu]** | Số hay hành vi Dấu đã đo, dẫn nơi ghi; không phải tài liệu Apple. |

## Hiện trạng (06/11/2026)

Phương án xét ở mục 7: cụm Lùi/Tiến ở `.navigation`, tiêu đề hệ thống `navigationTitle`, chặn thu gọn sidebar bằng `columnVisibility`.

- **Sidebar cố định bằng split view của chính app (06/11/2026; D9 (Giao diện) sửa theo; bằng chứng: mục 10):**
  - [Đo trên app thử] Cửa sổ scene SwiftUI chứa `NSSplitViewController` do app tạo.
    - Sidebar: `canCollapse = false`, `canCollapseFromWindowResize = false`, độ dày tối thiểu = tối đa = 232.
    - Nội dung SwiftUI nằm trong `NSHostingController`; thanh công cụ và tiêu đề đi qua `sceneBridgingOptions`.
  - Kết quả: sidebar giữ 232 qua kéo chuột, bấm đúp, đặt `AXSplitter`, đổi cỡ cửa sổ.
  - Thanh công cụ, tiêu đề, Lùi/Tiến, ⌘[ ⌘] khớp Dấu hiện tại.
  - `searchable(placement: .sidebar)` không vào sidebar khi không có `NavigationSplitView`; thay bằng `NSSearchField` `controlSize = .large`.
  - Các kết luận dưới đây (05/11/2026) vẫn đúng về SwiftUI.
- **Đã áp dụng (05/11/2026, D9; bằng chứng: mục 2.4, 3.2):**
  - Cụm Lùi/Tiến `ControlGroup` kiểu `.navigation` ở `.navigation`, `navigationTitle` của hệ thống.
  - `SidebarCommands` đã gỡ 06/11/2026 khi sidebar thành cố định (D9).
  - Đã gỡ `PageTitle`, `HiddenWindowTitle`, `RemoveToolbarTitle`; không chặn thu gọn sidebar.
  - [Đo của Dấu] Gắn `.toolbar` của cụm lên trang trong cột chi tiết thì đổi trang làm item dựng lại, và AXPress trên Lùi/Tiến trả lỗi -25205 dù vẫn chạy.
  - [Đo của Dấu] Gắn lên `NavigationSplitView` thì AXPress trả 0 (đo bằng app thử, rồi trên Dấu).
  - `run.sh` 05/11/2026 đạt toàn bộ.
  - Menu View có Lùi ⌘[, Tiến ⌘], "Hiển thị thanh bên" ⌃⌘S và mục toàn màn hình.
  - Điểm (a) của bullet "Hai việc mới phát hiện" bên dưới không xảy ra, vì không còn thay nhóm `.sidebar`.
- **Chặn người dùng thu gọn hay kéo rộng sidebar: SwiftUI không có API nào (mục 1.2, 1.3, 1.6, 8).**
  - Tài liệu chỉ có `navigationSplitViewColumnWidth` (độ rộng "ưu tiên", hệ thống "cố gắng" theo) và `columnVisibility` ("điều khiển bằng mã").
  - Không câu nào nói hai thứ này ngăn người dùng kéo.
  - Tra toàn bộ chỉ mục tài liệu SwiftUI và `SwiftUI.swiftinterface` không thấy API nào khác ([SDK]).
  - HIG còn khuyên điều ngược lại: cho người dùng ẩn sidebar và có nhiều cách mở lại (mục 1.6).
  - `FixedSidebar` dùng API công khai của AppKit nhưng đặt lên cấu trúc bên trong mà SwiftUI không công bố, nên không có cam kết nào là còn chạy ở macOS sau.
- **Thanh công cụ co còn 32 pt khi gỡ nút sidebar: Apple không ghi tài liệu cho hành vi này (mục 2.7).**
  - Cách được tài liệu hỗ trợ để có tiêu đề hệ thống nằm ngay sau cụm nút như System Settings: đặt nút điều hướng ở `ToolbarItemPlacement.navigation`.
  - Tài liệu ghi vị trí đó là "mép đầu thanh công cụ, **trước tiêu đề inline**" (mục 2.4).
  - Khi chỉ có nút ở `.navigation`, thanh vẫn cao 52 pt và tiêu đề hệ thống 15 pt đậm (đo 05/11/2026, `docs/research/SYSTEM-SETTINGS-REFERENCE.md`).
- **Lùi/Tiến: hệ thống không có sẵn cho `NavigationSplitView` trên macOS (mục 3.1, 3.2).**
  - `NavigationStack` chỉ cho nút Lùi, không có Tiến.
  - Theo Apple, System Settings được dựng bằng SwiftUI, "navigation split view và stack" (WWDC22), nhưng Apple không nói Lùi/Tiến của nó làm thế nào.
  - Cách làm khớp tài liệu: app tự giữ lịch sử chọn mục, đặt hai nút trong `ToolbarItem(placement: .navigation)` (gói bằng `ControlGroup`), và có lệnh trên thanh menu tương ứng (HIG).
- **Đối chiếu phương án ở mục 7:** hai phần đầu có tài liệu ủng hộ; phần thứ ba (chặn thu gọn bằng `columnVisibility`) không có, và thuộc loại "chống lại người dùng" mà HIG khuyên tránh.
- **Hai việc phát hiện ngày 05/11, đã giải quyết (mục 1.5, 6):**
  - (a) Thay cả nhóm `.sidebar` có thể bỏ luôn "Enter/Exit Full Screen". Mã hiện nay không thay nhóm đó mà chỉ thêm Lùi/Tiến vào trước nó (`SettingsHistoryCommands`), nên câu hỏi không còn.
  - (b) Sidebar của System Settings đã đo ngày 05/11/2026: kéo đường chia và bấm đúp không đổi độ rộng, không thu được (`docs/research/SYSTEM-SETTINGS-REFERENCE.md`).
- Mọi phiên bản macOS ghi trong file là phiên bản Apple ghi trên trang tài liệu.
  - D1 (Nền tảng) đặt tối thiểu macOS 14, nên API cần macOS 15 trở lên phải có `if #available`.

## 1. `NavigationSplitView` trên macOS: sidebar, độ rộng, thu gọn

### 1.1 `NavigationSplitView` (macOS 13+)

- [Tài liệu] "On some platforms, `NavigationSplitView` adds a `sidebarToggle` toolbar item. Use the `toolbar(removing:)` modifier to remove the default item."
  - Về độ rộng: "The navigation split view does its best to accommodate the preferences that you specify, but might make adjustments based on other constraints."
  - Nguồn: https://developer.apple.com/documentation/swiftui/navigationsplitview
- [WWDC] Phiên "What's new in SwiftUI" (WWDC22): System Settings của macOS Ventura "features a streamlined navigation structure, built using the navigation split view and stacks". https://developer.apple.com/videos/play/wwdc2022/10052/
- Dùng cho Dấu thế nào: giữ `NavigationSplitView`, đúng cấu trúc Apple nói System Settings dùng.

### 1.2 `columnVisibility` và `NavigationSplitViewVisibility` (macOS 13+)

- [Tài liệu] `init(columnVisibility:sidebar:detail:)`: "Creates a two-column navigation split view that enables **programmatic control** of the sidebar's visibility." https://developer.apple.com/documentation/swiftui/navigationsplitview/init(columnvisibility:sidebar:detail:)
- [Tài liệu] Các giá trị: `.automatic`, `.all`, `.doubleColumn` (với hai cột thì "equivalent to `all`"), `.detailOnly`.
  - Ghi chú: "Some platforms don't respect every option. For example, macOS always displays the content column."
  - https://developer.apple.com/documentation/swiftui/navigationsplitviewvisibility
- [Tài liệu] Trang `NavigationSplitView` chỉ có ví dụ đặt `.detailOnly` bằng mã khi view hiện ra; không có câu nào nói binding chặn người dùng thu gọn.
- Binding có nhận thay đổi khi người dùng kéo thu sidebar (hay bấm nút, chọn lệnh menu) không: tài liệu không nói.
  - [Suy luận, cần kiểm chứng] Vì là `Binding` hai chiều, SwiftUI có lẽ ghi `.detailOnly` vào khi người dùng thu gọn.
  - [Phải đo] Kéo đường chia tới khi sidebar thu lại, đọc giá trị binding; rồi đặt lại `.all` trong `onChange` xem sidebar có mở lại không, có giật không.
- Dùng cho Dấu thế nào:
  - Đây là API được hỗ trợ để **mở lại** sidebar bằng mã (ví dụ khi mở cửa sổ).
  - Nó không phải API để **ngăn** thu gọn.
  - Muốn dùng nó để đẩy sidebar mở lại ngay sau khi người dùng thu thì đó là suy luận, phải đo, và trái khuyến nghị của HIG (mục 1.6).

### 1.3 `navigationSplitViewColumnWidth` (macOS 13+)

- [Tài liệu] `navigationSplitViewColumnWidth(_:)`: "Sets a **fixed, preferred** width for the column containing this view." https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(_:)
- [Tài liệu] `navigationSplitViewColumnWidth(min:ideal:max:)`: "Sets a **flexible**, preferred width…". https://developer.apple.com/documentation/swiftui/view/navigationsplitviewcolumnwidth(min:ideal:max:)
  - Cả hai trang: "Only some platforms enable resizing columns. If you specify a width that the current presentation environment doesn't support, SwiftUI may use a different width for your column."
- Tài liệu không nói `min`/`max` có giới hạn được việc người dùng kéo trên macOS hay không, cũng không nói gì về thu gọn.
- [Đo của Dấu, bản dùng `NavigationSplitView` trước mục 10] Đường chia vẫn kéo được dù độ rộng cố định, kéo có thể thu gọn sidebar (chú thích của `FixedSidebar`; mục 16 của `docs/UI-CHECKS.md`).
- Dùng cho Dấu thế nào:
  - `navigationSplitViewColumnWidth(232)` (một giá trị) đúng với ý "độ rộng cố định" theo tài liệu.
  - Dùng `min = ideal = max` cũng được nhưng tài liệu không hứa thêm gì.
  - Không có API SwiftUI nào biến độ rộng này thành ràng buộc với người dùng.

### 1.4 `navigationSplitViewStyle` (macOS 13+)

- [Tài liệu] `.automatic`, `.balanced` ("reduces the size of the detail content to make room when showing the leading column"), `.prominentDetail` ("attempts to maintain the size of the detail content when hiding or showing the leading columns"). https://developer.apple.com/documentation/swiftui/navigationsplitviewstyle
- Dùng cho Dấu thế nào: chỉ đổi cách cột chi tiết co giãn khi sidebar ẩn/hiện; không có kiểu nào khoá sidebar.

### 1.5 Nút bật/tắt sidebar và lệnh trên thanh menu

- [Tài liệu] `toolbar(removing:)` (macOS 14+): "Remove a toolbar item present by default", ví dụ đặt trên cột sidebar để bỏ nút sidebar. https://developer.apple.com/documentation/swiftui/view/toolbar(removing:)
- [Tài liệu] `ToolbarDefaultItemKind.sidebarToggle` (macOS 14+): "The sidebar toggle toolbar item a `NavigationSplitView` adds by default."
  - `.title` (macOS 15+): "The title and subtitle shown in title bar / navigation bar."
  - `.search` (macOS 26+).
  - https://developer.apple.com/documentation/swiftui/toolbardefaultitemkind
- [Tài liệu] `SidebarCommands` (macOS 11+): "A built-in set of commands for manipulating window sidebars. These commands are optional and can be explicitly requested by passing a value of this type to the `commands(content:)` modifier." https://developer.apple.com/documentation/swiftui/sidebarcommands
- [Tài liệu] `CommandGroupPlacement.sidebar` (macOS 11+): "Placement for commands that control the app's sidebar and full-screen modes. By default, this group includes the following commands in macOS: Show/Hide Sidebar, Enter/Exit Full Screen." https://developer.apple.com/documentation/swiftui/commandgroupplacement/sidebar
- [Tài liệu] `CommandGroup(replacing:addition:)`: "complete replacement of the contents of the indicated group". https://developer.apple.com/documentation/swiftui/commandgroup/init(replacing:addition:)
- [Suy luận, cần kiểm chứng] Vì thay **toàn bộ** nhóm, `CommandGroup(replacing: .sidebar) {}` có thể bỏ cả "Enter/Exit Full Screen" trong menu View.
  - [Đã giải quyết] Mã hiện nay không thay nhóm này, chỉ thêm vào (`SettingsHistoryCommands`), nên mục toàn màn hình vẫn còn.
  - Việc cửa sổ Cài đặt có vào toàn màn hình được không còn phụ thuộc `windowResizability` và khung tối đa, nên đo cả hai.
- [Tài liệu, chưa rõ] Hai trang trên lệch nhau: `SidebarCommands` "optional", còn nhóm `.sidebar` "by default" có Show/Hide Sidebar.
  - Chú thích của `SettingsHistoryCommands` (mã hiện nay, không dùng `SidebarCommands`) ghi menu View không có "Show/Hide Sidebar"; tài liệu này chưa ghi số đo riêng cho điều đó.
- [HIG] Thanh menu, menu View: "Show/Hide Sidebar — In a window that includes a sidebar, toggles the sidebar's visibility." https://developer.apple.com/design/human-interface-guidelines/the-menu-bar

### 1.6 HIG: có nên cho người dùng ẩn sidebar trên macOS

- [HIG] Sidebars: "**Consider letting people hide the sidebar.** … When possible, let people hide and show the sidebar using the platform-specific interactions they already know. For example, … in macOS, you can include a show/hide button or add Show Sidebar and Hide Sidebar commands to your app's View menu. … Avoid hiding the sidebar by default to ensure that it remains discoverable." https://developer.apple.com/design/human-interface-guidelines/sidebars
- [HIG] Split views, macOS: https://developer.apple.com/design/human-interface-guidelines/split-views
  - "Set reasonable defaults for minimum and maximum pane sizes. If people can resize the panes … make sure to use sizes that keep the divider visible."
  - "Consider letting people hide a pane when it makes sense."
  - "**Provide multiple ways to reveal hidden panes.** For example, you might provide a toolbar button or a menu command — including a keyboard shortcut — that people can use to restore a hidden pane."
- [HIG] Toolbars, nhóm mục: "Leading edge. Elements that let people return to the previous document and show or hide a sidebar appear at the far leading edge, followed by the view title." https://developer.apple.com/design/human-interface-guidelines/toolbars
- Dùng cho Dấu thế nào:
  - HIG dùng chữ "consider", không bắt buộc phải cho ẩn.
  - Nhưng **một khi sidebar thu gọn được thì phải có cách mở lại** (nút hoặc lệnh menu kèm phím tắt).
  - Lỗi đã gặp (thu gọn được mà không mở lại được) là đúng trường hợp HIG cảnh báo.
  - System Settings không cho thu gọn sidebar (đo ngày 05/11/2026, `docs/research/SYSTEM-SETTINGS-REFERENCE.md`).

## 2. Thanh công cụ và tiêu đề trên macOS

### 2.1 `navigationTitle`, `navigationSubtitle`

- [Tài liệu] `navigationTitle` (macOS 11+ bản `StringProtocol`; macOS 13+ bản `LocalizedStringResource`): "on macOS, the primary destination's title is used as the window title in the titlebar, Windows menu and Mission Control." https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:) và bài https://developer.apple.com/documentation/swiftui/configure-your-apps-navigation-titles
- [Tài liệu] `navigationSubtitle` (macOS 13+): "On macOS, the primary destination's subtitle is displayed with the navigation title in the titlebar." https://developer.apple.com/documentation/swiftui/view/navigationsubtitle(_:)
- [WWDC] Phiên "Adopt the new look of macOS" (WWDC20): https://developer.apple.com/videos/play/wwdc2020/10104/
  - Kiểu thanh công cụ unified "supports the new inline title, which is placed at the leading edge of the toolbar, next to the sidebar".
  - Tiêu đề phụ nằm dưới tiêu đề chính ở kiểu unified.
- [HIG] Settings, macOS: "Update the window's title to reflect the currently visible pane." https://developer.apple.com/design/human-interface-guidelines/settings
- Dùng cho Dấu thế nào: `navigationTitle(section.title)` trên cột chi tiết là đúng API và đúng HIG; tiêu đề hệ thống chính là thứ `PageTitle` đang vẽ lại bằng tay.

### 2.2 `toolbarRole`

- [Tài liệu] `toolbarRole(_:)` macOS 13+. https://developer.apple.com/documentation/swiftui/toolbarrole
  - `ToolbarRole.automatic`: "In macOS, this resolves to the `editor` role."
  - `.editor` có trên macOS, nhưng phần mô tả chỉ nói iPadOS.
  - `.browser` và `.navigationStack` **không có macOS** trong danh sách nền tảng.
- Dùng cho Dấu thế nào: trên macOS không có vai trò nào khác để chọn; không ảnh hưởng chiều cao hay tiêu đề theo tài liệu.

### 2.3 `toolbarTitleDisplayMode`, `toolbarTitleAlignment`, placement tiêu đề

- [Tài liệu] `toolbarTitleDisplayMode(_:)` (macOS 14+): "**This modifier has no effect on macOS.**" https://developer.apple.com/documentation/swiftui/view/toolbartitledisplaymode(_:)
- [Tài liệu] `toolbarTitleAlignment(_:)`: chỉ iOS/iPadOS/Mac Catalyst 27.2. https://developer.apple.com/documentation/swiftui/view/toolbartitlealignment(_:)
- [Tài liệu] `ToolbarItemPlacement.title`, `.subtitle`, `.largeTitle` (thay tiêu đề hệ thống bằng view riêng): chỉ iOS/iPadOS/Mac Catalyst, **không có macOS**. https://developer.apple.com/documentation/swiftui/toolbaritemplacement/title
- Dùng cho Dấu thế nào:
  - Trên macOS không có chỗ hợp lệ để đặt một view tiêu đề tự vẽ thay tiêu đề hệ thống.
  - `PageTitle` đang mượn `.navigation`, placement dành cho nút điều hướng (mục 2.4).

### 2.4 `ToolbarItemPlacement` trên macOS (macOS 11+)

- [Tài liệu] `.navigation`: "Navigation actions allow the user to move between contexts. For example, the forward and back buttons of a web browser are navigation actions. In macOS …, the system places navigation items in the leading edge of the toolbar **ahead of the inline title if that is present** in the toolbar." https://developer.apple.com/documentation/swiftui/toolbaritemplacement/navigation
- [Tài liệu] `.principal`: "In macOS …, the system places the principal item in the center of the toolbar." https://developer.apple.com/documentation/swiftui/toolbaritemplacement/principal
- [Tài liệu] `.automatic`: "In macOS …, the system places items in the current toolbar section in order of leading to trailing." https://developer.apple.com/documentation/swiftui/toolbaritemplacement/automatic
- [Tài liệu] `.primaryAction`: "In macOS …, the location for the primary action is the leading edge of the toolbar." https://developer.apple.com/documentation/swiftui/toolbaritemplacement/primaryaction
- [WWDC] WWDC20 "Adopt the new look of macOS": "if your toolbar contains controls, such as back and forward, these items belong to the leading edge of the window … they can't be moved out of this title-leading position."
- Dùng cho Dấu thế nào:
  - Lùi/Tiến đặt ở `.navigation` thì theo tài liệu sẽ nằm ở mép đầu, trước tiêu đề inline.
  - Đúng bố cục System Settings (cụm Lùi/Tiến rồi tiêu đề, `docs/research/SYSTEM-SETTINGS-REFERENCE.md`).
  - [Phải đo] Toạ độ cụm nút và chữ tiêu đề so với System Settings.

### 2.5 `toolbar(removing: .title)` (macOS 15+)

- [Tài liệu] `ToolbarDefaultItemKind.title`: "The title and subtitle shown in title bar / navigation bar." macOS 15+. https://developer.apple.com/documentation/swiftui/toolbardefaultitemkind/title
- [WWDC] "Tailor macOS windows with SwiftUI" (WWDC24): https://developer.apple.com/videos/play/wwdc2024/10148/
  - Bỏ tiêu đề bằng `.toolbar(removing:)`.
  - "Even though the title is hidden from the user interface, it is still associated with the window. It will be used by accessibility, and other features. For example, the main menu item will continue to show the window title."
- Dùng cho Dấu thế nào:
  - API đúng để ẩn tiêu đề hệ thống mà vẫn giữ tên cửa sổ, nhưng cần macOS 15 (D1 là 14).
  - Chỉ cần khi có tiêu đề tự vẽ; dùng tiêu đề hệ thống thì không cần.

### 2.6 `windowToolbarStyle`, `presentedWindowToolbarStyle` (macOS 11+)

- [Tài liệu] `Scene.windowToolbarStyle(_:)`: "Sets the style for the toolbar defined within this scene." https://developer.apple.com/documentation/swiftui/windowtoolbarstyle
  - Kiểu: `.automatic`.
  - `.unified` ("displays its toolbar and title bar inline"); `.unified(showsTitle:)`.
  - `.unifiedCompact` ("similar to unified, but with a more compact vertical sizing"); `.unifiedCompact(showsTitle:)`.
  - `.expanded` ("displays its title bar area above the toolbar").
- [Tài liệu] AppKit tương ứng, `NSWindow.toolbarStyle` (macOS 11+): https://developer.apple.com/documentation/appkit/nswindow/toolbarstyle-swift.property
  - `.unified`: "toolbar appears next to the window title".
  - `.unifiedCompact`: "… with reduced margins".
  - `.expanded`: "toolbar appears below the window title".
  - `.preference`: "below the window title with toolbar items centered".
  - Mặc định `.automatic`.
- [WWDC] WWDC20: unified compact "has a more compressed layout with regular-sized controls and a smaller toolbar height. This is the look that's been used in the past if your window was configured to hide the window's title."
- [Tài liệu] `presentedWindowToolbarStyle(_:)` (macOS 11+): "Sets the style for the toolbar in windows created by interacting with this view." Không có mô tả thêm. https://developer.apple.com/documentation/swiftui/view/presentedwindowtoolbarstyle(_:)
- Dùng cho Dấu thế nào:
  - `.windowToolbarStyle(.unified(showsTitle: false))` trên scene `Window` là cách công khai, không cần `NSViewRepresentable`, để ẩn chữ tiêu đề ở macOS 14 (thay `HiddenWindowTitle`).
  - [Suy luận, cần kiểm chứng] Tên cửa sổ vẫn được giữ cho menu Window và VoiceOver như với `toolbar(removing: .title)`; tài liệu của `showsTitle` không nói.
  - `presentedWindowToolbarStyle` không dùng: cửa sổ Cài đặt là scene `Window`, không phải cửa sổ do view khác mở ra.

### 2.7 Thanh công cụ không có mục nào: vì sao co lại

- Không tìm thấy trang tài liệu, mục HIG hay phiên WWDC nào mô tả chiều cao thanh công cụ khi không có mục nào, hay việc SwiftUI có gắn `NSToolbar` vào cửa sổ hay không trong trường hợp đó.
- [Đo của Dấu] Khi bỏ nút sidebar và không còn mục nào: thanh co từ 52 còn 32, tiêu đề thành chữ tiêu đề cửa sổ nhỏ (đo ở màn 1x, `docs/research/SYSTEM-SETTINGS-REFERENCE.md`, mục "Cửa sổ, thanh công cụ, tiêu đề").
  - Ô tìm `searchable(placement: .sidebar)` không giữ được thanh cao 52 (theo chú thích trong `SettingsWindow`).
- [Suy luận, cần kiểm chứng] Không còn mục nào thì SwiftUI không gắn thanh công cụ, cửa sổ chỉ còn thanh tiêu đề thường, nên tiêu đề rơi về kiểu chữ tiêu đề cửa sổ.
  - Câu WWDC20 ở mục 2.6 (kiểu thấp là "the look … if your window was configured to hide the window's title") hợp với giả thuyết này nhưng không chứng minh được.
  - [Phải đo] Trong bản Debug, đọc `NSWindow.toolbar` (nil hay không, số mục) ở ba cấu hình:
    - có nút sidebar;
    - không nút sidebar và không mục nào;
    - không nút sidebar nhưng có một mục `.navigation`.
- Dùng cho Dấu thế nào:
  - Thanh co là hệ quả của việc **không có mục nào**.
  - Cách được tài liệu hỗ trợ là có mục thật (Lùi/Tiến ở `.navigation`) chứ không vẽ tiêu đề giả làm mục.

### 2.8 Ẩn thanh công cụ, nền thanh (tham khảo)

- [Tài liệu] `toolbarVisibility(_:for:)` (macOS 15+) và `toolbar(_:for:)` (macOS 13+); `ToolbarPlacement.windowToolbar` (macOS 13+): ẩn bằng placement này thì "hides the entire window toolbar, including the title and 'traffic light' window controls". https://developer.apple.com/documentation/swiftui/toolbarplacement/windowtoolbar
- [Tài liệu] `toolbarBackgroundVisibility(_:for:)` macOS 15+. `ToolbarContent.sharedBackgroundVisibility(_:)` macOS 26+ (tắt nền glass chung của một mục). https://developer.apple.com/documentation/swiftui/toolbarcontent/sharedbackgroundvisibility(_:)
- Dùng cho Dấu thế nào:
  - Không cần cho hướng dùng tiêu đề hệ thống.
  - `sharedBackgroundVisibility(.hidden)` đang có trên `PageTitle` chỉ vì tiêu đề tự vẽ là một mục thanh công cụ.

## 3. Lùi/Tiến kiểu System Settings và HIG cho cửa sổ cài đặt

### 3.1 Hệ thống có sẵn Lùi/Tiến không

- [SDK] Chỉ mục tài liệu SwiftUI và `SwiftUI.swiftinterface` không có API lịch sử Lùi/Tiến nào cho `NavigationSplitView`.
  - Thứ duy nhất có tên "back/forward" là `webViewBackForwardNavigationGestures(_:)` của WebView.
- [Tài liệu] `NavigationStack` (macOS 13+): người dùng "remove views using built-in, platform-appropriate controls, like a Back button"; xoá khỏi ngăn xếp là mất, không có Tiến. https://developer.apple.com/documentation/swiftui/navigationstack
- [WWDC] WWDC22 "The SwiftUI cookbook for navigation": "NavigationStack represents a push-pop interface like you see in … the new System Settings app on macOS Ventura." https://developer.apple.com/videos/play/wwdc2022/10054/
- Apple không ghi tài liệu nào cho Lùi/Tiến của System Settings (đi theo lịch sử các pane đã mở).
  - [Suy luận, cần kiểm chứng] System Settings tự giữ lịch sử; `NavigationStack` không đủ vì không có Tiến.

### 3.2 Mẫu làm khớp tài liệu

- [Tài liệu] `ToolbarItemGroup` (macOS 11+), `ControlGroup` (macOS 12+): "displays semantically-related controls in a visually-appropriate manner for the context"; trong thanh công cụ, nhãn của nhóm dùng khi nhóm bị dồn vào menu tràn. https://developer.apple.com/documentation/swiftui/controlgroup
- [HIG] Toolbars:
  - "Use the standard Back and Close buttons … Prefer the standard symbols for each, and don't use a text label that says Back or Close."
  - "Group navigation controls … in dedicated, familiar, and visually distinct sections."
  - macOS: "**Make every toolbar item available as a command in the menu bar.** Because people can customize the toolbar or hide it, it can't be the only place that presents a command."
- Mẫu đề xuất:
  - App giữ hai ngăn lịch sử chọn mục.
  - `ToolbarItem(placement: .navigation) { ControlGroup { nút Lùi; nút Tiến } }`, nút tắt khi ngăn tương ứng rỗng.
  - Thêm lệnh Lùi/Tiến vào thanh menu bằng `CommandGroup`.
  - Tên lệnh, phím tắt, ký hiệu SF Symbol: [Phải đo] trên System Settings (đọc menu và nhãn trợ năng của nút bằng Accessibility API), không đoán.
- Lưu ý quy trình: Lùi/Tiến là nội dung giao diện mới.
  - Theo CLAUDE.md (canvas trước, mã sau) và D9 (mockup quy định nội dung), phải có artboard được người dùng duyệt trước khi giao viết mã.

### 3.3 HIG cho cửa sổ cài đặt; scene `Settings` hay cửa sổ thường

- [HIG] Settings, macOS: https://developer.apple.com/design/human-interface-guidelines/settings
  - Cửa sổ cài đặt thường có thanh công cụ với các nút chuyển pane.
  - "Dim a settings window's minimize and maximize buttons".
  - "use a noncustomizable toolbar that remains visible and always indicates the active toolbar button".
  - "Update the window's title to reflect the currently visible pane".
  - "**Restore the most recently viewed pane.**"
- [Tài liệu] Scene `Settings` (macOS 11+) bật mục "Settings…" trong menu app và tự quản lý cửa sổ. https://developer.apple.com/documentation/swiftui/settings
- [Tài liệu] `WindowResizability.automatic`: "`Settings` windows use the `contentSize` strategy, while all others use `contentMinSize`." https://developer.apple.com/documentation/swiftui/windowresizability
- Dấu dùng scene `Window` (cửa sổ Cài đặt là giao diện chính của app chủ) với `.windowResizability(.contentSize)`, đúng cách tài liệu tả để giới hạn khung.
  - Mục HIG về cửa sổ cài đặt nói về cửa sổ phụ kiểu thanh nút pane, không nói về bố cục sidebar như System Settings.
- Ghi nhận, không đề xuất sửa: `SettingsWindow` mở ở mục `.typing` mỗi lần, khác khuyến nghị "Restore the most recently viewed pane".
  - Không làm: cửa sổ Cài đặt chỉ có bốn mục, mở ở mục Gõ phím mỗi lần là đủ.

## 4. `searchable(placement: .sidebar)` trên macOS

- [Tài liệu] `SearchFieldPlacement.sidebar` (macOS 12+): "In macOS the search field appears as a **sticky header in the sidebar, attached to the toolbar**. If a sidebar isn't available … SwiftUI uses automatic placement instead." https://developer.apple.com/documentation/swiftui/searchfieldplacement/sidebar
  - Ghi chú: "The search field appears inline with the sidebar's content when building with Xcode 16 SDKs or earlier."
- [Tài liệu] `.toolbar`: "In macOS, the search field appears in the trailing toolbar." `.automatic` trên macOS: trong thanh công cụ. https://developer.apple.com/documentation/swiftui/searchfieldplacement
- [Tài liệu] Bài "Adding a search interface to your app": đặt `searchable` lên `NavigationSplitView` thì ô tìm ở mép cuối thanh công cụ; `placement: .sidebar` để đưa vào cột sidebar. https://developer.apple.com/documentation/swiftui/adding-a-search-interface-to-your-app
- [Tài liệu] `ToolbarDefaultItemKind.search` và `DefaultToolbarItem` (macOS 26+): chỉnh vị trí hoặc bỏ ô tìm do `searchable` thêm. https://developer.apple.com/documentation/swiftui/defaulttoolbaritem
- Dùng cho Dấu thế nào:
  - Giữ nguyên.
  - Ô tìm ở sidebar không phải mục thanh công cụ nên không giữ được chiều cao 52 (mục 2.7).
  - Ô tìm ở trang Ứng dụng (trong thanh công cụ) là chuyện khác, không liên quan việc gỡ tiêu đề.

## 5. AppKit tương đương (chỉ để tham khảo)

- [Tài liệu] `NSSplitViewItem(sidebarWithViewController:)` (macOS 10.11+): sidebar có sẵn "the ability to collapse and expand on split view size changes", `canCollapse` mặc định `true`, độ dày tối thiểu/tối đa theo chuẩn hệ thống. https://developer.apple.com/documentation/appkit/nssplitviewitem/init(sidebarwithviewcontroller:)
- [Tài liệu] `canCollapse` (macOS 10.10+): "determines whether a **user interaction** can collapse the child view controller". https://developer.apple.com/documentation/appkit/nssplitviewitem/cancollapse
  - `canCollapseFromWindowResize` (macOS 10.14+): riêng cho thu gọn do co cửa sổ; "Setting `canCollapse` for sidebars resets this value to that new value."
  - `minimumThickness`/`maximumThickness` (macOS 10.11+).
  - `holdingPriority`.
- [Tài liệu] `NSSplitViewController.toggleSidebar(_:)` (macOS 10.11+): thu/mở sidebar đầu tiên, có hiệu ứng. https://developer.apple.com/documentation/appkit/nssplitviewcontroller/togglesidebar(_:)
- [Tài liệu] `NSTrackingSeparatorToolbarItem` (macOS 11+): vạch ngăn thanh công cụ đi theo đường chia của split view. https://developer.apple.com/documentation/appkit/nstrackingseparatortoolbaritem
  - [WWDC] WWDC20: AppKit có định danh mục chuẩn tự tìm sidebar toàn chiều cao; "Toolbar items placed before the separator will appear over the full-height sidebar."
- [Tài liệu] `NSWindow.toolbarStyle`, `NSWindow.titleVisibility` (macOS 10.10+, mặc định `.visible`). https://developer.apple.com/documentation/appkit/nswindow/titlevisibility-swift.property
- [Tài liệu] `NSSplitView.autosaveName`: tên dùng để tự lưu vị trí đường chia. https://developer.apple.com/documentation/appkit/nssplitview/autosavename-swift.property
  - Tài liệu không nêu khoá defaults mà SwiftUI dùng.
- [WWDC] WWDC22 "Use SwiftUI with AppKit": Shortcuts dùng `NSSplitViewController` của AppKit, sidebar viết bằng SwiftUI trong `NSHostingController`. https://developer.apple.com/videos/play/wwdc2022/10075/
- Dùng cho Dấu thế nào:
  - Nếu cần đúng một sidebar không thu gọn được thì AppKit có API công khai (`canCollapse = false`, độ dày tối thiểu bằng tối đa) **trên `NSSplitViewController` của chính app**.
  - Muốn vậy, cửa sổ phải dựng split view bằng AppKit (sidebar và chi tiết vẫn là view SwiftUI trong `NSHostingController`), không với vào split view do `NavigationSplitView` dựng.
  - Đây là thay đổi kiến trúc lớn; nêu ra để đủ lựa chọn, không đề xuất.
  - (Về sau người dùng chọn hướng này; xem mục 10.)

## 6. System Settings được dựng thế nào (chỉ điều Apple công bố)

- [WWDC] Platforms State of the Union (WWDC22): "the modern, forward-looking design of the new macOS System Settings app was built using [SwiftUI]". https://developer.apple.com/videos/play/wwdc2022/102/
- [WWDC] What's new in SwiftUI (WWDC22): "built using the navigation split view and stacks"; kiểu Form của System Settings có cho app dùng bằng `formStyle(.grouped)`. https://developer.apple.com/videos/play/wwdc2022/10052/
- Apple không công bố:
  - System Settings làm Lùi/Tiến thế nào;
  - sidebar của nó có thu gọn hay kéo rộng được không, làm bằng cách nào;
  - thanh công cụ của nó cấu hình ra sao.
- Đã đo ngày 05/11/2026 (`docs/research/SYSTEM-SETTINGS-REFERENCE.md`): sidebar của System Settings không kéo, không thu được.
- Không đo thêm menu View và nhãn trợ năng của cụm Lùi/Tiến của System Settings: Dấu đã chọn sidebar cố định và Lùi/Tiến kiểu hệ thống (mục 10), nên các số đó không đổi gì.

## 7. Đối chiếu phương án (Lùi/Tiến ở `.navigation`, tiêu đề hệ thống, chặn thu gọn bằng `columnVisibility`)

| Phần của phương án | Tài liệu có ủng hộ không | Bằng chứng | Còn phải đo |
|---|---|---|---|
| Lùi/Tiến ở `ToolbarItemPlacement.navigation` | **Có** | `.navigation` "ahead of the inline title" (mục 2.4); HIG đặt nút quay lại ở mép đầu, rồi tới tiêu đề; WWDC20 "back and forward … title-leading position"; HIG đòi có lệnh trên thanh menu cho mọi mục thanh công cụ | Thanh cao 52, toạ độ cụm nút so với System Settings (cụm 73 × 36 ở x 240); lịch sử là app tự làm (không có API hệ thống) |
| Tiêu đề hệ thống `navigationTitle` (bỏ `PageTitle`) | **Có** | `navigationTitle` là tiêu đề trên thanh tiêu đề, menu Window, Mission Control (mục 2.1); kiểu unified đặt tiêu đề inline cạnh sidebar (WWDC20) | Có mục `.navigation` thì tiêu đề có 15 pt đậm và không co không ([Suy luận, cần kiểm chứng]: số đo mặc định có nút sidebar đã là 52 / 15 đậm) |
| Chặn thu gọn bằng `columnVisibility` | **Không** | Tài liệu chỉ nói "programmatic control"; không câu nào nói binding chặn người dùng; macOS "doesn't respect every option"; HIG khuyên cho ẩn và "provide multiple ways to reveal hidden panes" (mục 1.2, 1.6) | Binding có nhận `.detailOnly` khi kéo không; đặt lại `.all` có mở lại sidebar không, có giật không |

Thay cho phần thứ ba, cách có tài liệu: cho phép thu gọn nhưng luôn mở lại được.
- Bằng lệnh "Show Sidebar" trong menu View (nhóm `.sidebar` mặc định hoặc `SidebarCommands`) và/hoặc nút sidebar.
- Chọn cách nào là quyết định giao diện (D9, canvas trước), không thuộc nghiên cứu này. Sau đó D9 chọn sidebar cố định bằng split view của chính app (mục 10): sidebar không thu được nên không cần lệnh mở lại.

## 8. Từng cách vá hiện có và API được hỗ trợ thay cho nó

Bảng mô tả mã lúc nghiên cứu (05/11/2026).
Về sau: `PageTitle`, `HiddenWindowTitle`, `RemoveToolbarTitle` đã gỡ (05/11/2026); `FixedSidebar` được thay bằng split view của chính app (06/11/2026, mục 10).

| Cách vá (tên trong mã) | Vì sao có | API được hỗ trợ làm nó thừa | Tình trạng bằng chứng |
|---|---|---|---|
| Gỡ nút sidebar: `toolbar(removing: .sidebarToggle)` trong `SettingsWindow` | Cho giống System Settings (không có nút sidebar) | Bản thân nó là API công khai (macOS 14+). Vấn đề là hệ quả: không còn mục nào thì thanh co (mục 2.7) và sidebar thu gọn được mà không mở lại được (mục 1.6) | Tài liệu cho API; hệ quả là [Đo của Dấu] |
| `PageTitle` (tiêu đề 15 pt đậm vẽ tay, đặt ở `ToolbarItem(.navigation)`, khung rộng cố định, lề 16) | Tiêu đề hệ thống co khi thanh không còn mục nào | `navigationTitle` + có ít nhất một mục thật trên thanh công cụ (Lùi/Tiến ở `.navigation`, mục 2.4). macOS không có placement nào để thay tiêu đề bằng view riêng (`.title`, `.largeTitle` chỉ có iOS, mục 2.3), và `.navigation` là chỗ cho nút điều hướng, không phải tiêu đề | Có tài liệu; 52 / 15 đậm khi chỉ có Lùi/Tiến: [Phải đo] |
| `HiddenWindowTitle` (`NSViewRepresentable` đặt `NSWindow.titleVisibility = .hidden`) | Không cho tiêu đề hệ thống hiện cùng `PageTitle` ở macOS 14 | Khi dùng tiêu đề hệ thống thì không cần. Nếu vẫn cần ẩn ở macOS 14: `.windowToolbarStyle(.unified(showsTitle: false))` trên scene (macOS 11+), không phải đi qua `NSWindow` | Có tài liệu; tên cửa sổ có còn trong menu Window không: [Suy luận, cần kiểm chứng] |
| `RemoveToolbarTitle` (`toolbar(removing: .title)` từ macOS 15, không làm gì ở 14) | Không cho tiêu đề vẽ hai lần | Bản thân nó là API công khai (macOS 15+, mục 2.5). Thừa khi bỏ `PageTitle` | Có tài liệu |
| `FixedSidebar` (đi tìm `NSSplitView` mà SwiftUI dựng, đặt `canCollapse = false`, độ dày cố định, phủ một view chặn chuột lên đường chia) và `FixedSidebar.discardSavedState` (xoá khoá defaults `NSSplitView Subview Frames settings, SidebarNavigationSplitView`) | Sidebar kéo thu gọn được mà không có cách mở lại | **Không có cách nào có tài liệu** để khoá sidebar của `NavigationSplitView` (mục 1.2, 1.3; [SDK]). Thuộc tính AppKit thì công khai (mục 5), nhưng việc `NavigationSplitView` dựng bằng `NSSplitViewController`, nó làm delegate của `NSSplitView`, và tên khoá autosave đều không có trong tài liệu. Cách có tài liệu: để thu gọn được nhưng luôn mở lại được (lệnh View › Show Sidebar, nút sidebar) | Bằng chứng "không có API": chỉ mục tài liệu SwiftUI và `SwiftUI.swiftinterface` (SDK 27.2) |
| `CommandGroup(replacing: .sidebar) {}` trong `SettingsCommands` | Bỏ "Show/Hide Sidebar" (⌃⌘S) vì sidebar cố định | API công khai (macOS 11+), nhưng thay **cả nhóm**, mà nhóm gồm cả "Enter/Exit Full Screen" (mục 1.5). Nếu sidebar được thu gọn thì lệnh này chính là cách mở lại mà HIG khuyên giữ | Bỏ mất mục toàn màn hình hay không: [Phải đo] |

## 9. Danh sách đo đề xuất ngày 05/11/2026

Danh sách này không được chạy nguyên như vậy. Mục 3 và 4 không còn áp dụng từ khi sidebar không dùng `NavigationSplitView` nữa (mục 10). Phần sidebar của mục 5 đã đo (`docs/research/SYSTEM-SETTINGS-REFERENCE.md`). Số đo thanh công cụ và tiêu đề của Dấu hiện nay do `scripts/selftest/settings-window/run.sh` kiểm.

Mọi mục dưới đây là thao tác trên cửa sổ thật, chiếm màn hình: hỏi người dùng giờ chạy (CLAUDE.md). Đo trên Dấu thật, không kết luận từ app thử.

1. Bản Debug có thêm `ToolbarItem(.navigation) { ControlGroup { Lùi; Tiến } }`, có `navigationTitle`, không `PageTitle`, `HiddenWindowTitle`, `RemoveToolbarTitle`:
   - đo chiều cao thanh, x của cụm nút, x và cỡ chữ tiêu đề, ở cả 4 mục, màn 1x và 2x;
   - so với `docs/research/SYSTEM-SETTINGS-REFERENCE.md`.
2. Cùng bản đó: `NSWindow.toolbar` có hay không, số mục (mục 2.7).
3. `columnVisibility`: kéo đường chia tới khi sidebar thu lại, ghi giá trị binding; thử đặt lại `.all` (mục 1.2).
4. Menu View khi không có `CommandGroup(replacing: .sidebar)`, khi có, và khi có `SidebarCommands`: các mục và phím tắt (mục 1.5).
5. System Settings, chỉ đọc: `AXSplitter`, menu View, cụm Lùi/Tiến (mục 6).

## 10. Sidebar cố định bằng `NSSplitViewController` (đo trên app thử, 06/11/2026)

[Đo trên app thử] macOS 27.2, `build/probe-fixed-sidebar/` (git bỏ qua), đo qua Accessibility với `scripts/selftest/settings-window/Reference.swift` làm chuẩn. Hai lượt: 6 cấu hình (09:40), rồi cấu hình chọn (10:00).

| Cấu hình | Sidebar cố định 232 (kéo, bấm đúp, `AXSplitter`, đổi cỡ) | Thanh 52, tiêu đề x 317 15 pt, Lùi 240,8 36×36, Tiến 276,8 37×36 | ⌘[ ⌘] trong menu View | Ô tìm sidebar |
|---|---|---|---|---|
| v1: scene `Window` SwiftUI + `NSViewControllerRepresentable` bọc split view, `.searchable(placement: .sidebar)` | có | khớp | chạy | lên thanh công cụ (509,7 224×38) |
| v1 + `NSSearchField` `controlSize = .large` (`NSViewRepresentable`, lề 10) | có | khớp | chạy | 10,62 212×28 (System Settings 10,61 212×28); hàng đầu y 100 (98); gõ "upd" lọc còn 1 mục |
| v2: `NSWindow` do app tạo | có | khớp | **không chạy** (`focusedSceneValue` không tới cửa sổ AppKit); menu View thêm "Show Tab Bar", "Show All Tabs" | lên thanh công cụ |
| v2 + `NSToolbar` AppKit (`sidebarTrackingSeparator`, nhóm `isNavigational`) | có | Lùi 240,9 38×36, Tiến 278,9 38×36 (lệch) | không chạy | lên thanh công cụ |
| v2 + `NSSearchField` cỡ thường | có | khớp | không chạy | 10,63 212×24 |
| v2, đường chia để AppKit tự quản | có | khớp | không chạy | — ; con trỏ đổi cỡ hiện ở đường chia (bản có `splitView(_:effectiveRect:forDrawnRect:ofDividerAt:)` trả `.zero` cho mũi tên thường) |

- `NSSearchField` theo `controlSize`: mini 16, small 20, regular 24, large 28, extraLarge 36 (`intrinsicContentSize`, đo ngoài màn hình).
  - Phải đặt cỡ cả phía AppKit lẫn `.controlSize(.large)` phía SwiftUI.
- 20 lần đổi cỡ cửa sổ 740 ↔ 976: trung vị 9,7 ms, tối đa 22,2 ms mỗi lần (v1 + ô tìm); sidebar không lệch lần nào.
  - Chưa có số so sánh của `NavigationSplitView` hiện tại.
- Ô tìm `NSSearchField` nhận focus lúc mở cửa sổ (hàng chọn màu xám); với `.searchable` focus ở danh sách.
  - Đặt focus đầu tiên là việc khi làm vào Dấu.
