import AppKit
import SwiftUI
import Testing
import DauShared
@testable import SnapshotSettings

/// The "Dấu chưa được bật" banner (docs/UI.md "Các trạng thái bổ sung", artboards
/// "SettingsNotEnabled", "SettingsBannerStates"): first on every Settings page while Dấu is
/// not among the enabled input sources, in each state "Bật lại" leads to, and absent
/// otherwise. The real window's split view (`SettingsSplitViewController`) is laid out in
/// a window that is never shown; the pages' `layoutProbe`s report where each view is.
@MainActor
@Suite("Not-enabled banner")
struct NotEnabledBannerTests {
    /// Frames the pages report, by probe name; a view that is gone takes its frame out.
    final class Probes {
        var frames: [String: CGRect] = [:]
    }

    /// Lays out `section` of the Settings window and returns the frames its probes report.
    func layout(_ section: SettingsSection, enabled: Bool?, actions: InputMethodActions? = nil) -> [String: CGRect] {
        let suite = "dau.snapshot-settings.tests.banner"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        let model = SettingsModel(store: SettingsStore(defaults: defaults, suiteName: suite))
        let probes = Probes()
        let environment = SettingsEnvironment(
            model: model, inputSource: InputSourceStatus(fixed: enabled), actions: actions,
            layoutProbe: { name, frame in probes.frames[name] = frame.isNull ? nil : frame },
            smartAdvancedExpanded: false, openWindow: nil)
        let state = SettingsWindowState(section)
        let controller = SettingsSplitViewController(sidebar: SettingsSidebarRoot(state: state, environment: environment),
                                                     detail: SettingsDetailRoot(state: state, environment: environment))
        let window = NSWindow(contentRect: CGRect(origin: CGPoint(x: -6000, y: -6000), size: SettingsScene.defaultSize),
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: true)
        window.isReleasedWhenClosed = false
        window.contentViewController = controller
        for _ in 0..<20 {
            RunLoop.main.run(until: Date().addingTimeInterval(0.03))
            controller.view.layoutSubtreeIfNeeded()
        }
        let frames = probes.frames
        window.contentViewController = nil
        return frames
    }

    /// The banner probe `banner` is there and above every other view the page reports
    /// (the first card, a section header's card, a control): nothing of the page comes
    /// before it. At least one other view must report, or the order says nothing.
    func expectBannerFirst(_ frames: [String: CGRect], _ banner: String, on section: SettingsSection) {
        let banners = frames.keys.filter { $0.hasPrefix("banner") }
        #expect(banners == [banner], "\(section): banner probes \(banners.sorted())")
        guard let top = frames[banner] else { return }
        let page = frames.filter { !$0.key.hasPrefix("banner") }
        #expect(!page.isEmpty, "\(section): no view of the page reported a frame")
        for (name, frame) in page {
            #expect(frame.minY >= top.maxY, "\(section): \(name) at y \(frame.minY), above the banner's bottom \(top.maxY)")
        }
    }

    @Test("not enabled: the banner is the first card of every page", arguments: SettingsSection.allCases)
    func firstOnEveryPage(_ section: SettingsSection) {
        expectBannerFirst(layout(section, enabled: false), "banner.idle", on: section)
    }

    @Test("enabled, or a state that cannot be read (N5): no banner", arguments: [true, nil] as [Bool?])
    func hidden(_ enabled: Bool?) {
        for section in SettingsSection.allCases {
            let frames = layout(section, enabled: enabled)
            #expect(frames.keys.filter { $0.hasPrefix("banner") }.isEmpty, "\(section), enabled \(String(describing: enabled))")
            #expect(frames["firstRow"] != nil, "\(section): the page laid out nothing")
        }
    }

    func actions(_ installer: FakeInputMethodInstaller) -> InputMethodActions {
        InputMethodActions(installer: installer, openKeyboardSettings: {}, openInputSources: {},
                           shortcut: { .unknown }, englishLayout: { nil })
    }

    @Test("after Bật lại: waiting for Allow, then still first")
    func waiting() async {
        let installer = FakeInputMethodInstaller(.installed(version: nil))
        installer.enableWaits = true
        let actions = actions(installer)
        let run = Task { await actions.enableFromBanner() }
        for _ in 0..<200 where !installer.enableWaiting { try? await Task.sleep(for: .milliseconds(5)) }
        #expect(actions.banner == .working)
        expectBannerFirst(layout(.typing, enabled: false, actions: actions), "banner.working", on: .typing)
        installer.release = .notEnabled
        _ = await run.value
    }

    @Test("after Bật lại: macOS kept Dấu off, then still first")
    func keptOff() async {
        let installer = FakeInputMethodInstaller(.installed(version: nil))
        installer.enableOutcome = .notEnabled
        let actions = actions(installer)
        _ = await actions.enableFromBanner()
        #expect(actions.banner == .notEnabled)
        for section in SettingsSection.allCases {
            expectBannerFirst(layout(section, enabled: false, actions: actions), "banner.notEnabled", on: section)
        }
    }

    @Test("after Bật lại: enabled, the confirmation first until Ẩn")
    func enabled() async {
        let installer = FakeInputMethodInstaller(.installed(version: nil))
        let actions = actions(installer)
        _ = await actions.enableFromBanner()
        #expect(actions.banner == .enabled)
        // The status has caught up (Dấu is on); the confirmation stays until Ẩn.
        expectBannerFirst(layout(.typing, enabled: true, actions: actions), "banner.enabled", on: .typing)
        actions.dismissBanner()
        #expect(layout(.typing, enabled: true, actions: actions).keys.filter { $0.hasPrefix("banner") }.isEmpty)
    }
}
