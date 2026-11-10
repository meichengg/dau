import AppKit

/// Opens panes of System Settings. Dấu never changes system settings itself; it only
/// opens the right screen (N4).
enum SystemSettings {
    /// Keyboard settings: keyboard shortcuts for input sources and the input source list.
    static func openKeyboard() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Keyboard settings with the Input Sources list (the "Edit…" sheet) already open, where
    /// the user removes Dấu in the uninstall (measured on macOS 27.2, 04/11/2026: the
    /// `?InputSources` query opens that sheet). Only the uninstall uses it; every other
    /// button opens the plain Keyboard pane.
    static func openInputSources() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Keyboard-Settings.extension?InputSources") {
            NSWorkspace.shared.open(url)
        }
    }

    /// General › Language & Region, whose "Applications" section sets a language for one
    /// app (D41): the "Change…" of the Language row.
    static func openLanguageAndRegion() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension") {
            NSWorkspace.shared.open(url)
        }
    }
}
