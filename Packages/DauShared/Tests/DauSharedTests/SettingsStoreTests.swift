import Foundation
import Testing
@testable import DauShared

/// Each test uses its own suite so tests never touch real settings. The suite name is an
/// absolute path in the temporary directory, so its plist lives there (a plain name would
/// leave an empty plist in ~/Library/Preferences that removing the domain does not delete).
final class TemporarySuite {
    let name: String
    let defaults: UserDefaults

    init(_ test: String = #function) {
        let file = "dau-tests-" + test.filter { $0.isLetter || $0.isNumber }
        name = FileManager.default.temporaryDirectory.appendingPathComponent(file).path
        defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
    }

    deinit {
        defaults.removePersistentDomain(forName: name)
        try? FileManager.default.removeItem(atPath: name + ".plist")
    }
}

@Suite("SettingsStore")
struct SettingsStoreTests {
    @Test("nothing saved yet reads as D15 defaults")
    func emptySuite() {
        let suite = TemporarySuite()
        #expect(SettingsStore(defaults: suite.defaults, suiteName: suite.name).load() == .defaults)
    }

    @Test("save then load returns the same settings")
    func saveLoad() {
        let suite = TemporarySuite()
        let store = SettingsStore(defaults: suite.defaults, suiteName: suite.name)
        var s = DauSettings(typingMethod: .vni, advanced: .allowZFWJ)
        s.upsert(AppRule(bundleID: "com.apple.Terminal", underline: true))
        store.save(s)
        #expect(store.load() == s)
        // A second store on the same suite (the other process) sees it too.
        let other = SettingsStore(defaults: UserDefaults(suiteName: suite.name)!, suiteName: suite.name)
        #expect(other.load() == s)
    }

    @Test("unreadable data reads as defaults")
    func corruptData() {
        let suite = TemporarySuite()
        suite.defaults.set(Data("not json".utf8), forKey: SettingsStore.settingsKey)
        #expect(SettingsStore(defaults: suite.defaults, suiteName: suite.name).load() == .defaults)
    }

    @Test("notification name is derived from the suite")
    func notificationName() {
        #expect(SettingsStore.changeNotificationName(suiteName: "TEAM.com.codefastlabs.dau")
                == "TEAM.com.codefastlabs.dau.settingsDidChange")
    }

    @Test("App Group ID is read from Info.plist; unexpanded or empty values are ignored")
    func appGroupIdentifier() throws {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("dau-tests-" + UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: dir) }
        func bundle(_ value: String?) throws -> Bundle {
            let url = dir.appendingPathComponent(UUID().uuidString + ".bundle")
            let contents = url.appendingPathComponent("Contents")
            try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
            var info: [String: Any] = ["CFBundleIdentifier": "dau.tests." + UUID().uuidString]
            if let value { info[SettingsStore.appGroupInfoKey] = value }
            let data = try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0)
            try data.write(to: contents.appendingPathComponent("Info.plist"))
            return try #require(Bundle(url: url))
        }
        #expect(SettingsStore.appGroupIdentifier(in: try bundle("TEAM.com.codefastlabs.dau")) == "TEAM.com.codefastlabs.dau")
        #expect(SettingsStore.appGroupIdentifier(in: try bundle("$(APP_GROUP_ID)")) == nil)
        #expect(SettingsStore.appGroupIdentifier(in: try bundle("")) == nil)
        #expect(SettingsStore.appGroupIdentifier(in: try bundle(nil)) == nil)
    }

    @Test("save posts the Darwin notification that observers hear")
    func saveNotifies() throws {
        let suite = TemporarySuite()
        let store = SettingsStore(defaults: suite.defaults, suiteName: suite.name)
        let heard = DispatchSemaphore(value: 0)
        let observer = try #require(store.observeChanges(on: DispatchQueue(label: "dau.tests.notify")) {
            heard.signal()
        })
        #expect(observer.name == suite.name + ".settingsDidChange")
        store.save(DauSettings(typingMethod: .vni))
        #expect(heard.wait(timeout: .now() + 2) == .success)
        withExtendedLifetime(observer) {}
    }
}

