import AppKit
import SwiftUI
import DauShared

/// Host app: the Settings window (M4) and the onboarding window (M5). Updates (M7)
/// come later. The entry point is main.swift.
///
/// The Settings window is the app's main window, so opening Dấu from Finder shows it;
/// the input menu's "Dấu Settings…" item is meant to open the app the same way. ⌘,
/// reopens it after it was closed. At launch, while Dấu is not installed or not enabled,
/// the onboarding window opens instead (`LaunchRouter`); "Help › Setup Guide…" opens it at
/// any time.
///
/// At launch, an older input method in ~/Library/Input Methods is replaced by the one
/// inside the app (D7, D37: `upgradeIfNeeded`); nothing happens when none is installed.
struct DauApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = SettingsModel.appGroup()
    @State private var inputSource = InputSourceStatus()
    @State private var onboarding: OnboardingFlow
    @State private var actions: InputMethodActions
    private let opensOnboarding: Bool

    init() {
        let installer = SystemInputMethodInstaller.standard()
        let (flow, opens) = DauApp.makeOnboarding(installer)
        _onboarding = State(initialValue: flow)
        let actions = InputMethodActions(installer: installer)
        _actions = State(initialValue: actions)
        #if DEBUG
        DebugCapture.actions = actions
        #endif
        opensOnboarding = opens
        DauApp.upgradeAtLaunch(actions)
        DauApp.checkInstalled(actions)
    }

    @MainActor
    private static func checkInstalled(_ actions: InputMethodActions) {
        #if DEBUG
        if CommandLine.arguments.contains("--tampered") { actions.forceTampered(); return }
        // Captures run a re-signed copy: its team does not match the installed one.
        if DebugCapture.onboardingDirectory != nil || DebugCapture.uninstallDirectory != nil { return }
        #endif
        Task { await actions.checkInstalledAfterUpgrade() }
    }

    /// D7: replace an older installed input method. The user just opened Dấu (or the
    /// updater relaunched it), so no word is being typed; the input method still ends
    /// its word before it quits (InputMethodLifecycle).
    @MainActor
    private static func upgradeAtLaunch(_ actions: InputMethodActions) {
        #if DEBUG
        // Window captures and debug commands never touch the installed input method.
        if DebugCapture.onboardingDirectory != nil || DebugCapture.uninstallDirectory != nil
            || DebugCapture.settingsWindowOnly { return }
        #endif
        actions.startLaunchUpgrade()
    }

    /// The onboarding flow on the real services, and whether it opens at launch.
    @MainActor
    private static func makeOnboarding(_ installer: InputMethodInstaller) -> (OnboardingFlow, Bool) {
        var flow = OnboardingFlow(detector: WorkspaceInputMethodDetector(), installer: installer)
        var opens = LaunchRouter.opensOnboarding(installer.status())
        #if DEBUG
        if DebugCapture.uninstallDirectory != nil || DebugCapture.settingsWindowOnly { opens = false }
        if let step = DebugCapture.onboardingStep {
            // `--onboarding <1|2|3>`: open onboarding at that step.
            flow.forcedStartStep = step
            opens = true
        }
        if DebugCapture.onboardingDirectory != nil {
            // `--capture-onboarding <dir>`: fixed services, so every step has content.
            let detector = FakeInputMethodDetector([FakeInputMethodDetector.running("OpenKey", bundleID: "com.tuyenmai.openkey")])
            let fake = FakeInputMethodInstaller(.installed(version: nil))
            DebugCapture.onboardingDetector = detector
            DebugCapture.onboardingInstaller = fake
            flow = OnboardingFlow(
                detector: detector,
                installer: fake,
                shortcut: { DebugCapture.shortcutNow ?? InputSourceShortcut.read() },
                openKeyboardSettings: {})
            opens = true
        }
        DebugCapture.onboardingFlow = flow
        #endif
        return (flow, opens)
    }

    var body: some Scene {
        Window(Text("Dấu Settings"), id: SettingsScene.id) {
            SettingsWindow()
                .environment(model)
                .environment(inputSource)
                .environment(\.inputMethodActions, actions)
                #if DEBUG
                .environment(\.layoutProbe, DebugCapture.probe)
                #endif
                .modifier(LaunchRouting(opens: opensOnboarding))
                // The installed input method's signature, whenever Dấu comes to the
                // front (TamperedBanner): any process of the user can replace it.
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    DauApp.checkInstalled(actions)
                }
        }
        .defaultSize(SettingsScene.defaultSize)
        // The content's min and max frame bound the window (`SettingsWindow`).
        .windowResizability(.contentSize)
        .commands {
            SettingsCommands()
            // View › Back (⌘[) and Forward (⌘]). No `SidebarCommands`: the sidebar is
            // fixed, so the View menu has no Show/Hide Sidebar (D9).
            SettingsHistoryCommands()
            // Edit › Find › Find… (⌘F) for the sidebar search (D9;
            // `SettingsSplitViewController.performFindPanelAction(_:)`). The system's
            // built-in group "for searching, editing, and transforming selections of
            // text" (https://developer.apple.com/documentation/swiftui/texteditingcommands):
            // the text-editing placement's Find, Spelling and Grammar, Substitutions,
            // Transformations and Speech submenus
            // (https://developer.apple.com/documentation/swiftui/commandgroupplacement/textediting).
            TextEditingCommands()
        }

        Window(Text("Set Up Dấu"), id: OnboardingScene.id) {
            OnboardingWindow()
                .environment(onboarding)
                .environment(model)
                .environment(\.inputMethodActions, actions)
                #if DEBUG
                .environment(\.layoutProbe, DebugCapture.probe)
                #endif
        }
        // "Hides both the window's title and the backing of the titlebar area"
        // (https://developer.apple.com/documentation/swiftui/hiddentitlebarwindowstyle):
        // the mockup has no title text. The title stays set, for the Window menu.
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

/// Opens the onboarding window instead of Settings at launch when `opens` is true.
/// SwiftUI opens the first window scene (Settings) by itself; this swaps it on its first
/// appearance, once per launch.
struct LaunchRouting: ViewModifier {
    let opens: Bool
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @MainActor private static var routed = false

    func body(content: Content) -> some View {
        content.onAppear {
            guard !Self.routed else { return }
            Self.routed = true
            guard opens else { return }
            openWindow(id: OnboardingScene.id)
            dismissWindow(id: SettingsScene.id)
        }
    }
}

/// Replaces the standard "Settings…" item so ⌘, opens the Settings window.
struct SettingsCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") { openWindow(id: SettingsScene.id) }
                .keyboardShortcut(",", modifiers: .command)
        }
        // Dấu has no help book: the Help menu holds the setup guide instead.
        CommandGroup(replacing: .help) {
            Button("Setup Guide…") { openWindow(id: OnboardingScene.id) }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        DebugCapture.applyAppearanceOverride()
        DebugCapture.startOnboarding()
        DebugCapture.startUninstall()
        #endif
    }

    /// Closing the last window (Settings or onboarding) quits, like System Settings.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
