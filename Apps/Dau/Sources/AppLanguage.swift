import AppKit
import SwiftUI

/// The language of Dấu's own interface (D41). macOS picks it at launch from the user's
/// preferred languages, or from the language the user set for Dấu alone in System
/// Settings › General › Language & Region › Applications. Dấu only shows which one it
/// is and opens that pane; it never writes the language (N1, N4).
enum AppLanguage {
    /// Reads one key of Dấu's own preferences domain; nil when the key is not there.
    typealias DomainReader = (_ key: String) -> Any?

    /// The key macOS writes into the app's own domain when the user sets a language for
    /// Dấu only (measured 08/11/2026: `AppleLanguages` = (vi-VN, en, en-VN) in
    /// com.codefastlabs.dau). The global domain holds the user's list under the same key.
    static let domainKey = "AppleLanguages"

    /// D41: no preferred language Dấu has → English (the development language).
    static let fallback = "en"

    /// The localization Dấu is showing: the one macOS chose for this launch.
    static func current(in bundle: Bundle = .main) -> String {
        bundle.preferredLocalizations.first ?? fallback
    }

    /// A language named in that language, as macOS lists languages: "Tiếng Việt",
    /// "English", "Français". The code itself when Foundation has no name for it.
    static func name(of code: String) -> String {
        let locale = Locale(identifier: code)
        guard let name = locale.localizedString(forLanguageCode: code), let first = name.first else { return code }
        return String(first).uppercased(with: locale) + name.dropFirst()
    }

    /// Whether the language is set for Dấu only: the app's own domain has the key.
    static func isSetForDau(read: DomainReader = { appDomainValue($0) }) -> Bool {
        read(domainKey) != nil
    }

    /// A key of `domain` alone, for the current user on any host. Not `UserDefaults.standard`:
    /// that falls through to the global domain (where every Mac has `AppleLanguages`) and to
    /// launch arguments (`-AppleLanguages`), so it would always find the key.
    static func appDomainValue(_ key: String, domain: String? = Bundle.main.bundleIdentifier) -> Any? {
        guard let domain else { return nil }
        // Pick up a change made in System Settings while Dấu runs.
        CFPreferencesAppSynchronize(domain as CFString)
        return CFPreferencesCopyValue(key as CFString, domain as CFString,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    }

    /// The user's preferred languages (General › Language & Region), from the global
    /// domain; the machine-wide list when the user has none. Not `UserDefaults.standard`,
    /// for the reason given at `appDomainValue`: a launch argument does not outlive this
    /// launch, so it says nothing about the next one.
    static func globalLanguages() -> Any? {
        CFPreferencesSynchronize(kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        return CFPreferencesCopyValue(domainKey as CFString, kCFPreferencesAnyApplication,
                                      kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
            ?? CFPreferencesCopyValue(domainKey as CFString, kCFPreferencesAnyApplication,
                                      kCFPreferencesAnyUser, kCFPreferencesAnyHost)
    }

    /// The localization macOS will pick when Dấu opens next: from the list set for Dấu
    /// only (`appDomain`), else from the user's list (`global`); the first language of the
    /// list that Dấu has, else English (D41).
    static func nextLaunch(available: [String], appDomain: Any?, global: Any?) -> String {
        let preferences = (appDomain as? [String]) ?? (global as? [String]) ?? []
        let localizations = available.filter { $0 != "Base" }
        // Foundation returns some localization even when nothing matches; D41 wants
        // English then, so the pick counts only when a preferred language is its language.
        guard let pick = Bundle.preferredLocalizations(from: localizations, forPreferences: preferences).first,
              preferences.contains(where: { languageCode($0) == languageCode(pick) })
        else { return fallback }
        return pick
    }

    private static func languageCode(_ identifier: String) -> String? {
        Locale(identifier: identifier).language.languageCode?.identifier
    }

    /// What the Language row shows.
    struct Status: Equatable, Sendable {
        /// The language Dấu is showing (`current()`).
        var current: String
        /// The language of the next launch (`nextLaunch`).
        var next: String
        /// The app's own domain has `AppleLanguages` (`isSetForDau`).
        var setForDau: Bool

        /// The language was changed in System Settings and Dấu has not reopened yet:
        /// macOS asks whether to relaunch the app and never does it by itself (D41).
        var isPending: Bool { next != current }
        /// The row's value: the language of the next launch, the one shown now when the
        /// two are the same.
        var shownLanguage: String { isPending ? next : current }
        /// "Reopen Dấu" before "Change…", only while the change waits for a relaunch.
        var showsReopen: Bool { isPending }
    }

    /// The row's status from the real preferences; tests inject the readers.
    static func status(current: String = current(),
                       available: [String] = Bundle.main.localizations,
                       read: DomainReader = { appDomainValue($0) },
                       global: () -> Any? = { globalLanguages() }) -> Status {
        let appDomain = read(domainKey)
        let next = nextLaunch(available: available, appDomain: appDomain,
                              global: appDomain is [String] ? nil : global())
        return Status(current: current, next: next, setForDau: appDomain != nil)
    }

    /// The row's subtitle. `applications`: macOS's own name of the Applications section of
    /// Language & Region, in the system's language (D38).
    static func subtitle(setForDau: Bool, applications: String) -> LocalizedStringResource {
        setForDau
            ? "Set for Dấu only. Click Change… to pick another language, or remove Dấu from the \(applications) list."
            : "Follows macOS. To set a language for Dấu only, click Change…, then under \(applications) click + and choose Dấu."
    }

    /// The row's subtitle for `status`: while a change waits for a relaunch, the first
    /// sentence stays and the rest names the language before and after reopening, each in
    /// its own language as the value is.
    static func subtitle(_ status: Status, applications: String) -> LocalizedStringResource {
        guard status.isPending else { return subtitle(setForDau: status.setForDau, applications: applications) }
        let next = name(of: status.next)
        let now = name(of: status.current)
        return status.setForDau
            ? "Set for Dấu only. Dấu switches to \(next) when it reopens; until then it stays in \(now)."
            : "Follows macOS. Dấu switches to \(next) when it reopens; until then it stays in \(now)."
    }
}

/// "Reopen Dấu" on the Language row (D41): Dấu quits normally and opens again, so macOS
/// picks the new language at launch. Nothing is written; the language is already in the
/// preferences, set by System Settings.
///
/// A small shell, started before quitting, waits until this process is gone and then
/// opens the same bundle. Not `NSWorkspace.openApplication` with
/// `createsNewApplicationInstance`: that starts the second Dấu while this one still runs
/// (same bundle ID: two Settings windows for a moment, and two launch-time upgrade checks
/// of the input method, `DauApp.upgradeAtLaunch`). Waiting for the exit keeps one Dấu at a
/// time, and `open` then launches it as Finder would.
enum AppRelauncher {
    /// `$1`: the process to wait for; `$2`: the app bundle; `$3`: the opener. Gives up
    /// after 30 s, so a quit that never happened does not reopen Dấu at some later quit.
    static let script = """
        i=0
        while kill -0 "$1" 2>/dev/null; do
            i=$((i + 1))
            [ "$i" -gt 300 ] && exit 1
            sleep 0.1
        done
        exec "$3" "$2"
        """

    /// The helper, not started. `opener`: `/usr/bin/open`; tests pass a harmless command.
    static func helper(waitingFor pid: Int32, thenOpen bundle: URL, opener: String = "/usr/bin/open") -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", script, "dau-reopen", String(pid), bundle.path, opener]
        process.standardInput = FileHandle.nullDevice
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        return process
    }

    /// Starts the helper and quits. When the helper cannot start, Dấu stays open.
    @MainActor
    static func reopen() {
        let helper = helper(waitingFor: ProcessInfo.processInfo.processIdentifier, thenOpen: Bundle.main.bundleURL)
        do {
            try helper.run()
        } catch {
            NSSound.beep()
            return
        }
        NSApp.terminate(nil)
    }
}

/// "Ngôn ngữ" on Updates & Support (D41; artboards "Cài đặt – hàng Ngôn ngữ"): the
/// language Dấu shows, how it was chosen, and "Change…", which opens Language & Region.
/// After a change that waits for a relaunch, the language of the next launch and "Reopen
/// Dấu" (artboard "SettingsLanguagePending"). Read only, laid out as the "Remember the
/// input source for each window" row of Apps.
struct LanguageRow: View {
    /// A fixed status instead of the preferences (`scripts/snapshot-settings`).
    @Environment(\.languageRowStatus) private var fixedStatus
    @State private var liveStatus = AppLanguage.status()

    var body: some View {
        let ui = SystemUINames.system()
        let status = fixedStatus ?? liveStatus
        let language = AppLanguage.name(of: status.shownLanguage)
        LabeledContent {
            HStack(spacing: 8) {
                Text(verbatim: language)
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    // One element: as a plain Text, macOS 27.2 exposes a static text
                    // holding a second one with the same value, so VoiceOver can read the
                    // language twice (AX tree of Dấu 6d772e6, 09/11/2026; not caused by
                    // `fixedSize`). Same pattern as the shortcut row's keycaps.
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isStaticText)
                    .accessibilityLabel(Text(verbatim: language))
                if status.showsReopen {
                    Button("Reopen Dấu") { AppRelauncher.reopen() }
                }
                Button("Change…") { SystemSettings.openLanguageAndRegion() }
                    .help(Text("Open \(ui.languageAndRegion)"))
                    .accessibilityHint(Text("Open \(ui.languageAndRegion)"))
            }
        } label: {
            Text("Language")
            Text(AppLanguage.subtitle(status, applications: ui.languageRegionApplications))
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            liveStatus = AppLanguage.status()
        }
    }
}

extension EnvironmentValues {
    /// Nil in the app: the Language row reads the preferences. The snapshot tool sets it to
    /// draw the row waiting for a relaunch.
    @Entry var languageRowStatus: AppLanguage.Status?
}
