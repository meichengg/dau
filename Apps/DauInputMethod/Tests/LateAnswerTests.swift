import Foundation
import DauEngine
import DauShared
import Testing

/// Keys → composer → `LateDocument`, 100 ms apart (the 1b run: 100 ± 30 ms, so every key
/// is past `InPlaceComposer.settleInterval`).
private struct LateSession {
    var engine: VietEngine
    var composer = InPlaceComposer()
    let doc: LateDocument
    var interval: TimeInterval = 0.1
    var now: TimeInterval = 0
    var kinds: [PerfLog.Kind] = []
    /// Keys with more than one call of a kind (must stay 0, N3).
    var overCalls = 0

    init(_ text: String = "", settings: DauSettings = .defaults) {
        engine = VietEngine(options: settings.engineOptions)
        composer.addMarksEnabled = settings.addMarksToTypedWords
        doc = LateDocument(text)
    }

    mutating func key(_ route: KeyRoute, lag: Int) {
        now += interval
        doc.lag = lag
        doc.selections = 0; doc.reads = 0; doc.inserts = 0
        let outcome = composer.handle(route, time: now, engine: &engine, client: doc)
        if doc.selections > 1 || doc.reads > 1 || doc.inserts > 1 { overCalls += 1 }
        kinds.append(outcome.kind)
        if !outcome.consumed { doc.typed(route) }
    }

    /// `⌫` Backspace, `⏎` Return; anything else is a character. Every key with `lag`.
    mutating func type(_ keys: String, lag: Int = 0) {
        for c in keys.unicodeScalars {
            switch c {
            case "⌫": key(.backspace, lag: lag)
            case "⏎": key(.endWord, lag: lag)
            default: key(.character(c), lag: lag)
            }
        }
    }
}

@Suite("In-place mode with an app that answers late (M6, Chrome with a busy page)")
struct LateAnswerTests {
    /// Each word that came out wrong in the 1b run (build/load/1b-20261109-213527, not
    /// committed), replayed with the answers one edit late at the key the diag log shows
    /// late. `keys` is typed on time, then `late` with lag 1, then `rest` on time.
    @Test("words of the 1b log: the first replacement of a word, answer one key late",
          arguments: [
              // dau-busy-3: "bạn" → "ạnn" (sel 21, real cursor 22).
              ("nguoiwf ban", "j", " ", "người bạn "),
              // dau-busy-1: "meeting" → "êeting" (sel one key behind at the second e).
              ("truwocs me", "e", "ting ", "trước meeting "),
              // dau-busy-1: "ngày" → "nàyy".
              ("mooix ngay", "f", ". ", "mỗi ngày. "),
              // dau-busy-3: "viết" → "vêetjs" (late at the second e; D11 then re-read
              // the damaged word at j).
              ("phari vie", "e", "tjs ", "phải viết "),
              // dau-busy-3: "chiều" → "chêeuf".
              ("meeting chie", "e", "uf nay", "meeting chiều nay"),
              // Start of the document (dau-busy-1 key 3; there "S" itself never reached
              // the page, see the 1c report): position known from the D20 read at "S".
              ("Sa", "s", "ng nay", "Sáng nay"),
          ])
    func firstReplacementLate(_ keys: String, _ late: String, _ rest: String, _ expected: String) {
        var s = LateSession()
        s.type(keys)
        s.type(late, lag: 1)
        s.type(rest)
        #expect(s.doc.text == expected)
        #expect(s.doc.badRanges == 0)
        #expect(s.overCalls == 0)
    }

    /// The 1d run (build/load/1d-20261109-225810, not committed), after the first fix:
    /// at each wrong word the answer was one behind `known` and the read did not prove
    /// a late answer. Replayed with Chrome's cache as its source shows it: the page two
    /// edits behind, plus the latest key written into the cache at the page's caret
    /// (`LateDocument.Cache.chromium`). `late` is typed so; then `rest` on time.
    @Test("words of the 1d log: the answer is the page two keys behind plus the latest key in Chrome's cache",
          arguments: [
              // dau-busy-1 "ỏii" (sel 35, known 36).
              ("gửi email hoi", "r", " veef", "gửi email hỏi về"),
              // dau-busy-1 "ìnhh" (sel 65, known 66).
              ("project. Minh", "f", " phari", "project. Mình phải"),
              // dau-busy-1 "chêeuf" (sel 107, known 108).
              ("meeting chie", "e", "uf nay", "meeting chiều nay"),
              // dau-busy-3 "née" (sel 218, known 219).
              ("daanx nhe", "s", ". ", "dẫn nhé. "),
              // dau-busy-3 of 1b, "đaaline": the check of a locked word, same cache.
              ("cuar dea", "d", "line ", "của deadline "),
          ])
    func cacheInsertLate(_ keys: String, _ late: String, _ rest: String, _ expected: String) {
        var s = LateSession()
        s.doc.cache = .chromium
        s.type(keys)
        s.type(late, lag: 2)
        s.type(rest)
        #expect(s.doc.text == expected)
        // Shown by the text read, not guessed.
        #expect(!s.kinds.contains(.lateGuess))
        #expect(s.doc.badRanges == 0)
        #expect(s.overCalls == 0)
    }

    @Test("first replacement, answer one behind, text read proves nothing: replaced at the followed position (late_guess)")
    func guessAtFirstReplacement() {
        var s = LateSession()
        s.type("nguoiwf ban")
        // One behind, and the text before the answer is neither the word nor the typed
        // text with a unit missing ("xa").
        s.doc.override = "người xa"
        s.type("j")
        s.doc.override = nil
        s.type(" guiwr")
        #expect(s.doc.text == "người bạn gửi")
        #expect(s.kinds.contains(.lateGuess))
        #expect(s.overCalls == 0)
    }

    @Test("first replacement, answer behind but the whole word is before it: the app moved the text, the answer stands")
    func wholeWordBeforeAnswer() {
        var s = LateSession()
        s.type("ab cd vie")
        // The app shortened the text before the word ("cd" → "c"): the word is all there.
        s.doc.appEdit("ab c vie")
        s.type("etj ")
        #expect(s.doc.text == "ab c việt ")
        #expect(!s.kinds.contains(.lateGuess) && !s.kinds.contains(.late))
    }

    @Test("dau-busy-2: không khó — a stale answer taken as the followed position must not hide the next one")
    func staleAnswerDoesNotMoveKnown() {
        var s = LateSession()
        s.doc.cache = .chromium
        s.type("tieesng Anh kho")
        s.type("o", lag: 2)        // sel 131, known 132 in the log: "kôong"
        s.type("ng⌫g kho")
        s.type("s", lag: 2)        // sel 137 = the known the first answer left: "kóo"
        s.type(", ")
        #expect(s.doc.text == "tiếng Anh không khó, ")
        #expect(s.overCalls == 0)
    }

    @Test("dau-busy-3: deadline — the D11 check of a word that stopped being Vietnamese reads one key late")
    func lockedWordCheckLate() {
        var s = LateSession()
        s.type("cuar dea")
        s.type("d", lag: 1)
        s.type("line ")
        #expect(s.doc.text == "của deadline ")
        #expect(s.overCalls == 0)
    }

    @Test("dau-busy-2: Hoc ⌫ j — the D20 read after ⌫ answers from before the ⌫")
    func addMarksAfterBackspaceLate() {
        var s = LateSession()
        s.type("nay. Hoc ⌫")
        s.type("j", lag: 1)
        s.type(" tieesng")
        #expect(s.doc.text == "nay. Học tiếng")
        #expect(s.overCalls == 0)
    }

    @Test("dau-busy-2: được — the answer is behind the input method's own replacement")
    func ownReplacementLate() {
        var s = LateSession()
        s.type("caanf dduwo")
        s.type("w", lag: 1)
        s.type("jc ")
        #expect(s.doc.text == "cần được ")
        s.type("luyeen", lag: 0)
        s.type("j", lag: 2)
        s.type(" ")
        #expect(s.doc.text == "cần được luyện ")
        #expect(s.overCalls == 0)
    }

    /// The strings of `scripts/selftest/load/run.sh` (`--text edit`, the 1b string, and
    /// `--text std`; `--print keys`, `--print expect`) with every key answered 0, 1 or 2
    /// edits late, at random: after every key the text must be what the same keys give
    /// on time. (Three edits late is past `CursorTracker.lateLimit`: the answer is then
    /// taken as it is, as before the fix, and words come out wrong.)
    static let editKeys = "Sasng nay mojot nguoiwf banj guiwr email hoir veef deadline cuar project. Minhf phari vieetjs laji kees hoajch truwocs meeting chieeuf nay. Hoc ⌫j tieesng Anh khoong⌫g khos, chir caanf dduwowjc luyeenj ddeeuf mooix ngayf. Chaofz banj, xem video treen YouTube huowsng daanx nhes. "

    static let stdKeys = "Chieeuf nay anh cos ranhr khoong, minhf ddi uoongs caf phee nhes. Deadline cuar project nayf laf thuws saus tuaanf sau. Seeps vuwaf guwir email veef buooir meeting toois qua. Toois nay xem phim treen Netflix hay YouTube ddaay? "
    static let strings = [
        (editKeys, "Sáng nay một người bạn gửi email hỏi về deadline của project. Mình phải viết lại kế hoạch trước meeting chiều nay. Học tiếng Anh không khó, chỉ cần được luyện đều mỗi ngày. Chao bạn, xem video trên YouTube hướng dẫn nhé. "),
        (stdKeys, "Chiều nay anh có rảnh không, mình đi uống cà phê nhé. Deadline của project này là thứ sáu tuần sau. Sếp vừa gửi email về buổi meeting tối qua. Tối nay xem phim trên Netflix hay YouTube đây? "),
    ]

    @Test("the load-test strings, answers up to two keys late at random: same text as on time",
          arguments: [0, 1, 2, 3], Array(UInt64(1)...24))
    func wholeStringLate(_ which: Int, _ seed: UInt64) {
        // 0, 1: the page's text some edits ago; 2, 3: plus Chrome's cache insert.
        let (keysToType, expected) = Self.strings[which % 2]
        var onTime = LateSession()
        onTime.type(keysToType)
        #expect(onTime.doc.text == expected)
        // Both in step: after every key the app's real text must be the same.
        var step = LateSession()
        var late = LateSession()
        late.doc.cache = which >= 2 ? .chromium : .snapshot
        var rng = SplitMix(seed)
        var lags: [Int] = []
        var keys: [Unicode.Scalar] = []
        for c in keysToType.unicodeScalars {
            let lag = Int(rng.next() % 3)
            lags.append(lag); keys.append(c)
            let route: KeyRoute = c == "⌫" ? .backspace : .character(c)
            step.key(route, lag: 0)
            late.key(route, lag: lag)
            if late.doc.text != step.doc.text {
                let from = max(0, keys.count - 6)
                let context = zip(keys[from...], lags[from...]).map { "\(Character($0))/\($1)" }.joined(separator: " ")
                Issue.record("key \(keys.count) (\(context)) kinds \(late.kinds.suffix(6)): \(late.doc.text.suffix(20)) ≠ \(step.doc.text.suffix(20))")
                break
            }
        }
        #expect(late.doc.text == onTime.doc.text)
        #expect(late.doc.badRanges == 0)
        #expect(late.overCalls == 0)
    }

    // MARK: What must not change

    @Test("an app that answers on time: no read on any key typed in order")
    func onTimeNoExtraRead() {
        var s = LateSession()
        var reads = 0
        for c in "tooi laf sinh vieen, hoc ⌫j ".unicodeScalars {
            if c == "⌫" { s.key(.backspace, lag: 0) } else { s.key(.character(c), lag: 0) }
            reads += s.doc.reads
        }
        #expect(s.doc.text == "tôi là sinh viên, học ")
        // Only the D20 read after ⌫.
        #expect(reads == 1)
    }

    @Test("text shortened by the app at a word boundary (smart dash): the answer is believed, not taken for a late one")
    func shortenedByApp() {
        var s = LateSession()
        s.type("a --")
        // The app turns "--" into "—" (one unit shorter) when the next key comes.
        s.type(" ")
        s.doc.appEdit("a — ")
        s.type("vieetj ")
        #expect(s.doc.text == "a — việt ")
        #expect(s.doc.badRanges == 0)
        #expect(s.overCalls == 0)
    }
}

