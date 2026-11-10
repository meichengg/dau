// Checks 3b and 10 of scripts/check-docs/check.sh, which builds this file once with
// scripts/lib/swift-tool.sh. Run from the repo root.
//
//   doc-check names FILE...   the first citation of each principle or decision carries its name
//   doc-check flags FILE...   every option a document cites for a script exists in that script
//
// names: docs/DECISIONS.md defines names as "- **D4. Từ nước ngoài.**". In any other
// document, the first time "D4" appears it must read "D4 (Từ nước ngoài)", so a reader knows
// what D4 is without opening DECISIONS.md; later citations in the same file may be bare.
// Text inside backticks is skipped (code, paths), and so are ranges ("N1–N5", "D1–D…").
// Prints one line per problem: FILE<TAB>number<TAB>what it found.
//
// flags: looks at code spans (text in backticks) that name a script, by path
// ("scripts/dev/x.sh") or by file name alone ("x.sh", when only one script has that name),
// and at every option in the same span ("--release", "--keys=…"). The option must appear in
// the script's own text (its usage header or its argument parsing). Prints one line per
// problem: FILE<TAB>script<TAB>option.
//
// Exit status 0 when the checks ran (problems or not), 1 on an unreadable file, 2 on bad usage.
import Foundation

func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

/// The file as UTF-8 text, with "\r\n" and "\r" read as "\n".
func readText(_ path: String) -> String {
    guard let data = FileManager.default.contents(atPath: path),
          let text = String(data: data, encoding: .utf8) else { fail("Không đọc được \(path)") }
    return text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
}

func regex(_ pattern: String, _ options: NSRegularExpression.Options = []) -> NSRegularExpression {
    // The patterns are literals: a bad one is a bug in this file.
    try! NSRegularExpression(pattern: pattern, options: options)
}

extension NSString {
    func group(_ match: NSTextCheckingResult, _ index: Int) -> String { substring(with: match.range(at: index)) }
}

/// Exact comparison, code point by code point (String == treats canonically equivalent
/// strings as equal).
func same(_ a: Substring, _ b: String) -> Bool { a.unicodeScalars.elementsEqual(b.unicodeScalars) }

// MARK: names

func checkNames(_ files: [String]) {
    let definition = regex(#"^- \*\*([DN]\d+)\. (.+?)\.\*\*"#, .anchorsMatchLines)
    let citation = regex(#"(?<![\w/.\-–])([DN]\d{1,2})(?![\w–])"#)
    let code = regex("`[^`\n]*`")

    let decisions = readText("docs/DECISIONS.md") as NSString
    var known: [String: String] = [:]
    for m in definition.matches(in: decisions as String, range: NSRange(location: 0, length: decisions.length)) {
        known[decisions.group(m, 1)] = decisions.group(m, 2)
    }

    for path in files {
        // Blank out code spans, keeping offsets.
        let raw = readText(path) as NSString
        let blanked = NSMutableString(string: raw)
        // One space per code point (not per UTF-16 unit), last span first.
        for m in code.matches(in: raw as String, range: NSRange(location: 0, length: raw.length)).reversed() {
            let width = raw.group(m, 0).unicodeScalars.count
            blanked.replaceCharacters(in: m.range, with: String(repeating: " ", count: width))
        }
        let text = blanked as String
        var seen = Set<String>()
        for m in citation.matches(in: text, range: NSRange(location: 0, length: blanked.length)) {
            let number = blanked.group(m, 1)
            guard !seen.contains(number), let name = known[number] else { continue }
            seen.insert(number)
            let expected = " (\(name))"
            let range = Range(m.range, in: text)!
            let scalars = text.unicodeScalars
            let afterEnd = scalars.index(range.upperBound, offsetBy: expected.unicodeScalars.count, limitedBy: scalars.endIndex) ?? scalars.endIndex
            if !same(text[range.upperBound..<afterEnd], expected) {
                let snippetEnd = scalars.index(range.upperBound, offsetBy: 40, limitedBy: scalars.endIndex) ?? scalars.endIndex
                let snippet = text[range.lowerBound..<snippetEnd].split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)[0]
                print("\(path)\t\(number)\t\(snippet)")
            }
        }
    }
}

// MARK: flags

func checkFlags(_ files: [String]) {
    let span = regex("`([^`\n]+)`")
    let script = regex(#"(?:^|[\s/])((?:scripts/)?[\w./-]*?([\w-]+\.sh))(?=\s|$)"#)
    let option = regex(#"(?<![\w-])(--[a-z][a-z0-9-]*)"#)

    // Every scripts/**/*.sh outside .build folders, plus the hook.
    var byPath: [String: String] = [:]
    if let walker = FileManager.default.enumerator(atPath: "scripts") {
        while let relative = walker.nextObject() as? String {
            let name = (relative as NSString).lastPathComponent
            if name == ".build" { walker.skipDescendants(); continue }
            if name.hasSuffix(".sh") { byPath["scripts/" + relative] = "scripts/" + relative }
        }
    }
    byPath[".claude/hooks/guard-scripts.sh"] = ".claude/hooks/guard-scripts.sh"
    var byName: [String: [String]] = [:]
    for path in byPath.keys { byName[(path as NSString).lastPathComponent, default: []].append(path) }

    var texts: [String: String] = [:]
    for doc in files {
        let docText = readText(doc) as NSString
        for s in span.matches(in: docText as String, range: NSRange(location: 0, length: docText.length)) {
            let spanText = docText.group(s, 1) as NSString
            guard let m = script.firstMatch(in: spanText as String, range: NSRange(location: 0, length: spanText.length)) else { continue }
            let cited = spanText.group(m, 1), name = spanText.group(m, 2)
            var target = byPath[String(cited.drop(while: { $0 == "." || $0 == "/" }))]
            if target == nil {
                let found = byName[name] ?? []
                guard found.count == 1 else { continue } // unknown or ambiguous: check 1 reports missing paths
                target = found[0]
            }
            let path = target!
            if texts[path] == nil { texts[path] = readText(path) }
            let rest = spanText.substring(from: NSMaxRange(m.range)) as NSString
            for o in option.matches(in: rest as String, range: NSRange(location: 0, length: rest.length)) {
                let flag = rest.group(o, 1)
                if texts[path]!.range(of: flag, options: .literal) == nil {
                    print("\(doc)\t\(path)\t\(flag)")
                }
            }
        }
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
switch arguments.first {
case "names"?: checkNames(Array(arguments.dropFirst()))
case "flags"?: checkFlags(Array(arguments.dropFirst()))
default: fail("Cách dùng: doc-check names|flags FILE...", code: 2)
}
