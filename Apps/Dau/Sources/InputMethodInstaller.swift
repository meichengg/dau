import AppKit
import Carbon
import DauShared
import Security
import os

// The real `InputMethodInstaller` (M5, D14, D16, D37; docs/research/M5-INSTALL.md
// sections 2–4). It talks to the system through narrow interfaces, so the order of
// operations and every failure path are tested with fakes
// (scripts/snapshot-settings/Tests/…/InputMethodInstallerTests.swift):
// - `InputMethodFiles`: the bundle inside the app and the copy in ~/Library/Input Methods;
// - `TextInputSources`: register, enable, read back;
// - `InputMethodProcesses`: is the input method running, ask it to quit;
// - `SystemSettingsControl`: System Settings' Keyboard cache and the System Settings
//   process (D37, M5-INSTALL.md section 8.1b);
// - `InputSourceCaches`: the input source list cache of every app (D37, M5-INSTALL.md
//   section 9.10, section 10.10, section 8.1b round E).
//
// N4: install copies Dấu's own files; enable and uninstall run only from a button the
// user clicked ("Bật Dấu", "Bật lại", "Tiếp tục gỡ"); upgrade replaces Dấu's own bundle
// (D7). Dấu never selects itself as the input source, and never switches its own input
// source off: macOS blocks that from an app, the user removes it in System Settings.

let installLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Dau", category: "install")

// MARK: - Interfaces

/// What the installer needs from an input method bundle's Info.plist.
struct InputMethodBundleInfo: Equatable, Sendable {
    let bundleID: String
    /// CFBundleVersion, compared to decide on an upgrade.
    let version: String?
    /// CFBundleShortVersionString, for display.
    let shortVersion: String?
    /// Input mode IDs declared in ComponentInputModeDict.
    let modeIDs: [String]

    /// The Vietnamese mode (D2, D24: "….Dau.vi").
    var vietnameseModeID: String {
        modeIDs.first { $0.hasSuffix(".vi") } ?? bundleID + ".vi"
    }
}

@MainActor
protocol InputMethodFiles {
    /// The input method shipped inside the app; nil when missing or unreadable.
    var embedded: InputMethodBundleInfo? { get }
    /// Where the input method is installed (~/Library/Input Methods/DauInputMethod.app).
    var installedURL: URL { get }
    var isInstalled: Bool { get }
    /// The installed copy's Info.plist, read fresh from disk (no Bundle cache).
    var installed: InputMethodBundleInfo? { get }
    /// False when an installed copy is there but its signature is invalid or not by this
    /// app's team: replaced or modified after install. True when nothing is installed.
    var installedIsGenuine: Bool { get }
    /// Copies the embedded bundle to a staging folder next to the destination, clears
    /// quarantine, checks the signature, then swaps it in place in one rename.
    func installEmbedded() throws
    func moveInstalledToTrash() throws
}

/// One input source as Text Input Sources reports it.
struct InputSourceEntry: Equatable, Sendable {
    let id: String
    let bundleID: String?
    /// An input mode (kTISTypeKeyboardInputMode), as opposed to the parent input method.
    let isMode: Bool
    let name: String
}

@MainActor
protocol TextInputSources: AnyObject {
    func register(_ url: URL) -> OSStatus
    /// Sources of `bundleID`; `includeDisabled` false returns the enabled ones only.
    func sources(bundleID: String, includeDisabled: Bool) -> [InputSourceEntry]
    func enable(_ id: String) -> OSStatus
    func current() -> InputSourceEntry?
    /// The IDs of `bundleID` macOS has stored as enabled (`com.apple.inputsources`
    /// › `AppleEnabledThirdPartyInputSources`; the parent's entry has no input mode, its
    /// ID is the bundle ID). This is what the next login enables, and what the user's
    /// "–" in System Settings removes. The TIS list of this process can disagree with it
    /// for a while.
    func storedEnabledIDs(bundleID: String) -> Set<String>
}

@MainActor
protocol InputMethodProcesses: AnyObject {
    func isRunning(bundleID: String) -> Bool
    /// Darwin notification the input method exits on (`InputMethodLifecycle`).
    func requestQuit(bundleID: String)
    /// Last resort when the request is not heard (an input method older than the
    /// request): ends Dấu's own input method process, nothing else.
    func forceQuit(bundleID: String)
}

/// What "Bật Dấu" and uninstall need from System Settings (D37, docs/research/M5-INSTALL.md
/// section 8.1b): the enable request is only handled when System Settings has to open the
/// Keyboard extension, and its input source cache must be rebuilt to drop a removed source.
@MainActor
protocol SystemSettingsControl: AnyObject {
    /// Deletes `com.apple.IntlDataCache.le*` in the user cache folder of System
    /// Settings' Keyboard extension (uninstall). `failed` counts files that could not be
    /// removed.
    func clearKeyboardCache() -> (removed: Int, failed: Int)
    var isRunning: Bool { get }
    /// Polite request to quit (`terminate()`, never a forced end).
    func terminate()
}

/// Counts of one pass over the input source caches, for the log.
struct InputSourceCacheCounts: Equatable, Sendable {
    /// `.kbdx` files read (verification pass only).
    var checked = 0
    /// Caches that do not list the input method (verification pass only).
    var stale = 0
    /// Cache files deleted.
    var removed = 0
    /// Folders that could not be listed, `.kbdx` files that could not be read, cache files
    /// that could not be removed. Skipped, never an error of the caller.
    var failed = 0
}

/// The input source list caches of every app (D37; docs/research/M5-INSTALL.md section 0
/// section 9.10, section 10.10, section 8.1b round E). Each sandboxed app (System Settings' Keyboard
/// extension too) keeps `com.apple.IntlDataCache.le*` in its own folder of the user cache
/// folder and uses it as is, even after a relaunch; a missing cache is rebuilt from disk
/// at the next `TISRegisterInputSource`. The shared cache in the folder's root refreshes
/// itself and is never touched.
@MainActor
protocol InputSourceCaches {
    /// Deletes `com.apple.IntlDataCache.le*` in every immediate subfolder of the user
    /// cache folder.
    func clearAll() -> InputSourceCacheCounts
    /// Reads every subfolder's `com.apple.IntlDataCache.le.kbdx` that is readable and
    /// deletes the caches whose bytes do not contain `marker` (UTF-8).
    func removeCaches(notMentioning marker: String) -> InputSourceCacheCounts
}

// MARK: - Installer

@MainActor
final class SystemInputMethodInstaller: InputMethodInstaller {
    private let files: InputMethodFiles
    private let sources: TextInputSources
    private let processes: InputMethodProcesses
    private let settings: SystemSettingsControl
    private let caches: InputSourceCaches
    /// Deletes the App Group data (settings, app rules); true on success.
    private let deleteSharedData: @MainActor () -> Bool
    private let pause: @MainActor (Duration) async -> Void
    private let openInputSources: @MainActor () -> Void

    /// How long `enable()` waits for macOS to store Dấu as enabled: the user needs time
    /// to read the "Allow" dialog and click it (D37).
    var enableTimeout: Duration = .seconds(60)
    /// How long System Settings has to quit on request before `enable()` goes on.
    var settingsQuitTimeout: Duration = .seconds(5)
    /// How long the input method has to quit on request before it is ended.
    var quitTimeout: Duration = .seconds(2)
    /// How often uninstall looks for the user to have removed Dấu from the input sources.
    var removalPollInterval: Duration = .milliseconds(500)
    private let pollInterval: Duration = .milliseconds(100)
    private let enablePollInterval: Duration = .milliseconds(250)

    init(files: InputMethodFiles, sources: TextInputSources, processes: InputMethodProcesses,
         settings: SystemSettingsControl, caches: InputSourceCaches,
         deleteSharedData: @escaping @MainActor () -> Bool,
         openInputSources: @escaping @MainActor () -> Void = { SystemSettings.openInputSources() },
         pause: @escaping @MainActor (Duration) async -> Void = { try? await Task.sleep(for: $0) }) {
        self.files = files
        self.sources = sources
        self.processes = processes
        self.settings = settings
        self.caches = caches
        self.deleteSharedData = deleteSharedData
        self.openInputSources = openInputSources
        self.pause = pause
    }

    /// The installer on the real system.
    static func standard() -> SystemInputMethodInstaller {
        SystemInputMethodInstaller(files: InputMethodBundleFiles.standard(),
                                   sources: SystemTextInputSources(),
                                   processes: SystemInputMethodProcesses(),
                                   settings: SystemSettingsProcess(),
                                   caches: UserInputSourceCaches.standard(),
                                   deleteSharedData: SharedData.delete)
    }

    func status() -> InputMethodStatus {
        guard let embedded = files.embedded else { return .unknown }
        guard files.isInstalled else { return .notInstalled }
        let mode = embedded.vietnameseModeID
        guard isEnabled(mode, of: embedded.bundleID) else {
            return .installed(version: files.installed?.shortVersion)
        }
        return sources.current()?.id == mode ? .selected : .enabled
    }

    func install() async throws {
        guard let embedded = files.embedded else { throw InputMethodInstallerError.unavailable }
        try files.installEmbedded()
        installLogger.notice("event=installed version=\(embedded.version ?? "?", privacy: .public)")
        // A process still running from an older copy keeps the old code until it exits.
        await stopInputMethod(embedded.bundleID)
        let status = sources.register(files.installedURL)
        installLogger.notice("event=register status=\(status)")
        guard status == noErr else { throw InputMethodInstallerError.failed("TISRegisterInputSource \(status)") }
    }

    func enable() async throws -> EnableOutcome {
        guard let embedded = files.embedded else { throw InputMethodInstallerError.unavailable }
        guard files.isInstalled else { throw InputMethodInstallerError.failed("not installed") }
        let bundleID = embedded.bundleID, mode = embedded.vietnameseModeID

        // Every app's input source cache goes right before registering: an app keeps a
        // cache built before Dấu was installed forever, and rebuilds a missing one from
        // disk at the register below, running or not (D37; System Settings' Keyboard
        // extension is one of them). As short a gap as possible: an app may rebuild it
        // in between.
        let cleared = caches.clearAll()
        installLogger.notice("event=enable-caches-cleared removed=\(cleared.removed) failed=\(cleared.failed)")

        // Always register: harmless, and what makes TIS list a bundle installed in this
        // session (D37).
        let registered = sources.register(files.installedURL)
        installLogger.notice("event=enable-register status=\(registered)")
        guard !sources.sources(bundleID: bundleID, includeDisabled: true).isEmpty else {
            installLogger.notice("event=enable-not-listed")
            return .notListed
        }

        // "Enabled" is what macOS has stored, not TIS's flag: right after register TIS
        // reports the mode enabled while the stored list is empty (8.1b).
        if isEnabled(mode, of: bundleID) {
            installLogger.notice("event=enable-already-stored")
            refreshStaleCaches()
            return .enabled
        }

        // System Settings handles the enable request only when it builds the Keyboard
        // extension afresh: make it quit (8.1b). Its cache went with the others above.
        await quitSystemSettings()

        // The parent only; macOS stores the mode with it. TISEnableInputSource sends the
        // request to System Settings and returns 0 whatever happens next.
        let storedBefore = sources.storedEnabledIDs(bundleID: bundleID)
        if !storedBefore.contains(bundleID) {
            let status = sources.enable(bundleID)
            installLogger.notice("event=enable id=\(bundleID, privacy: .public) status=\(status)")
        }

        // The status code proves nothing: wait for the stored entry (N4, N5). The user
        // may take a while to click Allow; "Thử lại" cancels the wait.
        var waited: Duration = .zero
        while true {
            try Task.checkCancellation()
            if isEnabled(mode, of: bundleID) {
                installLogger.notice("event=enable-stored waited=\(waited.components.seconds)s")
                refreshStaleCaches()
                return .enabled
            }
            if waited >= enableTimeout { break }
            await pause(enablePollInterval)
            waited += enablePollInterval
        }
        installLogger.notice("event=enable-timeout waited=\(waited.components.seconds)s")
        return .notEnabled
    }

    func installedIsGenuine() -> Bool {
        let genuine = files.installedIsGenuine
        if !genuine { installLogger.error("event=installed-not-genuine") }
        return genuine
    }

    func upgradeIfNeeded() async throws -> UpgradeOutcome {
        guard let embedded = files.embedded, files.isInstalled else { return .notInstalled }
        guard let installed = files.installed else {
            return .skipped("installed bundle unreadable")
        }
        guard installed.bundleID == embedded.bundleID else {
            // D37: IDs never change between versions; another identity means another
            // install, which needs the user (and a logout), not a silent swap.
            return .skipped("bundle ID \(installed.bundleID)")
        }
        guard let new = embedded.version, Self.isNewer(new, than: installed.version) else { return .upToDate }
        try files.installEmbedded()
        // The old process keeps the old code mapped: ask it to quit; macOS launches the
        // new bundle at the next key. Then register again (harmless, keeps TIS current).
        await stopInputMethod(embedded.bundleID)
        let status = sources.register(files.installedURL)
        installLogger.notice("event=upgraded from=\(installed.version ?? "?", privacy: .public) to=\(new, privacy: .public) register=\(status)")
        return .upgraded(from: installed.version, to: new)
    }

    func isListedInInputSources() -> Bool {
        guard let embedded = files.embedded else { return true }
        return !sources.storedEnabledIDs(bundleID: embedded.bundleID).isEmpty
    }

    func prepareUninstall() async throws {
        guard files.embedded != nil else { throw InputMethodInstallerError.unavailable }
        // Only opens the list: "–" works for the selected source too, and macOS selects a
        // keyboard itself when Dấu goes away (measured on macOS 27.2, 04/11/2026).
        openInputSources()
        installLogger.notice("event=uninstall-prepared")
    }

    func waitUntilRemovedFromInputSources() async throws {
        guard let embedded = files.embedded else { throw InputMethodInstallerError.unavailable }
        while true {
            try Task.checkCancellation()
            if sources.storedEnabledIDs(bundleID: embedded.bundleID).isEmpty { return }
            await pause(removalPollInterval)
        }
    }

    func finishUninstall(deleteSettings: Bool) async throws -> UninstallReport {
        guard let embedded = files.embedded else { throw InputMethodInstallerError.unavailable }
        let bundleID = embedded.bundleID
        // Only once the user removed Dấu from the list: a bundle gone before that leaves
        // an entry nobody can remove.
        let stored = sources.storedEnabledIDs(bundleID: bundleID)
        guard stored.isEmpty else {
            installLogger.error("event=uninstall-still-stored ids=\(stored.sorted(), privacy: .public)")
            throw InputMethodInstallerError.stillListed
        }
        var report = UninstallReport()

        // Move it to the Trash, then stop it: the input method quits only once its
        // bundle is gone from disk (InputMethodLifecycle), the running process keeps its
        // code mapped meanwhile.
        if files.isInstalled {
            try files.moveInstalledToTrash()
            report.movedToTrash = true
        }
        await stopInputMethod(bundleID)

        // System Settings' input source cache still holds the removed bundle: the "+"
        // list keeps a row without a name (and TIS keeps listing it) until the cache is
        // rebuilt, which used to take a logout. Deleting it makes System Settings rebuild
        // it at once (D37, docs/research/M5-INSTALL.md section 8.1b, rounds U).
        let cache = settings.clearKeyboardCache()
        installLogger.notice("event=uninstall-cache-cleared removed=\(cache.removed) failed=\(cache.failed)")

        // The App Group data, only when asked.
        if deleteSettings {
            report.dataDeleted = deleteSharedData()
        }
        // What macOS stored, not TIS's flag (it can stay true after the source is gone).
        report.stillEnabled = !sources.storedEnabledIDs(bundleID: bundleID).isEmpty
        installLogger.notice("event=uninstalled stillEnabled=\(report.stillEnabled) dataDeleted=\(report.dataDeleted)")
        return report
    }

    // MARK: Helpers

    /// The mode is among the entries macOS stored as enabled (D37, N4): not TIS's flag,
    /// which is true right after `TISRegisterInputSource`.
    private func isEnabled(_ mode: String, of bundleID: String) -> Bool {
        sources.storedEnabledIDs(bundleID: bundleID).contains(mode)
    }

    /// One pass once Dấu is enabled (D37): a cache an app rebuilt between the clearing and
    /// the register may still miss Dấu; such caches go, and one more register makes the
    /// apps rebuild them. Never throws, never changes the outcome of `enable()`.
    ///
    /// Heuristic on an undocumented format: a cache that lists the input method is taken
    /// to contain its path, ".../Input Methods/DauInputMethod.app", as UTF-8
    /// (M5-INSTALL.md section 9.10 found the bundle name in rebuilt caches; the exact
    /// bytes are not documented and may change).
    private func refreshStaleCaches() {
        let url = files.installedURL
        let marker = url.deletingLastPathComponent().lastPathComponent + "/" + url.lastPathComponent
        let pass = caches.removeCaches(notMentioning: marker)
        installLogger.notice("event=enable-caches-checked checked=\(pass.checked) stale=\(pass.stale) removed=\(pass.removed) failed=\(pass.failed)")
        guard pass.stale > 0 else { return }
        let status = sources.register(url)
        installLogger.notice("event=enable-register-again status=\(status)")
    }

    /// Asks System Settings to quit (never forced) and waits up to `settingsQuitTimeout`.
    private func quitSystemSettings() async {
        guard settings.isRunning else {
            installLogger.notice("event=enable-settings-not-running")
            return
        }
        settings.terminate()
        var waited: Duration = .zero
        while settings.isRunning, waited < settingsQuitTimeout {
            await pause(pollInterval)
            waited += pollInterval
        }
        if settings.isRunning {
            installLogger.notice("event=enable-settings-still-running")
        } else {
            installLogger.notice("event=enable-settings-quit")
        }
    }

    /// Asks the input method to quit, waits up to `quitTimeout`, then ends it. Returns
    /// false if it still runs.
    @discardableResult
    private func stopInputMethod(_ bundleID: String) async -> Bool {
        guard processes.isRunning(bundleID: bundleID) else { return true }
        processes.requestQuit(bundleID: bundleID)
        var waited: Duration = .zero
        while waited < quitTimeout {
            await pause(pollInterval)
            waited += pollInterval
            if !processes.isRunning(bundleID: bundleID) { return true }
        }
        installLogger.notice("event=quit-timeout, ending the input method")
        processes.forceQuit(bundleID: bundleID)
        for _ in 0..<10 {
            await pause(pollInterval)
            if !processes.isRunning(bundleID: bundleID) { return true }
        }
        installLogger.error("event=still-running")
        return false
    }

    /// CFBundleVersion order ("1.10" > "1.9"); an unreadable installed version is older.
    nonisolated static func isNewer(_ candidate: String, than installed: String?) -> Bool {
        guard let installed else { return true }
        return candidate.compare(installed, options: .numeric) == .orderedDescending
    }
}

// MARK: - Files

/// The real bundle files. Directories are parameters so tests run on a temp folder.
struct InputMethodBundleFiles: InputMethodFiles {
    let embeddedURL: URL
    let directory: URL
    /// Signature check of the staged copy (default: valid, same team as this app).
    var verify: (URL) -> Bool = CodeSignature.isValidAndSameTeam
    /// Default: the user's Trash (`FileManager.trashItem`).
    var trash: (URL) throws -> Void = { try FileManager.default.trashItem(at: $0, resultingItemURL: nil) }

    /// The input method inside this app.
    nonisolated static let standardEmbeddedURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/Input Methods/DauInputMethod.app")
    /// The user's Input Methods folder.
    nonisolated static let standardDirectory = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Input Methods")

    static func standard() -> InputMethodBundleFiles {
        InputMethodBundleFiles(embeddedURL: standardEmbeddedURL, directory: standardDirectory)
    }

    /// Same file name as inside the app (D37: never changes).
    var installedURL: URL { directory.appendingPathComponent(embeddedURL.lastPathComponent) }

    var embedded: InputMethodBundleInfo? { Self.info(at: embeddedURL) }
    var installed: InputMethodBundleInfo? { Self.info(at: installedURL) }
    var isInstalled: Bool {
        (try? installedURL.checkResourceIsReachable()) == true
    }
    var installedIsGenuine: Bool { !isInstalled || verify(installedURL) }

    nonisolated static func info(at url: URL) -> InputMethodBundleInfo? {
        let plist = url.appendingPathComponent("Contents/Info.plist")
        guard let data = try? Data(contentsOf: plist),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let bundleID = dict["CFBundleIdentifier"] as? String, !bundleID.isEmpty else { return nil }
        let modes = (dict["ComponentInputModeDict"] as? [String: Any])?["tsInputModeListKey"] as? [String: Any]
        return InputMethodBundleInfo(bundleID: bundleID,
                                     version: dict["CFBundleVersion"] as? String,
                                     shortVersion: dict["CFBundleShortVersionString"] as? String,
                                     modeIDs: modes.map { $0.keys.sorted() } ?? [])
    }

    func installEmbedded() throws {
        let fm = FileManager.default
        guard (try? embeddedURL.checkResourceIsReachable()) == true else {
            throw InputMethodInstallerError.unavailable
        }
        try fm.createDirectory(at: directory, withIntermediateDirectories: true)
        // Hidden, no ".app": Text Input Sources does not pick up the staging copy.
        let staging = directory.appendingPathComponent(".DauInputMethod-staging-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: staging) }
        try fm.copyItem(at: embeddedURL, to: staging)
        Quarantine.clear(staging)
        guard verify(staging) else { throw InputMethodInstallerError.invalidSignature }
        if fm.fileExists(atPath: installedURL.path) {
            // One atomic swap: the running process never sees half a bundle. The old
            // bundle ends up at `staging` and is removed by the defer above.
            guard renamex_np(staging.path, installedURL.path, UInt32(RENAME_SWAP)) == 0 else {
                throw InputMethodInstallerError.failed("swap errno \(errno)")
            }
        } else {
            guard renamex_np(staging.path, installedURL.path, UInt32(RENAME_EXCL)) == 0 else {
                throw InputMethodInstallerError.failed("rename errno \(errno)")
            }
        }
    }

    func moveInstalledToTrash() throws {
        try trash(installedURL)
    }
}

/// `com.apple.quarantine` on files the app copies (D37: an unsandboxed app may clear it).
enum Quarantine {
    static let attribute = "com.apple.quarantine"

    /// Removes the attribute from `url` and everything inside it.
    static func clear(_ url: URL) {
        removexattr(url.path, attribute, XATTR_NOFOLLOW)
        guard let items = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) else { return }
        for case let item as URL in items {
            removexattr(item.path, attribute, XATTR_NOFOLLOW)
        }
    }

    static func isSet(_ url: URL) -> Bool {
        getxattr(url.path, attribute, nil, 0, 0, XATTR_NOFOLLOW) >= 0
    }
}

/// Code signature checks of the input method before it is installed.
enum CodeSignature {
    /// Valid signature (all architectures, nested code) by the same team as this app.
    static func isValidAndSameTeam(_ url: URL) -> Bool {
        var code: SecStaticCode?
        guard SecStaticCodeCreateWithPath(url as CFURL, [], &code) == errSecSuccess, let code else { return false }
        let flags = SecCSFlags(rawValue: SecCSFlags.RawValue(kSecCSCheckAllArchitectures | kSecCSCheckNestedCode | kSecCSStrictValidate))
        guard SecStaticCodeCheckValidity(code, flags, nil) == errSecSuccess else {
            installLogger.error("event=signature-invalid")
            return false
        }
        let theirs = teamID(of: code)
        let ours = hostTeamID()
        if theirs != ours {
            installLogger.error("event=signature-team-mismatch theirs=\(theirs ?? "-", privacy: .public) ours=\(ours ?? "-", privacy: .public)")
        }
        return theirs == ours
    }

    private static func teamID(of code: SecStaticCode) -> String? {
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(code, SecCSFlags(rawValue: SecCSFlags.RawValue(kSecCSSigningInformation)), &info) == errSecSuccess,
              let dict = info as? [String: Any] else { return nil }
        return dict[kSecCodeInfoTeamIdentifier as String] as? String
    }

    private static func hostTeamID() -> String? {
        var me: SecCode?
        var staticMe: SecStaticCode?
        guard SecCodeCopySelf([], &me) == errSecSuccess, let me,
              SecCodeCopyStaticCode(me, [], &staticMe) == errSecSuccess, let staticMe else { return nil }
        return teamID(of: staticMe)
    }
}

/// The App Group data (settings and app rules, `SettingsStore`).
enum SharedData {
    /// Deletes the App Group suite and tells listeners. True on success.
    @MainActor
    static func delete() -> Bool {
        guard let suite = SettingsStore.appGroupIdentifier(),
              let store = SettingsStore.appGroup() else { return false }
        store.defaults.removePersistentDomain(forName: suite)
        store.postChange()
        return store.defaults.data(forKey: SettingsStore.settingsKey) == nil
    }
}

// MARK: - Text Input Sources

@MainActor
final class SystemTextInputSources: TextInputSources {
    func register(_ url: URL) -> OSStatus {
        TISRegisterInputSource(url as CFURL)
    }

    func sources(bundleID: String, includeDisabled: Bool) -> [InputSourceEntry] {
        list([kTISPropertyBundleID as String: bundleID], includeDisabled: includeDisabled).map(Self.entry)
    }

    func enable(_ id: String) -> OSStatus {
        guard let source = source(id) else { return OSStatus(paramErr) }
        return TISEnableInputSource(source)
    }

    func current() -> InputSourceEntry? {
        TISCopyCurrentKeyboardInputSource().map { Self.entry($0.takeRetainedValue()) }
    }

    func storedEnabledIDs(bundleID: String) -> Set<String> {
        Self.readStoredEnabledIDs(bundleID: bundleID)
    }

    /// Also used by the banner (`InputSourceStatus.query`), so every "is Dấu on" answer
    /// comes from the same place.
    nonisolated static func readStoredEnabledIDs(bundleID: String) -> Set<String> {
        let domain = "com.apple.inputsources" as CFString
        CFPreferencesAppSynchronize(domain)
        guard let entries = CFPreferencesCopyAppValue("AppleEnabledThirdPartyInputSources" as CFString, domain)
                as? [[String: Any]] else { return [] }
        return Set(entries.filter { $0["Bundle ID"] as? String == bundleID }
                          .map { $0["Input Mode"] as? String ?? bundleID })
    }

    private func list(_ filter: [String: Any], includeDisabled: Bool) -> [TISInputSource] {
        TISCreateInputSourceList(filter as CFDictionary, includeDisabled)?.takeRetainedValue() as? [TISInputSource] ?? []
    }

    private func source(_ id: String) -> TISInputSource? {
        list([kTISPropertyInputSourceID as String: id], includeDisabled: true).first
    }

    private static func entry(_ source: TISInputSource) -> InputSourceEntry {
        func string(_ key: CFString) -> String? {
            TISGetInputSourceProperty(source, key).map { Unmanaged<CFString>.fromOpaque($0).takeUnretainedValue() as String }
        }
        let id = string(kTISPropertyInputSourceID) ?? ""
        // A keyboard layout is named as the menu bar names it (`LayoutNames`); TIS's name
        // follows this process's language (Vietnamese), not the system's.
        let name = LayoutNames.system().displayName(sourceID: id, fallback: string(kTISPropertyLocalizedName) ?? "")
        return InputSourceEntry(id: id,
                                bundleID: string(kTISPropertyBundleID),
                                isMode: string(kTISPropertyInputSourceType) == (kTISTypeKeyboardInputMode as String),
                                name: name)
    }
}

// MARK: - Processes

@MainActor
final class SystemInputMethodProcesses: InputMethodProcesses {
    func isRunning(bundleID: String) -> Bool {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).contains { !$0.isTerminated }
    }

    func requestQuit(bundleID: String) {
        InputMethodLifecycle.requestQuit(inputMethodBundleID: bundleID)
    }

    func forceQuit(bundleID: String) {
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: bundleID) {
            app.forceTerminate()
        }
    }
}

// MARK: - System Settings

@MainActor
final class SystemSettingsProcess: SystemSettingsControl {
    static let bundleID = "com.apple.systempreferences"

    var isRunning: Bool {
        NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleID).contains { !$0.isTerminated }
    }

    func terminate() {
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleID) {
            app.terminate()
        }
    }

    func clearKeyboardCache() -> (removed: Int, failed: Int) {
        guard let folder = Self.cacheFolder() else {
            installLogger.error("event=cache-folder-unknown")
            return (0, 0)
        }
        let fm = FileManager.default
        let names = (try? fm.contentsOfDirectory(atPath: folder.path)) ?? []
        var removed = 0, failed = 0
        for name in names where name.hasPrefix("com.apple.IntlDataCache.le") {
            do {
                try fm.removeItem(at: folder.appendingPathComponent(name))
                removed += 1
            } catch {
                failed += 1
                installLogger.error("event=cache-remove-failed name=\(name, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            }
        }
        return (removed, failed)
    }

    /// `$(getconf DARWIN_USER_CACHE_DIR)/com.apple.Keyboard-Settings.extension`.
    nonisolated static func cacheFolder() -> URL? {
        UserInputSourceCaches.userCacheFolder()?
            .appendingPathComponent("com.apple.Keyboard-Settings.extension", isDirectory: true)
    }
}

// MARK: - Input source caches

/// The real caches. `root` is a parameter so tests run on a temp folder.
struct UserInputSourceCaches: InputSourceCaches {
    static let prefix = "com.apple.IntlDataCache.le"
    static let index = prefix + ".kbdx"

    /// The user cache folder (`$(getconf DARWIN_USER_CACHE_DIR)`); nil when unknown.
    let root: URL?

    static func standard() -> UserInputSourceCaches {
        UserInputSourceCaches(root: userCacheFolder())
    }

    nonisolated static func userCacheFolder() -> URL? {
        var buffer = [CChar](repeating: 0, count: Int(PATH_MAX) + 1)
        guard confstr(_CS_DARWIN_USER_CACHE_DIR, &buffer, buffer.count) > 0 else { return nil }
        let path = String(decoding: buffer.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
        return URL(fileURLWithPath: path, isDirectory: true)
    }

    func clearAll() -> InputSourceCacheCounts {
        var counts = InputSourceCacheCounts()
        for folder in subfolders() {
            removeCacheFiles(in: folder, into: &counts)
        }
        return counts
    }

    func removeCaches(notMentioning marker: String) -> InputSourceCacheCounts {
        var counts = InputSourceCacheCounts()
        let needle = Data(marker.utf8)
        let fm = FileManager.default
        for folder in subfolders() {
            let index = folder.appendingPathComponent(Self.index)
            // Missing, or out of reach (some folders are protected): nothing to check.
            guard fm.isReadableFile(atPath: index.path) else { continue }
            let data: Data
            do {
                data = try Data(contentsOf: index, options: .mappedIfSafe)
            } catch {
                counts.failed += 1
                installLogger.error("event=cache-read-failed folder=\(folder.lastPathComponent, privacy: .public) code=\((error as NSError).code)")
                continue
            }
            counts.checked += 1
            guard data.range(of: needle) == nil else { continue }
            counts.stale += 1
            removeCacheFiles(in: folder, into: &counts)
        }
        return counts
    }

    /// Immediate subfolders of `root`, symbolic links excluded. Files in `root` itself
    /// (the shared cache) are never returned.
    private func subfolders() -> [URL] {
        guard let root else {
            installLogger.error("event=cache-folder-unknown")
            return []
        }
        do {
            return try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                .filter {
                    let values = try? $0.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                    return values?.isDirectory == true && values?.isSymbolicLink != true
                }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            installLogger.error("event=cache-root-unlisted code=\((error as NSError).code)")
            return []
        }
    }

    /// Deletes `com.apple.IntlDataCache.le*` in `folder`; a folder that cannot be listed
    /// or a file that cannot be removed is skipped and counted as failed. Logs folder and
    /// file names only.
    private func removeCacheFiles(in folder: URL, into counts: inout InputSourceCacheCounts) {
        let fm = FileManager.default
        let names: [String]
        do {
            names = try fm.contentsOfDirectory(atPath: folder.path)
        } catch {
            counts.failed += 1
            installLogger.error("event=cache-folder-unlisted folder=\(folder.lastPathComponent, privacy: .public) code=\((error as NSError).code)")
            return
        }
        for name in names where name.hasPrefix(Self.prefix) {
            do {
                try fm.removeItem(at: folder.appendingPathComponent(name))
                counts.removed += 1
            } catch {
                counts.failed += 1
                installLogger.error("event=cache-remove-failed folder=\(folder.lastPathComponent, privacy: .public) name=\(name, privacy: .public) code=\((error as NSError).code)")
            }
        }
    }
}
