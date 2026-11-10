import AppKit
import SwiftUI
import DauShared

// Usage: SnapshotSettings <output-dir> [<artboard-dir> [<real-window-dir> [<onboarding-capture-dir>]]]
//        [-AppleLanguages '(en)']   (default: Vietnamese, as the artboards)
// - Renders every page in light, dark and high-contrast appearance and the 2×2 grids of
//   the four sections. No pass criteria: the layout is checked on the real window
//   (scripts/selftest/settings-window).
// - With <artboard-dir> (the canvas export holding Settings*.dc.html), also renders
//   each artboard and writes "<page>-compare-<mode>.png" (mockup | app) plus a table
//   of measurements, mockup against app.
// - With <real-window-dir> (the real/ directory of scripts/selftest/settings-window/run.sh:
//   ax-check's screenshots of the real window and their frames.json), the app side of the
//   comparisons in the appearance those screenshots were taken in uses them: this
//   hand-made window does not reproduce the scene's chrome, system colors and control
//   sizes exactly. The other appearance uses this tool's window.
// - With <onboarding-capture-dir> (Dau --capture-onboarding <dir>), also writes
//   "onboarding-<step>-compare-<mode>.png" (mockup | real window) for the onboarding
//   artboards (OnboardingConflict, OnboardingConflictDone, OnboardingEnable, OnboardingEnableNotes,
//   OnboardingEnableWaiting, OnboardingEnableFailed, OnboardingEnableError,
//   OnboardingEnableDone, OnboardingEnableDoneNoShortcut, Onboarding) and their element frames. There is no dark artboard: the
//   dark compare puts the light mockup beside the dark window.

// Before anything reads a localization: the app's catalog for Bundle.main, Vietnamese
// unless -AppleLanguages is given.
SnapshotLocalization.installForMainBundle()
print("localization:", Bundle.main.preferredLocalizations.first ?? "none")

var arguments: [String] = []
var skipNext = false
for arg in CommandLine.arguments.dropFirst() {
    if skipNext { skipNext = false; continue }
    if arg.hasPrefix("-") { skipNext = true; continue }   // -Key value pairs
    arguments.append(arg)
}
let outDir = URL(fileURLWithPath: arguments.first ?? FileManager.default.currentDirectoryPath, isDirectory: true)
let artboards = arguments.count > 1 ? URL(fileURLWithPath: arguments[1], isDirectory: true) : nil
let realDir = arguments.count > 2 ? URL(fileURLWithPath: arguments[2], isDirectory: true) : nil
let onboardingDir = arguments.count > 3 ? URL(fileURLWithPath: arguments[3], isDirectory: true) : nil

/// A capture `<key>.png` in `dir` and its frames under `key` in the directory's
/// frames.json, if present.
func capture(_ key: String, in dir: URL?) -> (NSBitmapImageRep, [String: CGRect])? {
    guard let dir,
          let rep = NSBitmapImageRep(data: (try? Data(contentsOf: dir.appendingPathComponent("\(key).png"))) ?? Data()),
          let json = try? JSONSerialization.jsonObject(with: Data(contentsOf: dir.appendingPathComponent("frames.json"))) as? [String: [String: [Double]]]
    else { return nil }
    var frames: [String: CGRect] = [:]
    for (name, v) in json[key] ?? [:] where v.count == 4 { frames[name] = CGRect(x: v[0], y: v[1], width: v[2], height: v[3]) }
    return (rep, frames)
}

/// The real window's screenshot of `page` on the primary display and its frames (ax-check
/// names: close, title, firstCard, segmented, switch, button, headerAdd, headerSearch), if
/// the real window was captured in `mode`.
func realCapture(_ page: String, _ mode: String) -> (NSBitmapImageRep, [String: CGRect])? {
    guard let realDir,
          let json = try? JSONSerialization.jsonObject(with: Data(contentsOf: realDir.appendingPathComponent("frames.json"))) as? [String: [String: [Double]]],
          let scale = json["meta"]?["primaryScale"]?.first, let dark = json["meta"]?["dark"]?.first,
          (dark == 1 ? "dark" : "light") == mode
    else { return nil }
    return capture("\(page)-\(Int(scale))x", in: realDir)
}
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

NSApplication.shared.setActivationPolicy(.accessory)

MainActor.assumeIsolated {
    // A throwaway suite so snapshots never touch real settings.
    let suite = "dau.snapshot-settings"
    defer { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
    UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite)
    let store = SettingsStore(defaults: UserDefaults(suiteName: suite) ?? .standard, suiteName: suite)
    store.save(Snapshot.sampleSettings())
    let model = SettingsModel(store: store, compatibility: Snapshot.sampleList)
    let enabled = InputSourceStatus(fixed: true)
    let notEnabled = InputSourceStatus(fixed: false)
    let windowSize = SettingsScene.defaultSize

    @MainActor func window(_ section: SettingsSection, _ status: InputSourceStatus) -> some View {
        SettingsWindow(initialSection: section).environment(model).environment(status)
    }

    let appearances: [(String, NSAppearance.Name)] = [
        ("light", .aqua), ("dark", .darkAqua),
        ("light-high-contrast", .accessibilityHighContrastAqua),
        ("dark-high-contrast", .accessibilityHighContrastDarkAqua),
    ]
    var app: [String: Snapshot.Result] = [:]

    for (mode, appearance) in appearances {
        func file(_ name: String) -> URL { outDir.appendingPathComponent("\(name)-\(mode).png") }
        for section in SettingsSection.allCases {
            let result = Snapshot.render(window(section, enabled), to: file(section.rawValue), appearance: appearance,
                                         size: windowSize)
            if let result { app["\(section.rawValue)-\(mode)"] = result }
        }
        app["not-enabled-\(mode)"] = Snapshot.render(window(.typing, notEnabled), to: file("typing-not-enabled"),
                                                       appearance: appearance, size: windowSize)
        app["smart-advanced-\(mode)"] = Snapshot.render(
            window(.smart, enabled).environment(\.smartAdvancedExpanded, true),
            to: file("smart-advanced"), appearance: appearance,
            size: CGSize(width: windowSize.width, height: windowSize.height + 80))
        // The Language row waiting for a relaunch (D41, artboard SettingsLanguagePending):
        // set for Dấu to English while Dấu still shows Vietnamese. The row otherwise reads
        // the real preferences, so this is the only fixed state.
        app["updates-language-pending-\(mode)"] = Snapshot.render(
            window(.updates, enabled).environment(\.languageRowStatus,
                                                  AppLanguage.Status(current: "vi", next: "en", setForDau: true)),
            to: file("updates-language-pending"), appearance: appearance, size: windowSize)
    }

    Snapshot.grid(SettingsSection.allCases.map { outDir.appendingPathComponent("\($0.rawValue)-light.png") },
                  columns: 2, to: outDir.appendingPathComponent("sections-grid.png"))
    Snapshot.grid(SettingsSection.allCases.map { outDir.appendingPathComponent("\($0.rawValue)-dark.png") },
                  columns: 2, to: outDir.appendingPathComponent("sections-grid-dark.png"))

    func f(_ r: CGRect?) -> String {
        guard let r else { return "—" }
        return String(format: "%.0f,%.0f %.0f×%.0f", r.minX, r.minY, r.width, r.height)
    }

    // Mockup against app.
    if let artboards {
        struct Board { let page: String; let file: String; let size: CGSize; let mode: String }
        let boards = [
            Board(page: "typing", file: "SettingsTyping", size: CGSize(width: 900, height: 680), mode: "light"),
            Board(page: "typing", file: "SettingsDark", size: CGSize(width: 900, height: 680), mode: "dark"),
            Board(page: "smart", file: "SettingsSmart", size: CGSize(width: 900, height: 680), mode: "light"),
            Board(page: "smart-advanced", file: "SettingsSmartAdvanced", size: CGSize(width: 900, height: 760), mode: "light"),
            Board(page: "apps", file: "SettingsApps", size: CGSize(width: 900, height: 680), mode: "light"),
            Board(page: "updates", file: "SettingsAbout", size: CGSize(width: 900, height: 680), mode: "light"),
            Board(page: "not-enabled", file: "SettingsNotEnabled", size: CGSize(width: 900, height: 680), mode: "light"),
        ]
        let measure = [
            "firstCard": "document.querySelector('main [role=status], main .card').getBoundingClientRect()",
            "segmented": "document.querySelector('main .seg') && document.querySelector('main .seg').getBoundingClientRect()",
            "switch": "document.querySelector('main .sw') && document.querySelector('main .sw').getBoundingClientRect()",
            "button": "document.querySelector('main .btn') && document.querySelector('main .btn').getBoundingClientRect()",
            "close": "document.querySelector('nav [aria-hidden=true] span').getBoundingClientRect()",
            "title": "(() => { const r = document.createRange(); r.selectNodeContents(document.querySelector('main header h1')); return r.getBoundingClientRect(); })()",
            "header": "document.querySelector('main header').getBoundingClientRect()",
            "sidebar": "document.querySelector('nav').getBoundingClientRect()",
            "headerSearch": "document.querySelector('main header label') && document.querySelector('main header label').getBoundingClientRect()",
            "headerAdd": "document.querySelector('main header .btn') && document.querySelector('main header .btn').getBoundingClientRect()",
        ]
        var rows: [String] = []
        for board in boards {
            let crop = CGRect(x: 40, y: 40, width: board.size.width - 80, height: board.size.height - 80)
            guard let mock = Mockup.render(artboards.appendingPathComponent("\(board.file).dc.html"),
                                           size: board.size, crop: crop, measure: measure),
                  let shot = app["\(board.page)-\(board.mode)"] else { print("cannot render \(board.file)"); continue }
            let real = realCapture(board.page, board.mode)
            if board.page == "apps", let realShot = real?.0 {
                // The Apps header (title, search field, +), 3×, against the real window.
                let header = CGRect(x: 220, y: 0, width: 520, height: 56)
                if let a = Snapshot.crop(mock.image, header, scale: 3), let b = Snapshot.crop(realShot, header, scale: 3) {
                    Snapshot.sideBySide([a, b], to: outDir.appendingPathComponent("apps-header-compare-\(board.mode).png"))
                }
                // No dark artboard exists for this page: the light mockup beside the dark app.
                if let dark = realCapture("apps", "dark")?.0,
                   let a = Snapshot.crop(mock.image, header, scale: 3), let b = Snapshot.crop(dark, header, scale: 3) {
                    Snapshot.sideBySide([a, b], to: outDir.appendingPathComponent("apps-header-compare-dark.png"))
                }
                for key in ["headerSearch", "headerAdd"] {
                    rows.append("apps-\(board.mode) | \(key) | \(f(mock.frames[key])) | \(f(real?.1[key]))")
                }
            }
            if board.page == "typing" {
                // Sidebar only, 4×: the real-window capture does not draw the sidebar's
                // vibrant content, so the app side is this tool's window.
                let area = CGRect(x: 0, y: 0, width: 232, height: 280)
                if let a = Snapshot.crop(mock.image, area, scale: 4), let b = Snapshot.crop(shot.rep, area, scale: 4) {
                    Snapshot.sideBySide([a, b], to: outDir.appendingPathComponent("sidebar-compare-\(board.mode).png"))
                }
                // The "Kiểu gõ" card, 3×, against the real window when captured.
                let card = CGRect(x: 246, y: 214, width: 548, height: 140)
                if let a = Snapshot.crop(mock.image, card, scale: 3), let b = Snapshot.crop(real?.0 ?? shot.rep, card, scale: 3) {
                    Snapshot.sideBySide([a, b], to: outDir.appendingPathComponent("segmented-compare-\(board.mode).png"))
                }
            }
            Snapshot.sideBySide([mock.image, real?.0 ?? shot.rep],
                                to: outDir.appendingPathComponent("\(board.page)-compare-\(board.mode).png"))
            // The mockup's first card against the real window's first card, or this tool's
            // first row (the card inset by the Form's 10 pt row margins).
            for key in ["close", "title", "firstCard", "segmented", "switch", "button"] {
                let appKey = key == "firstCard" && real == nil ? "firstRow" : key
                rows.append("\(board.page)-\(board.mode) | \(key) | \(f(mock.frames[key])) | \(f((real?.1 ?? shot.frames)[appKey]))")
            }
        }
        // The Language row waiting for a relaunch: the 740×560 window of the artboard
        // (at 80,100 in its 900×760 frame) beside this tool's window.
        if let mock = Mockup.render(artboards.appendingPathComponent("SettingsLanguagePending.dc.html"),
                                    size: CGSize(width: 900, height: 760),
                                    crop: CGRect(x: 80, y: 100, width: 740, height: 560), measure: [:]),
           let shot = app["updates-language-pending-light"] {
            Snapshot.sideBySide([mock.image, shot.rep],
                                to: outDir.appendingPathComponent("updates-language-pending-compare-light.png"))
        } else {
            print("cannot render SettingsLanguagePending")
        }
        // The add-rule sheet: the dialog only, against the sheet presented off screen.
        if let full = Mockup.render(artboards.appendingPathComponent("SettingsAppsAdd.dc.html"),
                                    size: CGSize(width: 900, height: 680), crop: .zero,
                                    measure: ["dialog": "document.querySelector('[role=dialog]').getBoundingClientRect()"]),
           let dialog = full.frames["dialog"] {
            let crop = dialog.integral
            for (mode, appearance) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
                let sheet = Snapshot.renderSheet(AddAppRuleSheet().environment(model),
                                                 to: outDir.appendingPathComponent("apps-add-sheet-\(mode).png"),
                                                 appearance: appearance)
                if sheet == nil { print("cannot present the add-rule sheet (\(mode))") }
                if mode == "light", let mock = Mockup.render(
                    artboards.appendingPathComponent("SettingsAppsAdd.dc.html"),
                    size: CGSize(width: 900, height: 680), crop: crop, measure: [:]), let sheet {
                    Snapshot.sideBySide([mock.image, sheet],
                                        to: outDir.appendingPathComponent("apps-add-compare-light.png"))
                }
            }
        }
        // Onboarding: the window is at 50,40 in the 820×580 artboards.
        if let onboardingDir {
            let crop = CGRect(x: 50, y: 40, width: 720, height: 500)
            let measure = [
                "close": "document.querySelector('aside [aria-hidden=true] span').getBoundingClientRect()",
                "onbAppName": "document.querySelector('aside > div:nth-child(2)').getBoundingClientRect()",
                "onbSteps": "document.querySelector('aside ol').getBoundingClientRect()",
                "onbTitle": "(() => { const r = document.createRange(); r.selectNodeContents(document.querySelector('main h1')); return r.getBoundingClientRect(); })()",
                "onbCard": "document.querySelector('main .card').getBoundingClientRect()",
                "onbSegmented": "document.querySelector('main .seg') && document.querySelector('main .seg').getBoundingClientRect()",
                "onbButtons": "document.querySelector('main > div:last-child').getBoundingClientRect()",
            ]
            for (step, file) in [("1", "OnboardingConflict"), ("1-done", "OnboardingConflictDone"),
                                 ("2", "OnboardingEnable"),
                                 ("2-notes", "OnboardingEnableNotes"),
                                 ("2-waiting", "OnboardingEnableWaiting"), ("2-failed", "OnboardingEnableFailed"),
                                 ("2-error", "OnboardingEnableError"), ("2-done", "OnboardingEnableDone"),
                                 ("2-done-noshortcut", "OnboardingEnableDoneNoShortcut"), ("3", "Onboarding")] {
                guard let mock = Mockup.render(artboards.appendingPathComponent("\(file).dc.html"),
                                               size: CGSize(width: 820, height: 580), crop: crop, measure: measure)
                else { print("cannot render \(file)"); continue }
                for mode in ["light", "dark"] {
                    guard let real = capture("onboarding-\(step)-\(mode)", in: onboardingDir) else { continue }
                    Snapshot.sideBySide([mock.image, real.0],
                                        to: outDir.appendingPathComponent("onboarding-\(step)-compare-\(mode).png"))
                    if mode == "light" {
                        for key in measure.keys.sorted() {
                            rows.append("onboarding-\(step) | \(key) | \(f(mock.frames[key])) | \(f(real.1[key]))")
                        }
                    }
                }
            }
        }
        print("\nMockup | app (points, window origin top-left):")
        print("page | element | mockup | app" + (realDir == nil ? " (snapshot window)" : " (real window where captured)"))
        rows.forEach { print($0) }
    }
}
