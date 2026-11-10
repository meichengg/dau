import Foundation

/// The app's String Catalog (Localizable.xcstrings, symlinked from Apps/Dau/Resources and
/// compiled by SwiftPM into this target's resource bundle) for the snapshot tool and the
/// tests.
///
/// The app's views look their text up in `Bundle.main` (`Text("…")`,
/// `String(localized:)`). The tool is a bare executable, whose main bundle is the build
/// directory it runs from, so `installForMainBundle` copies the compiled `.lproj` folders
/// there before anything reads a localization. Tests run inside the test runner, whose
/// main bundle is Xcode's: they read a language straight from `bundle(_:)` instead.
enum SnapshotLocalization {
    /// The compiled `<language>.lproj` of the catalog (`en`, `vi`), or nil.
    static func bundle(_ language: String) -> Bundle? {
        Bundle.module.url(forResource: language, withExtension: "lproj").flatMap(Bundle.init(url:))
    }

    /// The catalog's text for `key` in `language`; the key itself when there is none.
    static func text(_ key: String, _ language: String) -> String {
        bundle(language)?.localizedString(forKey: key, value: nil, table: nil) ?? key
    }

    /// Snapshot tool only, first thing at launch: makes the catalog visible to
    /// `Bundle.main` and picks the language, Vietnamese unless `-AppleLanguages` is given
    /// (`SnapshotSettings <out> -AppleLanguages '(en)'`). Only the build directory is
    /// written; no user setting changes (the language goes to this process's argument
    /// domain).
    static func installForMainBundle() {
        let fm = FileManager.default
        guard let resources = Bundle.module.resourceURL else { return }
        let destination = Bundle.main.bundleURL
        for entry in (try? fm.contentsOfDirectory(atPath: resources.path)) ?? [] where entry.hasSuffix(".lproj") {
            let target = destination.appendingPathComponent(entry)
            try? fm.removeItem(at: target)
            do {
                try fm.copyItem(at: resources.appendingPathComponent(entry), to: target)
            } catch {
                FileHandle.standardError.write(Data("cannot copy \(entry): \(error)\n".utf8))
            }
        }
        let defaults = UserDefaults.standard
        var arguments = defaults.volatileDomain(forName: UserDefaults.argumentDomain)
        if arguments["AppleLanguages"] == nil {
            arguments["AppleLanguages"] = ["vi"]
            defaults.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
        }
    }
}
