import Foundation

/// A name of macOS's own interface that Dấu's text mentions (D38).
enum SystemUIName: String, CaseIterable, Sendable {
    case systemSettings, general, loginItemsAndExtensions, keyboard, inputSources
    case edit, add, done, allow, dontAllow, logOut, applications, trash, vietnamese
    case automaticallySwitchOption
    /// The Language & Region pane, and its "Applications" section, where macOS sets a
    /// language per app (D41). Not `.applications`: that is Finder's folder name, from
    /// another table, and the two may differ in a language.
    case languageAndRegion, languageRegionApplications
    /// The "Allow … to enable …?" dialog macOS shows: title (two `%@`: the input method's name twice) and body.
    case allowDialogTitle, allowDialogBody
    /// Dấu's own input source as macOS lists it: "Dấu – Vietnamese" on an English Mac,
    /// "Dấu – Tiếng Việt" on a Vietnamese one (D41). macOS picks the input method's
    /// localization by the system's languages, so Dấu's text must too, not by the app's.
    case dauInputSource

    /// The name in English: what the macOS strings are keyed by, and the fallback.
    var english: String {
        switch self {
        case .systemSettings: "System Settings"
        case .general: "General"
        case .loginItemsAndExtensions: "Login Items & Extensions"
        case .keyboard: "Keyboard"
        case .inputSources: "Input Sources"
        case .edit: "Edit…"
        case .add: "Add"
        case .done: "Done"
        case .allow: "Allow"
        case .dontAllow: "Don’t Allow"
        case .logOut: "Log Out"
        case .applications: "Applications"
        case .trash: "Trash"
        case .vietnamese: "Vietnamese"
        case .automaticallySwitchOption: "Automatically switch to a document’s input source"
        case .languageAndRegion: "Language & Region"
        case .languageRegionApplications: "Applications"
        case .allowDialogTitle: "Allow “%1$@” to enable “%2$@”?"
        case .allowDialogBody: "The developer of the input source will be able to access anything you type with this input source. This could include sensitive information such as your credit card number or home address."
        // The "en" value of the mode name in Apps/DauInputMethod/Resources/InfoPlist.xcstrings.
        case .dauInputSource: "Dấu – Vietnamese"
        }
    }
}

/// Where a name is in the system's own strings (read only).
enum SystemUITable: String, CaseIterable, Sendable {
    case systemSettings, systemSettingsInfo, keyboardSettings, generalSettings, loginWindow, folderNames, finderNames
    /// Language & Region's `Localizable.loctable` and `InfoPlist.loctable`.
    case localizationSettings, localizationSettingsInfo
    /// The input method's `InfoPlist.strings`, per language (key: the input mode ID).
    case dauInputMethod
}

/// Names of macOS's interface as the user's macOS shows them (D38), for every sentence
/// that points the user at a place in System Settings: "System Settings › Keyboard ›
/// Input Sources" on an English Mac, "Cài đặt hệ thống › Bàn phím › Nguồn đầu vào" on a
/// Vietnamese one. The words come from the system's own tables, not from Dấu's
/// translation, and follow the system's preferred languages, not this process's (which
/// can differ, D41): same idea as `LayoutNames`. A name with no entry in any
/// preferred language is shown in English.
///
/// The tables are `language → key → value` (the shape of a `.loctable`), found by the
/// key whose English value is the name's English text (`SystemUIName.english`), or by a
/// fixed key where the English text lives in the Info.plist (the app's display name).
struct SystemUINames: Sendable {
    typealias Table = [String: [String: String]]

    let languages: [String]
    let tables: [SystemUITable: Table]
    /// The name of a language in another one ("Vietnamese" in English, "Tiếng Việt" in
    /// Vietnamese), for the Input Sources group; nil when unknown.
    let languageName: @Sendable (_ code: String, _ in: String) -> String?

    /// Table and lookup rule of each name. `nil` key: match the English text.
    static func location(of name: SystemUIName) -> (table: SystemUITable, fixedKey: String?)? {
        switch name {
        case .systemSettings: (.systemSettingsInfo, "CFBundleDisplayName")
        case .general, .keyboard: (.systemSettings, nil)
        case .loginItemsAndExtensions: (.generalSettings, nil)
        case .inputSources, .edit, .add, .done, .allow, .dontAllow, .automaticallySwitchOption, .allowDialogTitle, .allowDialogBody: (.keyboardSettings, nil)
        case .logOut: (.loginWindow, nil)
        case .applications: (.folderNames, nil)
        case .trash: (.finderNames, nil)
        case .languageAndRegion: (.localizationSettingsInfo, "CFBundleDisplayName")
        // A fixed key: other keys of that table have the English value "Applications" too
        // ("Application" is a different key with the same Vietnamese "Ứng dụng").
        case .languageRegionApplications: (.localizationSettings, "Applications")
        // Keyed by the input mode ID (D24, never changes: D37), not by the English value:
        // an older installed input method may name itself differently, and macOS shows that.
        case .dauInputSource: (.dauInputMethod, "com.codefastlabs.dau.inputmethod.Dau.vi")
        case .vietnamese: nil
        }
    }

    func name(_ name: SystemUIName) -> String {
        if name == .vietnamese {
            for language in languages {
                if let primary = Self.candidates(language).last,
                   let value = languageName("vi", primary), !value.isEmpty { return value }
            }
            return name.english
        }
        guard let (tableID, fixedKey) = Self.location(of: name), let table = tables[tableID] else { return name.english }
        let key = fixedKey ?? Self.key(forEnglish: name.english, in: table)
        guard let key else { return name.english }
        for language in languages {
            for candidate in Self.candidates(language) {
                if let value = table[candidate]?[key], !value.isEmpty { return value }
            }
            // English is the base text of the system's strings (no column of its own in some
            // tables): a first language of English means the English name, not a later language's.
            if Self.candidates(language).last == "en" { return name.english }
        }
        return name.english
    }

    /// "System Settings › Keyboard › Input Sources" as the user's macOS names them.
    func path(_ names: SystemUIName...) -> String {
        names.map { name($0) }.joined(separator: " › ")
    }

    // Names used in sentences, by purpose.
    var systemSettings: String { name(.systemSettings) }
    var inputSources: String { name(.inputSources) }
    var applications: String { name(.applications) }
    var trash: String { name(.trash) }
    var allow: String { name(.allow) }
    var dontAllow: String { name(.dontAllow) }
    var edit: String { name(.edit) }
    var add: String { name(.add) }
    var done: String { name(.done) }
    var logOut: String { name(.logOut) }
    var vietnamese: String { name(.vietnamese) }
    var automaticallySwitchOption: String { name(.automaticallySwitchOption) }
    /// "Language & Region" / "Ngôn ngữ & Vùng".
    var languageAndRegion: String { name(.languageAndRegion) }
    /// The "Applications" section of Language & Region: "Applications" / "Ứng dụng".
    var languageRegionApplications: String { name(.languageRegionApplications) }
    /// "Dấu – Vietnamese" / "Dấu – Tiếng Việt", as macOS's Input menu and list show it.
    var dauInputSource: String { name(.dauInputSource) }
    /// "Allow “Dấu” to enable “Dấu”?" in the user's language.
    func allowDialogTitle(app: String) -> String {
        String(format: name(.allowDialogTitle), app, app)
    }
    var allowDialogBody: String { name(.allowDialogBody) }
    /// "System Settings › Keyboard".
    var keyboardPath: String { path(.systemSettings, .keyboard) }
    /// "System Settings › Keyboard › Input Sources".
    var inputSourcesPath: String { path(.systemSettings, .keyboard, .inputSources) }
    /// "System Settings › General › Login Items & Extensions".
    var loginItemsPath: String { path(.systemSettings, .general, .loginItemsAndExtensions) }

    /// "zh-Hans-CN" → zh_Hans_CN, zh_Hans, zh (`LayoutNames.candidates`).
    static func candidates(_ language: String) -> [String] { LayoutNames.candidates(for: language) }

    /// The key whose English value is `english`; tables without an English column
    /// (English is the key) are matched by the key itself.
    static func key(forEnglish english: String, in table: Table) -> String? {
        if let en = table["en"] {
            return en.first { $0.value == english }?.key
        }
        return table.values.contains { $0[english] != nil } ? english : nil
    }

    // MARK: The real system

    private static let extensions = "/System/Library/ExtensionKit/Extensions/"

    static func tableURLs() -> [SystemUITable: URL] {
        [.systemSettings: URL(fileURLWithPath: "/System/Applications/System Settings.app/Contents/Resources/Localizable.loctable"),
         .systemSettingsInfo: URL(fileURLWithPath: "/System/Applications/System Settings.app/Contents/Resources/InfoPlist.loctable"),
         .keyboardSettings: URL(fileURLWithPath: extensions + "KeyboardSettings.appex/Contents/Resources/Localizable.loctable"),
         .generalSettings: URL(fileURLWithPath: extensions + "GeneralSettings.appex/Contents/Resources/Localizable.loctable"),
         .loginWindow: URL(fileURLWithPath: "/System/Library/CoreServices/loginwindow.app/Contents/Resources/loginwindow.loctable"),
         .localizationSettings: URL(fileURLWithPath: extensions + "Localization.appex/Contents/Resources/Localizable.loctable"),
         .localizationSettingsInfo: URL(fileURLWithPath: extensions + "Localization.appex/Contents/Resources/InfoPlist.loctable")]
    }

    static let folderNamesDirectory = URL(fileURLWithPath: "/System/Library/CoreServices/SystemFolderLocalizations")

    /// Finder's own strings: one `Localizable.strings` per language, where "Trash" is keyed by its English name.
    static let finderResources = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app/Contents/Resources")

    /// Reads every table; one that cannot be read is left out (its names come out in English).
    static func loadTables() -> [SystemUITable: Table] {
        var result: [SystemUITable: Table] = [:]
        for (id, url) in tableURLs() {
            result[id] = LayoutNames.loadTable(from: url)
        }
        // SystemFolderLocalizations: one `.strings` per language, keyed by the English name.
        var folders: Table = [:]
        let fm = FileManager.default
        for entry in (try? fm.contentsOfDirectory(atPath: folderNamesDirectory.path)) ?? [] where entry.hasSuffix(".lproj") {
            let language = String(entry.dropLast(".lproj".count))
            let file = folderNamesDirectory.appendingPathComponent(entry).appendingPathComponent("SystemFolderLocalizations.strings")
            if let data = try? Data(contentsOf: file),
               let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
                folders[language] = plist
            }
        }
        result[.folderNames] = folders
        // Finder: only the "Trash" entry of each language is kept.
        var finder: Table = [:]
        for entry in (try? fm.contentsOfDirectory(atPath: finderResources.path)) ?? [] where entry.hasSuffix(".lproj") {
            let language = String(entry.dropLast(".lproj".count))
            let file = finderResources.appendingPathComponent(entry).appendingPathComponent("Localizable.strings")
            if let data = try? Data(contentsOf: file),
               let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String],
               let trash = plist["Trash"] {
                finder[language] = ["Trash": trash]
            }
        }
        result[.finderNames] = finder
        // Dấu's input method: the installed copy is the one macOS lists; before install,
        // the copy inside the app (same names).
        let embedded = InputMethodBundleFiles.standardEmbeddedURL
        let installed = InputMethodBundleFiles.standardDirectory.appendingPathComponent(embedded.lastPathComponent)
        let inputMethod = (try? installed.checkResourceIsReachable()) == true ? installed : embedded
        result[.dauInputMethod] = stringsTables(in: inputMethod.appendingPathComponent("Contents/Resources"), file: "InfoPlist.strings")
        return result
    }

    /// `<language>.lproj/<file>` of a bundle's resources, as `language → key → value`.
    static func stringsTables(in resources: URL, file: String) -> Table {
        var table: Table = [:]
        for entry in (try? FileManager.default.contentsOfDirectory(atPath: resources.path)) ?? [] where entry.hasSuffix(".lproj") {
            let url = resources.appendingPathComponent(entry).appendingPathComponent(file)
            if let data = try? Data(contentsOf: url),
               let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] {
                table[String(entry.dropLast(".lproj".count))] = plist
            }
        }
        return table
    }

    private static let loadedTables = loadTables()

    /// On the real system; `languages` defaults to the system's own list.
    static func system(languages: [String] = LayoutNames.systemLanguages()) -> SystemUINames {
        SystemUINames(languages: languages, tables: loadedTables) { code, language in
            Locale(identifier: language).localizedString(forLanguageCode: code)
        }
    }
}
