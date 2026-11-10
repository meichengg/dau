import AppKit
import Carbon

// Services the onboarding window (D14) and the Settings window call through protocols,
// so previews, captures and tests run on fakes: detecting other Vietnamese input methods
// (NSWorkspace, Text Input Sources) and installing, enabling, upgrading and removing
// Dấu's input method (`SystemInputMethodInstaller`, InputMethodInstaller.swift).

// MARK: - Other Vietnamese input methods (step 1)

/// Another Vietnamese input method found on this Mac.
struct DetectedInputMethod: Identifiable, Equatable, Sendable {
    var id: String { bundleID }
    let name: String
    let bundleID: String
    let isRunning: Bool
    /// How to quit it and keep it from starting again, one line per step (N4: Dấu only
    /// explains, it never quits other apps or edits login items).
    let quitSteps: [String]
}

/// Finds other Vietnamese input methods.
@MainActor
protocol OldInputMethodDetector {
    /// Key-intercepting apps (event taps) installed or running. Only running ones clash
    /// with Dấu: they change keys whatever input source is selected.
    func detect() -> [DetectedInputMethod]
    /// Names of other Vietnamese input sources enabled in the system (Apple's
    /// Vietnamese input modes, another IMK input method). They only handle keys while
    /// selected, so they never type over Dấu: a soft note, not a block (D14).
    func otherVietnameseSources() -> [String]
}

/// The key-intercepting input methods step 1 looks for, with the bundle IDs read from
/// each app's released Info.plist (docs/research/M5-INSTALL.md section 5, 30/10/2026).
/// Matched by bundle ID, never by process name. UniKey, VietKey and Laban Key have no
/// macOS app. XKey also installs an IMK input method (`com.codetay.inputmethod.XKey`,
/// process `XKeyIM`): as an input source it is only a soft note
/// (`otherVietnameseSources`), so it is not listed here.
enum KnownInputMethods {
    struct Entry: Sendable {
        let name: String
        let bundleIDs: [String]
        /// Steps verified for this app (research section 5); nil: the generic steps.
        let steps: [String]?
    }

    static let all: [Entry] = [
        Entry(name: "OpenKey", bundleIDs: ["com.tuyenmai.openkey"], steps: [
            String(localized: "In OpenKey’s “Bảng điều khiển…”, turn off “Khởi động cùng macOS”"),
            String(localized: "Click the OpenKey icon in the menu bar, then choose “Thoát”"),
            loginItemsStep("OpenKey"),
        ]),
        Entry(name: "EVKey", bundleIDs: ["com.lamquangminh.evkey"], steps: nil),
        Entry(name: "GoTiengViet", bundleIDs: ["com.trankynam.GoTiengViet"], steps: nil),
        Entry(name: "XKey", bundleIDs: ["com.codetay.XKey"], steps: [
            String(localized: "In XKey’s settings, turn off “Khởi động cùng hệ thống”"),
            String(localized: "Choose “Thoát XKey” from XKey’s menu"),
            loginItemsStep("XKey"),
        ]),
        Entry(name: "PHTV", bundleIDs: ["com.phamhungtien.phtv"], steps: [
            String(localized: "In PHTV’s settings, turn off “Khởi động cùng macOS”"),
            String(localized: "Quit PHTV"),
            loginItemsStep("PHTV"),
        ]),
        Entry(name: "Gõ Nhanh", bundleIDs: ["org.gonhanh.GoNhanh"], steps: [
            String(localized: "In Gõ Nhanh’s settings, turn off “Launch at login”"),
            String(localized: "Quit Gõ Nhanh"),
            loginItemsStep("Gõ Nhanh"),
        ]),
        Entry(name: "GoKey", bundleIDs: ["com.goxkey.app"], steps: nil),
    ]

    /// The steps shown for `name`: the verified ones, or generic ones that claim no
    /// menu wording (N5).
    static func quitSteps(for name: String) -> [String] {
        all.first { $0.name == name }?.steps ?? [
            String(localized: "Quit \(name)"),
            loginItemsStep(name),
        ]
    }

    /// System Settings path on macOS 27.2 (research section 2.5).
    static func loginItemsStep(_ name: String) -> String {
        String(localized: "In \(SystemUINames.system().loginItemsPath), turn off \(name)")
    }
}

/// Real detector, read only: running apps of this user session (NSWorkspace) and
/// installed apps by bundle ID; enabled input sources (Text Input Sources).
@MainActor
struct WorkspaceInputMethodDetector: OldInputMethodDetector {
    var entries: [KnownInputMethods.Entry] = KnownInputMethods.all

    func detect() -> [DetectedInputMethod] {
        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        return entries.compactMap { entry in
            let isRunning = entry.bundleIDs.contains(where: running.contains)
            let installedID = entry.bundleIDs.first {
                NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) != nil
            }
            guard let bundleID = entry.bundleIDs.first(where: running.contains) ?? installedID else { return nil }
            return DetectedInputMethod(name: entry.name, bundleID: bundleID, isRunning: isRunning,
                                       quitSteps: KnownInputMethods.quitSteps(for: entry.name))
        }
    }

    func otherVietnameseSources() -> [String] {
        InputSourceStatus.otherVietnameseSourceNames()
    }
}

/// Fixed answers, for previews, captures and tests.
@MainActor
final class FakeInputMethodDetector: OldInputMethodDetector {
    var found: [DetectedInputMethod]
    var otherSources: [String]
    init(_ found: [DetectedInputMethod] = [], otherSources: [String] = []) {
        self.found = found
        self.otherSources = otherSources
    }
    func detect() -> [DetectedInputMethod] { found }
    func otherVietnameseSources() -> [String] { otherSources }

    static func running(_ name: String, bundleID: String = "com.example.ime") -> DetectedInputMethod {
        DetectedInputMethod(name: name, bundleID: bundleID, isRunning: true,
                            quitSteps: KnownInputMethods.quitSteps(for: name))
    }
}

// MARK: - Dấu's own input method (step 2, Settings)

/// Where Dấu's input source stands in the system.
enum InputMethodStatus: Equatable, Sendable {
    /// Cannot be read (no input method bundle inside the app): nothing is claimed (N5).
    case unknown
    case notInstalled
    /// Installed in ~/Library/Input Methods but "Dấu – Tiếng Việt" is not among the
    /// enabled input sources. `version` is nil when it cannot be read.
    case installed(version: String?)
    /// Among the enabled input sources.
    case enabled
    /// Enabled and the current input source.
    case selected

    var isEnabled: Bool { self == .enabled || self == .selected }
}

enum InputMethodInstallerError: Error, Equatable {
    /// The action is not available (no input method bundle inside the app).
    case unavailable
    /// The input method inside the app is not validly signed by the app's own team.
    case invalidSignature
    case failed(String)
    /// Dấu's entries are still among the stored input sources: the user has not removed
    /// it yet, so nothing is deleted (a bundle gone before that leaves an entry that can
    /// no longer be removed).
    case stillListed
}

/// What Text Input Sources reports after "Bật Dấu" (N4: re-read, never assumed).
enum EnableOutcome: Equatable, Sendable {
    /// "Dấu – Tiếng Việt" is among the enabled input sources.
    case enabled
    /// The calls went through but the source is still off (macOS may wait for the user
    /// to allow it, or ignore the call: docs/research/M5-INSTALL.md section 2.2).
    case notEnabled
    /// Text Input Sources does not list Dấu at all: macOS shows a new input method only
    /// after a logout (D37), when none of the ways around it worked.
    case notListed
}

/// What `upgradeIfNeeded` did (D7, D37).
enum UpgradeOutcome: Equatable, Sendable {
    /// Nothing installed (the first install is the user's, from onboarding).
    case notInstalled
    case upToDate
    case upgraded(from: String?, to: String)
    /// Not replaced: the installed bundle has another identity (D37: IDs never change).
    case skipped(String)
}

extension InputMethodInstallerError {
    /// What the "Chi tiết" line of the error screen says, in Vietnamese and only what the
    /// error is (N5). The technical text (system status codes) goes to the log, not here.
    var detail: String {
        switch self {
        case .unavailable:
            String(localized: "The input method wasn’t found inside the Dấu app.")
        case .invalidSignature:
            String(localized: "The input method’s signature isn’t valid, or it isn’t from the same developer as the app.")
        case .failed(let message) where message == "not installed":
            String(localized: "The input method hasn’t been copied to this Mac.")
        case .failed:
            String(localized: "macOS reported an error while copying or registering the input method.")
        case .stillListed:
            String(localized: "Dấu is still in the input sources.")
        }
    }
}

/// What the uninstall did (D16), for the result alert.
struct UninstallReport: Equatable, Sendable {
    /// The input method bundle was moved to the Trash (false: it was not installed).
    var movedToTrash = false
    /// One of Dấu's sources still reads as enabled afterwards.
    var stillEnabled = false
    /// The App Group settings were deleted (the user ticked the box).
    var dataDeleted = false
}

/// Installs, enables, upgrades and removes Dấu's input method. The user starts enable
/// and uninstall (N4); results are read back from Text Input Sources (N5). Dấu cannot
/// switch its own input source off (macOS blocks `TISDisableInputSource` from an app,
/// docs/research/M5-INSTALL.md section 4): only the user removes it, in System
/// Settings, so there is no undo and uninstall waits for that.
@MainActor
protocol InputMethodInstaller: AnyObject {
    func status() -> InputMethodStatus
    /// Copies the input method bundled in the app to ~/Library/Input Methods and
    /// registers it.
    func install() async throws
    /// Adds "Dấu – Tiếng Việt" to the user's input sources, then reads it back. Waits for
    /// the user to allow it in macOS's dialog; throws `CancellationError` when the task
    /// is cancelled.
    func enable() async throws -> EnableOutcome
    /// Whether the installed input method is the one this app installs (valid signature
    /// by the same team); true when none is installed. ~/Library/Input Methods is
    /// writable by any process of the user, and macOS keeps feeding keys to an enabled
    /// input source whatever bundle sits there.
    func installedIsGenuine() -> Bool
    /// Replaces an older installed input method with the one in the app (D7).
    func upgradeIfNeeded() async throws -> UpgradeOutcome
    /// Whether one of Dấu's entries is stored among the input sources (the same reading
    /// as `waitUntilRemovedFromInputSources`). True when it cannot tell (no bundle in the
    /// app), so uninstall takes the usual path and reports the error there.
    func isListedInInputSources() -> Bool
    /// Uninstall, step 1 (D16): opens the Input Sources list of System Settings, where the
    /// user removes Dấu. Selects nothing and removes nothing: macOS picks a keyboard itself
    /// when Dấu goes away.
    func prepareUninstall() async throws
    /// Uninstall, step 2: returns once none of Dấu's entries is stored as enabled any
    /// more (the user removed it). Polls; throws `CancellationError` when cancelled.
    func waitUntilRemovedFromInputSources() async throws
    /// Uninstall, step 3, only once none of Dấu's entries is stored (else throws
    /// `stillListed`, nothing touched): stops the input method, moves it to the Trash,
    /// deletes the App Group data when `deleteSettings`, and reads the result back (D16).
    func finishUninstall(deleteSettings: Bool) async throws -> UninstallReport
}

/// In-memory installer for previews, captures and tests. Records the calls it gets.
@MainActor
final class FakeInputMethodInstaller: InputMethodInstaller {
    var current: InputMethodStatus
    var failure: InputMethodInstallerError?
    /// What the next `enable()` reports.
    var enableOutcome: EnableOutcome = .enabled
    /// `enable()` waits (like the real one for the user's click) until `release` is set,
    /// or throws `CancellationError` when the task is cancelled. Captures and tests.
    var enableWaits = false
    private(set) var enableWaiting = false
    var release: EnableOutcome?
    var uninstallReport = UninstallReport()
    /// Dấu is still among the stored input sources: `finishUninstall` throws, and
    /// `waitUntilRemovedFromInputSources` waits until this is false or it is cancelled.
    var stillListed = false
    /// `finishUninstall` throws this (a failure after the wait).
    var finishFailure: InputMethodInstallerError?
    var genuine = true
    /// `upgradeIfNeeded` takes a moment, then replaces a bad installed copy with a good one
    /// (`genuine` becomes true): the ordering test of the launch upgrade and the check.
    var upgradeRepairs = false
    private(set) var calls: [String] = []

    init(_ status: InputMethodStatus = .notInstalled, failure: InputMethodInstallerError? = nil) {
        current = status
        self.failure = failure
    }

    func status() -> InputMethodStatus { current }

    func install() async throws {
        calls.append("install")
        if let failure { throw failure }
        genuine = true
        if current == .notInstalled || current == .unknown { current = .installed(version: nil) }
    }

    func enable() async throws -> EnableOutcome {
        calls.append("enable")
        if let failure { throw failure }
        guard current != .notInstalled else { throw InputMethodInstallerError.failed("not installed") }
        var outcome = enableOutcome
        if enableWaits {
            enableWaiting = true
            defer { enableWaiting = false }
            release = nil
            while release == nil {
                try Task.checkCancellation()
                try await Task.sleep(for: .milliseconds(5))
            }
            outcome = release ?? outcome
        }
        if outcome == .enabled, !current.isEnabled { current = .enabled }
        return outcome
    }

    func installedIsGenuine() -> Bool { genuine }

    func upgradeIfNeeded() async throws -> UpgradeOutcome {
        calls.append("upgrade")
        if let failure { throw failure }
        if upgradeRepairs {
            try await Task.sleep(for: .milliseconds(30))
            genuine = true
            return .upgraded(from: nil, to: "2")
        }
        return .upToDate
    }

    func isListedInInputSources() -> Bool { stillListed }

    func prepareUninstall() async throws {
        calls.append("prepareUninstall")
        if let failure { throw failure }
    }

    func waitUntilRemovedFromInputSources() async throws {
        calls.append("wait")
        while stillListed {
            try Task.checkCancellation()
            try await Task.sleep(for: .milliseconds(5))
        }
    }

    func finishUninstall(deleteSettings: Bool) async throws -> UninstallReport {
        calls.append(deleteSettings ? "finish+data" : "finish")
        if let failure { throw failure }
        if let finishFailure { throw finishFailure }
        if stillListed { throw InputMethodInstallerError.stillListed }
        current = .notInstalled
        return uninstallReport
    }
}

// MARK: - Text Input Sources, read only

extension InputSourceStatus {
    /// Whether the input method is installed (registered with Text Input Sources,
    /// enabled or not). `nil` when the bundle is not found inside the app.
    nonisolated static func queryInstalled() -> Bool? {
        guard let bundleID = inputMethodBundleID else { return nil }
        let filter = [kTISPropertyBundleID as String: bundleID] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, true)?.takeRetainedValue() else { return false }
        return CFArrayGetCount(list) > 0
    }

    /// Whether Dấu is the current input source. `nil` when unknown.
    nonisolated static func querySelected() -> Bool? {
        guard let bundleID = inputMethodBundleID,
              let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let raw = TISGetInputSourceProperty(source, kTISPropertyBundleID) else { return nil }
        let current = Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
        return current == bundleID
    }

    /// Localized name of an enabled keyboard layout other than Dấu, e.g. "U.S.": the one
    /// the user switches to for English (D2). `nil` when there is none to name.
    nonisolated static func englishLayoutName() -> String? {
        let filter = [kTISPropertyInputSourceType as String: kTISTypeKeyboardLayout as String,
                      kTISPropertyInputSourceIsSelectCapable as String: true] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
            return nil
        }
        func string(_ source: TISInputSource, _ key: CFString) -> String? {
            TISGetInputSourceProperty(source, key).map { Unmanaged<CFString>.fromOpaque($0).takeUnretainedValue() as String }
        }
        func isEnglish(_ source: TISInputSource) -> Bool {
            guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else { return false }
            let languages = Unmanaged<CFArray>.fromOpaque(raw).takeUnretainedValue() as? [String] ?? []
            return languages.first == "en"
        }
        // An English layout first (U.S., or another English one), else any other layout.
        let ordered = list.filter(isEnglish) + list.filter { !isEnglish($0) }
        // The name as the menu bar shows it (`LayoutNames`), TIS's own as the fallback.
        let names = LayoutNames.system()
        return ordered.lazy.compactMap { source -> String? in
            guard let tisName = string(source, kTISPropertyLocalizedName), !tisName.isEmpty else { return nil }
            return names.displayName(sourceID: string(source, kTISPropertyInputSourceID) ?? "", fallback: tisName)
        }.first
    }

    /// Localized names of enabled, selectable Vietnamese input sources that are not
    /// Dấu's (Apple's Telex/VNI modes, XKeyIM…), for step 2's soft note.
    nonisolated static func otherVietnameseSourceNames() -> [String] {
        let filter = [kTISPropertyInputSourceIsSelectCapable as String: true] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
            return []
        }
        func string(_ source: TISInputSource, _ key: CFString) -> String? {
            TISGetInputSourceProperty(source, key).map { Unmanaged<CFString>.fromOpaque($0).takeUnretainedValue() as String }
        }
        return list.compactMap { source in
            guard let raw = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages),
                  (Unmanaged<CFArray>.fromOpaque(raw).takeUnretainedValue() as? [String])?.first == "vi",
                  string(source, kTISPropertyBundleID) != inputMethodBundleID,
                  let type = string(source, kTISPropertyInputSourceType),
                  type == (kTISTypeKeyboardInputMode as String) || type == (kTISTypeKeyboardInputMethodWithoutModes as String)
            else { return nil }
            return string(source, kTISPropertyLocalizedName)
        }
    }
}
