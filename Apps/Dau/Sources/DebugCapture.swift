#if DEBUG
import AppKit
import ApplicationServices
import SwiftUI

/// Where the capture modes put a window: the middle of the primary display (the one with
/// the menu bar), in view. They used to move it to (-9000, -9000); macOS pulled it back
/// into a corner of the main screen, where it peeked out during the run, and AppKit saved
/// that corner as the window's frame for the next normal launch (03/11/2026). Not
/// `NSScreen.main`: that is the screen of the user's key window, which can be a 1x display
/// and gave 1x captures that the pass values (made on the Retina display) do not fit.
@MainActor func centeredFrame(size: NSSize) -> NSRect {
    let visible = NSScreen.screens.first?.visibleFrame ?? NSRect(x: 0, y: 0, width: size.width, height: size.height)
    return NSRect(x: (visible.midX - size.width / 2).rounded(), y: (visible.midY - size.height / 2).rounded(),
                  width: size.width, height: size.height)
}

/// Puts a capture window in the middle of the primary display over a plain backdrop. The
/// sidebar and toolbar materials blend what lies behind the window; the backdrop, one
/// system color right below it, keeps that the same whatever the user has on screen.
/// A precaution: its effect alone was not measured (the dark-mode failures of the first
/// on-screen runs came from 1x captures, see `centeredFrame`).
@MainActor func placeForCapture(_ window: NSWindow, size: NSSize) {
    let frame = centeredFrame(size: size)
    window.setFrame(frame, display: false)
    let backdrop = CaptureBackdrop.window
    backdrop.setFrame(frame.insetBy(dx: -40, dy: -40), display: true)
    backdrop.order(.below, relativeTo: window.windowNumber)
}

@MainActor enum CaptureBackdrop {
    static let window: NSWindow = {
        let w = NSWindow(contentRect: .zero, styleMask: .borderless, backing: .buffered, defer: false)
        w.backgroundColor = .windowBackgroundColor
        w.isOpaque = true
        w.hasShadow = false
        w.ignoresMouseEvents = true
        w.isReleasedWhenClosed = false
        return w
    }()
}

/// Debug only: in-app captures that need fake services, run by
/// scripts/selftest/settings-window on a copy re-signed ad hoc without entitlements:
/// `--capture-onboarding` (the onboarding window on fixed services),
/// `--capture-uninstall` (the uninstall alerts and the "Bỏ Dấu khỏi nguồn đầu vào"
/// sheet, laid out without running anything). The Settings window itself is measured from outside, in the real app (`--settings-window`,
/// ax-check.swift).
@MainActor
enum DebugCapture {
    /// Frames the onboarding window's layout probes report, while capturing; a view that
    /// disappears takes its frame out (`LayoutProbeModifier`), so a shot only lists the
    /// views it shows.
    static var frames: [String: CGRect] = [:]

    /// The probe closure installed in the onboarding scene while capturing.
    static var probe: (@MainActor @Sendable (String, CGRect) -> Void)? {
        guard onboardingDirectory != nil else { return nil }
        return { @MainActor name, frame in DebugCapture.frames[name] = frame.isNull ? nil : frame }
    }

    // MARK: Onboarding

    /// `--onboarding <1|2|3>`: open the onboarding window at that step (real services).
    static let onboardingStep: OnboardingFlow.Step? = {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--onboarding"), i + 1 < args.count,
              let n = Int(args[i + 1]) else { return nil }
        return OnboardingFlow.Step(rawValue: n)
    }()

    /// `--capture-onboarding <dir>`: the onboarding window on fixed services (OpenKey
    /// running, Dấu installed but not enabled). Writes `onboarding-<step>-<mode>.png` for
    /// steps 1, 2 before "Bật Dấu" (`2`), 1 after "Quay lại" with OpenKey quit
    /// (`1-done`), 2 with an unreadable shortcut and another
    /// Vietnamese source on (`2-notes`), 2 waiting for Allow (`2-waiting`), 2 when macOS
    /// left Dấu off (`2-failed`), 2 on an install error (`2-error`), 2 once enabled
    /// (`2-done`), 2 enabled with no shortcut set (`2-done-noshortcut`) and 3, light and
    /// dark, plus `frames.json`.
    static let onboardingDirectory: URL? = {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--capture-onboarding"), i + 1 < args.count else { return nil }
        return URL(fileURLWithPath: args[i + 1], isDirectory: true)
    }()

    /// `--shortcut none|unknown`: pretend the input source shortcut reads so (captures).
    static let shortcutArgument: InputSourceShortcut.Reading? = {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--shortcut"), i + 1 < args.count else { return nil }
        switch args[i + 1] {
        case "none": return InputSourceShortcut.Reading.none
        case "unknown": return InputSourceShortcut.Reading.unknown
        default: return nil
        }
    }()

    /// What the captures' flow reads as the shortcut: a shot may set it; nil reads the
    /// real one.
    static var shortcutNow: InputSourceShortcut.Reading? = shortcutArgument

    static var onboardingFlow: OnboardingFlow?
    static var onboardingDetector: FakeInputMethodDetector?
    static var onboardingInstaller: FakeInputMethodInstaller?
    /// The Settings window's actions (`--capture-uninstall` lays the sheet out through them).
    static var actions: InputMethodActions?

    static func startOnboarding() {
        guard let directory = onboardingDirectory else { return }
        NSApp.setActivationPolicy(.accessory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        Task { @MainActor in
            // The window opens once the Settings window has appeared (LaunchRouting):
            // wait for it, up to 10 s.
            var found: NSWindow?
            for _ in 0..<50 where found == nil {
                try? await Task.sleep(for: .milliseconds(200))
                found = NSApp.windows.first { $0.isVisible && $0.title == String(localized: "Set Up Dấu") }
            }
            try? await Task.sleep(for: .milliseconds(500))
            guard let flow = onboardingFlow, let window = found else {
                print("no onboarding window:", NSApp.windows.map { "\($0.title) \($0.frame) visible=\($0.isVisible)" })
                exit(1)
            }
            placeForCapture(window, size: window.frame.size)
            if CommandLine.arguments.contains("--active") {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate()
                window.makeKeyAndOrderFront(nil)
            }
            var report: [String: [String: [Double]]] = [:]
            // Show another step first so step 1's probes report again; drop the
            // Settings window's probes.
            flow.show(.typing)
            try? await Task.sleep(for: .milliseconds(300))
            frames = frames.filter { $0.key.hasPrefix("onb") }
            for (mode, name) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
                NSApp.appearance = NSAppearance(named: name)
                let openKey = onboardingDetector?.found ?? []
                onboardingInstaller?.current = .installed(version: nil)
                onboardingInstaller?.enableWaits = false
                onboardingInstaller?.failure = nil
                shortcutNow = shortcutArgument
                flow.start()
                flow.tryText = ""
                let installer = onboardingInstaller
                let detector = onboardingDetector
                let shots: [(String, @MainActor () async -> Void)] = [
                    ("1", { flow.show(.oldInputMethods) }),
                    // As in the mockup: the user quit OpenKey, step 1 is done.
                    ("2", { detector?.found = []; flow.refresh(); flow.show(.enable) }),
                    // "Quay lại" from there: step 1 says OpenKey is off.
                    ("1-done", { flow.back() }),
                    // "Tiếp tục"; the shortcut cannot be read and another Vietnamese
                    // source is on (D14).
                    ("2-notes", {
                        flow.next()
                        shortcutNow = InputSourceShortcut.Reading.unknown
                        detector?.otherSources = ["Tiếng Việt – Telex"]
                        flow.refresh()
                    }),
                    // "Bật Dấu" is waiting for the click on macOS's dialog.
                    ("2-waiting", {
                        shortcutNow = shortcutArgument
                        detector?.otherSources = []
                        flow.refresh()
                        installer?.enableWaits = true
                        Task { @MainActor in await flow.enable() }
                    }),
                    // The wait ends with Dấu still off.
                    ("2-failed", {
                        installer?.enableOutcome = .notEnabled
                        installer?.release = .notEnabled
                        while flow.isWorking { try? await Task.sleep(for: .milliseconds(20)) }
                    }),
                    // "Thử lại" hits an install error.
                    ("2-error", {
                        installer?.enableWaits = false
                        installer?.failure = .invalidSignature
                        await flow.enable()
                    }),
                    // "Thử lại", and this time the user allows it.
                    ("2-done", {
                        installer?.failure = nil
                        installer?.enableOutcome = .enabled
                        await flow.enable()
                    }),
                    ("2-done-noshortcut", { shortcutNow = InputSourceShortcut.Reading.none; flow.refresh() }),
                    ("3", { shortcutNow = shortcutArgument; flow.refresh(); flow.tryText = "Tôi yêu tiếng Việt"; flow.show(.typing) }),
                ]
                for (key, setUp) in shots {
                    // Probes report changes only: a view still shown keeps its frame
                    // from the shot before, a view gone has none (it is FAIL in check (f)),
                    // the step's own views report again when the step changes.
                    await setUp()
                    try? await Task.sleep(for: .milliseconds(700))
                    capture(window, to: directory.appendingPathComponent("onboarding-\(key)-\(mode).png"))
                    // Step views name their probes "<name>-<step>": keep the shown step's.
                    var entry: [String: [Double]] = [:]
                    for (name, r) in frames {
                        let parts = name.split(separator: "-", maxSplits: 1).map(String.init)
                        if parts.count == 2 {
                            // "<step>" or "<step>.<screen>" (step 2 swaps screens).
                            let current = "\(flow.step.rawValue)"
                            guard parts[1] == current || parts[1].hasPrefix(current + ".") else { continue }
                            entry[parts[0]] = [Double(r.minX), Double(r.minY), Double(r.width), Double(r.height)]
                        } else {
                            entry[name] = [Double(r.minX), Double(r.minY), Double(r.width), Double(r.height)]
                        }
                    }
                    if let b = window.standardWindowButton(.closeButton), let s = b.superview {
                        let r = s.convert(b.frame, to: nil)
                        entry["close"] = [Double(r.minX), Double(window.frame.height - r.maxY), Double(r.width), Double(r.height)]
                    }
                    entry["window"] = [0, 0, Double(window.frame.width), Double(window.frame.height)]
                    // Check (f): the window shows no title text (`.hiddenTitleBar`, DauApp).
                    entry["titleHidden"] = [window.titleVisibility == .hidden ? 1 : 0]
                    report["onboarding-\(key)-\(mode)"] = entry
                    if mode == "light" {
                        try? await accessibilityTree(window).write(
                            to: directory.appendingPathComponent("onboarding-\(key)-accessibility.txt"),
                            atomically: true, encoding: .utf8)
                    }
                }
                onboardingDetector?.found = openKey
            }
            if let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys, .prettyPrinted]) {
                try? data.write(to: directory.appendingPathComponent("frames.json"))
            }
            print("captured to \(directory.path)")
            exit(0)
        }
    }

    // MARK: Uninstall alert

    /// `--capture-uninstall <dir>`: opens the Settings window in the middle of the primary
    /// display, lays out the "Gỡ Dấu khỏi máy?" alert, the result alert and the "Bỏ Dấu
    /// khỏi nguồn đầu vào" sheet there without running anything, and writes
    /// `uninstall-confirm-<mode>.png`, `uninstall-done-<mode>.png`,
    /// `uninstall-remove-<mode>.png` (Dấu not selected) and
    /// `uninstall-remove-hint-<mode>.png` (Dấu selected: with the "–" hint), plus `frames.json`
    /// (sheet sizes).
    static let uninstallDirectory: URL? = {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--capture-uninstall"), i + 1 < args.count else { return nil }
        return URL(fileURLWithPath: args[i + 1], isDirectory: true)
    }()

    static func startUninstall() {
        guard let directory = uninstallDirectory else { return }
        NSApp.setActivationPolicy(.accessory)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            guard let window = NSApp.windows.first(where: { $0.isVisible && $0.contentView != nil }) else {
                print("no window"); exit(1)
            }
            placeForCapture(window, size: SettingsScene.defaultSize)
            var report: [String: [String: [Double]]] = [:]
            for (mode, name) in [("light", NSAppearance.Name.aqua), ("dark", .darkAqua)] {
                NSApp.appearance = NSAppearance(named: name)
                let sample = UninstallReport(movedToTrash: true, stillEnabled: false, dataDeleted: true)
                let alerts: [(String, NSAlert)] = [
                    ("confirm", UninstallAlert.confirmation().0),
                    ("done", UninstallAlert.done(sample)),
                ]
                for (key, alert) in alerts {
                    // The window `runModal` would show, without the modal loop.
                    alert.layout()
                    let panel = alert.window
                    panel.appearance = NSAppearance(named: name)
                    panel.orderFront(nil)
                    placeForCapture(panel, size: panel.frame.size)
                    try? await Task.sleep(for: .milliseconds(900))
                    // The alert's glass shows whatever is behind it (the backdrop): put it
                    // on the window background, roughly what it covers over the Settings window.
                    capture(panel, to: directory.appendingPathComponent("uninstall-\(key)-\(mode).png"),
                            background: .windowBackgroundColor)
                    report["uninstall-\(key)-\(mode)"] = ["sheet": [0, 0, Double(panel.frame.width), Double(panel.frame.height)]]
                    panel.orderOut(nil)
                    try? await Task.sleep(for: .milliseconds(300))
                }
                // The sheet of the Settings window, on the fake preparation.
                window.makeKeyAndOrderFront(nil)
                let sheets: [(String, Bool)] = [("remove", false), ("remove-hint", true)]
                for (key, dauIsSelected) in sheets {
                    actions?.showUninstallSheetForCapture(true, dauIsSelected: dauIsSelected)
                    try? await Task.sleep(for: .milliseconds(1200))
                    guard let sheet = window.attachedSheet else { print("no sheet for \(key)"); exit(1) }
                    capture(sheet, to: directory.appendingPathComponent("uninstall-\(key)-\(mode).png"),
                            background: .windowBackgroundColor)
                    report["uninstall-\(key)-\(mode)"] = ["sheet": [0, 0, Double(sheet.frame.width), Double(sheet.frame.height)]]
                    actions?.showUninstallSheetForCapture(false)
                    try? await Task.sleep(for: .milliseconds(600))
                }
            }
            if let data = try? JSONSerialization.data(withJSONObject: report, options: [.sortedKeys, .prettyPrinted]) {
                try? data.write(to: directory.appendingPathComponent("frames.json"))
            }
            print("captured to \(directory.path)")
            exit(0)
        }
    }

    /// The window's accessibility tree as VoiceOver gets it, one element per line:
    /// role, title/description, value, help, indented by depth. Uses the AX API on this
    /// process (SwiftUI builds its tree only for an AX client), from a background thread
    /// while the main thread keeps answering. Needs the Accessibility permission of the
    /// launching app (Terminal); empty without it.
    static func accessibilityTree(_ window: NSWindow) async -> String {
        let pid = ProcessInfo.processInfo.processIdentifier
        let title = window.title
        return await withCheckedContinuation { continuation in
            Thread.detachNewThread {
                continuation.resume(returning: axDump(pid: pid, windowTitle: title))
            }
        }
    }

    nonisolated private static func axDump(pid: pid_t, windowTitle: String) -> String {
        func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
            var value: CFTypeRef?
            return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
        }
        func string(_ element: AXUIElement, _ name: String) -> String? {
            guard let value = attribute(element, name) else { return nil }
            if CFGetTypeID(value) == CFStringGetTypeID() { return value as? String }
            if CFGetTypeID(value) == CFNumberGetTypeID() || CFGetTypeID(value) == CFBooleanGetTypeID() { return "\(value)" }
            return nil
        }
        var lines: [String] = []
        func walk(_ element: AXUIElement, depth: Int) {
            guard depth < 40 else { return }
            var parts = [string(element, kAXRoleAttribute) ?? "?"]
            for (key, name) in [("title", kAXTitleAttribute), ("desc", kAXDescriptionAttribute),
                                ("value", kAXValueAttribute), ("help", kAXHelpAttribute)] {
                if let v = string(element, name), !v.isEmpty { parts.append("\(key)=\"\(v)\"") }
            }
            if string(element, kAXEnabledAttribute) == "0" { parts.append("disabled") }
            lines.append(String(repeating: "  ", count: depth) + parts.joined(separator: " "))
            for child in (attribute(element, kAXChildrenAttribute) as? [AXUIElement]) ?? [] {
                walk(child, depth: depth + 1)
            }
        }
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 5)
        let windows = (attribute(app, kAXWindowsAttribute) as? [AXUIElement]) ?? []
        guard let window = windows.first(where: { string($0, kAXTitleAttribute) == windowTitle }) ?? windows.first else {
            return "no AX window (trusted: \(AXIsProcessTrusted()))\n"
        }
        walk(window, depth: 0)
        return lines.joined(separator: "\n") + "\n"
    }

    /// `--settings-window`: open the Settings window at launch, never the onboarding,
    /// and leave the installed input method alone (real-window checks).
    static let settingsWindowOnly = CommandLine.arguments.contains("--settings-window")

    /// `--appearance light|dark`: this app only draws in that appearance (the real-window
    /// checks capture the sheet in the appearance the system is not in). The system
    /// appearance is not changed (N4); `-AppleInterfaceStyle` as an argument does not
    /// change the windows' appearance (measured on macOS 27.2).
    static func applyAppearanceOverride() {
        let args = CommandLine.arguments
        guard let i = args.firstIndex(of: "--appearance"), i + 1 < args.count else { return }
        switch args[i + 1] {
        case "light": NSApp.appearance = NSAppearance(named: .aqua)
        case "dark": NSApp.appearance = NSAppearance(named: .darkAqua)
        default: break
        }
    }

    /// The window as the window server composites it (materials, scroll edge effects),
    /// through `CGWindowListCreateImage`, which needs no permission for the app's own
    /// windows. The function is unavailable to Swift in the macOS 15+ SDK, so it is
    /// looked up at run time; nil if it is gone.
    private static func compositedImage(_ window: NSWindow) -> CGImage? {
        typealias Create = @convention(c) (CGRect, UInt32, UInt32, UInt32) -> Unmanaged<CGImage>?
        guard let handle = dlopen(nil, RTLD_NOW), let sym = dlsym(handle, "CGWindowListCreateImage") else { return nil }
        let create = unsafeBitCast(sym, to: Create.self)
        // kCGWindowListOptionIncludingWindow = 8; kCGWindowImageBoundsIgnoreFraming = 1,
        // kCGWindowImageBestResolution = 8.
        return create(.null, 8, UInt32(window.windowNumber), 1 | 8)?.takeRetainedValue()
    }

    private static func capture(_ window: NSWindow, to url: URL, background: NSColor? = nil) {
        var image = compositedImage(window)
        if image == nil, let frameView = window.contentView?.superview {
            frameView.display()
            if let rep = frameView.bitmapImageRepForCachingDisplay(in: frameView.bounds) {
                frameView.cacheDisplay(in: frameView.bounds, to: rep)
                image = rep.cgImage
            }
        }
        guard var image else { return }
        if let background, let flat = flatten(image, on: background, appearance: window.effectiveAppearance) {
            image = flat
        }
        try? NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])?.write(to: url)
    }

    /// `image` drawn over `color` (resolved in `appearance`).
    private static func flatten(_ image: CGImage, on color: NSColor, appearance: NSAppearance) -> CGImage? {
        guard let context = CGContext(data: nil, width: image.width, height: image.height, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
        var fill: CGColor?
        appearance.performAsCurrentDrawingAppearance { fill = color.cgColor }
        let rect = CGRect(x: 0, y: 0, width: image.width, height: image.height)
        context.setFillColor(fill ?? .white)
        context.fill(rect)
        context.draw(image, in: rect)
        return context.makeImage()
    }
}
#endif
