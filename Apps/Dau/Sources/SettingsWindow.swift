import AppKit
import SwiftUI

/// The Settings window, built like System Settings (D9: native components with their
/// default metrics; numbers in docs/research/SYSTEM-SETTINGS-REFERENCE.md): a fixed
/// sidebar, 232 pt wide, with a search field and the four sections, and a grouped `Form`
/// per section. The toolbar holds the Back/Forward cluster (`SettingsHistoryButtons`)
/// and the system's own page title (`navigationTitle`, set by `SettingsDetail`). The
/// mockup only sets the content (sections, rows, copy, order, icons).
///
/// The sidebar cannot be resized or collapsed, as in System Settings (D9, "Sidebar cố
/// định như System Settings"). SwiftUI has no API to lock the sidebar of a
/// `NavigationSplitView`, so the scene's content is an AppKit split view the app owns
/// (`SettingsSplitViewController`), wrapped in an `NSViewControllerRepresentable`
/// (https://developer.apple.com/documentation/swiftui/nsviewcontrollerrepresentable). The
/// sidebar and the pages stay SwiftUI views, each in an `NSHostingController`; nothing
/// here reaches into views SwiftUI builds (docs/research/SWIFTUI-WINDOW-API.md, section 10).
struct SettingsWindow: View {
    @State private var state: SettingsWindowState
    @Environment(SettingsModel.self) private var model
    @Environment(InputSourceStatus.self) private var inputSource
    @Environment(\.inputMethodActions) private var actions
    @Environment(\.layoutProbe) private var layoutProbe
    @Environment(\.smartAdvancedExpanded) private var smartAdvancedExpanded
    @Environment(\.languageRowStatus) private var languageRowStatus
    @Environment(\.openWindow) private var openWindow

    init(initialSection: SettingsSection = .typing) {
        _state = State(initialValue: SettingsWindowState(initialSection))
    }

    var body: some View {
        SettingsSplitView(state: state, environment: SettingsEnvironment(
            model: model, inputSource: inputSource, actions: actions, layoutProbe: layoutProbe,
            smartAdvancedExpanded: smartAdvancedExpanded, openWindow: openWindow,
            languageRowStatus: languageRowStatus))
            // The split view reaches the window's top edge, under the toolbar, so the
            // sidebar runs the full height as in System Settings
            // (https://developer.apple.com/documentation/swiftui/view/ignoressafearea(_:edges:)).
            .ignoresSafeArea()
            // "Gỡ cài đặt…": the sheet that waits for the user to remove Dấu from the input
            // sources (`InputMethodActions.performUninstall`); closing it cancels the removal.
            .sheet(isPresented: Binding(get: { actions?.isShowingUninstallSheet == true },
                                        set: { if !$0 { actions?.cancelUninstall() } })) {
                if let actions {
                    UninstallRemoveSheet(actions: actions)
                }
            }
            // Fixed width like System Settings' window (740 pt); only the height changes.
            .frame(minWidth: SettingsScene.minSize.width, maxWidth: SettingsScene.minSize.width,
                   minHeight: SettingsScene.minSize.height, maxHeight: .infinity)
    }
}

/// What the sidebar and the page share: the history of sections shown, the sidebar's
/// query, and whether a page's sheet is up. One per window (`SettingsWindow`'s `@State`),
/// observed by both hosting controllers
/// (https://developer.apple.com/documentation/observation/observable()).
@MainActor @Observable
final class SettingsWindowState {
    var history: SectionHistory
    var query = ""
    /// A page's sheet is shown (`sheetShown(_:)`): the add-rule sheet.
    var pageSheetShown = false
    /// The sidebar's search field, handed over by `SidebarSearchField` when it makes it,
    /// for Edit › Find (`SettingsSplitViewController.performFindPanelAction(_:)`).
    @ObservationIgnored weak var searchField: NSSearchField?

    init(_ section: SettingsSection) {
        history = SectionHistory(section)
    }

    var visibleSections: [SettingsSection] {
        SettingsSection.allCases.filter { $0.matches(query) }
    }
}

/// The scene's environment, passed on to the two hosting controllers. A hosting
/// controller has its own SwiftUI hierarchy, and Apple documents no inheritance of the
/// environment into one placed inside a representable, so the window hands over
/// explicitly what the sidebar and the pages read.
struct SettingsEnvironment: ViewModifier {
    let model: SettingsModel
    let inputSource: InputSourceStatus
    let actions: InputMethodActions?
    let layoutProbe: (@MainActor @Sendable (String, CGRect) -> Void)?
    let smartAdvancedExpanded: Bool
    /// The scene's `openWindow` (read-only in `EnvironmentValues`), under a key of its own.
    /// Nil only in tests, which have no scene.
    let openWindow: OpenWindowAction?
    /// Nil in the app (`LanguageRow` reads the preferences); set by the snapshot tool.
    var languageRowStatus: AppLanguage.Status? = nil

    func body(content: Content) -> some View {
        content
            .environment(model)
            .environment(inputSource)
            .environment(\.inputMethodActions, actions)
            .environment(\.layoutProbe, layoutProbe)
            .environment(\.smartAdvancedExpanded, smartAdvancedExpanded)
            .environment(\.settingsOpenWindow, openWindow)
            .environment(\.languageRowStatus, languageRowStatus)
    }
}

extension EnvironmentValues {
    /// The Settings scene's `openWindow`, inside the window's hosting controllers
    /// (`SettingsEnvironment`). Nil outside the Settings window: use `openWindow`.
    @Entry var settingsOpenWindow: OpenWindowAction?
}

/// The split view controller in SwiftUI.
struct SettingsSplitView: NSViewControllerRepresentable {
    let state: SettingsWindowState
    let environment: SettingsEnvironment

    func makeNSViewController(context: Context) -> SettingsSplitViewController {
        SettingsSplitViewController(sidebar: SettingsSidebarRoot(state: state, environment: environment),
                                    detail: SettingsDetailRoot(state: state, environment: environment))
    }

    func updateNSViewController(_ controller: SettingsSplitViewController, context: Context) {
        controller.update(sidebar: SettingsSidebarRoot(state: state, environment: environment),
                          detail: SettingsDetailRoot(state: state, environment: environment))
    }
}

/// The window's split view: AppKit's `NSSplitViewController`
/// (https://developer.apple.com/documentation/appkit/nssplitviewcontroller) with a sidebar
/// the user cannot collapse or resize, and SwiftUI content in `NSHostingController`s
/// (https://developer.apple.com/documentation/swiftui/nshostingcontroller).
final class SettingsSplitViewController: NSSplitViewController {
    private let sidebarHost: NSHostingController<SettingsSidebarRoot>
    private let detailHost: NSHostingController<SettingsDetailRoot>
    private let state: SettingsWindowState

    init(sidebar: SettingsSidebarRoot, detail: SettingsDetailRoot) {
        state = sidebar.state
        sidebarHost = NSHostingController(rootView: sidebar)
        detailHost = NSHostingController(rootView: detail)
        super.init(nibName: nil, bundle: nil)

        // Which aspects of the window a host manages (`sceneBridgingOptions`, macOS 14,
        // https://developer.apple.com/documentation/swiftui/nshostingcontroller/scenebridgingoptions):
        // `.toolbars` "will have its toolbar populated with any items provided to the
        // toolbar(content:) modifier", `.title` "title and subtitle populated with the
        // values provided to the navigationTitle(_:) and navigationSubtitle(_:)
        // modifiers". The default is `.all` only for a window's `contentViewController`,
        // `[]` otherwise. The page host brings the whole toolbar: Back/Forward, the page
        // title and the Apps page's "+" and search field. The sidebar host brings
        // nothing: two hosts filling one toolbar has no documented outcome.
        sidebarHost.sceneBridgingOptions = []
        detailHost.sceneBridgingOptions = [.toolbars, .title]

        // The system sidebar: its material, full height under the full-size content view
        // (https://developer.apple.com/documentation/appkit/nssplitviewitem/init(sidebarwithviewcontroller:)).
        let sidebarItem = NSSplitViewItem(sidebarWithViewController: sidebarHost)
        // "determines whether a user interaction can collapse the child view controller"
        // (https://developer.apple.com/documentation/appkit/nssplitviewitem/cancollapse).
        sidebarItem.canCollapse = false
        // "determines whether a window resize can collapse"; set after `canCollapse`, which
        // "for sidebars resets this value"
        // (https://developer.apple.com/documentation/appkit/nssplitviewitem/cancollapsefromwindowresize).
        sidebarItem.canCollapseFromWindowResize = false
        // A fixed width, System Settings' sidebar column: minimum = maximum
        // (https://developer.apple.com/documentation/appkit/nssplitviewitem/minimumthickness,
        // https://developer.apple.com/documentation/appkit/nssplitviewitem/maximumthickness).
        sidebarItem.minimumThickness = SettingsScene.sidebarWidth
        sidebarItem.maximumThickness = SettingsScene.sidebarWidth

        addSplitViewItem(sidebarItem)
        addSplitViewItem(NSSplitViewItem(viewController: detailHost))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func update(sidebar: SettingsSidebarRoot, detail: SettingsDetailRoot) {
        sidebarHost.rootView = sidebar
        detailHost.rootView = detail
    }

    /// The sidebar's divider has no mouse area, so it shows the normal arrow and cannot
    /// be dragged, as in System Settings: "Allows the split view controller to modify the
    /// rectangle where mouse clicks initiate divider dragging"
    /// (https://developer.apple.com/documentation/appkit/nssplitviewcontroller/splitview(_:effectiverect:fordrawnrect:ofdividerat:)).
    /// The class reference asks overrides of split view delegate methods to call super
    /// (https://developer.apple.com/documentation/appkit/nssplitviewcontroller).
    override func splitView(_ splitView: NSSplitView, effectiveRect proposedEffectiveRect: NSRect,
                            forDrawnRect drawnRect: NSRect, ofDividerAt dividerIndex: Int) -> NSRect {
        let rect = super.splitView(splitView, effectiveRect: proposedEffectiveRect, forDrawnRect: drawnRect,
                                   ofDividerAt: dividerIndex)
        return dividerIndex == 0 ? .zero : rect
    }

    /// AppKit's own Show/Hide Sidebar action (`toggleSidebar(_:)`,
    /// https://developer.apple.com/documentation/appkit/nssplitviewcontroller/togglesidebar(_:))
    /// stays off should any menu item or key send it, and Edit › Find › Find… is on while
    /// the sidebar has its search field (the other Find items stay off): the controller
    /// validates its actions
    /// (https://developer.apple.com/documentation/appkit/nsuserinterfacevalidations).
    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(NSSplitViewController.toggleSidebar(_:)) { return false }
        if item.action == #selector(performFindPanelAction(_:)) {
            return item.tag == Self.showFindPanelTag && state.searchField != nil
        }
        return super.validateUserInterfaceItem(item)
    }

    /// Menu items ask `validateMenuItem(_:)` when their target implements it
    /// (https://developer.apple.com/documentation/appkit/nsmenuitemvalidation/validatemenuitem(_:)):
    /// the same answers as `validateUserInterfaceItem(_:)`.
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        validateUserInterfaceItem(menuItem)
    }

    /// Edit › Find › Find… (⌘F; the Find submenu of `TextEditingCommands` in `DauApp`)
    /// puts the focus in the sidebar's search field (D9). The item travels up the
    /// responder chain, which runs through this controller from either column, as AppKit's
    /// find action `performFindPanelAction(_:)` with the tag
    /// `NSFindPanelAction.showFindPanel`
    /// (https://developer.apple.com/documentation/appkit/nstextview/performfindpanelaction(_:),
    /// https://developer.apple.com/documentation/appkit/nsfindpanelaction/showfindpanel).
    /// SwiftUI does not document which action its Find submenu sends; its binary
    /// references this selector and not `performTextFinderAction:` (its selector
    /// references, read in-process on macOS 27.2). run.sh --focus checks the item and ⌘F
    /// on the real window. The field becomes first responder with `makeFirstResponder(_:)`
    /// (https://developer.apple.com/documentation/appkit/nswindow/makefirstresponder(_:)).
    /// A responder nearer the focus that handles Find itself (the Apps page's toolbar
    /// search field) answers first.
    @objc func performFindPanelAction(_ sender: Any?) {
        guard (sender as? NSValidatedUserInterfaceItem)?.tag == Self.showFindPanelTag,
              let field = state.searchField else { return }
        field.window?.makeFirstResponder(field)
    }

    private static let showFindPanelTag = Int(NSFindPanelAction.showFindPanel.rawValue)
}

// MARK: - Sidebar

/// The sidebar host's root: the scene's environment around the sidebar.
struct SettingsSidebarRoot: View {
    let state: SettingsWindowState
    let environment: SettingsEnvironment

    var body: some View {
        SettingsSidebar(state: state).modifier(environment)
    }
}

/// A sidebar `List` of the sections (icon tile and title), the search field above it and
/// the app's name and version below.
struct SettingsSidebar: View {
    @Bindable var state: SettingsWindowState
    /// The list, not the search field, has the focus when the window opens, so its
    /// selected row shows the accent color (as with the system's sidebar search). The list
    /// is bound with `focused(_:)`, and setting the binding to true "moves focus to the
    /// view" (https://developer.apple.com/documentation/swiftui/view/focused(_:),
    /// https://developer.apple.com/documentation/swiftui/focusstate): it is set when the
    /// list appears. `defaultFocus(_:_:priority:)` alone did not take inside this hosting
    /// controller: the real window opened with no focus and a grey selection (run.sh
    /// 06/11/2026); set on appear, the list became the window's first responder in an
    /// off-screen window (`swift test` "Settings window shell").
    @FocusState private var listFocused: Bool

    var body: some View {
        let visible = state.visibleSections
        // Choosing a row is a step in the history; the list never clears the page shown
        // (a nil selection is ignored).
        List(visible, selection: Binding(get: { state.history.current },
                                         set: { if let section = $0 { state.history.select(section) } })) { section in
            Label {
                Text(section.title)
            } icon: {
                SectionIcon(section: section)
            }
            .tag(section)
        }
        // A plain hosting controller is no sidebar column to SwiftUI: ask for the sidebar
        // style (https://developer.apple.com/documentation/swiftui/liststyle/sidebar).
        .listStyle(.sidebar)
        .focused($listFocused)
        .onAppear { listFocused = true }
        .overlay {
            // No section matches: the system's search empty state in the sidebar. The
            // page keeps the section shown and its title.
            if visible.isEmpty {
                ContentUnavailableView.search(text: state.query.trimmingCharacters(in: .whitespaces))
            }
        }
        .onChange(of: state.query) {
            // Jump to the first match (a step in the history, `showFirstMatch`).
            state.history.showFirstMatch(of: state.visibleSections)
        }
        .safeAreaInset(edge: .bottom, alignment: .leading) {
            // Mockup content: the app name and version under the sections.
            Text(verbatim: AppVersion.nameAndVersion)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)
        }
        // The search field at the top of the sidebar, under the toolbar, above the list
        // (https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:)).
        // `searchable(placement: .sidebar)` needs a `NavigationSplitView` sidebar: in this
        // hosting controller it went to the toolbar (docs/research/SWIFTUI-WINDOW-API.md,
        // section 10). The field's height is its own at the large control size (no frame
        // height), set on the SwiftUI side too
        // (https://developer.apple.com/documentation/swiftui/view/controlsize(_:)); the
        // inset is the sidebar's standard 10 pt, no other offset (D9 accepts the 1–2 pt
        // to System Settings).
        .safeAreaInset(edge: .top, spacing: 0) {
            SidebarSearchField(text: $state.query, prompt: String(localized: "Search"),
                               made: { state.searchField = $0 })
                .controlSize(.large)
                .padding(10)
        }
    }
}

/// The system search field (`NSSearchField`,
/// https://developer.apple.com/documentation/appkit/nssearchfield) at the large control
/// size (https://developer.apple.com/documentation/appkit/nscontrol/controlsize), in
/// SwiftUI (https://developer.apple.com/documentation/swiftui/nsviewrepresentable). The
/// query follows every edit (`controlTextDidChange(_:)`) and the field's action (its
/// cancel button).
struct SidebarSearchField: NSViewRepresentable {
    @Binding var text: String
    let prompt: String
    /// Called with the field once made (Edit › Find needs it).
    var made: (NSSearchField) -> Void = { _ in }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.controlSize = .large
        field.placeholderString = prompt
        field.setAccessibilityLabel(prompt)
        field.delegate = context.coordinator
        field.target = context.coordinator
        field.action = #selector(Coordinator.searched(_:))
        made(field)
        return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
        context.coordinator.text = $text
        if field.stringValue != text { field.stringValue = text }
    }

    @MainActor
    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var text: Binding<String>
        init(text: Binding<String>) { self.text = text }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            text.wrappedValue = field.stringValue
        }

        @objc func searched(_ field: NSSearchField) {
            if text.wrappedValue != field.stringValue { text.wrappedValue = field.stringValue }
        }
    }
}

// MARK: - Page

/// The page host's root: the shown section with the window's toolbar, title and View
/// menu commands, in the scene's environment.
struct SettingsDetailRoot: View {
    let state: SettingsWindowState
    let environment: SettingsEnvironment

    var body: some View {
        SettingsDetailChrome(state: state).modifier(environment)
    }
}

private struct SettingsDetailChrome: View {
    @Bindable var state: SettingsWindowState
    @Environment(\.inputMethodActions) private var actions

    /// Any sheet on the window: a page's, or the uninstall sheet.
    private var sheetShown: Bool { state.pageSheetShown || actions?.isShowingUninstallSheet == true }

    var body: some View {
        SettingsDetail(section: state.history.current)
            // Around the page, not on it: a page change swaps the page's view tree, and a
            // toolbar item declared there is rebuilt with it, so AXPress on Back changed
            // the page but returned kAXErrorAttributeUnsupported (-25205) to the caller
            // (measured on macOS 27.2, 05/11/2026; System Settings returns 0).
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    SettingsHistoryButtons(history: $state.history, sheetShown: sheetShown)
                }
            }
            // View › Back / Forward act on this window's history while it has focus.
            .focusedSceneValue(\.settingsNavigation, SettingsNavigation(
                canGoBack: state.history.canGoBack(sheetShown: sheetShown),
                canGoForward: state.history.canGoForward(sheetShown: sheetShown),
                goBack: { state.history.goBack() }, goForward: { state.history.goForward() }))
            .onPreferenceChange(SheetShownKey.self) { state.pageSheetShown = $0 }
    }
}

/// One section page. Its title is the system's navigation title: on macOS the inline
/// title of the unified toolbar, right after the Back/Forward cluster, and the window's
/// title in the Window menu, Mission Control and VoiceOver
/// (https://developer.apple.com/documentation/swiftui/view/navigationtitle(_:)); the HIG
/// asks a settings window to title itself after the visible pane
/// (https://developer.apple.com/design/human-interface-guidelines/settings).
struct SettingsDetail: View {
    let section: SettingsSection

    var body: some View {
        Group {
            switch section {
            case .typing: TypingSettingsView()
            case .smart: SmartSettingsView()
            case .apps: AppRulesView()
            case .updates: UpdatesSupportView()
            }
        }
        .navigationTitle(section.title)
    }
}

enum SettingsScene {
    static let id = "settings"
    /// System Settings' window (docs/research/SYSTEM-SETTINGS-REFERENCE.md).
    static let defaultSize = CGSize(width: 740, height: 560)
    /// System Settings' sidebar column, fixed (`SettingsSplitViewController`).
    static let sidebarWidth: CGFloat = 232
    /// The window's width is fixed at System Settings' 740 pt, as System Settings' own
    /// window is (measured on macOS 27.2: setting another width reads back 740); only the
    /// height changes. At least 400 pt under the 52 pt toolbar, so the window is at least
    /// 740 × 452.
    static let minSize = CGSize(width: 740, height: 400)
}
