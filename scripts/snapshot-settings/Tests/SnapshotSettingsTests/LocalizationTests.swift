import Foundation
import Testing
@testable import SnapshotSettings

/// The app's String Catalog as SwiftPM compiles it (D41): English keys, English and
/// Vietnamese text. Completeness and placeholders of every entry: scripts/check-l10n.
@Suite("String Catalog")
struct LocalizationTests {
    @Test("both languages are compiled; English is the key, Vietnamese the translation")
    func languages() {
        #expect(SnapshotLocalization.bundle("en") != nil)
        #expect(SnapshotLocalization.bundle("vi") != nil)
        // The key is the English text; the Vietnamese entry is a different text (wording: scripts/check-l10n).
        #expect(SnapshotLocalization.text("Dấu Settings", "en") == "Dấu Settings")
        #expect(SnapshotLocalization.text("Dấu Settings", "vi") != "Dấu Settings")
    }

    @Test("section titles and search words have a Vietnamese text of their own")
    func sectionWords() {
        for section in SettingsSection.allCases {
            for resource in [section.titleResource] + section.keywordResources
            where !["Telex", "VNI", "Beta"].contains(resource.key) {
                #expect(SnapshotLocalization.text(resource.key, "vi") != resource.key, "\(resource.key)")
            }
        }
    }
}
