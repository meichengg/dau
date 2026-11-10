import AppKit
import SwiftUI
import Testing
import DauShared
@testable import SnapshotSettings

/// The Settings window's split view (D9, "Sidebar cố định như System Settings"): built
/// off screen; the focus tests put it in a window that is never shown (not ordered in, no
/// screen). What only the real window shows (the selection's accent color at launch, the
/// sidebar width as the window resizes) is measured by scripts/selftest/settings-window.
@MainActor
@Suite("Settings window shell")
struct SettingsShellTests {
    func controller(_ state: SettingsWindowState = SettingsWindowState(.typing)) -> SettingsSplitViewController {
        let suite = "dau.snapshot-settings.tests.shell"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let model = SettingsModel(store: SettingsStore(defaults: defaults, suiteName: suite))
        let environment = SettingsEnvironment(model: model, inputSource: InputSourceStatus(fixed: true), actions: nil,
                                              layoutProbe: nil, smartAdvancedExpanded: false, openWindow: nil)
        return SettingsSplitViewController(sidebar: SettingsSidebarRoot(state: state, environment: environment),
                                           detail: SettingsDetailRoot(state: state, environment: environment))
    }

    /// The controller as a window's content, in a window never ordered in; the run loop
    /// turns a few times so SwiftUI lays out and settles the focus.
    func hiddenWindow(_ controller: SettingsSplitViewController) -> NSWindow {
        let window = NSWindow(contentRect: CGRect(x: -6000, y: -6000, width: 740, height: 560),
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.contentViewController = controller
        for _ in 0..<15 { RunLoop.main.run(until: Date().addingTimeInterval(0.03)) }
        return window
    }

    @Test("the sidebar list, not its search field, has the focus when the window opens")
    func launchFocus() {
        let state = SettingsWindowState(.typing)
        let controller = controller(state)
        let window = hiddenWindow(controller)
        let sidebar = controller.splitViewItems.first?.viewController.view
        let responder = window.firstResponder as? NSView
        #expect(responder != nil && sidebar != nil && responder!.isDescendant(of: sidebar!))
        #expect(state.searchField != nil)
        #expect(state.searchField?.currentEditor() == nil)
    }

    @Test("Edit › Find › Find… (⌘F) puts the focus in the sidebar search field")
    func findFocusesSearch() {
        let state = SettingsWindowState(.typing)
        let controller = controller(state)
        let window = hiddenWindow(controller)
        let action = #selector(SettingsSplitViewController.performFindPanelAction(_:))
        let find = NSMenuItem(title: "Find…", action: action, keyEquivalent: "f")
        find.tag = Int(NSFindPanelAction.showFindPanel.rawValue)
        let findNext = NSMenuItem(title: "Find Next", action: action, keyEquivalent: "g")
        findNext.tag = Int(NSFindPanelAction.next.rawValue)
        #expect(controller.validateMenuItem(find))
        #expect(!controller.validateMenuItem(findNext))
        #expect(state.searchField?.currentEditor() == nil)
        // From the list, up the responder chain, as the menu item's action travels.
        #expect(window.firstResponder?.tryToPerform(action, with: find) == true)
        #expect(state.searchField?.currentEditor() != nil)
    }

    @Test("a system sidebar, 232 pt, that neither collapses nor resizes")
    func fixedSidebar() {
        let items = controller().splitViewItems
        #expect(items.count == 2)
        guard let sidebar = items.first else { return }
        #expect(sidebar.behavior == .sidebar)
        #expect(!sidebar.canCollapse)
        #expect(!sidebar.canCollapseFromWindowResize)
        #expect(sidebar.minimumThickness == SettingsScene.sidebarWidth)
        #expect(sidebar.maximumThickness == SettingsScene.sidebarWidth)
    }

    @Test("the sidebar's divider has no mouse area (normal arrow, no drag)")
    func divider() {
        let controller = controller()
        let drawn = NSRect(x: SettingsScene.sidebarWidth - 1, y: 0, width: 1, height: 500)
        let rect = controller.splitView(controller.splitView, effectiveRect: drawn.insetBy(dx: -3, dy: 0),
                                        forDrawnRect: drawn, ofDividerAt: 0)
        #expect(rect == .zero)
    }

    @Test("AppKit's Show/Hide Sidebar action stays off")
    func toggleSidebarDisabled() {
        let item = NSMenuItem(title: "Hide Sidebar", action: #selector(NSSplitViewController.toggleSidebar(_:)),
                              keyEquivalent: "s")
        #expect(!controller().validateUserInterfaceItem(item))
    }

    @Test("the page host brings the toolbar and the title; the sidebar host nothing")
    func bridging() {
        let items = controller().splitViewItems
        let sidebar = items.first?.viewController as? NSHostingController<SettingsSidebarRoot>
        let detail = items.last?.viewController as? NSHostingController<SettingsDetailRoot>
        #expect(sidebar?.sceneBridgingOptions == [])
        #expect(detail?.sceneBridgingOptions == [.toolbars, .title])
    }
}
