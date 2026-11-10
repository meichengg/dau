// Small helper for scripts/selftest/app-group.sh, scripts/selftest/typing/run.sh,
// scripts/selftest/load/run.sh, scripts/dev/doctor.sh and scripts/dev/clean-dau.sh.
//
//   input-source current             prints the ID of the selected keyboard input source
//   input-source select <ID>         selects an input source that is ALREADY enabled
//   input-source enabled <prefix>    prints enabled, selectable sources whose ID starts with prefix
//   input-source recorded            prints the third-party sources macOS records as enabled
//   input-source count <key> <regex> reads a plist (`defaults export <domain> -`) on stdin and
//                                    prints how many dict entries of array <key> have a
//                                    "Bundle ID" that regex matches from its start; empty
//                                    stdin counts as an empty plist (prints 0)
//   input-source drop <key> <regex>  reads a plist on stdin and writes it to stdout (XML) with
//                                    those entries left out of array <key>
//
// Trust: the TIS "enabled" flag read from a fresh process can be wrong (it said enabled
// after System Settings had removed Dấu; docs/research/M5-INSTALL.md 2.6). TIS is
// only trusted for the CURRENT source (`current`). For every third-party source (ID not
// starting with com.apple.) `enabled` and `select` also require an entry in
// com.apple.inputsources › AppleEnabledThirdPartyInputSources, the record System Settings
// keeps (the same one scripts/dev/clean-dau.sh reads). When the two disagree the command
// prints a message on stderr, prints no source and exits with status 4.
//
// It never enables, disables, adds or removes an input source (N4): `select` refuses a
// source that is not enabled and select-capable. The self test uses it only to reselect
// Dấu (so macOS launches the input method) and to give back the source that was selected
// before. `count` and `drop` are stdin-to-stdout filters that read and write no
// preferences: clean-dau.sh itself runs `defaults export`/`defaults import` and reads the
// domain back.
import Carbon
import Foundation

func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
    guard let raw = TISGetInputSourceProperty(source, key) else { return nil }
    return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
}

func boolProperty(_ source: TISInputSource, _ key: CFString) -> Bool {
    guard let raw = TISGetInputSourceProperty(source, key) else { return false }
    return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(raw).takeUnretainedValue())
}

/// Enabled, select-capable sources (TISCreateInputSourceList with includeAllInstalled
/// false lists enabled sources only).
func enabledSources() -> [TISInputSource] {
    let filter = [kTISPropertyInputSourceIsSelectCapable as String: true] as CFDictionary
    guard let list = TISCreateInputSourceList(filter, false)?.takeRetainedValue() as? [TISInputSource] else {
        return []
    }
    return list.filter { boolProperty($0, kTISPropertyInputSourceIsEnabled) }
}

/// IDs of the third-party sources macOS records as enabled: the "Input Mode" of an entry
/// that has one, else its "Bundle ID" (the same IDs TIS uses for those sources). An input
/// method that has modes is recorded twice, the method itself ("Keyboard Input Method",
/// not select-capable) and each mode; only the modes are selectable, so the method entry
/// is left out then (Dấu added with "+" records both; docs/research/M5-INSTALL.md 2.6).
func recordedSourceIDs() -> Set<String> {
    let value = CFPreferencesCopyAppValue("AppleEnabledThirdPartyInputSources" as CFString,
                                          "com.apple.inputsources" as CFString)
    let entries = (value as? [[String: Any]]) ?? []
    let bundlesWithModes = Set(entries.compactMap { $0["Input Mode"] != nil ? $0["Bundle ID"] as? String : nil })
    var ids = Set<String>()
    for entry in entries {
        if let mode = entry["Input Mode"] as? String {
            ids.insert(mode)
        } else if let bundle = entry["Bundle ID"] as? String, !bundlesWithModes.contains(bundle) {
            ids.insert(bundle)
        }
    }
    return ids
}

func isAppleSource(_ id: String) -> Bool { id.hasPrefix("com.apple.") }

func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

/// The top-level dictionary of the plist on stdin; empty stdin gives an empty dictionary
/// when `emptyIsEmptyDict`, else fails.
func readPlistFromStdin(emptyIsEmptyDict: Bool) -> [String: Any] {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    if data.isEmpty {
        if emptyIsEmptyDict { return [:] }
        fail("empty plist on stdin")
    }
    do {
        guard let dict = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            fail("the plist on stdin is not a dictionary")
        }
        return dict
    } catch {
        fail("cannot read the plist on stdin: \(error.localizedDescription)")
    }
}

/// Whether an array entry is a dictionary whose "Bundle ID" the regex matches from its start.
func bundleIDMatcher(_ pattern: String) -> (Any) -> Bool {
    let regex: NSRegularExpression
    do { regex = try NSRegularExpression(pattern: pattern) } catch { fail("invalid regex: \(pattern)", code: 2) }
    return { entry in
        guard let dict = entry as? [String: Any] else { return false }
        let id = dict["Bundle ID"] as? String ?? ""
        return regex.firstMatch(in: id, options: .anchored, range: NSRange(id.startIndex..., in: id)) != nil
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
switch arguments.first {
case "current":
    guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
          let id = stringProperty(source, kTISPropertyInputSourceID) else {
        fail("no current input source")
    }
    print(id)

case "recorded":
    for id in recordedSourceIDs().sorted() { print(id) }

case "enabled":
    let prefix = arguments.count > 1 ? arguments[1] : ""
    let tisIDs = enabledSources()
        .compactMap { stringProperty($0, kTISPropertyInputSourceID) }
        .filter { $0.hasPrefix(prefix) }
    let recorded = recordedSourceIDs()
    // Disagreements: TIS says enabled but the record has no entry, or the record has an
    // entry that TIS does not list as enabled and selectable.
    let onlyTIS = tisIDs.filter { !isAppleSource($0) && !recorded.contains($0) }
    let onlyRecord = recorded.filter { $0.hasPrefix(prefix) && !isAppleSource($0) && !tisIDs.contains($0) }
    if !onlyTIS.isEmpty || !onlyRecord.isEmpty {
        for id in onlyTIS.sorted() {
            FileHandle.standardError.write(Data(("TIS báo \(id) đã bật nhưng com.apple.inputsources › "
                + "AppleEnabledThirdPartyInputSources không có: TIS đọc từ tiến trình mới không đáng tin "
                + "(đo trên macOS 27.2), coi như CHƯA bật.\n").utf8))
        }
        for id in onlyRecord.sorted() {
            FileHandle.standardError.write(Data(("com.apple.inputsources › AppleEnabledThirdPartyInputSources "
                + "ghi \(id) đã bật nhưng TIS không liệt kê là nguồn bật được chọn: không chọn được.\n").utf8))
        }
        exit(4)
    }
    for id in tisIDs { print(id) }

case "select":
    guard arguments.count > 1 else { fail("usage: input-source select <ID>", code: 2) }
    let wanted = arguments[1]
    guard let source = enabledSources().first(where: {
        stringProperty($0, kTISPropertyInputSourceID) == wanted
    }) else {
        fail("\(wanted) is not an enabled, selectable input source; not touching it (N4)")
    }
    if !isAppleSource(wanted) && !recordedSourceIDs().contains(wanted) {
        fail("TIS lists \(wanted) as enabled but com.apple.inputsources › AppleEnabledThirdPartyInputSources "
            + "does not: TIS is not trusted for it; not selecting it", code: 4)
    }
    let status = TISSelectInputSource(source)
    guard status == noErr else { fail("TISSelectInputSource(\(wanted)) failed: \(status)") }

case "count":
    guard arguments.count > 2 else { fail("usage: input-source count <key> <regex>", code: 2) }
    let matches = bundleIDMatcher(arguments[2])
    let plist = readPlistFromStdin(emptyIsEmptyDict: true)
    print((plist[arguments[1]] as? [Any] ?? []).filter(matches).count)

case "drop":
    guard arguments.count > 2 else { fail("usage: input-source drop <key> <regex>", code: 2) }
    let matches = bundleIDMatcher(arguments[2])
    var plist = readPlistFromStdin(emptyIsEmptyDict: false)
    plist[arguments[1]] = (plist[arguments[1]] as? [Any] ?? []).filter { !matches($0) }
    do {
        let out = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        FileHandle.standardOutput.write(out)
    } catch {
        fail("cannot write the plist: \(error.localizedDescription)")
    }

default:
    fail("usage: input-source current | enabled <prefix> | recorded | select <ID> | count <key> <regex> | drop <key> <regex>", code: 2)
}
