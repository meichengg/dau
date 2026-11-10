import Foundation

/// Names of keyboard layouts as the macOS menu bar shows them ("U.S." on an English
/// system), for every place Dấu names a layout to the user (the shortcut lines, the
/// uninstall messages). `kTISPropertyLocalizedName` cannot be used: it follows the
/// language of this process, which can differ from the system's (a language chosen for
/// Dấu alone, or a `-AppleLanguages` argument, D41) and then gives "Mỹ" for the U.S.
/// layout on an English system (D38).
///
/// The names live in the layout bundle's `InfoPlist.loctable` (language → name key →
/// name), keyed by the layout's ID without "com.apple.keylayout." ("US"). The language is
/// the system's own preferred language list (`AppleLanguages` of the global domain), not
/// the process's. No match in any preferred language: the name TIS gave. Read only (N4).
struct LayoutNames: Sendable {
    /// language ("en", "vi", "pt_BR") → name key ("US") → localized name.
    let table: [String: [String: String]]
    /// The user's preferred languages, most preferred first ("en-VN", "vi-VN").
    let languages: [String]

    static let sourceIDPrefix = "com.apple.keylayout."

    /// The name to show for the layout `sourceID`; `fallback` (TIS's name) when the table
    /// has none for the user's languages.
    func displayName(sourceID: String, fallback: String) -> String {
        guard sourceID.hasPrefix(Self.sourceIDPrefix) else { return fallback }
        let key = String(sourceID.dropFirst(Self.sourceIDPrefix.count))
        for language in languages {
            for candidate in Self.candidates(for: language) {
                if let name = table[candidate]?[key], !name.isEmpty { return name }
            }
        }
        return fallback
    }

    /// Table languages to try for a preferred language, most specific first:
    /// "zh-Hans-CN" → zh_Hans_CN, zh_Hans, zh; "en-VN" → en_VN, en.
    static func candidates(for language: String) -> [String] {
        var parts = language.replacingOccurrences(of: "-", with: "_").split(separator: "_").map(String.init)
        var result: [String] = []
        while !parts.isEmpty {
            result.append(parts.joined(separator: "_"))
            parts.removeLast()
        }
        return result
    }

    // MARK: The real system

    static let layoutBundleTable = URL(fileURLWithPath:
        "/System/Library/Keyboard Layouts/AppleKeyboardLayouts.bundle/Contents/Resources/InfoPlist.loctable")

    /// The system's language list: the global domain, not this process's (whose argument
    /// or app domain can hold a language of its own, D41).
    static func systemLanguages() -> [String] {
        CFPreferencesCopyValue("AppleLanguages" as CFString, kCFPreferencesAnyApplication,
                               kCFPreferencesCurrentUser, kCFPreferencesAnyHost) as? [String] ?? []
    }

    /// Reads the layout bundle's table; empty when it cannot be read (then every name is TIS's).
    static func loadTable(from url: URL = layoutBundleTable) -> [String: [String: String]] {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return [:] }
        var table: [String: [String: String]] = [:]
        for (language, value) in plist {
            // Some tables hold other kinds of values beside the strings (plural variants): keep the strings.
            if let entries = value as? [String: Any] { table[language] = entries.compactMapValues { $0 as? String } }
        }
        return table
    }

    /// Read once: the table does not change while the app runs.
    private static let loadedTable = loadTable()

    /// On the real system. The language list is read at each call (the user may change it).
    static func system() -> LayoutNames {
        LayoutNames(table: loadedTable, languages: systemLanguages())
    }
}
