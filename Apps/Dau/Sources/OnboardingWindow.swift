import AppKit
import Carbon
import SwiftUI
import DauShared

// The onboarding window (D14, docs/UI.md "Onboarding", mockup artboards
// "OnboardingConflict", "OnboardingEnable", "Onboarding"): a 230 pt sidebar with the app
// icon, the name and the three steps, and the current step on the right. 720 × 500 pt,
// no title text. System controls and colors only (D9).

@MainActor
enum OnboardingScene {
    nonisolated static let id = "onboarding"
    /// The window, title bar included (mockup).
    static let size = CGSize(width: 720, height: 500)
    /// The hidden title bar still counts as top safe area, and SwiftUI adds it to the
    /// window's size: the content is laid out below it (32 pt on macOS 27, 28 before).
    static let titleBarHeight: CGFloat = {
        let content = NSRect(x: 0, y: 0, width: 100, height: 100)
        return NSWindow.frameRect(forContentRect: content, styleMask: [.titled, .closable]).height - content.height
    }()

    /// Distance from the window's top edge, turned into one from the safe area's.
    static func belowTitleBar(_ top: CGFloat) -> CGFloat { max(0, top - titleBarHeight) }
}

struct OnboardingWindow: View {
    @Environment(OnboardingFlow.self) private var flow
    @Environment(\.controlActiveState) private var activeState

    var body: some View {
        // A plain split, not NavigationSplitView: the steps are not a selectable list,
        // and the mockup's sidebar runs the full height under the traffic lights.
        HStack(spacing: 0) {
            // 229 + the 1 pt divider: the content starts at 230, as in the mockup.
            OnboardingSidebar()
                .frame(width: 229)
                .frame(maxHeight: .infinity)
                .background { SidebarMaterial().ignoresSafeArea() }
                .layoutProbe("onbSidebar")
            Divider().ignoresSafeArea()
            OnboardingStepView()
        }
        .frame(width: OnboardingScene.size.width,
               height: OnboardingScene.size.height - OnboardingScene.titleBarHeight)
        .onAppear { flow.start() }
        // Step 1 is rechecked whenever the user comes back to the window.
        .onChange(of: activeState) { _, state in
            if state == .key { flow.refresh() }
        }
        .onReceive(DistributedNotificationCenter.default().publisher(
            for: Notification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String))) { _ in
            flow.refresh()
        }
        .onReceive(DistributedNotificationCenter.default().publisher(
            for: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String))) { _ in
            flow.refresh()
        }
    }
}

// MARK: - Sidebar

struct OnboardingSidebar: View {
    @Environment(OnboardingFlow.self) private var flow

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 44, height: 44)
                    .accessibilityHidden(true)
                Text(verbatim: "Dấu")
                    .font(.system(size: 17, weight: .bold))
            }
            .layoutProbe("onbAppName")

            VStack(alignment: .leading, spacing: 18) {
                ForEach(OnboardingFlow.Step.allCases, id: \.self) { step in
                    StepRow(step: step, state: flow.state(of: step))
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel(Text("Setup steps"))
            .layoutProbe("onbSteps")

            Spacer(minLength: 0)

            Hint(Text("Dấu doesn’t need permission to control your Mac."))
        }
        // Mockup: 16 pt inset, the 12 pt traffic lights, then 22 pt to the app name.
        .padding(.top, OnboardingScene.belowTitleBar(50))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// The system's sidebar material (behind-window vibrancy), as in a sidebar.
struct SidebarMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .sidebar
        view.blendingMode = .behindWindow
        view.state = .followsWindowActiveState
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

/// One step in the sidebar: a 24 pt circle (check when done, number otherwise), the
/// step's name (semibold when current) and a hint.
struct StepRow: View {
    let step: OnboardingFlow.Step
    let state: OnboardingFlow.StepState

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StepBadge(number: step.rawValue, state: state)
            VStack(alignment: .leading, spacing: 1) {
                Text(step.sidebarTitle)
                    .font(.system(size: 13, weight: state == .current ? .semibold : .regular))
                    .foregroundStyle(.primary)
                Hint(step.sidebarHint)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(step.rawValue): \(Text(step.sidebarTitle))"))
        .accessibilityValue(state.spoken)
        .accessibilityAddTraits(state == .current ? [.isStaticText, .isSelected] : .isStaticText)
    }
}

struct StepBadge: View {
    let number: Int
    let state: OnboardingFlow.StepState

    var body: some View {
        ZStack {
            switch state {
            case .done:
                Circle().fill(Color.green)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            case .current:
                Circle().fill(Color.accentColor)
                Text(verbatim: "\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
            case .pending:
                Circle().fill(.fill)
                Text(verbatim: "\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 24, height: 24)
        .accessibilityHidden(true)
    }
}

extension OnboardingFlow.Step {
    var sidebarTitle: LocalizedStringResource {
        switch self {
        case .oldInputMethods: "Check Other Input Methods"
        case .enable: "Turn On Dấu"
        case .typing: "Choose a Typing Method"
        }
    }

    var sidebarHint: Text {
        switch self {
        case .oldInputMethods: Text("So marks aren’t typed twice")
        case .enable: Text("Add to input sources")
        case .typing: Text("Try it right away")
        }
    }
}

extension OnboardingFlow.StepState {
    var spoken: Text {
        switch self {
        case .done: Text("Completed")
        case .current: Text("In progress")
        case .pending: Text("Not started")
        }
    }
}

// MARK: - Steps

struct OnboardingStepView: View {
    @Environment(OnboardingFlow.self) private var flow

    var body: some View {
        Group {
            switch flow.step {
            case .oldInputMethods:
                switch flow.oldInputMethodsScreen {
                case .conflict: ConflictStep()
                case .done: ConflictDoneStep()
                }
            case .enable: EnableStep()
            case .typing: TypingStep()
            }
        }
        // No side margin here: `StepLayout` puts it inside the scroll area, so the scroll
        // bar sits at the window's edge as in System Settings (D9; artboard
        // OnboardingEnableNotes, canvas version 104).
        .padding(.top, OnboardingScene.belowTitleBar(40))
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { SettingsColors.page.ignoresSafeArea() }
        .layoutProbe("onbDetail")
    }
}

/// Title (22 bold), subtitle (13 secondary), content, then the buttons at the bottom
/// right, as in the artboards. The title, subtitle and content scroll when they are taller
/// than the window (a long note, a large text size) while the buttons stay in place under a
/// separator, so nothing can run out of the window or under the buttons.
struct StepLayout<Content: View, Buttons: View>: View {
    /// Names the layout probes (captures): a step leaving the window can still report.
    let step: OnboardingFlow.Step
    /// Step 2 swaps whole screens: each names its probes apart (`onbTitle-2.waiting`),
    /// so a screen that disappears does not clear the frames of the one that replaced it.
    var screen: String = ""
    let title: Text
    let subtitle: Text
    @ViewBuilder var content: Content
    @ViewBuilder var buttons: Buttons

    @State private var contentHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 6) {
                        title
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.primary)
                            .accessibilityAddTraits(.isHeader)
                            .layoutProbe("onbTitle-\(step.rawValue)\(screen)")
                        // Mockup line height 1.5: 19.5 pt per line.
                        subtitle
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .lineSpacing(3.5)
                            .padding(.vertical, 1.75)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    content
                }
                // The side margin is inside the scroll area: the area reaches the window's
                // edge and so does its scroll bar (System Settings, D9).
                .padding(.horizontal, Self.sideMargin)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { viewportHeight = $0 }
            // The separator shows only when something is scrolled out of sight; it runs the
            // full width, edge to edge, as in the artboard.
            if contentHeight > viewportHeight + 0.5 {
                Divider()
                    .layoutProbe("onbDivider-\(step.rawValue)\(screen)")
                    .padding(.top, 8)
            }
            HStack(spacing: 10) {
                Spacer(minLength: 0)
                buttons
            }
            .settingsButton()
            .layoutProbe("onbButtons-\(step.rawValue)\(screen)")
            .padding(.horizontal, Self.sideMargin)
            .padding(.top, 18)
        }
    }

    /// The detail pane's side margin (artboards: 36).
    static var sideMargin: CGFloat { 36 }
}

/// A card as on the Settings pages, with 16 pt padding and 12 pt between items.
struct OnboardingCard<Content: View>: View {
    var spacing: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        SettingsCard(padding: 16) {
            VStack(alignment: .leading, spacing: spacing) { content }
        }
    }
}

// MARK: Step 1

struct ConflictStep: View {
    @Environment(OnboardingFlow.self) private var flow

    var body: some View {
        let names = flow.conflicts.map(\.name).formatted(.list(type: .and))
        StepLayout(step: .oldInputMethods, title: Text("Turn Off Other Input Methods"),
                   subtitle: Text("Running now: \(names). When two input methods run at the same time, marks are added twice and the text comes out wrong.")) {
            VStack(alignment: .leading, spacing: 18) {
                ForEach(flow.conflicts) { app in
                    ConflictCard(app: app)
                        .layoutProbe(app == flow.conflicts.first ? "onbCard-1" : "onbCard-1-more")
                }
                Hint(Text("Dấu checks again when you come back to this window."))
            }
        } buttons: {
            Button("Skip") { flow.skip() }
                .accessibilityHint(Text("Continue while the other input method is still running"))
            Button("Check Again") { flow.recheck() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }
}

/// Step 1 after "Quay lại" when no old input method runs any more (artboard
/// OnboardingConflictDone): the ones found in this onboarding, each marked "Đã tắt", and
/// "Tiếp tục" to step 2. One that starts again brings back the conflict screen.
struct ConflictDoneStep: View {
    @Environment(OnboardingFlow.self) private var flow

    var body: some View {
        StepLayout(step: .oldInputMethods, screen: ".done", title: Text("Other Input Methods Turned Off"),
                   subtitle: Text("No other Vietnamese input method is running, so marks won’t be typed twice.")) {
            OnboardingCard {
                ForEach(flow.foundOldInputMethods) { app in
                    HStack(spacing: 12) {
                        OtherAppIcon(bundleID: app.bundleID, name: app.name)
                        Text(verbatim: app.name)
                            .font(.system(size: 13, weight: .semibold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        StatusChip(text: Text("Turned Off"), tint: .green)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .layoutProbe("onbCard-1.done")
        } buttons: {
            Button("Continue") { flow.next() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }
}

struct ConflictCard: View {
    let app: DetectedInputMethod

    var body: some View {
        OnboardingCard {
            HStack(spacing: 12) {
                OtherAppIcon(bundleID: app.bundleID, name: app.name)
                Text(verbatim: app.name)
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                if app.isRunning {
                    RunningChip()
                }
            }
            .accessibilityElement(children: .combine)
            // Mockup line height 1.7: about 22 pt per line.
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(app.quitSteps.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(verbatim: "\(index + 1).")
                            .monospacedDigit()
                        Text(verbatim: line)
                            .lineSpacing(6)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(.system(size: 13))
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.vertical, 3)
            .padding(.leading, 4)
        }
    }
}

/// "Đang chạy": a capsule on the system orange tint.
struct RunningChip: View {
    var body: some View {
        StatusChip(text: Text("Running"), tint: .orange)
    }
}

/// A status capsule on a system color's light tint ("Đang chạy" orange, "Đã tắt" green).
struct StatusChip: View {
    let text: Text
    let tint: Color

    var body: some View {
        text
            .font(.system(size: 12))
            .foregroundStyle(.primary)
            .padding(.horizontal, 9)
            .frame(height: 22)
            .background(tint.quaternary, in: Capsule())
    }
}

/// Another app's icon (32 pt) from Launch Services, or its initial on a system fill.
struct OtherAppIcon: View {
    let bundleID: String
    let name: String

    var body: some View {
        Group {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
            } else {
                Text(verbatim: String(name.prefix(1)))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(.fill, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .frame(width: 32, height: 32)
        .accessibilityHidden(true)
    }
}

// MARK: Step 2

/// Step 2 has five screens (docs/UI.md "Onboarding"), one `StepLayout` each: before
/// "Bật Dấu" (`OnboardingEnable`, `OnboardingEnableNotes`), waiting for the user to click
/// Allow (`OnboardingEnableWaiting`), done (`OnboardingEnableDone`,
/// `OnboardingEnableDoneNoShortcut`), "Chưa bật được" (`OnboardingEnableFailed`) and an
/// install error (`OnboardingEnableError`). The first card of each is the `onbCard-2`
/// probe.
struct EnableStep: View {
    @Environment(OnboardingFlow.self) private var flow
    /// macOS's own names (D38), in the system's language.
    private var ui: SystemUINames { SystemUINames.system() }

    var body: some View {
        switch flow.enableScreen {
        case .ready: ready
        case .waiting: waiting
        case .done: done
        case .notEnabled: notEnabled
        case .error: installError
        }
    }

    private var addedSubtitle: Text {
        Text("Dấu will be added to your macOS input sources, next to the keyboard you use now.")
    }

    // Before the click.
    private var ready: some View {
        StepLayout(step: .enable, screen: ".ready", title: Text("Turn On Dấu"), subtitle: addedSubtitle) {
            OnboardingCard {
                Text("Once it’s on, you’ll see")
                    .font(.system(size: 13, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                HStack(spacing: 12) {
                    InputModeBadge()
                        .fill(.primary, style: FillStyle(eoFill: true))
                        .frame(width: 22, height: 16)
                        .accessibilityHidden(true)
                    Text("A V icon in the menu bar while you type Vietnamese")
                        .font(.system(size: 13))
                }
                ShortcutLine(reading: flow.shortcut, englishLayout: flow.englishLayout)
            }
            .layoutProbe("onbCard-2.ready")
            // Title and sentence across the card; the note and the picture of macOS's
            // dialog side by side under them, so the card is as tall as the picture.
            OnboardingCard(spacing: 6) {
                Text("When you click “Turn On Dấu”")
                    .font(.system(size: 13, weight: .semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("\(ui.systemSettings) will quit, reopen, and ask whether to turn on Dấu. Click **\(ui.allow)**.")
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .center, spacing: 16) {
                    Hint(Text("macOS asks because an input method receives every key you type. Dấu’s input method has no network access."))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    AllowDialogIllustration()
                }
            }
            if !flow.otherSources.isEmpty {
                OtherSourcesNote(names: flow.otherSources)
            }
        } buttons: {
            if flow.canGoBack {
                Button("Go Back") { flow.back() }
            }
            Button("Turn On Dấu") { Task { await flow.enable() } }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }

    // While `enable()` waits for the click.
    private var waiting: some View {
        StepLayout(step: .enable, screen: ".waiting", title: Text("Turn On Dấu"), subtitle: addedSubtitle) {
            OnboardingCard {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            ProgressView()
                                .controlSize(.small)
                                .accessibilityHidden(true)
                            Text("Waiting for you to click \(ui.allow)")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text("The dialog is in the \(ui.systemSettings) window. Click **\(ui.allow)** and Dấu moves on to the next step.")
                            .font(.system(size: 13))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    // A status for VoiceOver: one element that says what it waits for.
                    .accessibilityElement(children: .combine)
                    .accessibilityAddTraits(.updatesFrequently)
                    AllowDialogIllustration()
                }
            }
            .layoutProbe("onbCard-2.waiting")
            Hint(Text("Don’t see the dialog, or chose \(ui.dontAllow)? Click Try Again."))
        } buttons: {
            if flow.canGoBack {
                Button("Go Back") { flow.back() }
            }
            Button("Try Again") { Task { await flow.enable() } }
        }
        .onAppear {
            AccessibilityNotification.Announcement(String(localized: "Waiting for you to click \(ui.allow)")).post()
        }
    }

    /// D37: one app that still cannot select Dấu is fixed by a fresh login. The menu name
    /// is macOS's own (D38). The Apple menu symbol is drawn with the SF Symbol `applelogo`
    /// (macOS 11+), because the private-use glyph U+F8FF is missing from most fonts.
    static func logOutHint(logOut: String) -> Text {
        Text("If an app can’t select Dấu yet, log out (\(Image(systemName: "applelogo")) › \(logOut)) and log back in once.")
    }

    /// Plain-text form of the same catalog entry (symbol left out), for tests.
    static func logOutHintPlain(logOut: String) -> String {
        String(format: String(localized: "If an app can’t select Dấu yet, log out (%@ › %@) and log back in once."), "", logOut)
    }

    // `.enabled`.
    private var done: some View {
        StepLayout(step: .enable, screen: ".done", title: Text("Dấu Is On"),
                   subtitle: Text("“\(ui.dauInputSource)” is now in your macOS input sources.")) {
            OnboardingCard {
                HStack(alignment: .top, spacing: 12) {
                    ListBadge(kind: .done, size: 28)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Choose Dấu to type Vietnamese")
                            .font(.system(size: 13, weight: .semibold))
                            .accessibilityAddTraits(.isHeader)
                        ChooseDauLine(reading: flow.shortcut, englishLayout: flow.englishLayout)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .layoutProbe("onbCard-2.done")
            Hint(Self.logOutHint(logOut: ui.logOut))
        } buttons: {
            Button("Continue") { flow.next() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }

    // `.notEnabled` or `.notListed`.
    private var notEnabled: some View {
        StepLayout(step: .enable, screen: ".failed", title: Text("Couldn’t Turn On Dấu"),
                   subtitle: Text("macOS hasn’t added Dấu to your input sources. The dialog may not have appeared, or the request was declined.")) {
            OnboardingCard(spacing: 10) {
                NumberedLine(number: 1, text: Text("Click **Try Again**, then click **\(ui.allow)** when \(ui.systemSettings) asks."))
                NumberedLine(number: 2, text: Text("Or add it yourself: \(ui.inputSourcesPath) › **\(ui.edit)** › **+** › \(ui.vietnamese) › **Dấu**, then click **\(ui.add)**."))
                NumberedLine(number: 3, text: Text("If Dấu isn’t in that list, log out and log back in once (\(Image(systemName: "applelogo")) › **\(ui.logOut)**), then open Dấu again."))
            }
            .layoutProbe("onbCard-2.failed")
        } buttons: {
            Button("Open \(ui.systemSettings)") { flow.openSystemSettings() }
            Button("Try Again") { Task { await flow.enable() } }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }

    // An error while copying, checking the signature or registering.
    private var installError: some View {
        StepLayout(step: .enable, screen: ".error", title: Text("Couldn’t Install Dấu"),
                   subtitle: Text("Dấu couldn’t copy its input method to this Mac, so it can’t be turned on yet.")) {
            OnboardingCard(spacing: 10) {
                NumberedLine(number: 1, text: Text("Click **Try Again**."))
                NumberedLine(number: 2, text: Text("If it still fails, download Dấu again, drag it to the **\(ui.applications)** folder, then open it again."))
            }
            .layoutProbe("onbCard-2.error")
            if let detail = flow.errorDetail {
                // The error's own text, selectable so it can be copied into a report.
                VStack(alignment: .leading, spacing: 2) {
                    Hint(Text("Details"))
                    Text(verbatim: detail)
                        .font(.system(size: 12))
                        .textSelection(.enabled)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        } buttons: {
            if flow.canGoBack {
                Button("Go Back") { flow.back() }
            }
            Button("Try Again") { Task { await flow.enable() } }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }
}

/// A round badge, 22 pt, as in the artboards' lists: a number on a gray fill (a step in
/// a list), on the accent color (the step to do now), or a check on green (done).
struct ListBadge: View {
    enum Kind { case number(Int), current(Int), done }
    let kind: Kind
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            switch kind {
            case .number(let n):
                Circle().fill(.fill)
                Text(verbatim: "\(n)").font(.system(size: 12, weight: .bold)).foregroundStyle(.primary)
            case .current(let n):
                Circle().fill(Color.accentColor)
                Text(verbatim: "\(n)").font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
            case .done:
                Circle().fill(Color.green)
                Image(systemName: "checkmark")
                    .font(.system(size: size * 0.5, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// One numbered line of a card (badge and text).
struct NumberedLine: View {
    let number: Int
    let text: Text
    var isCurrent = false

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ListBadge(kind: isCurrent ? .current(number) : .number(number))
            text
                .font(.system(size: 13))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Step \(number)"))
        .accessibilityValue(text)
    }
}

/// A small picture of macOS's "Allow … to enable …?" dialog, so the user knows what to
/// look for. Not a control: hidden from VoiceOver. System colors only (D9); the text is
/// the dialog's own wording. Drawn like the real dialog at about 0.75 scale (measured on
/// macOS 27.2, docs/research/M5-INSTALL.md section 8.1b; artboards OnboardingEnable*,
/// canvas version 105): no icon, everything left-aligned, the whole body shown, two
/// equal capsule buttons with "Allow" (the default) blue on the right.
struct AllowDialogIllustration: View {
    /// The dialog's own words, in the system's language (D38).
    private let ui = SystemUINames.system()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(verbatim: ui.allowDialogTitle(app: "Dấu"))
                .font(.system(size: 10.5, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)
            Text(verbatim: ui.allowDialogBody)
                .font(.system(size: 9.5))
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 5) {
                Text(verbatim: ui.dontAllow)
                    .font(.system(size: 9.5, weight: .medium))
                    .frame(maxWidth: .infinity, minHeight: 22)
                    .background(.fill.tertiary, in: Capsule())
                Text(verbatim: ui.allow)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 22)
                    .background(Color.accentColor, in: Capsule())
            }
            .padding(.top, 4)
        }
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 15)
        .padding(.top, 14)
        .padding(.bottom, 13)
        .frame(width: 196, alignment: .leading)
        .background(Color(nsColor: .windowBackgroundColor), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(.separator))
        .shadow(color: .black.opacity(0.18), radius: 12, y: 8)
        .accessibilityHidden(true)
    }
}

/// "Chọn Dấu trong menu nhập liệu, hoặc bấm <phím tắt thật> để chuyển giữa Dấu và U.S.":
/// the real shortcut (N5), as the "Sau khi bật" card reads it, drawn as keycaps like the
/// Settings "Gõ phím" page (`OnboardingEnableDone`). No shortcut set: says so and offers
/// "Đặt phím tắt trong System Settings" (`OnboardingEnableDoneNoShortcut`). A shortcut
/// that cannot be read: only "Chọn Dấu trong menu nhập liệu." and the same button, no
/// claim about the shortcut.
struct ChooseDauLine: View {
    let reading: InputSourceShortcut.Reading
    let englishLayout: String?
    private let ui = SystemUINames.system()

    /// The sentence with `ShortcutSentence.marker` where the shortcut goes.
    static func sentence(englishLayout: String?) -> String {
        let marker = ShortcutSentence.marker
        if let englishLayout {
            return String(localized: "Choose Dấu from the Input menu, or press \(marker) to switch between Dấu and “\(englishLayout)”.")
        }
        return String(localized: "Choose Dấu from the Input menu, or press \(marker) to switch between Dấu and an English keyboard.")
    }

    var body: some View {
        switch reading {
        case .shortcut(let shortcut):
            // The artboard lays the text before the keys, the keys and the text after them
            // side by side, each moving to the next line whole when it does not fit.
            ShortcutSentence(sentence: Self.sentence(englishLayout: englishLayout), shortcut: shortcut,
                             fontSize: 13, wrap: .pieces)
        case .none:
            Text("Choose Dấu from the Input menu. macOS has no shortcut yet to switch quickly between Dấu and an English keyboard.")
                .font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true)
            SystemSettingsLinkButton(title: String(localized: "Set a Shortcut in \(ui.systemSettings)"))
        case .unknown:
            Text("Choose Dấu from the Input menu.")
                .font(.system(size: 13))
                .fixedSize(horizontal: false, vertical: true)
            SystemSettingsLinkButton(title: String(localized: "Set a Shortcut in \(ui.systemSettings)"))
        }
    }
}

/// A sentence that names the input-source shortcut, with the shortcut drawn as keycaps
/// (`ShortcutKeycaps`, the Settings "Gõ phím" page's) where the text names it. The
/// sentence is localized with `marker` in the shortcut's place, so a translation puts the
/// keys wherever its word order needs them. VoiceOver reads it as one sentence with the
/// keys spelled out (`InputSourceShortcut.inlineText`).
struct ShortcutSentence: View {
    /// U+FFFC OBJECT REPLACEMENT CHARACTER: stands for the keycaps in the localized text.
    nonisolated static let marker = "\u{FFFC}"

    enum Wrap {
        /// The text before the keys, the keys and the text after them stay three pieces,
        /// laid side by side (artboard OnboardingEnableDone).
        case pieces
        /// Word by word, as running text (artboard OnboardingNotSelected).
        case words
    }

    let sentence: String
    let shortcut: InputSourceShortcut
    var fontSize: CGFloat
    var keycaps: Keycap.Size = .regular
    var wrap: Wrap

    /// The text before and after the marker, without the spaces around it, and whether
    /// a space separates each from the keys (a comma right after them does not).
    struct Parts: Equatable {
        var before: String
        var after: String
        var spaceBefore: Bool
        var spaceAfter: Bool
    }

    /// nil when the localized sentence has no marker.
    nonisolated static func parts(of sentence: String) -> Parts? {
        let halves = sentence.components(separatedBy: marker)
        guard halves.count == 2 else { return nil }
        let before = halves[0], after = halves[1]
        return Parts(before: before.trimmingCharacters(in: .whitespaces),
                     after: after.trimmingCharacters(in: .whitespaces),
                     spaceBefore: before.last?.isWhitespace ?? false,
                     spaceAfter: after.first?.isWhitespace ?? false)
    }

    /// What VoiceOver reads: the sentence with the keys as text.
    nonisolated static func spoken(_ sentence: String, shortcut: InputSourceShortcut) -> String {
        sentence.replacingOccurrences(of: marker, with: shortcut.inlineText)
    }

    var body: some View {
        Group {
            if let parts = Self.parts(of: sentence) {
                switch wrap {
                case .pieces: piecesFlow(parts)
                case .words: wordsFlow(parts)
                }
            } else {
                Text(verbatim: Self.spoken(sentence, shortcut: shortcut))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .font(.system(size: fontSize))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: Self.spoken(sentence, shortcut: shortcut)))
        .accessibilityAddTraits(.isStaticText)
    }

    private var caps: some View {
        ShortcutKeycaps(shortcut: shortcut, size: keycaps, inSentence: true)
    }

    // Artboard OnboardingEnableDone: 6 pt between the pieces and between the lines.
    private func piecesFlow(_ parts: Parts) -> some View {
        InlineFlow(spacing: 6, lineSpacing: 6) {
            if !parts.before.isEmpty { Text(verbatim: parts.before) }
            caps
            if !parts.after.isEmpty { Text(verbatim: parts.after) }
        }
    }

    // Artboard OnboardingNotSelected: a space between words, lines as tall as a keycap
    // plus 4 pt (22 pt apart with the small keycaps).
    private func wordsFlow(_ parts: Parts) -> some View {
        var before = Self.words(parts.before)
        var after = Self.words(parts.after)
        // Punctuation against the keys stays on their line.
        let leading = parts.spaceBefore ? nil : before.popLast()
        let trailing = parts.spaceAfter ? nil : (after.isEmpty ? nil : after.removeFirst())
        let space = (" " as NSString).size(withAttributes: [.font: NSFont.systemFont(ofSize: fontSize)]).width
        return InlineFlow(spacing: space, lineSpacing: 4, minLineHeight: keycaps.height) {
            ForEach(Array(before.enumerated()), id: \.offset) { _, word in Text(verbatim: word) }
            HStack(spacing: 0) {
                if let leading { Text(verbatim: leading) }
                caps
                if let trailing { Text(verbatim: trailing) }
            }
            ForEach(Array(after.enumerated()), id: \.offset) { _, word in Text(verbatim: word) }
        }
    }

    nonisolated static func words(_ text: String) -> [String] {
        text.split(whereSeparator: \.isWhitespace).map(String.init)
    }
}

/// Lays pieces out as running text: left to right; a piece that does not fit on the line
/// starts the next one, and a piece wider than a whole line wraps inside it (then the next
/// piece starts a new line), as CSS flex-wrap does in the artboards. The pieces of a line
/// are centered on it (keycaps are taller than the text).
struct InlineFlow: Layout {
    var spacing: CGFloat
    var lineSpacing: CGFloat
    var minLineHeight: CGFloat = 0

    private struct Line {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func lines(width maxWidth: CGFloat, _ subviews: Subviews) -> [Line] {
        var lines = [Line()]
        func add(_ index: Int, _ size: CGSize) {
            let gap = lines[lines.count - 1].items.isEmpty ? 0 : spacing
            lines[lines.count - 1].items.append((index, size))
            lines[lines.count - 1].width += gap + size.width
            lines[lines.count - 1].height = max(lines[lines.count - 1].height, size.height, minLineHeight)
        }
        for (index, subview) in subviews.enumerated() {
            let ideal = subview.sizeThatFits(.unspecified)
            let current = lines[lines.count - 1]
            let gap = current.items.isEmpty ? 0 : spacing
            if current.width + gap + ideal.width <= maxWidth {
                add(index, ideal)
                continue
            }
            if !current.items.isEmpty { lines.append(Line()) }
            if ideal.width <= maxWidth {
                add(index, ideal)
            } else {
                add(index, subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil)))
                lines.append(Line())
            }
        }
        return lines.filter { !$0.items.isEmpty }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let lines = lines(width: proposal.width ?? .infinity, subviews)
        let height = lines.map(\.height).reduce(0, +) + lineSpacing * CGFloat(max(0, lines.count - 1))
        return CGSize(width: lines.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for line in lines(width: bounds.width, subviews) {
            var x = bounds.minX
            for (index, size) in line.items {
                subviews[index].place(at: CGPoint(x: x, y: y + (line.height - size.height) / 2),
                                      anchor: .topLeading, proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += line.height + lineSpacing
        }
    }
}

/// The input source shortcut row of step 2: the real shortcut as keycaps (D2), never a
/// guessed one. None set: says so, with a way to System Settings. Not readable: one line
/// saying so, with the same button and no empty keycap (`OnboardingEnableNotes`).
struct ShortcutLine: View {
    let reading: InputSourceShortcut.Reading
    let englishLayout: String?
    private let ui = SystemUINames.system()

    var body: some View {
        switch reading {
        case .shortcut(let shortcut):
            HStack(spacing: 12) {
                ShortcutKeycaps(shortcut: shortcut)
                switchText
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
            }
        case .none:
            HStack(spacing: 12) {
                Text("There’s no shortcut yet to switch quickly to an English keyboard.")
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SystemSettingsLinkButton(title: String(localized: "Open \(ui.systemSettings)"))
            }
        case .unknown:
            HStack(spacing: 12) {
                Text("Couldn’t read the input source shortcut.")
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                SystemSettingsLinkButton(title: String(localized: "Open \(ui.systemSettings)"))
            }
        }
    }

    private var switchText: Text {
        if let englishLayout {
            Text("The macOS shortcut to switch to “\(englishLayout)” for typing English")
        } else {
            Text("The macOS shortcut to switch to an English keyboard")
        }
    }
}

/// A small capsule button that opens the Keyboard pane of System Settings (N4: only opens
/// it), 24 pt tall as in the artboards.
struct SystemSettingsLinkButton: View {
    /// Already in the user's language (`String(localized:)`).
    let title: String

    var body: some View {
        Button(title) { SystemSettings.openKeyboard() }
            .controlSize(.small)
            .buttonBorderShape(.capsule)
            .fixedSize()
    }
}

/// Soft note under the cards: other Vietnamese input sources are on (D14). Not a block.
/// The names are macOS's own, in English.
struct OtherSourcesNote: View {
    let names: [String]
    private let ui = SystemUINames.system()

    var body: some View {
        let list = names.map { "“\($0)”" }.formatted(.list(type: .and))
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Hint(Text("Other Vietnamese input sources are on: \(list). You can remove some in \(ui.inputSourcesPath) to keep the list short."))
        }
        .accessibilityElement(children: .combine)
    }
}

/// The input mode icon, drawn from the same geometry as `scripts/assets/make-mode-icons.swift`
/// (22 × 16 pt: a rounded badge with the V cut out). Fill it with even-odd so the V is
/// a hole, like the template image the menu bar shows.
struct InputModeBadge: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 22, sy = rect.height / 16
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            // The script draws with the origin at the bottom left.
            CGPoint(x: rect.minX + x * sx, y: rect.minY + (16 - y) * sy)
        }
        var path = Path(roundedRect: CGRect(x: rect.minX + 0.5 * sx, y: rect.minY + 0.5 * sy,
                                            width: 21 * sx, height: 15 * sy),
                        cornerRadius: 4 * min(sx, sy), style: .circular)
        path.addLines([p(6.5, 12.25), p(8.3, 12.25), p(11.0, 5.875), p(13.7, 12.25),
                       p(15.5, 12.25), p(11.9, 3.75), p(10.1, 3.75)])
        path.closeSubpath()
        return path
    }
}

// MARK: Step 3

struct TypingStep: View {
    @Environment(OnboardingFlow.self) private var flow
    @Environment(SettingsModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    private let ui = SystemUINames.system()

    var body: some View {
        @Bindable var model = model
        @Bindable var flow = flow
        StepLayout(step: .typing, title: Text("Choose a Typing Method and Try It"),
                   subtitle: Text("You can change this anytime in Dấu Settings.")) {
            SegmentedPicker(String(localized: "Typing method"), selection: $model.settings.typingMethod,
                            options: DauSettings.TypingMethod.allCases.map { ($0, $0.title) })
                .layoutProbe("onbSegmented-3")
            OnboardingCard(spacing: 10) {
                Text("Try typing")
                    .font(.system(size: 13, weight: .semibold))
                TextField(text: $flow.tryText, prompt: Text("Type here")) {
                    Text("Try typing")
                }
                .textFieldStyle(.roundedBorder)
                .controlSize(.large)
                .font(.system(size: 16))
                .accessibilityLabel(Text("Try typing"))
                .layoutProbe("onbTryField-3")
                Hint(Text("Try typing: \(SettingsSamples.tryIt(model.settings.typingMethod).keys)"))
                if flow.status != .selected {
                    notActive
                }
            }
            .layoutProbe("onbCard-3")
        } buttons: {
            Button("Go Back") { flow.back() }
            Button("Start Typing") { dismiss() }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
        }
    }

    /// The field types with the current input source, which is not Dấu yet. The real
    /// shortcut as small keycaps in the hint (N5; artboard OnboardingNotSelected).
    @ViewBuilder private var notActive: some View {
        if let shortcut = flow.shortcut.shortcut {
            ShortcutSentence(sentence: Self.notActiveSentence(dauInputSource: ui.dauInputSource),
                             shortcut: shortcut, fontSize: 12, keycaps: .small, wrap: .words)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Hint(Text("Dấu isn’t the current input source: choose “\(ui.dauInputSource)” from the Input menu, then try typing."))
        }
    }

    /// The hint with `ShortcutSentence.marker` where the shortcut goes.
    static func notActiveSentence(dauInputSource: String) -> String {
        let marker = ShortcutSentence.marker
        return String(localized: "Dấu isn’t the current input source: choose “\(dauInputSource)” from the Input menu or press \(marker), then try typing.")
    }
}
