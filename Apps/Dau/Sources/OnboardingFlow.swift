import Foundation
import Observation

/// The onboarding window's state (D14, docs/UI.md "Onboarding"): which step shows, what
/// was detected, Dấu's status and the result of the last action. Views only read it and
/// call its actions; services come in through protocols (`OldInputMethodDetector`,
/// `InputMethodInstaller`) so tests drive it with fakes.
///
/// Steps:
/// 1. "Tắt bộ gõ cũ trước đã": only while another Vietnamese input method is running.
///    Rechecked when the window becomes active; skipping is allowed. "Quay lại" from
///    step 2 shows it again: "Đã tắt bộ gõ cũ" when none runs any more, the conflict
///    screen when one runs again.
/// 2. "Bật Dấu": install if needed, then enable: macOS asks the user to allow it, so the
///    step waits ("Đang chờ"), then shows the result read back from Text Input Sources
///    (N4, N5): enabled → "Đã bật"; still off or not listed → "Chưa bật được" with the
///    ways around it (retry, add it by hand, one logout, D37). No undo: Dấu cannot
///    switch itself off, only the user can.
/// 3. "Chọn kiểu gõ và gõ thử".
@MainActor
@Observable
final class OnboardingFlow {
    enum Step: Int, CaseIterable, Sendable {
        case oldInputMethods = 1, enable, typing
    }

    enum StepState: Equatable, Sendable {
        case done, current, pending
    }

    private(set) var step: Step = .enable
    /// Other input methods running now (installed but not running ones do not clash).
    private(set) var conflicts: [DetectedInputMethod] = []
    private(set) var status: InputMethodStatus = .unknown
    private(set) var shortcut: InputSourceShortcut.Reading = .unknown
    /// Name of the keyboard layout used for English, e.g. "U.S."; nil if unknown.
    private(set) var englishLayout: String?
    /// Other Vietnamese input sources enabled in the system (soft note, step 2).
    private(set) var otherSources: [String] = []
    /// `enable()` is running: installing, or waiting for the user to click Allow.
    private(set) var isWorking = false
    /// What went wrong with the last action, shown on step 2.
    private(set) var problem: Problem?
    /// Step 1 was part of this onboarding: another input method was running when it
    /// started. Step 2 offers "Quay lại" only then, so the button never leads to a step
    /// that was never shown.
    private(set) var cameThroughOldInputMethods = false
    /// Every old input method found running during this onboarding, in the order found
    /// ("Đã tắt bộ gõ cũ" lists them).
    private(set) var foundOldInputMethods: [DetectedInputMethod] = []
    /// The user came back to step 1 with "Quay lại": it stays there, showing
    /// "Đã tắt bộ gõ cũ" while nothing runs, instead of moving on by itself.
    private(set) var cameBackToOldInputMethods = false

    /// What step 1 shows.
    enum OldInputMethodsScreen: Equatable, Sendable {
        /// Another input method is running (artboard OnboardingConflict).
        case conflict
        /// None runs any more (artboard OnboardingConflictDone).
        case done
    }

    var oldInputMethodsScreen: OldInputMethodsScreen { conflicts.isEmpty ? .done : .conflict }

    enum Problem: Equatable, Sendable {
        /// An error: the copy, the signature, the registration…
        case failed
        /// Nothing stored as enabled after the wait (the dialog did not show, or the user
        /// declined it).
        case notEnabled
        /// Text Input Sources does not list Dấu (D37).
        case notListed
    }

    /// What step 2 shows.
    enum EnableScreen: Equatable, Sendable {
        /// Before "Bật Dấu".
        case ready
        /// "Bật Dấu" is waiting for the user to click Allow.
        case waiting
        /// Dấu is among the enabled input sources.
        case done
        /// `notEnabled` or `notListed`: retry, add by hand, log out.
        case notEnabled
        /// An install error (copy, signature, registration): "Chưa cài được Dấu".
        case error
    }

    var enableScreen: EnableScreen {
        if status.isEnabled { return .done }
        if isWorking { return .waiting }
        switch problem {
        case .notEnabled?, .notListed?: return .notEnabled
        case .failed?: return .error
        case nil: return .ready
        }
    }

    var failed: Bool { problem != nil }
    /// The error's own description, shown as "Chi tiết" on the error screen (no
    /// placeholder, N5). Set with `problem == .failed`.
    private(set) var errorDetail: String?
    /// Text of the try-it field (step 3).
    var tryText = ""
    /// Step to open at instead of the usual first step, once (debug flag `--onboarding`).
    @ObservationIgnored var forcedStartStep: Step?

    @ObservationIgnored private let detector: OldInputMethodDetector
    @ObservationIgnored private let installer: InputMethodInstaller
    @ObservationIgnored private let readShortcut: () -> InputSourceShortcut.Reading
    @ObservationIgnored private let readEnglishLayout: () -> String?
    @ObservationIgnored private let openKeyboardSettings: () -> Void
    /// The running `enable()` and which call it belongs to: "Thử lại" and "Quay lại"
    /// cancel it, and a call that was replaced leaves the state alone.
    @ObservationIgnored private var enableTask: Task<EnableOutcome, Error>?
    @ObservationIgnored private var attempt = 0

    init(detector: OldInputMethodDetector, installer: InputMethodInstaller,
         shortcut: @escaping () -> InputSourceShortcut.Reading = InputSourceShortcut.read,
         englishLayout: @escaping () -> String? = InputSourceStatus.englishLayoutName,
         openKeyboardSettings: @escaping () -> Void = SystemSettings.openKeyboard) {
        self.detector = detector
        self.installer = installer
        self.readShortcut = shortcut
        self.readEnglishLayout = englishLayout
        self.openKeyboardSettings = openKeyboardSettings
    }

    /// Starts over: step 1 if another input method is running, else step 2.
    func start() {
        cancelEnable()
        problem = nil
        errorDetail = nil
        foundOldInputMethods = []
        cameBackToOldInputMethods = false
        readSystem()
        step = conflicts.isEmpty ? .enable : .oldInputMethods
        cameThroughOldInputMethods = step == .oldInputMethods
        if let forced = forcedStartStep {
            step = forced
            forcedStartStep = nil
        }
    }

    /// Reads everything again (window became active, input sources changed). On step
    /// 1, moves on by itself once nothing clashes any more, unless the user came back to
    /// it ("Đã tắt bộ gõ cũ" then shows, or the conflict screen if one runs again).
    func refresh() {
        readSystem()
        if step == .oldInputMethods && conflicts.isEmpty && !cameBackToOldInputMethods { step = .enable }
        // macOS turned Dấu on (the user allowed it, or added it by hand): the failure no
        // longer holds.
        if status.isEnabled { problem = nil }
    }

    /// Step 1, "Kiểm tra lại".
    func recheck() { refresh() }

    /// Step 1, "Bỏ qua": go on with the other input method still running.
    func skip() {
        guard step == .oldInputMethods else { return }
        cameBackToOldInputMethods = false
        step = .enable
    }

    /// "Quay lại" (HIG: an assistant's previous pane). Step 2 offers it before Dấu is on
    /// (before "Bật Dấu", while waiting for Allow, after an install error; artboards
    /// OnboardingEnable, OnboardingEnableNotes, OnboardingEnableWaiting,
    /// OnboardingEnableError) and only when step 1 was part of this onboarding. Once Dấu
    /// is on, and on "Chưa bật được", the screen keeps its own buttons as drawn.
    var canGoBack: Bool {
        switch step {
        case .oldInputMethods: false
        case .enable:
            switch enableScreen {
            case .ready, .waiting, .error: cameThroughOldInputMethods
            case .done, .notEnabled: false
            }
        case .typing: true
        }
    }

    /// Back one step. From step 2 it cancels a wait still running (as "Thử lại" does, so
    /// no wait outlives the screen) and drops the last error; step 1 then checks the old
    /// input methods again: "Đã tắt bộ gõ cũ" (artboard OnboardingConflictDone) when none
    /// runs, the conflict screen when one does, never an empty list.
    func back() {
        guard canGoBack, let previous = Step(rawValue: step.rawValue - 1) else { return }
        cancelEnable()
        problem = nil
        errorDetail = nil
        if previous == .oldInputMethods { cameBackToOldInputMethods = true }
        step = previous
        if previous == .oldInputMethods { refresh() }
    }

    /// "Tiếp tục": step 1 → 2 once no old input method runs ("Đã tắt bộ gõ cũ"); step
    /// 2 → 3 once Dấu is enabled.
    func next() {
        switch step {
        case .oldInputMethods:
            guard conflicts.isEmpty else { return }
            cameBackToOldInputMethods = false
            step = .enable
        case .enable:
            guard status.isEnabled else { return }
            problem = nil
            step = .typing
        case .typing:
            return
        }
    }

    /// Step 2, "Bật Dấu" and "Thử lại": installs first when needed, then waits for macOS
    /// to store Dấu as enabled. A run still waiting is cancelled first (the new one makes
    /// macOS ask again).
    func enable() async {
        guard step == .enable, !status.isEnabled else { return }
        enableTask?.cancel()
        attempt += 1
        let mine = attempt
        isWorking = true
        problem = nil
        errorDetail = nil
        let installer = self.installer
        let install = status == .notInstalled
        let task = Task { @MainActor () throws -> EnableOutcome in
            if install { try await installer.install() }
            return try await installer.enable()
        }
        enableTask = task
        let result = await task.result
        // Replaced by a newer run, or cancelled by "Quay lại": not this call's state.
        guard mine == attempt else { return }
        enableTask = nil
        isWorking = false
        switch result {
        case .success(.enabled): break
        case .success(.notEnabled): problem = .notEnabled
        case .success(.notListed): problem = .notListed
        case .failure(let error):
            problem = .failed
            errorDetail = Self.describe(error)
            installLogger.error("event=enable-failed error=\(String(describing: error), privacy: .public)")
        }
        status = installer.status()
        if status.isEnabled { problem = nil }
    }

    /// What the error screen shows under "Chi tiết": the error's description.
    nonisolated static func describe(_ error: Error) -> String {
        if let error = error as? InputMethodInstallerError { return error.detail }
        // Any other error (a file operation): its text is in the system's language, not
        // Dấu's, so the screen says only where it happened; the log has the error.
        return String(localized: "Something went wrong while copying or registering the input method.")
    }

    /// "Mở System Settings" on the "Chưa bật được" screen (N4: only opens the pane).
    func openSystemSettings() { openKeyboardSettings() }

    private func cancelEnable() {
        enableTask?.cancel()
        enableTask = nil
        attempt += 1
        isWorking = false
    }

    func state(of step: Step) -> StepState {
        if step == self.step { return .current }
        switch step {
        case .oldInputMethods:
            // Skipped with an input method still running: not done.
            return conflicts.isEmpty ? .done : .pending
        case .enable:
            return status.isEnabled ? .done : .pending
        case .typing:
            return .pending
        }
    }

    /// Debug captures: show a step as is.
    func show(_ step: Step) {
        self.step = step
        if step == .oldInputMethods { cameThroughOldInputMethods = true }
    }

    private func readSystem() {
        conflicts = detector.detect().filter(\.isRunning)
        for app in conflicts where !foundOldInputMethods.contains(where: { $0.bundleID == app.bundleID }) {
            foundOldInputMethods.append(app)
        }
        otherSources = detector.otherVietnameseSources()
        status = installer.status()
        shortcut = readShortcut()
        englishLayout = readEnglishLayout()
    }
}

/// Which window opens at launch (docs/UI.md): onboarding while Dấu is not installed or
/// not enabled, Settings otherwise. Unknown status opens Settings (nothing is claimed).
enum LaunchRouter {
    static func opensOnboarding(_ status: InputMethodStatus) -> Bool {
        switch status {
        case .notInstalled, .installed: true
        case .unknown, .enabled, .selected: false
        }
    }
}
