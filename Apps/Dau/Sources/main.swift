import Foundation

// The interface follows the macOS language list (D41): the bundle's development
// language is English and macOS picks the first language Dấu has, else English. A
// -AppleLanguages argument on the command line still picks the language, for checks.

#if DEBUG
// Debug checks that run in the built app without opening a window: each
// prints one value and exits.
DebugSettingsCommand.runIfRequested()
if CommandLine.arguments.contains("--print-localizations") {
    print(Bundle.main.preferredLocalizations)
    exit(0)
}
if CommandLine.arguments.contains("--print-input-source-name") {
    // Dấu's input source as macOS names it, in the system's languages (D41).
    print(SystemUINames.system().dauInputSource)
    exit(0)
}
if CommandLine.arguments.contains("--print-input-source-status") {
    switch InputSourceStatus.query() {
    case true?: print("enabled")
    case false?: print("disabled")
    case nil: print("unknown (input method bundle not found)")
    }
    exit(0)
}
if CommandLine.arguments.contains("--print-input-shortcut") {
    if let shortcut = InputSourceShortcut.current() {
        print(shortcut.keys.joined(separator: " "), shortcut.globeKey ? "+ globe key" : "")
    } else {
        print("unreadable")
    }
    exit(0)
}
#endif

DauApp.main()
