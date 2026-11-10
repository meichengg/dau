// swift-tools-version: 6.0
// Renders the Settings window of the host app to PNG, light and dark, without any
// interaction, and checks every "keys → result" sample the window shows.
//
//   swift run --package-path scripts/snapshot-settings SnapshotSettings <output-dir>
//   swift test --package-path scripts/snapshot-settings   (DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
//   when xcode-select points at the Command Line Tools)
//
// The app's view code is compiled straight from Apps/Dau/Sources (symlink "App"),
// minus its entry point, with the app's String Catalog (symlink
// "Localizable.xcstrings"). Screenshots are Vietnamese unless -AppleLanguages is given:
//   swift run --package-path scripts/snapshot-settings SnapshotSettings <output-dir> -AppleLanguages '(en)'
// Not sandboxed, so it reads the real input-source shortcut; the "not enabled" banner
// is forced per screenshot.

import PackageDescription

let package = Package(
    name: "SnapshotSettings",
    defaultLocalization: "en",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(path: "../../Packages/DauShared"),
    ],
    targets: [
        .executableTarget(
            name: "SnapshotSettings",
            dependencies: [.product(name: "DauShared", package: "DauShared")],
            exclude: ["App/main.swift", "App/DauApp.swift"],
            resources: [.process("Localizable.xcstrings")]
        ),
        .testTarget(
            name: "SnapshotSettingsTests",
            dependencies: ["SnapshotSettings", .product(name: "DauShared", package: "DauShared")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
