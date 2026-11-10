import Testing
@testable import SnapshotSettings

/// Keyboard layout names as the menu bar shows them (`LayoutNames`): the system's language
/// picks the entry of the layout bundle's table, TIS's own name is the fallback.
@Suite("Layout names")
struct LayoutNamesTests {
    // The shape of AppleKeyboardLayouts.bundle's InfoPlist.loctable (values read on macOS 27.2).
    let table: [String: [String: String]] = [
        "en": ["US": "U.S.", "ABC": "ABC"],
        "vi": ["US": "Mỹ", "ABC": "ABC"],
        "pt_BR": ["US": "EUA"],
    ]
    let us = "com.apple.keylayout.US"

    @Test("system language English → the English entry, whatever language the app shows")
    func english() {
        let names = LayoutNames(table: table, languages: ["en-VN", "vi-VN"])
        #expect(names.displayName(sourceID: us, fallback: "Mỹ") == "U.S.")
    }

    @Test("system language Vietnamese → the Vietnamese entry")
    func vietnamese() {
        let names = LayoutNames(table: table, languages: ["vi-VN", "en-VN"])
        #expect(names.displayName(sourceID: us, fallback: "U.S.") == "Mỹ")
    }

    @Test("region subtags fall back to the language, then to the next preferred language")
    func subtags() {
        #expect(LayoutNames(table: table, languages: ["pt-BR"]).displayName(sourceID: us, fallback: "x") == "EUA")
        #expect(LayoutNames(table: table, languages: ["pt-PT", "en"]).displayName(sourceID: us, fallback: "x") == "U.S.")
        // A layout the first language lacks is looked up in the next one.
        #expect(LayoutNames(table: table, languages: ["pt-BR", "en"]).displayName(sourceID: "com.apple.keylayout.ABC", fallback: "x") == "ABC")
        #expect(LayoutNames.candidates(for: "zh-Hans-CN") == ["zh_Hans_CN", "zh_Hans", "zh"])
    }

    @Test("unknown language, unknown layout or a source that is not a layout → TIS's name")
    func fallback() {
        #expect(LayoutNames(table: table, languages: ["xx"]).displayName(sourceID: us, fallback: "TIS") == "TIS")
        #expect(LayoutNames(table: table, languages: ["en"]).displayName(sourceID: "com.apple.keylayout.Nope", fallback: "TIS") == "TIS")
        #expect(LayoutNames(table: table, languages: ["en"]).displayName(sourceID: "com.codefastlabs.dau.inputmethod.Dau.vi", fallback: "Dấu – Tiếng Việt") == "Dấu – Tiếng Việt")
        #expect(LayoutNames(table: [:], languages: ["en"]).displayName(sourceID: us, fallback: "TIS") == "TIS")
        #expect(LayoutNames(table: table, languages: []).displayName(sourceID: us, fallback: "TIS") == "TIS")
    }

    @Test("the real table reads on this Mac (skipped where the layout bundle is missing)")
    func realTable() {
        let real = LayoutNames.loadTable()
        guard !real.isEmpty else { return }
        #expect(real["en"]?["US"] == "U.S.")
    }
}
