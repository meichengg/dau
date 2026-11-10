import Foundation
import Testing
@testable import SnapshotSettings

/// macOS's interface names as the user's macOS shows them (D38, `SystemUINames`), on fake
/// tables with the shapes of the real ones.
@Suite("System UI names")
struct SystemUINamesTests {
    // Localizable.loctable of KeyboardSettings: key → English in "en", other languages by key.
    let keyboard: SystemUINames.Table = [
        "en": ["Input Sources": "Input Sources", "Edit…": "Edit…", "Allow": "Allow"],
        "vi": ["Input Sources": "Nguồn đầu vào", "Edit…": "Sửa…", "Allow": "Cho phép"],
    ]
    // Localizable.loctable of System Settings.
    let settings: SystemUINames.Table = [
        "en": ["Keyboard": "Keyboard", "General": "General"],
        "vi": ["Keyboard": "Bàn phím", "General": "Cài đặt chung"],
    ]
    // InfoPlist.loctable of System Settings: no English column, a fixed key.
    let info: SystemUINames.Table = ["vi": ["CFBundleDisplayName": "Cài đặt hệ thống"]]
    // SystemFolderLocalizations: per language, keyed by the English name.
    let folders: SystemUINames.Table = ["vi": ["Applications": "Ứng dụng"], "en": ["Applications": "Applications"]]

    // Finder's Localizable.strings per language: "Trash" keyed by its English name.
    let finder: SystemUINames.Table = ["vi": ["Trash": "Thùng rác"], "en": ["Trash": "Trash"]]

    func names(_ languages: [String]) -> SystemUINames {
        SystemUINames(languages: languages,
                      tables: [.keyboardSettings: keyboard, .systemSettings: settings,
                               .systemSettingsInfo: info, .folderNames: folders, .finderNames: finder]) { code, language in
            language == "vi" ? "Tiếng Việt" : (language == "en" ? "Vietnamese" : nil)
        }
    }

    struct LanguageCase: Sendable, CustomTestStringConvertible {
        var languages: [String]
        var inputSourcesPath, edit, allow, applications, vietnamese, trash: String
        var testDescription: String { languages.joined(separator: ",") }
    }

    @Test("system language decides the names, whatever the app speaks: English → English names; Vietnamese → the system's own Vietnamese words, found by the English value (D38)",
          arguments: [
              LanguageCase(languages: ["en-VN", "vi-VN"], inputSourcesPath: "System Settings › Keyboard › Input Sources",
                           edit: "Edit…", allow: "Allow", applications: "Applications", vietnamese: "Vietnamese", trash: "Trash"),
              LanguageCase(languages: ["vi-VN", "en-VN"], inputSourcesPath: "Cài đặt hệ thống › Bàn phím › Nguồn đầu vào",
                           edit: "Sửa…", allow: "Cho phép", applications: "Ứng dụng", vietnamese: "Tiếng Việt", trash: "Thùng rác"),
          ])
    func languageDecidesNames(_ c: LanguageCase) {
        let n = names(c.languages)
        #expect(n.inputSourcesPath == c.inputSourcesPath)
        #expect(n.edit == c.edit)
        #expect(n.allow == c.allow)
        #expect(n.applications == c.applications)
        #expect(n.vietnamese == c.vietnamese)
        #expect(n.trash == c.trash)
    }

    @Test("the Trash is English when no table has it (D38)")
    func trashFallback() {
        #expect(names(["xx"]).trash == "Trash")
        let none = SystemUINames(languages: ["vi"], tables: [:]) { _, _ in nil }
        #expect(none.trash == "Trash")
    }

    @Test("unknown language, a name a table lacks, or no table → English")
    func fallback() {
        let unknown = names(["xx"])
        #expect(unknown.inputSourcesPath == "System Settings › Keyboard › Input Sources")
        // "Done" is in no fake table: English even in Vietnamese.
        #expect(names(["vi"]).done == "Done")
        let none = SystemUINames(languages: ["vi"], tables: [:]) { _, _ in nil }
        #expect(none.inputSourcesPath == "System Settings › Keyboard › Input Sources")
        #expect(none.vietnamese == "Vietnamese")
        #expect(names([]).keyboardPath == "System Settings › Keyboard")
    }

    @Test("a language falls back to the next preferred one for a name it lacks")
    func nextLanguage() {
        // pt has Input Sources only; the next language (vi) supplies Edit….
        var table = keyboard
        table["pt"] = ["Input Sources": "Fontes de Entrada"]
        let n = SystemUINames(languages: ["pt-BR", "vi"], tables: [.keyboardSettings: table]) { _, _ in nil }
        #expect(n.inputSources == "Fontes de Entrada")
        #expect(n.edit == "Sửa…")
    }

    @Test("the real tables read on this Mac; every name resolves (English at worst)")
    func real() {
        let tables = SystemUINames.loadTables()
        guard tables[.keyboardSettings]?.isEmpty == false else { return }
        let en = SystemUINames.system(languages: ["en"])
        #expect(en.inputSourcesPath == "System Settings › Keyboard › Input Sources")
        #expect(en.name(.applications) == "Applications")
        let vi = SystemUINames.system(languages: ["vi"])
        #expect(vi.inputSources == "Nguồn đầu vào")
        #expect(vi.systemSettings == "Cài đặt hệ thống")
        if tables[.finderNames]?["vi"] != nil { #expect(vi.trash == "Thùng rác") }
        #expect(en.trash == "Trash")
        if tables[.localizationSettingsInfo]?["vi"] != nil {
            #expect(vi.languageAndRegion == "Ngôn ngữ & Vùng")
            #expect(en.languageAndRegion == "Language & Region")
        }
        if tables[.localizationSettings]?["vi"] != nil {
            #expect(vi.languageRegionApplications == "Ứng dụng")
            #expect(en.languageRegionApplications == "Applications")
        }
    }

    // Language & Region (Localization.appex): InfoPlist.loctable with an English column
    // and a fixed key; Localizable.loctable, where "Applications" and "Application" both
    // read "Ứng dụng" in Vietnamese.
    let localizationInfo: SystemUINames.Table = [
        "en": ["CFBundleDisplayName": "Language & Region", "CFBundleName": "Localization"],
        "vi": ["CFBundleDisplayName": "Ngôn ngữ & Vùng", "CFBundleName": "Bản địa hóa"],
    ]
    let localization: SystemUINames.Table = [
        "en": ["Application": "Application", "Applications": "Applications"],
        "vi": ["Application": "Ứng dụng (một)", "Applications": "Ứng dụng"],
    ]

    func languageNames(_ languages: [String], folders: SystemUINames.Table? = nil) -> SystemUINames {
        var tables: [SystemUITable: SystemUINames.Table] = [.localizationSettingsInfo: localizationInfo,
                                                           .localizationSettings: localization]
        if let folders { tables[.folderNames] = folders }
        return SystemUINames(languages: languages, tables: tables) { _, _ in nil }
    }

    @Test("Language & Region and its Applications section in the system's language (D38, D41)")
    func languageAndRegion() {
        let en = languageNames(["en-VN", "vi-VN"])
        #expect(en.languageAndRegion == "Language & Region")
        #expect(en.languageRegionApplications == "Applications")
        let vi = languageNames(["vi-VN", "en-VN"])
        #expect(vi.languageAndRegion == "Ngôn ngữ & Vùng")
        #expect(vi.languageRegionApplications == "Ứng dụng")
        // Unreadable tables or an unknown language: English.
        let none = SystemUINames(languages: ["vi"], tables: [:]) { _, _ in nil }
        #expect(none.languageAndRegion == "Language & Region")
        #expect(none.languageRegionApplications == "Applications")
        #expect(languageNames(["xx"]).languageAndRegion == "Language & Region")
    }

    @Test("the Applications section and Finder's Applications folder come from their own tables")
    func applicationsKeptApart() {
        let n = languageNames(["vi"], folders: ["vi": ["Applications": "Thư mục Ứng dụng"]])
        #expect(n.languageRegionApplications == "Ứng dụng")
        #expect(n.applications == "Thư mục Ứng dụng")
    }

    // The input method's InfoPlist.strings per language (compiled from its catalog).
    let inputMethod: SystemUINames.Table = [
        "en": ["CFBundleName": "Dấu", "com.codefastlabs.dau.inputmethod.Dau.vi": "Dấu – Vietnamese"],
        "vi": ["CFBundleName": "Dấu", "com.codefastlabs.dau.inputmethod.Dau.vi": "Dấu – Tiếng Việt"],
    ]

    func inputSourceName(_ languages: [String]) -> String {
        SystemUINames(languages: languages, tables: [.dauInputMethod: inputMethod]) { _, _ in nil }.dauInputSource
    }

    @Test("Dấu's input source name follows the system's languages, as macOS picks it (D41)")
    func dauInputSource() {
        #expect(inputSourceName(["en-VN", "vi-VN"]) == "Dấu – Vietnamese")
        #expect(inputSourceName(["vi-VN", "en-VN"]) == "Dấu – Tiếng Việt")
        // No Dấu localization for Japanese: macOS uses the next language Dấu has…
        #expect(inputSourceName(["ja-JP", "vi-VN"]) == "Dấu – Tiếng Việt")
        // …or the development language, English.
        #expect(inputSourceName(["ja-JP"]) == "Dấu – Vietnamese")
        // Input method not found: the English name.
        let none = SystemUINames(languages: ["vi"], tables: [:]) { _, _ in nil }
        #expect(none.dauInputSource == "Dấu – Vietnamese")
    }

    @Test("the English fallback is the input method catalog's English mode name")
    func dauInputSourceEnglishMatchesCatalog() throws {
        let catalog = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("Apps/DauInputMethod/Resources/InfoPlist.xcstrings")
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: catalog)) as? [String: Any]
        let strings = json?["strings"] as? [String: Any]
        let mode = strings?["com.codefastlabs.dau.inputmethod.Dau.vi"] as? [String: Any]
        let en = ((mode?["localizations"] as? [String: Any])?["en"] as? [String: Any])?["stringUnit"] as? [String: Any]
        #expect(en?["value"] as? String == SystemUIName.dauInputSource.english)
    }
}
