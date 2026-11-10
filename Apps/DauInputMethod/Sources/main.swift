import AppKit
import InputMethodKit
import os
import DauShared

// Entry point of the input method process.
// IMKServer registers the Mach connection named in Info.plist (InputMethodConnectionName);
// the system then instantiates DauInputController (InputMethodServerControllerClass) per client.

let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DauInputMethod", category: "server")

guard let connectionName = Bundle.main.object(forInfoDictionaryKey: "InputMethodConnectionName") as? String,
      !connectionName.isEmpty else {
    logger.fault("InputMethodConnectionName missing from Info.plist")
    exit(1)
}

let server = IMKServer(name: connectionName, bundleIdentifier: Bundle.main.bundleIdentifier)

#if DEBUG
// Debug only: log the settings at launch and on every change (SettingsReloadLog).
let settingsReloadLog = SettingsReloadLog.start()
#else
let settingsReloadLog: SettingsChangeObserver? = nil
#endif

// D7, D16, D37: the host app asks this process to quit after replacing the bundle
// (upgrade) or before moving it to the Trash (uninstall). Every live controller first
// ends its word (underline mode commits the marked text as shown, `quitRequested`), then
// the process exits; macOS launches the bundle on disk at the next key.
let executablePath = Bundle.main.executablePath ?? ""
let launchedFrom = InputMethodLifecycle.BundleFile.at(executablePath)
let quitObserver = InputMethodLifecycle.observeQuitRequests(
    inputMethodBundleID: Bundle.main.bundleIdentifier ?? "DauInputMethod", on: .main) {
    MainActor.assumeIsolated {
        // Anyone can post this notification: quit only after an upgrade or uninstall
        // really changed the bundle on disk (InputMethodLifecycle).
        guard InputMethodLifecycle.shouldQuit(launchedFrom: launchedFrom,
                                              now: InputMethodLifecycle.BundleFile.at(executablePath)) else {
            logger.notice("event=quit-ignored reason=bundle-unchanged")
            return
        }
        logger.notice("event=quit-requested")
        NotificationCenter.default.post(name: .dauQuitRequested, object: nil)
        // Next turn of the run loop, so the commits above reach the clients first.
        DispatchQueue.main.async { exit(0) }
    }
}
if quitObserver == nil {
    logger.error("event=quit-observe-failed (the host app falls back to terminating the process)")
}

// Launched by the user (Finder double-click) rather than by the system to serve typing:
// open the host app and quit; reopened while running: open the host app
// (InputMethodAppDelegate, LaunchPolicy). NSApplication keeps the delegate weakly.
let appDelegate = InputMethodAppDelegate()
NSApplication.shared.delegate = appDelegate

withExtendedLifetime((server, settingsReloadLog, quitObserver, appDelegate)) {
    NSApplication.shared.run()
}
