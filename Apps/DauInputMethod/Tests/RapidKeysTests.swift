import Foundation
import DauEngine
import DauShared
import Testing

/// How an app applies keys, for the simulation of keys that come in a burst (M6). The
/// cache and replacement behaviour of each model comes from the app's source
/// (`LateDocument`); the times are not measured: they are chosen so the code from
/// before M6 fails where M3 measured it fail (`docs/COMPATIBILITY.md` 5: Chrome at 0 ms
/// only, VS Code and Firefox at 0 and 5 ms, every app right from 20 ms).
struct AppModel: CustomStringConvertible {
    var name: String
    var cache: LateDocument.Cache
    var replace: LateDocument.Replace
    /// Milliseconds the app takes to apply one edit, uniform in this range.
    var work: ClosedRange<Double>
    /// Now and then the app stops for a while (garbage collection, layout, a busy
    /// page): chance per edit and milliseconds.
    var stall: (chance: Double, ms: Double) = (0, 0)
    var description: String { name }

    /// Chromium text field: browser-side cache, caret kept after a replaced range.
    static let chrome = AppModel(name: "chrome", cache: .chromium, replace: .keepSelection, work: 0.2...2.0)
    /// VS Code: Chromium's cache, EditContext (caret to the end of a replacement), a
    /// slower page.
    static let vscode = AppModel(name: "vscode", cache: .chromium, replace: .caretAfterText, work: 1.0...7.0)
    /// Firefox: a snapshot of the content process, caret to the end of a replacement.
    static let firefox = AppModel(name: "firefox", cache: .snapshot, replace: .caretAfterText, work: 1.0...6.0)
    /// Chrome with stalls of 40 ms on 5% of the edits (not calibrated: a stress test).
    static let busy = AppModel(name: "busy", cache: .chromium, replace: .keepSelection, work: 0.5...3.0,
                               stall: (0.05, 40))

    static let all = [chrome, vscode, firefox, busy]
}

/// Keys → composer → `LateDocument` with timed answers. The keys reach the app at
/// `arrival`; the app's main thread handles one key at a time (the input method's calls
/// included), so a key may be handled later than it arrived; the event's own time is
/// what the composer sees (`NSEvent.timestamp`).
struct RapidSession {
    var engine: VietEngine
    var composer = InPlaceComposer()
    let doc: LateDocument
    var kinds: [PerfLog.Kind] = []
    /// Keys with more than one call of a kind (must stay 0, N3).
    var overCalls = 0
    /// Reads (`attributedSubstring`) over the whole run.
    var reads = 0
    /// The longest `composer.handle` took, in seconds (this test build, not the app).
    var slowest: Duration = .zero
    private var free: TimeInterval = 0
    private let timed: Bool

    /// `model` nil: an app that is always up to date (the reference).
    init(_ model: AppModel?, seed: UInt64 = 0, settings: DauSettings = .defaults) {
        engine = VietEngine(options: settings.engineOptions)
        composer.addMarksEnabled = settings.addMarksToTypedWords
        doc = LateDocument()
        timed = model != nil
        if let model {
            doc.cache = model.cache
            doc.replace = model.replace
            doc.clock = 0
            doc.reportDelay = 0.0003
            var rng = SplitMix(seed &* 7919 &+ 17)
            doc.work = {
                var ms = rng.uniform(model.work.lowerBound, model.work.upperBound)
                if model.stall.chance > 0, rng.uniform(0, 1) < model.stall.chance { ms += model.stall.ms }
                return ms / 1000
            }
        }
    }

    mutating func key(_ route: KeyRoute, at arrival: TimeInterval) {
        let start = max(arrival, free)
        if timed { doc.clock = start }
        doc.sentAt = start
        doc.selections = 0; doc.reads = 0; doc.inserts = 0
        var outcome = InPlaceComposer.Outcome()
        let took = ContinuousClock().measure {
            outcome = composer.handle(route, time: arrival, engine: &engine, client: doc)
        }
        slowest = max(slowest, took)
        if doc.selections > 1 || doc.reads > 1 || doc.inserts > 1 { overCalls += 1 }
        reads += doc.reads
        kinds.append(outcome.kind)
        // Costs of the calls, medians measured in M2/M3 (Debug; COMPATIBILITY.md 5,
        // DECISIONS.md D20): selectedRange 0.3 ms, attributedSubstring 0.8 ms (Chrome,
        // VS Code), insertText 0.6 ms; the rest of a key 0.3 ms.
        let end = start + 0.0003 + Double(doc.selections) * 0.0003 + Double(doc.reads) * 0.0008
            + Double(doc.inserts) * 0.0006
        if !outcome.consumed {
            doc.sentAt = end
            doc.typed(route)
        }
        free = end
    }

    mutating func type(_ keys: [KeyRoute], at times: [TimeInterval]) {
        for (route, time) in zip(keys, times) { key(route, at: time) }
    }
}

/// `⌫` Backspace; anything else is a character.
func routes(_ keys: String) -> [KeyRoute] {
    keys.unicodeScalars.map { $0 == "⌫" ? .backspace : .character($0) }
}

/// Arrival times of `count` keys `ms` apart (± `jitter` ms, never below 0.5 ms). 0 ms is
/// one System Events `keystroke` of the whole string, about 1 ms per key
/// (`scripts/selftest/typing/run.sh`, `--delay`).
func arrivals(_ count: Int, ms: Double, jitter: Double, seed: UInt64) -> [TimeInterval] {
    var rng = SplitMix(seed &* 104_729 &+ 3)
    var t = 0.0
    var times: [TimeInterval] = []
    let pace = ms == 0 ? 1.0 : ms
    for _ in 0..<count {
        t += max(0.5, pace + rng.uniform(-jitter, jitter)) / 1000
        times.append(t)
    }
    return times
}

@Suite("In-place mode with keys in a burst (M6: keys under 50 ms apart in Chrome, VS Code, Firefox)")
struct RapidKeysTests {
    static let strings = [("edit", LateAnswerTests.editKeys), ("std", LateAnswerTests.stdKeys)]
    static let speeds: [Double] = [0, 5, 10, 20]
    static let seeds = 40

    struct Run {
        var ok: Bool
        var behind: Int
        var overCalls: Int
        var badRanges: Int
        var text: String
        var reference: String
        var kinds: [PerfLog.Kind]
        var reads: Int
        var slowest: Duration
    }

    static func simulate(_ keys: String, _ model: AppModel, ms: Double, seed: UInt64) -> Run {
        let keyRoutes = routes(keys)
        let times = arrivals(keyRoutes.count, ms: ms, jitter: ms == 0 ? 0.3 : 1, seed: seed)
        var reference = RapidSession(nil)
        reference.type(keyRoutes, at: times)
        var s = RapidSession(model, seed: seed)
        s.type(keyRoutes, at: times)
        return Run(ok: s.doc.text == reference.doc.text, behind: s.doc.maxBehind, overCalls: s.overCalls,
                   badRanges: s.doc.badRanges, text: s.doc.text, reference: reference.doc.text,
                   kinds: s.kinds, reads: s.reads, slowest: s.slowest)
    }

    /// Every app model × speed × string over `seeds` seeds, against an app that is always
    /// up to date given the same keys at the same times (at these speeds D20 and the D11
    /// re-read do not apply: "Hoc ⌫j" gives "Hocj" there too). Must match at 5, 10, 20 ms
    /// for Chrome, VS Code, Firefox; 0 ms and `busy` are printed only (the table of the
    /// M6 report, lines starting with RAPID).
    @Test("load-test strings at 5, 10, 20 ms in Chrome, VS Code, Firefox models, many seeds: same text as an app that is up to date")
    func burstTable() {
        var lines: [String] = []
        var failures = 0
        for model in AppModel.all {
            for ms in Self.speeds {
                var cells: [String] = []
                for (name, keys) in Self.strings {
                    var wrong = 0, behind = 0, over = 0, bad = 0, late = 0, guess = 0, mismatch = 0, reads = 0, keyCount = 0
                    var slowest: Duration = .zero
                    var example: Run?
                    for seed in 1...UInt64(Self.seeds) {
                        let run = Self.simulate(keys, model, ms: ms, seed: seed)
                        if !run.ok { wrong += 1; if example == nil { example = run } }
                        behind = max(behind, run.behind)
                        over += run.overCalls
                        bad += run.badRanges
                        late += run.kinds.filter { $0 == .late }.count
                        guess += run.kinds.filter { $0 == .lateGuess }.count
                        mismatch += run.kinds.filter { $0 == .mismatch }.count
                        reads += run.reads
                        keyCount += run.kinds.count
                        slowest = max(slowest, run.slowest)
                    }
                    // Pass criterion (D13: typing speed of a person, M6): the calibrated models
                    // at 5, 10, 20 ms. 0 ms (a machine sending the whole string) and the
                    // uncalibrated `busy` model are recorded only. N3 and ranges always.
                    failures += over + bad + (ms > 0 && model.name != AppModel.busy.name ? wrong : 0)
                    let n = Self.seeds
                    let slowMs = Double(slowest.components.attoseconds) / 1e15 + Double(slowest.components.seconds) * 1000
                    cells.append("\(name) \(wrong)/\(n) wrong, behind ≤ \(behind), late \(late / n), guess \(guess / n), "
                        + "mismatch \(mismatch / n), reads/key \(String(format: "%.2f", Double(reads) / Double(keyCount))), "
                        + "slowest \(String(format: "%.2f", slowMs)) ms, over \(over), bad \(bad)")
                    if let example {
                        lines.append("  e.g. \(model) \(Int(ms)) ms \(name): \(example.text.suffix(60)) ≠ \(example.reference.suffix(60))")
                    }
                }
                lines.append("RAPID \(model) \(Int(ms)) ms: " + cells.joined(separator: "; "))
            }
        }
        print(lines.joined(separator: "\n"))
        #expect(failures == 0)
    }

    // MARK: Words in a burst, answers a fixed number of edits late

    /// Keys 5 ms apart (under `InPlaceComposer.settleInterval`), each answer `lag` edits
    /// behind: the first replacement of each word must not take the stale caret, and a
    /// replacement inside a word must not reset it.
    @Test("words in a burst, every answer 2 or 4 edits late, each app's cache and caret behaviour",
          arguments: [LateDocument.Cache.snapshot, .chromium], [LateDocument.Replace.keepSelection, .caretAfterText])
    func burstWords(_ cache: LateDocument.Cache, _ replace: LateDocument.Replace) {
        for lag in [2, 4] {
            let doc = LateDocument()
            doc.cache = cache
            doc.replace = replace
            var engine = VietEngine(options: DauSettings.defaults.engineOptions)
            var composer = InPlaceComposer()
            var now = 0.0
            var over = 0
            for route in routes("nguoiwf banj guiwr email hoir veef deadline. ") {
                now += 0.005
                doc.lag = lag
                doc.selections = 0; doc.reads = 0; doc.inserts = 0
                let outcome = composer.handle(route, time: now, engine: &engine, client: doc)
                if doc.selections > 1 || doc.reads > 1 || doc.inserts > 1 { over += 1 }
                if !outcome.consumed { doc.typed(route) }
            }
            #expect(doc.text == "người bạn gửi email hỏi về deadline. ", "lag \(lag)")
            #expect(doc.badRanges == 0)
            #expect(over == 0)
        }
    }

    // MARK: Caret after a replacement

    /// VS Code and Firefox put the caret at the end of a replaced range. A replacement
    /// at the followed position that leaves the unchanged end of the word out of the
    /// range would put the caret before that end, and the next key would land inside
    /// the word.
    @Test("late answer at 100 ms in an app that moves the caret to the end of a replacement: the next key goes after the word")
    func caretAfterReplacement() {
        let doc = LateDocument()
        doc.replace = .caretAfterText
        var engine = VietEngine(options: DauSettings.defaults.engineOptions)
        var composer = InPlaceComposer()
        var now = 0.0
        func type(_ keys: String, lag: Int) {
            for route in routes(keys) {
                now += 0.1
                doc.lag = lag
                let outcome = composer.handle(route, time: now, engine: &engine, client: doc)
                if !outcome.consumed { doc.typed(route) }
            }
        }
        type("nguoiwf ban", lag: 0)
        type("j", lag: 1)
        type(" guiwr", lag: 0)
        #expect(doc.text == "người bạn gửi")
        #expect(doc.badRanges == 0)
    }

    // MARK: What a burst must not change

    /// An app that edits the text at a word boundary (a smart dash) while the keys come in
    /// a burst: its answer is believed, not taken for a late one, as at a human pace
    /// (`LateAnswerTests.shortenedByApp`).
    @Test("text shortened by the app at a word boundary while keys come 5 ms apart: the answer is believed")
    func shortenedByAppInBurst() {
        let doc = LateDocument()
        var engine = VietEngine(options: DauSettings.defaults.engineOptions)
        var composer = InPlaceComposer()
        var now = 0.0
        var kinds: [PerfLog.Kind] = []
        func type(_ keys: String) {
            for route in routes(keys) {
                now += 0.005
                let outcome = composer.handle(route, time: now, engine: &engine, client: doc)
                kinds.append(outcome.kind)
                if !outcome.consumed { doc.typed(route) }
            }
        }
        type("a -- ")
        doc.appEdit("a — ")
        type("vieetj ")
        #expect(doc.text == "a — việt ")
        #expect(!kinds.contains(.late) && !kinds.contains(.lateGuess))
        #expect(doc.badRanges == 0)
    }

    /// Past `CursorTracker.lateLimit`, a late answer must also show the text this
    /// composer typed before the edits the app is missing. An app whose caret is where
    /// this composer was some edits ago, but with other text before it, is not taken for
    /// late, however long the burst.
    @Test("an answer three edits behind in a burst, other text before it: not late")
    func farBehindOtherText() {
        let doc = LateDocument()
        var engine = VietEngine(options: DauSettings.defaults.engineOptions)
        var composer = InPlaceComposer()
        var now = 0.0
        for route in routes("xin chao ban") {
            now += 0.005
            let outcome = composer.handle(route, time: now, engine: &engine, client: doc)
            if !outcome.consumed { doc.typed(route) }
        }
        // Caret 9 (before "ban", three edits ago), but not "xin chao " before it.
        doc.override = "abc defg "
        now += 0.005
        let outcome = composer.handle(.character("j"), time: now, engine: &engine, client: doc)
        // The first replacement of a word: the answer stands (D11), as before M6.
        #expect(outcome.kind == .replace)
        // The same answer with the text that was typed there: late.
        var engine2 = VietEngine(options: DauSettings.defaults.engineOptions)
        var composer2 = InPlaceComposer()
        let doc2 = LateDocument()
        now = 0
        for route in routes("xin chao ban") {
            now += 0.005
            let outcome = composer2.handle(route, time: now, engine: &engine2, client: doc2)
            if !outcome.consumed { doc2.typed(route) }
        }
        doc2.lag = 3
        now += 0.005
        #expect(composer2.handle(.character("j"), time: now, engine: &engine2, client: doc2).kind == .late)
        #expect(doc2.text == "xin chao bạn")
    }
}
