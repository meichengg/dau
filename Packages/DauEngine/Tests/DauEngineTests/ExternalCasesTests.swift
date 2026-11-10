import Foundation
import Testing
@testable import DauEngine

/// Step 2 of "test inputs from other Vietnamese input methods"
/// (docs/research/EXTERNAL-TEST-INPUTS.md): replays the key sequences of
/// `docs/research/external-test-inputs/*.tsv` through the engine and checks
/// invariants derived from DECISIONS.md. The other projects' expected outputs are
/// never read (D10); the checks below need no per-case answer.
///
/// Dấu's own output per case goes to `build/external-dau-output/<source>.tsv`
/// (git-ignored) for the comparison in step 3.
@Suite("External cases (blind invariant check)")
struct ExternalCasesTests {

    // MARK: - Case model

    struct ExternalCase {
        var id: String
        var method: String
        var options: [String]
        var keys: String
    }

    struct Failure: Hashable {
        var kind: String
        var detail: String
    }

    struct Result {
        var output: String
        var failures: [Failure]
        var boundaryChecks = 0
        /// D20 reads the harness simulated, and how many of them seeded the engine.
        var d20Reads = 0
        var d20Seeded = 0
        var kinds: [String] { Array(Set(failures.map(\.kind))).sorted() }
    }

    // MARK: - Locating and loading

    static let repoRoot: URL = {
        var url = URL(fileURLWithPath: #filePath)
        for _ in 0..<5 { url.deleteLastPathComponent() }
        return url
    }()

    static func load(_ file: URL) throws -> [ExternalCase] {
        let text = try String(contentsOf: file, encoding: .utf8)
        var cases: [ExternalCase] = []
        var first = true
        for line in text.split(separator: "\n", omittingEmptySubsequences: true) {
            if first { first = false; continue }
            let cols = line.split(separator: "\t", omittingEmptySubsequences: false)
            guard cols.count >= 4 else { continue }
            cases.append(ExternalCase(
                id: String(cols[0]),
                method: String(cols[1]),
                options: cols[2].split(separator: ";").map(String.init),
                keys: String(cols[3])
            ))
        }
        return cases
    }

    /// Maps `method` and the Dấu-side options (docs/research/EXTERNAL-TEST-INPUTS.md 2.2).
    static func engineOptions(_ c: ExternalCase) -> EngineOptions {
        var o = EngineOptions()
        switch c.method {
        case "vni": o.inputMethod = .vni
        case "simple-telex": o.inputMethod = .simpleTelex
        default: o.inputMethod = .telex
        }
        for item in c.options {
            switch item {
            case "tone=classic": o.tonePlacement = .classic
            case "freeMarking=off": o.freeMarking = false
            case "autoRestore=off": o.autoRestore = false
            case "advanced=consonantShortcuts": o.advanced = .consonantShortcuts
            case "advanced=allowZFWJ": o.advanced = .allowZFWJ
            default: break
            }
        }
        return o
    }

    // MARK: - Replay

    /// A text field driven like the IMK layer drives it, but recording errors instead of
    /// trapping when the engine's replacement does not fit the field.
    struct Field {
        var engine: VietEngine
        var text: [Unicode.Scalar] = []
        var failures: [Failure] = []
        var combiningAllowed = false
        var boundaryChecks = 0
        var d20Reads = 0
        var d20Seeded = 0
        /// Mirror of `InPlaceComposer.Before`: false = `.unknown` (the cursor may follow a
        /// word the engine does not know), true = `.noWord`.
        var knownNoWord = false

        mutating func fail(_ kind: String, _ detail: String) {
            if !failures.contains(where: { $0.kind == kind }) {
                failures.append(Failure(kind: kind, detail: detail))
            }
        }

        static func isCombining(_ s: Unicode.Scalar) -> Bool { s.value >= 0x300 && s.value <= 0x36F }

        mutating func apply(_ action: Action, passing key: Unicode.Scalar?) {
            switch action {
            case .passThrough:
                if let key { text.append(key) }
            case .replace(let deleteCount, let insert):
                if deleteCount > text.count {
                    let have = text.count
                    fail("delete-overrun", "engine deleted \(deleteCount) of \(have)")
                    text.removeAll()
                } else {
                    text.removeLast(deleteCount)
                }
                for s in insert {
                    if Field.isCombining(s) && !combiningAllowed {
                        fail("nfc", "combining U+\(String(s.value, radix: 16)) in output (D3)")
                    }
                    text.append(s)
                }
            }
        }
    }

    /// The letters, digits and marks at the end of `text` (`InPlaceComposer.trailingWord`).
    static func trailingWord(_ text: [Unicode.Scalar]) -> [Unicode.Scalar] {
        var word: [Unicode.Scalar] = []
        for scalar in text.reversed() {
            guard CharacterSet.alphanumerics.contains(scalar) else { break }
            word.append(scalar)
        }
        word.reverse()
        return word
    }

    /// `InPlaceComposer.isMarkKey`.
    static func isMarkKey(_ scalar: Unicode.Scalar, method: EngineOptions.InputMethod) -> Bool {
        let v = scalar.value
        switch method {
        case .vni: return v >= 0x30 && v <= 0x39
        case .telex, .simpleTelex:
            guard v < 0x80 else { return false }
            let lower = (v >= 0x41 && v <= 0x5A) ? v + 0x20 : v
            return "sfrxjzaeowd".unicodeScalars.contains { $0.value == lower }
        }
    }

    /// D20 as `InPlaceComposer.addMarks`/`seedWord` do it: a mark key or a plain ASCII
    /// letter (E8) with no word in the engine and an unknown text before the cursor reads
    /// the word before the cursor (16 UTF-16 units), seeds the engine with it and lets the
    /// engine decide, with the three exceptions of D20:
    /// - (b) a word that is not Vietnamese takes the key unchanged, any case: one the
    ///   engine cannot seed (all letters, longer than 7 or unknown) goes to D33's
    ///   pass-through state (`VietEngine.seedOverflow`), one locked by spelling before
    ///   the key stays seeded;
    /// - (a) on a Vietnamese word, an upper-case key after a lower-case letter is not
    ///   seeded ("#Hà" + N), unless a mark key changes the word ("hoc" + J → "học");
    /// - E8: a plain letter on a Vietnamese word joins only if the result is still a
    ///   valid prefix (D30: not locked by spelling, not past D33's length);
    /// - (c) a mark key on a Vietnamese word that passes through and leaves it locked or
    ///   past 7 letters is not seeded ("anh" + e, "tôi" + d); a D26 double key applies.
    /// Returns the engine's action, or nil when the key takes the normal path (nothing
    /// seeded: the engine is reset and the caller handles the key as the first key of a
    /// word).
    /// Not mirrored: the 50 ms rule (`settleInterval`) — typing at normal speed is slower,
    /// so every read counts as settled — and apps that give no text.
    static func d20Seed(_ f: inout Field, key: Unicode.Scalar, letter: Bool) -> Action? {
        f.d20Reads += 1
        let count = min(f.text.count, 16)
        let text = Array(f.text.suffix(count))
        let word = trailingWord(text)
        if word.isEmpty { f.knownNoWord = true; return nil }
        // (b) `InPlaceComposer.continueForeignWord`.
        func foreign() -> Action? {
            f.engine.reset()
            guard word.allSatisfy({ CharacterSet.letters.contains($0) }) else { return nil }
            f.engine.seedOverflow(shown: String(String.UnicodeScalarView(word)).count)
            f.d20Seeded += 1
            return f.engine.handle(key)
        }
        if word.count == text.count && f.text.count > count { return foreign() }
        guard word.allSatisfy({ $0.utf16.count == 1 }), f.engine.seed(displayed: word) else {
            return foreign()
        }
        let lockedBefore = f.engine.isSpellingLocked
        let action = f.engine.handle(key)
        // (a) `InPlaceComposer.startsNewWord`; (b) wins on a locked word.
        if !lockedBefore, Character(key).isUppercase,
           String(String.UnicodeScalarView(word)).last?.isLowercase == true {
            var addsLetter = true
            if !letter, case .replace(let deleteCount, _) = action, deleteCount > 0 { addsLetter = false }
            if addsLetter { f.engine.reset(); return nil }
        }
        let validPrefix = !f.engine.isSpellingLocked && !f.engine.overflow
        if !lockedBefore, !validPrefix {
            if letter {
                // E8: "tôi" + l starts a new word "l" (`InPlaceComposer.isValidPrefix`).
                f.engine.reset()
                return nil
            }
            if case .passThrough = action {
                // (c): "anh" + e, "tôi" + d start a new word.
                f.engine.reset()
                return nil
            }
        }
        f.d20Seeded += 1
        return action
    }

    /// `InPlaceComposer.isLetter`: ASCII letters, any case.
    static func isLetter(_ scalar: Unicode.Scalar) -> Bool {
        let v = scalar.value
        return (v >= 0x41 && v <= 0x5A) || (v >= 0x61 && v <= 0x7A)
    }

    static func isBoundaryKey(_ v: UInt32) -> Bool {
        if v < 0x20 && v != 0x09 && v != 0x0A && v != 0x0D { return false }
        if v == 0x7F || (v >= 0xF700 && v <= 0xF8FF) { return false }
        return Letters.decompose(v) == nil
    }

    static func validSyllable(_ scalars: ArraySlice<Unicode.Scalar>, allowZFWJ: Bool) -> Bool {
        var e = VietEngine()
        guard e.seed(displayed: scalars) else { return false }
        return Spelling.check(e.word, .full, allowZFWJ: allowZFWJ)
    }

    static func replay(_ c: ExternalCase) -> Result {
        let options = engineOptions(c)
        var f = Field(engine: VietEngine(options: options))
        let allowZFWJ = options.advanced == .allowZFWJ
        let shortcuts = options.advanced == .consonantShortcuts
        var after: [Unicode.Scalar] = []

        var scalars = Array(c.keys.unicodeScalars)
        f.combiningAllowed = scalars.contains(where: Field.isCombining)

        // ⟦before|after⟧ prefix (D20).
        if scalars.first == "⟦", let close = scalars.firstIndex(of: "⟧") {
            let inner = Array(scalars[1..<close])
            scalars.removeSubrange(0...close)
            var before = inner
            if let bar = inner.firstIndex(of: "|") {
                before = Array(inner[..<bar])
                after = Array(inner[(bar + 1)...])
            }
            // Text already in the field: the engine does not know it; the first mark key
            // or letter reads it (D20, E8), and only the last word before the cursor.
            f.text.append(contentsOf: before)
        }

        for key in scalars {
            let pre = f.engine
            let preText = f.text
            var boundary = false
            var plainKey: Unicode.Scalar = key
            switch key {
            case "⌫":
                let action = f.engine.backspace()
                defer { if !f.engine.isComposing { f.knownNoWord = false } }
                if case .passThrough = action {
                    if !f.text.isEmpty { f.text.removeLast() }
                } else {
                    f.apply(action, passing: nil)
                }
            case "←", "⎋":
                f.engine.reset()
                f.knownNoWord = false
                if f.engine.isComposing { f.fail("reset-composing", "reset left the engine composing (D4)") }
            case "⏎":
                boundary = true
                f.apply(f.engine.endWord(), passing: nil)
                f.engine.reset()
                f.knownNoWord = false
                f.text.append("\n")
                plainKey = "\n"
            case "⇥":
                boundary = true
                f.apply(f.engine.endWord(), passing: nil)
                f.engine.reset()
                f.knownNoWord = false
                f.text.append("\t")
                plainKey = "\t"
            default:
                if key == "␣" { plainKey = " " }
                boundary = isBoundaryKey(plainKey.value)
                var action: Action?
                let mark = isMarkKey(plainKey, method: options.inputMethod)
                if !f.engine.isComposing, !f.knownNoWord, mark || isLetter(plainKey) {
                    action = d20Seed(&f, key: plainKey, letter: !mark)
                    if action == nil { f.engine.reset() }
                }
                f.apply(action ?? f.engine.handle(plainKey), passing: plainKey)
                if !f.engine.isComposing { f.knownNoWord = true }
            }

            // D33: after overflow every key passes through unchanged until the word ends.
            if pre.overflow && key != "⌫" && key != "←" && key != "⎋" {
                if f.text != preText + [plainKey] {
                    f.fail("overflow-passthrough", "key changed text after D33 overflow")
                }
                continue
            }

            if boundary && pre.word.count > 0 && !pre.overflow {
                let start = preText.count - pre.screen.count
                let end = f.text.count - 1
                if start >= 0 && end >= start && f.text.count >= preText.count - pre.screen.count + 1 {
                    let word = f.text[start..<end]
                    f.boundaryChecks += 1
                    let raw = Array(pre.raw)
                    let shown = Array(pre.screen)
                    if !shortcuts {
                        let preValid = Spelling.check(pre.word, .full, allowZFWJ: allowZFWJ)
                        if preValid && Array(word) != shown {
                            f.fail("boundary-valid-changed",
                                   "valid \(pre.screen) became \(String(String.UnicodeScalarView(word))) (D4/D31)")
                        } else if !preValid && !options.autoRestore && Array(word) != shown {
                            f.fail("boundary-off-changed",
                                   "autoRestore off but \(pre.screen) became \(String(String.UnicodeScalarView(word))) (D4/D30)")
                        }
                    }
                    if options.autoRestore {
                        let valid = validSyllable(word, allowZFWJ: allowZFWJ)
                        if !valid && Array(word) != raw {
                            f.fail("boundary-restore",
                                   "word \(String(String.UnicodeScalarView(word))) neither valid (D31) nor the keys since the restore point \(String(String.UnicodeScalarView(raw))) (D4)")
                        }
                    }
                } else {
                    f.fail("field-mismatch", "word region outside the field at a boundary (D4)")
                }
            } else if !boundary && key != "⌫" && key != "←" && key != "⎋" {
                // D26/D30: a locked word takes letters verbatim.
                if pre.word.count > 0 && !pre.overflow && pre.isLocked && !f.engine.overflow
                    && Letters.decompose(plainKey.value) != nil
                    && f.text != preText + [plainKey] {
                    f.fail("locked-literal", "locked word (D26/D30) changed on key \(plainKey)")
                }
            }

            // The engine's idea of the word must be the tail of the field (D4, N3).
            if !boundary && f.engine.isComposing && !f.engine.overflow {
                let shown = Array(f.engine.screen)
                if shown.count > f.text.count || Array(f.text.suffix(shown.count)) != shown {
                    let tail = String(String.UnicodeScalarView(f.text.suffix(8)))
                    f.fail("field-mismatch", "engine shows \(shown.count) scalars but the field ends with \(tail)")
                }
            }
        }

        // D3: output is NFC (decomposed input is the exception: it is the input's doing).
        if !f.combiningAllowed {
            var view = String.UnicodeScalarView()
            view.append(contentsOf: f.text)
            let s = String(view)
            if Array(s.precomposedStringWithCanonicalMapping.unicodeScalars) != f.text {
                f.fail("nfc", "output is not NFC (D3)")
            }
        }

        var out = String.UnicodeScalarView()
        out.append(contentsOf: f.text)
        out.append(contentsOf: after)
        let shown = String(out)
            .replacingOccurrences(of: " ", with: "␣")
            .replacingOccurrences(of: "\n", with: "⏎")
            .replacingOccurrences(of: "\t", with: "⇥")
        return Result(output: shown, failures: f.failures, boundaryChecks: f.boundaryChecks,
                      d20Reads: f.d20Reads, d20Seeded: f.d20Seeded)
    }

    // MARK: - Checker self-test

    @Test func checkerSanity() {
        func word(_ s: String) -> ArraySlice<Unicode.Scalar> { Array(s.unicodeScalars)[...] }
        #expect(Self.validSyllable(word("cả"), allowZFWJ: false))
        #expect(Self.validSyllable(word("Việt"), allowZFWJ: false))
        #expect(!Self.validSyllable(word("car"), allowZFWJ: false))
        #expect(!Self.validSyllable(word("hòc"), allowZFWJ: false))
        #expect(!Self.validSyllable(word("windows"), allowZFWJ: false))
        #expect(Self.isBoundaryKey(0x2C) && Self.isBoundaryKey(0x20) && !Self.isBoundaryKey(0x61))
        // The replay itself: "car " restores nothing (cả), "carr " gives "car ", "tesst " gives "test ".
        func run(_ keys: String) -> Result { Self.replay(ExternalCase(id: "t", method: "telex", options: [], keys: keys)) }
        #expect(run("car␣").output == "cả␣" && run("car␣").boundaryChecks == 1)
        #expect(run("carr␣").output == "car␣" && run("carr␣").failures.isEmpty)
        #expect(run("tesst␣").output == "test␣" && run("tesst␣").failures.isEmpty)
        #expect(run("⟦cả⟧r␣").output == "car␣")
        // D20 after ⌫ over a space, Return, a reset-only key; only the last word is read.
        #expect(run("du␣⌫j").output == "dụ" && run("du␣⌫j").d20Seeded == 1)
        #expect(run("tooi←s").output == "tối")
        #expect(run("du⏎j").output == "du⏎j" && run("du⏎j").d20Reads == 2)
        #expect(run("⟦ngả nghieng⟧e").output == "ngả␣nghiêng")
        #expect(run("viet␣⌫j").output == "vietj")
        // Only the first key of the field reads (E8: a letter too); a mark key after a
        // word end typed here does not.
        #expect(run("hoc,a").d20Reads == 1)
        // E8: a plain letter reads too, and joins only a valid prefix.
        #expect(run("⟦q⟧uer␣").output == "quẻ␣" && run("⟦q⟧uer␣").d20Seeded == 1)
        #expect(run("ba␣⌫nj␣").output == "bạn␣")
        #expect(run("⟦tôi⟧laf␣").output == "tôilà␣" && run("⟦tôi⟧laf␣").d20Seeded == 0)
        #expect(run("ddi␣⌫hocj␣").output == "đihọc␣")
        #expect(run("⟦nghiêng⟧bans␣").output == "nghiêngbán␣")
        // D20's three exceptions: (a) upper case after lower case starts a new word…
        #expect(run("⟦#Hà⟧Nooij␣").output == "#HàNội␣" && run("⟦#Hà⟧Nooij␣").d20Seeded == 0)
        #expect(run("⟦VI⟧EEJT␣").output == "VIỆT␣" && run("⟦V⟧ieejt␣").output == "Việt␣")
        // …unless a mark key changes the word, and not after a foreign word (b wins).
        #expect(run("⟦hoc⟧J␣").output == "học␣" && run("⟦hoc⟧J␣").d20Seeded == 1)
        #expect(run("⟦foo⟧Bar␣").output == "fooBar␣" && run("⟦keyboard⟧Bar␣").output == "keyboardBar␣")
        // …(b) a foreign word takes the letters unchanged until it ends…
        #expect(run("⟦foo⟧bar␣").output == "foobar␣" && run("⟦foo⟧bar␣").failures.isEmpty)
        #expect(run("⟦keyboard⟧bar␣").output == "keyboardbar␣" && run("⟦keyboard⟧bar␣").failures.isEmpty)
        #expect(run("⟦iPhone⟧mowis␣").output == "iPhonemowis␣")
        #expect(run("⟦car⟧s␣").output == "cars␣")
        // …(c) a mark key that does not apply starts a new word; a double key applies.
        #expect(run("⟦anh⟧emx␣").output == "anhẽm␣" && run("⟦tôi⟧ddi␣").output == "tôiđi␣")
        #expect(run("⟦ba⟧ef␣").output == "baè␣" && run("⟦cả⟧r␣").output == "car␣")
        #expect(run("⟦viet⟧j␣").output == "vietj␣" && run("⟦hoc⟧f␣").output == "hocf␣")
        // Remaining limit: a new word that starts like a valid continuation still joins.
        #expect(run("⟦#hà⟧nooij␣").output == "#hànooij␣" && run("⟦ba⟧nawm␣").output == "banawm␣")
    }

    // MARK: - The test

    @Test func externalCases() throws {
        let started = Date()
        let dir = Self.repoRoot.appendingPathComponent("docs/research/external-test-inputs")
        let outDir = Self.repoRoot.appendingPathComponent("build/external-dau-output")
        try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)
        let files = try FileManager.default.contentsOfDirectory(atPath: dir.path)
            .filter { $0.hasSuffix(".tsv") }.sorted()
        #expect(!files.isEmpty)

        var total = 0
        var asserted = 0
        var skippedBySrc: [String: Int] = [:]
        var skippedCases = 0
        var failuresByKind: [String: Int] = [:]
        var failuresBySource: [String: [String: Int]] = [:]
        var examples: [String: [(String, String, String, String)]] = [:]
        var newFailures: [String] = []
        var boundaryChecks = 0
        var d20Reads = 0
        var d20Seeded = 0
        var d20Cases = 0
        var found = Set<String>()

        for file in files {
            let source = String(file.dropLast(4))
            let cases = try Self.load(dir.appendingPathComponent(file))
            var rows = "id\tdau_output\tinvariant_result\n"
            for c in cases {
                total += 1
                let result = Self.replay(c)
                boundaryChecks += result.boundaryChecks
                d20Reads += result.d20Reads
                d20Seeded += result.d20Seeded
                if result.d20Seeded > 0 { d20Cases += 1 }
                let srcOptions = c.options.filter { $0.hasPrefix("src:") }
                let kinds = result.kinds
                var status = kinds.isEmpty ? "ok" : "fail:" + kinds.joined(separator: ",")
                if srcOptions.isEmpty {
                    asserted += 1
                    for f in result.failures {
                        let key = "\(c.id)\t\(f.kind)"
                        found.insert(key)
                        failuresByKind[f.kind, default: 0] += 1
                        failuresBySource[source, default: [:]][f.kind, default: 0] += 1
                        if examples[f.kind, default: []].filter({ $0.0 == source }).count < 3 {
                            examples[f.kind, default: []].append((source, c.id, c.keys, result.output + "  // " + f.detail))
                        }
                        if !externalKnownFailures.contains(key) { newFailures.append(key) }
                    }
                } else {
                    skippedCases += 1
                    for o in srcOptions { skippedBySrc[o, default: 0] += 1 }
                    status = "skipped(\(srcOptions.joined(separator: "+"))):" + status
                }
                rows += "\(c.id)\t\(result.output)\t\(status)\n"
            }
            try rows.write(to: outDir.appendingPathComponent(file), atomically: true, encoding: .utf8)
        }

        var report = "EXTERNAL CASES: \(total) read, \(asserted) asserted, \(skippedCases) skipped (src: option; run, not asserted)\n"
        for (o, n) in skippedBySrc.sorted(by: { $0.key < $1.key }) { report += "  skipped by \(o): \(n)\n" }
        report += "  word-boundary checks executed (all cases): \(boundaryChecks)\n"
        report += "  D20 reads simulated: \(d20Reads), seeded: \(d20Seeded), cases with a seed: \(d20Cases)\n"
        report += "  failures by kind (asserted cases): \(failuresByKind.sorted { $0.key < $1.key })\n"
        for (s, m) in failuresBySource.sorted(by: { $0.key < $1.key }) { report += "  \(s): \(m.sorted { $0.key < $1.key })\n" }
        for (k, list) in examples.sorted(by: { $0.key < $1.key }) {
            report += "  [\(k)]\n"
            for e in list { report += "    \(e.1)  keys=\(e.2)  dau=\(e.3)\n" }
        }
        let stale = externalKnownFailures.subtracting(found)
        report += "  new failures: \(newFailures.count); recorded but now passing: \(stale.count); elapsed \(Date().timeIntervalSince(started)) s\n"
        print(report)
        if ProcessInfo.processInfo.environment["DAU_EXTERNAL_DUMP"] != nil {
            try found.sorted().joined(separator: "\n").write(
                to: outDir.appendingPathComponent("known-failures.txt"), atomically: true, encoding: .utf8)
        }

        #expect(newFailures.isEmpty, "new invariant failures: \(newFailures.prefix(20))")
    }
}
