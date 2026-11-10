import Foundation
import Testing
@testable import SnapshotSettings

/// The Language row of Updates & Support (D41, `AppLanguage`): Dấu reads, never writes,
/// the language macOS chose for it. The domain reader is injected, so no test reads the
/// user's real preferences.
@Suite("Language row")
struct AppLanguageTests {
    @Test("set for Dấu only exactly when the app's own domain has AppleLanguages")
    func domainKey() {
        var asked: [String] = []
        #expect(AppLanguage.isSetForDau { key in asked.append(key); return ["vi-VN", "en", "en-VN"] })
        #expect(asked == ["AppleLanguages"])
        #expect(!AppLanguage.isSetForDau { _ in nil })
        // Another key of the domain does not count.
        #expect(!AppLanguage.isSetForDau { key in key == "AppleLocale" ? "vi_VN" : nil })
    }

    @Test("the domain read is that domain alone: no fall-through to the global domain or launch arguments")
    func noFallThrough() {
        // A domain nobody writes. UserDefaults.standard has AppleLanguages (global domain,
        // and -AppleLanguages for the snapshot tool); the domain read must not see it.
        #expect(AppLanguage.appDomainValue("AppleLanguages", domain: "com.codefastlabs.dau.tests.no-such-domain") == nil)
        #expect(AppLanguage.appDomainValue("AppleLanguages", domain: nil) == nil)
    }

    @Test("the language is named in that language, capitalized as macOS lists it")
    func names() {
        #expect(AppLanguage.name(of: "vi") == "Tiếng Việt")
        #expect(AppLanguage.name(of: "en") == "English")
        #expect(AppLanguage.name(of: "fr") == "Français")
    }

    // Which sentence the row shows (the wording and its translation: scripts/check-l10n).
    struct SubtitleCase: Sendable, CustomTestStringConvertible {
        var status: AppLanguage.Status
        var key: String
        var testDescription: String { key }
    }
    static let notPendingFollows = "Follows macOS. To set a language for Dấu only, click Change…, then under %@ click + and choose Dấu."
    static let notPendingSet = "Set for Dấu only. Click Change… to pick another language, or remove Dấu from the %@ list."
    static let pendingFollows = "Follows macOS. Dấu switches to %@ when it reopens; until then it stays in %@."
    static let pendingSet = "Set for Dấu only. Dấu switches to %@ when it reopens; until then it stays in %@."

    @Test("the subtitle's sentence follows set-for-Dấu and pending (artboards SettingsLanguage, SettingsLanguageEn, SettingsLanguagePending)",
          arguments: [
              SubtitleCase(status: .init(current: "vi", next: "vi", setForDau: false), key: notPendingFollows),
              SubtitleCase(status: .init(current: "en", next: "en", setForDau: true), key: notPendingSet),
              SubtitleCase(status: .init(current: "en", next: "vi", setForDau: false), key: pendingFollows),
              SubtitleCase(status: .init(current: "vi", next: "en", setForDau: true), key: pendingSet),
          ])
    func subtitleKey(_ c: SubtitleCase) {
        #expect(AppLanguage.subtitle(c.status, applications: "x").key == c.key)
        if !c.status.isPending {
            #expect(AppLanguage.subtitle(setForDau: c.status.setForDau, applications: "x").key == c.key)
        }
    }

    // MARK: Waiting for a relaunch (D41, artboard SettingsLanguagePending)

    static let localizations = ["en", "vi", "Base"]

    struct NextCase: Sendable, CustomTestStringConvertible {
        var appDomain: [String]?
        var global: [String]
        var expected: String
        var testDescription: String { "app \(appDomain ?? []) global \(global) → \(expected)" }
    }

    @Test("next launch: the list set for Dấu wins over the macOS list, and the macOS list is used when nothing is set for Dấu; the first language Dấu has",
          arguments: [
              NextCase(appDomain: ["en-VN", "vi"], global: ["vi-VN", "en"], expected: "en"),
              NextCase(appDomain: ["vi-VN", "en", "en-VN"], global: ["en-US"], expected: "vi"),
              NextCase(appDomain: ["fr-FR", "vi-VN"], global: ["en"], expected: "vi"),
              NextCase(appDomain: nil, global: ["vi-VN", "en-VN"], expected: "vi"),
              NextCase(appDomain: nil, global: ["en-VN", "vi-VN"], expected: "en"),
              NextCase(appDomain: nil, global: ["de", "vi"], expected: "vi"),
          ])
    func nextLaunch(_ c: NextCase) {
        #expect(AppLanguage.nextLaunch(available: Self.localizations, appDomain: c.appDomain, global: c.global) == c.expected)
    }

    @Test("next launch: English when no preferred language is one Dấu has, or there is no list")
    func nextFallback() {
        for order in [["en", "vi"], ["vi", "en"], ["Base", "vi", "en"]] {
            #expect(AppLanguage.nextLaunch(available: order, appDomain: nil, global: ["fr", "de"]) == "en")
            #expect(AppLanguage.nextLaunch(available: order, appDomain: ["zh-Hans"], global: ["vi"]) == "en")
            #expect(AppLanguage.nextLaunch(available: order, appDomain: nil, global: nil) == "en")
            #expect(AppLanguage.nextLaunch(available: order, appDomain: nil, global: "not a list") == "en")
        }
    }

    @Test("status: the app key is read first; the macOS list only when it is absent")
    func statusReaders() {
        var globalReads = 0
        let setForDau = AppLanguage.status(current: "vi", available: Self.localizations,
                                           read: { $0 == "AppleLanguages" ? ["en"] : nil },
                                           global: { globalReads += 1; return ["vi"] })
        #expect(setForDau == AppLanguage.Status(current: "vi", next: "en", setForDau: true))
        #expect(globalReads == 0)
        let follows = AppLanguage.status(current: "en", available: Self.localizations,
                                         read: { _ in nil }, global: { globalReads += 1; return ["vi-VN"] })
        #expect(follows == AppLanguage.Status(current: "en", next: "vi", setForDau: false))
        #expect(globalReads == 1)
    }

    @Test("the user's macOS list is read from the global domain itself")
    func globalDomain() {
        // Every user session has a language list; launch arguments do not reach this read.
        #expect(AppLanguage.globalLanguages() is [String])
    }

    @Test("pending exactly when the next launch differs from the language shown; Reopen only then")
    func pending() {
        let waiting = AppLanguage.Status(current: "vi", next: "en", setForDau: true)
        #expect(waiting.isPending)
        #expect(waiting.showsReopen)
        #expect(waiting.shownLanguage == "en")
        let back = AppLanguage.Status(current: "en", next: "vi", setForDau: false)
        #expect(back.isPending && back.showsReopen && back.shownLanguage == "vi")
        for status in [AppLanguage.Status(current: "vi", next: "vi", setForDau: true),
                       AppLanguage.Status(current: "en", next: "en", setForDau: false)] {
            #expect(!status.isPending)
            #expect(!status.showsReopen)
            #expect(status.shownLanguage == status.current)
        }
    }

}

/// "Reopen Dấu" (`AppRelauncher`): the helper waits for the process to end, then runs the
/// opener on the bundle. Tests use `sleep` as the process and `touch` as the opener, so
/// nothing is launched.
@Suite("Reopen helper")
struct AppRelauncherTests {
    func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("dau-reopen-\(UUID().uuidString)")
    }

    @Test("opens the bundle only after the process it waits for has ended")
    func waitsThenOpens() throws {
        let waited = Process()
        waited.executableURL = URL(fileURLWithPath: "/bin/sleep")
        waited.arguments = ["0.6"]
        try waited.run()
        let marker = temporaryFile()
        defer { try? FileManager.default.removeItem(at: marker) }
        let helper = AppRelauncher.helper(waitingFor: waited.processIdentifier, thenOpen: marker, opener: "/usr/bin/touch")
        try helper.run()
        Thread.sleep(forTimeInterval: 0.3)
        #expect(waited.isRunning)
        #expect(!FileManager.default.fileExists(atPath: marker.path))
        waited.waitUntilExit()
        helper.waitUntilExit()
        #expect(helper.terminationStatus == 0)
        #expect(FileManager.default.fileExists(atPath: marker.path))
    }

    @Test("a bundle path with spaces and non-ASCII letters reaches the opener intact")
    func quoting() throws {
        let marker = FileManager.default.temporaryDirectory.appendingPathComponent("Dấu \(UUID().uuidString) 'x'.app")
        defer { try? FileManager.default.removeItem(at: marker) }
        // A process that has already ended: the helper opens at once.
        let ended = Process()
        ended.executableURL = URL(fileURLWithPath: "/usr/bin/true")
        try ended.run()
        ended.waitUntilExit()
        let helper = AppRelauncher.helper(waitingFor: ended.processIdentifier, thenOpen: marker, opener: "/usr/bin/touch")
        try helper.run()
        helper.waitUntilExit()
        #expect(FileManager.default.fileExists(atPath: marker.path))
    }

    @Test("the real opener is /usr/bin/open on this app's own process and bundle")
    func realArguments() {
        let helper = AppRelauncher.helper(waitingFor: 4242, thenOpen: URL(fileURLWithPath: "/Applications/Dấu.app"))
        #expect(helper.executableURL?.path == "/bin/sh")
        #expect(Array(helper.arguments?.suffix(3) ?? []) == ["4242", "/Applications/Dấu.app", "/usr/bin/open"])
    }
}
