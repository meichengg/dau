import Foundation
import Testing

@Suite("HostApp (input menu › Dấu Settings…)")
struct HostAppTests {
    @Test("the app an input method bundle is nested in")
    func enclosingApp() {
        let nested = URL(fileURLWithPath: "/Applications/Dau.app/Contents/Library/Input Methods/DauInputMethod.app")
        #expect(HostApp.enclosingApp(of: nested)?.path == "/Applications/Dau.app")
    }

    @Test("an installed copy is not nested in any app")
    func installedCopy() {
        let installed = URL(fileURLWithPath: "/Users/someone/Library/Input Methods/DauInputMethod.app")
        #expect(HostApp.enclosingApp(of: installed) == nil)
        #expect(HostApp.enclosingApp(of: URL(fileURLWithPath: "/DauInputMethod.app")) == nil)
    }
}

@Suite("HostApp choice among copies")
struct HostAppChoiceTests {
    @Test("an Applications folder wins over build folders")
    func preferApplications() {
        let build = URL(fileURLWithPath: "/Users/someone/dau/build/DerivedData/Build/Products/Debug/Dau.app")
        let installed = URL(fileURLWithPath: "/Applications/Dau.app")
        #expect(HostApp.preferred([build, installed]) == installed)
        #expect(HostApp.preferred([build]) == build)
        #expect(HostApp.preferred([]) == nil)
    }

    @Test("versions match only when both parts are known and equal")
    func versions() {
        typealias V = HostApp.Version
        #expect(V(short: "0.1.0", build: "1") == V(short: "0.1.0", build: "1"))
        #expect(V(short: "0.1.0", build: "1") != V(short: "0.1.0", build: "2"))
        #expect(V(short: "0.1.0", build: "1") != V(short: "0.2.0", build: "1"))
        #expect(V(short: nil, build: nil) != V(short: nil, build: nil))
    }
}

@Suite("HostApp scan of the Applications folder")
struct HostAppScanTests {
    /// A folder with fake app bundles: (file name, bundle ID, version, build).
    static func folder(_ apps: [(String, String, String, String)]) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("HostAppScan-\(UUID().uuidString)")
        for (name, id, short, build) in apps {
            let contents = dir.appendingPathComponent(name).appendingPathComponent("Contents")
            try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
            let plist: [String: Any] = ["CFBundleIdentifier": id, "CFBundlePackageType": "APPL",
                                        "CFBundleShortVersionString": short, "CFBundleVersion": build]
            try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
                .write(to: contents.appendingPathComponent("Info.plist"))
        }
        return dir
    }

    @Test("finds the host app with the same version, not other apps or versions")
    func sameVersion() throws {
        let dir = try Self.folder([("Another.app", "com.example.other", "0.1.0", "1"),
                                   ("Dau old.app", "com.example.dau", "0.0.9", "1"),
                                   ("Dau.app", "com.example.dau", "0.1.0", "1")])
        defer { try? FileManager.default.removeItem(at: dir) }
        let found = HostApp.scan([dir], hostID: "com.example.dau", version: .init(short: "0.1.0", build: "1"))
        #expect(found?.lastPathComponent == "Dau.app")
    }

    @Test("nothing when no copy has the same version, or the folder is missing")
    func noMatch() throws {
        let dir = try Self.folder([("Dau.app", "com.example.dau", "0.0.9", "1")])
        defer { try? FileManager.default.removeItem(at: dir) }
        #expect(HostApp.scan([dir], hostID: "com.example.dau", version: .init(short: "0.1.0", build: "1")) == nil)
        let missing = dir.appendingPathComponent("none")
        #expect(HostApp.scan([missing], hostID: "com.example.dau", version: .init(short: "0.1.0", build: "1")) == nil)
    }
}
