import Foundation
import DauEngine
import DauShared
import Testing

/// A text document seen through `IMKTextInput` with document access (TSMDocumentAccess),
/// cursor at the end unless moved. Records every call so the tests can check N3.
///
/// `lag` models an app that applies keys asynchronously (WebKit, Chromium, terminals):
/// for `lag` seconds after any edit, `selectedRange` and `text(in:)` still answer from
/// the document as it was before that edit. `staleText` makes only the text lag (the
/// selection is fresh), the case M2 saw in Safari.
private final class FakeDocument: InPlaceClient {
    enum Call: Equatable {
        case selectedRange
        case read(NSRange)
        case insert(String, NSRange?)
    }

    var text = ""
    var cursor: Int
    var calls: [Call] = []
    /// Answer `text(in:)` with nil (no document access for text).
    var noText = false
    /// Answer `selectedRange` with NSNotFound (no document access at all).
    var noAccess = false
    /// Answer `text(in:)` with this instead (odd client, D18).
    var oddText: String?
    /// Length of the selection ending at the cursor that `selectedRange` reports.
    var selectionLength = 0

    var lag: TimeInterval = 0
    var staleText = false
    /// Chromium/Electron (COMPATIBILITY.md 6.4): the app runs its own Delete for ⌫ even
    /// when the input method consumed the key, after the input method's `insertText`
    /// (`render_widget_host_view_cocoa.mm` forwards the raw key-down to the page after
    /// `interpretKeyEvents:` unless there is marked text).
    var deletesConsumedBackspace = false
    private var lastEdit: TimeInterval = -.infinity
    private var previous: (text: String, cursor: Int) = ("", 0)
    /// Current time of the scripted session.
    var now: TimeInterval = 0

    init(_ text: String = "") {
        self.text = text
        cursor = text.utf16.count
    }

    private var stale: Bool { now - lastEdit < lag }

    private func edit(_ body: () -> Void) {
        if !stale { previous = (text, cursor) }
        body()
        lastEdit = now
    }

    func selectedRange() -> NSRange {
        calls.append(.selectedRange)
        if noAccess { return NSRange(location: NSNotFound, length: NSNotFound) }
        let end = stale && !staleText ? previous.cursor : cursor
        return NSRange(location: end - selectionLength, length: selectionLength)
    }

    func text(in range: NSRange) -> String? {
        calls.append(.read(range))
        if noText { return nil }
        if let oddText { return oddText }
        let source = stale ? previous.text : text
        let utf16 = Array(source.utf16)
        guard range.location >= 0, range.location + range.length <= utf16.count else { return nil }
        return String(decoding: utf16[range.location..<(range.location + range.length)], as: UTF16.self)
    }

    func insertText(_ string: String, replacementRange: NSRange) {
        let range: NSRange
        if replacementRange.location == NSNotFound {
            range = NSRange(location: cursor, length: 0)
            calls.append(.insert(string, nil))
        } else {
            range = replacementRange
            calls.append(.insert(string, replacementRange))
        }
        edit {
            let ns = NSMutableString(string: text)
            ns.replaceCharacters(in: range, with: string)
            text = ns as String
            cursor = range.location + string.utf16.count
        }
    }

    /// What the app types for an end-word key (Return; "\t" for Tab).
    var endWordText = "\n"

    /// What the app does with a key the input method did not consume.
    func defaultAction(_ route: KeyRoute) {
        switch route {
        case .character(let c):
            insertText(String(Character(c)), replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
            calls.removeLast()
        case .backspace:
            guard cursor > 0 else { return }
            edit {
                let ns = NSMutableString(string: text)
                ns.deleteCharacters(in: NSRange(location: cursor - 1, length: 1))
                text = ns as String
                cursor -= 1
            }
        case .endWord:
            insertText(endWordText, replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
            calls.removeLast()
        case .ignore:
            break
        }
    }
}

/// In-place mode end to end: keys → composer → fake document.
private struct Session {
    var engine: VietEngine
    var composer = InPlaceComposer()
    let doc: FakeDocument
    var kinds: [PerfLog.Kind] = []
    var consumed: [Bool] = []
    #if DEBUG
    var traces: [InPlaceComposer.D20Trace?] = []
    var diffs: [Bool?] = []
    #endif
    /// Keys that made more than one `insertText` or `selectedRange`, or more than one read
    /// (must stay 0, N3).
    var overCalls = 0
    /// Seconds between keys.
    var interval: TimeInterval = 0.2

    init(_ text: String = "", settings: DauSettings = .defaults) {
        engine = VietEngine(options: settings.engineOptions)
        composer.addMarksEnabled = settings.addMarksToTypedWords
        doc = FakeDocument(text)
    }

    mutating func key(_ route: KeyRoute) {
        doc.now += interval
        let before = doc.calls.count
        let outcome = composer.handle(route, time: doc.now, engine: &engine, client: doc)
        let made = doc.calls[before...]
        let inserts = made.filter { if case .insert = $0 { true } else { false } }.count
        let selections = made.filter { $0 == .selectedRange }.count
        let reads = made.filter { if case .read = $0 { true } else { false } }.count
        if inserts > 1 || selections > 1 || reads > 1 { overCalls += 1 }
        kinds.append(outcome.kind)
        consumed.append(outcome.consumed)
        #if DEBUG
        traces.append(outcome.d20)
        diffs.append(outcome.seedDiffers)
        #endif
        if !outcome.consumed || (route == .backspace && doc.deletesConsumedBackspace) {
            doc.defaultAction(route)
        }
    }

    /// `⌫` Backspace, `←` an arrow (reset), `⏎` Return; anything else is a character.
    mutating func type(_ keys: String) {
        for c in keys.unicodeScalars {
            switch c {
            case "⌫": key(.backspace)
            case "←": key(.ignore)
            case "⏎": key(.endWord)
            default: key(.character(c))
            }
        }
    }

    /// Text already in the app before the session (the engine knows nothing about it).
    var reads: Int { doc.calls.filter { if case .read = $0 { true } else { false } }.count }
}

@Suite("InPlaceComposer (method A, D20)")
struct InPlaceComposerTests {
    // MARK: Method A, unchanged behaviour

    @Test("the sample sentence, one insertText and at most one selectedRange per key")
    func sample() {
        var s = Session()
        s.type("windows carr tooi yeeu tieengs Vieetj, Sunrise ")
        #expect(s.doc.text == "windows car tôi yêu tiếng Việt, Sunrise ")
        #expect(s.overCalls == 0)
        // Words start after a Space typed here: no D20 read. The words that stop being
        // Vietnamese (windows, carr, Sunrise) are checked once each against the app's
        // text (D11).
        #expect(s.reads <= 3)
    }

    @Test("an app that moves the text under the word is caught (D11 mismatch)")
    func mismatch() {
        var s = Session()
        s.type("tooi")
        #expect(s.doc.text == "tôi")
        // The app inserts text before the word behind the input method's back.
        s.doc.text = "xx" + s.doc.text
        s.doc.cursor += 2
        s.type("s")
        // Re-synced from the text before the cursor ("xxtôi", not a syllable): nothing
        // replaced at the old position, the key goes in as typed.
        #expect(s.kinds.last == .resyncPass)
        #expect(s.doc.text == "xxtôis")
        #expect(s.overCalls == 0)
    }

    @Test("D11: a click the app did not report — the word is re-read and the key applies")
    func resyncAfterUnreportedClick() {
        var s = Session()
        s.type("oo")
        #expect(s.doc.text == "ô")
        // Chrome's address bar: a click selects everything and the next key replaces it,
        // but the input method is not told; the engine still holds "ô".
        s.doc.text = ""
        s.doc.cursor = 0
        s.type("is")
        // "ôi" + s would replace two letters at a cursor that is not there: mismatch,
        // then the real word "i" is read and the key applies to it.
        #expect(s.doc.text == "í")
        #expect(s.kinds.last == .resync)
        #expect(s.overCalls == 0)
    }

    @Test("D11: a re-synced word the key only adds to (d + w → dư) is written once")
    func resyncAppends() {
        var s = Session()
        s.type("oo")
        // The app's text changed behind the input method's back: "x d" now.
        s.doc.text = "x d"
        s.doc.cursor = 3
        s.type("w")
        #expect(s.doc.text == "x dư")
        #expect(s.kinds.last == .resync)
        #expect(s.overCalls == 0)
    }

    @Test("D11: ⌘A the input method never sees — tốt, select all, toots → tốt")
    func selectAllUnseen() {
        var s = Session()
        s.type("toots")
        #expect(s.doc.text == "tốt")
        // Chrome's address bar: ⌘A is a menu shortcut, the input method never gets it;
        // the next key replaces the selection.
        s.doc.text = ""
        s.doc.cursor = 0
        s.type("toots")
        #expect(s.doc.text == "tốt")
        #expect(s.overCalls == 0)
    }

    @Test("D11: ⌘A unseen, then the app autocompletes after t — toots → tốt")
    func selectAllThenAutocomplete() {
        var s = Session()
        s.type("toots")
        s.doc.text = ""
        s.doc.cursor = 0
        s.type("t")
        // Chrome's address bar selects a suggestion after the t ("t|witter.com"); the
        // fake reports a selection that ends at its cursor.
        s.doc.text = "twitter.com"
        s.doc.cursor = 11
        s.doc.selectionLength = 10
        s.type("o")
        #expect(s.kinds.last == .resyncPass)
        // Chrome typed the o over its suggestion (the fake cannot): "to", no selection.
        s.doc.text = "to"
        s.doc.cursor = 2
        s.doc.selectionLength = 0
        s.type("ots")
        #expect(s.doc.text == "tốt")
        #expect(s.overCalls == 0)
    }

    @Test("D11: a real English word is checked once and left as typed")
    func englishWordCheckedOnce() {
        var s = Session()
        s.type("windows ")
        #expect(s.doc.text == "windows ")
        #expect(s.reads <= 1)
        #expect(s.overCalls == 0)
    }

    @Test("D11: keys faster than settleInterval do not re-sync (stale snapshot)")
    func noResyncWhenFast() {
        var s = Session()
        s.interval = 0.01
        s.type("oo")
        s.doc.text = ""
        s.doc.cursor = 0
        s.type("is")
        #expect(s.kinds.last == .mismatch)
        #expect(s.doc.text == "is")
    }

    // MARK: D20 examples (DECISIONS.md)

    @Test("D20: viet + j → vietj (not a valid syllable: the key goes straight)")
    func vietJ() {
        var s = Session("viet")
        s.type("j")
        #expect(s.doc.text == "vietj")
        // D20 (c): "vietj" is not a prefix, so the j starts a new word (same text).
        #expect(s.kinds == [.seedNone])
        #expect(s.doc.calls == [.selectedRange, .read(NSRange(location: 0, length: 4))])
    }

    @Test("D20: viet + e + j → việt")
    func vietEJ() {
        var s = Session("viet")
        s.type("ej")
        #expect(s.doc.text == "việt")
        #expect(s.kinds == [.seed, .replace])
        #expect(s.overCalls == 0)
        // Only the first key reads; the second is a normal in-word replacement.
        #expect(s.reads == 1)
    }

    @Test("D20 + D26: cả + r → car; the word then restores and locks as typed")
    func doubleUndo() {
        var s = Session("cả")
        s.type("r")
        #expect(s.doc.text == "car")
        s.type("s ")
        #expect(s.doc.text == "cars ")
    }

    @Test("D20 + D30/D31: hoc + f → hòc, the word end restores hocf")
    func hocF() {
        var s = Session("hoc")
        s.type("f")
        #expect(s.doc.text == "hòc")
        s.type(" ")
        #expect(s.doc.text == "hocf ")
    }

    @Test("D20: K7 in the compatibility matrix — hoc, Space, ⌫, j → học")
    func k7() {
        var s = Session()
        s.type("hoc ⌫j")
        #expect(s.doc.text == "học")
        #expect(s.kinds.last == .seed)
        s.type(" ")
        #expect(s.doc.text == "học ")
        #expect(s.overCalls == 0)
    }

    @Test("D20: the word is read only up to the cursor, with text before it")
    func wordAfterText() {
        var s = Session("xin chao")
        s.type("f")
        #expect(s.doc.text == "xin chào")
        #expect(s.doc.calls.contains(.read(NSRange(location: 0, length: 8))))
    }

    @Test("D20: VNI digits are mark keys (D36)")
    func vni() {
        var settings = DauSettings.defaults
        settings.typingMethod = .vni
        var s = Session("Viet", settings: settings)
        s.type("65")
        #expect(s.doc.text == "Việt")
    }

    @Test("D20: decomposed (NFD) text is replaced over its decomposed length")
    func decomposed() {
        var s = Session("vie\u{0302}t")
        s.type("j")
        #expect(s.doc.text.unicodeScalars.map(\.value) == "việt".unicodeScalars.map(\.value))
    }

    // MARK: D20, when not to read (N3)

    @Test("D20 off: no read, the key starts a new word")
    func off() {
        var settings = DauSettings.defaults
        settings.addMarksToTypedWords = false
        var s = Session("hoc", settings: settings)
        s.type("j")
        #expect(s.doc.text == "hocj")
        #expect(s.doc.calls.isEmpty)
    }

    @Test("D15: on by default")
    func defaultOn() {
        #expect(DauSettings.defaults.addMarksToTypedWords)
        #expect(InPlaceComposer().addMarksEnabled)
    }

    @Test("E8: a plain letter reads too and joins a valid prefix; no read inside a word")
    func letterReadsOnce() {
        var s = Session("ho")
        s.type("c")      // not a mark key: reads "ho", "hoc" is a valid prefix (E8)
        #expect(s.reads == 1)
        #expect(s.kinds == [.seedPass])
        s.type("j")      // inside the word "hoc" (engine tracks it): normal key
        #expect(s.doc.text == "học")
        #expect(s.reads == 1)
        #expect(s.overCalls == 0)
    }

    @Test("no read after a word-ending key typed here; read again after a reset")
    func knownBoundary() {
        var s = Session()
        s.type("hoc ")
        s.type("a")      // after Space typed here: known, no read
        #expect(s.reads == 0)
        s.type("←")
        s.type("f")      // after an arrow: unknown, read the word before the cursor ("a") → seeded
        #expect(s.reads == 1)
        #expect(s.doc.text == "hoc à")
    }

    @Test("a read that finds no word is not repeated for the next key")
    func noWordFound() {
        var s = Session("xin, ")
        s.type("a")
        #expect(s.kinds == [.seedNone])
        #expect(s.reads == 1)
        s.type("s")
        #expect(s.doc.text == "xin, á")
        #expect(s.reads == 1)
    }

    @Test("start of the document: one selectedRange, no read")
    func startOfDocument() {
        var s = Session()
        s.type("a")
        #expect(s.doc.calls == [.selectedRange])
        #expect(s.kinds == [.seedNone])
    }

    @Test("a word longer than the read is not Vietnamese: the key and the rest pass (D20 b)")
    func longWord() {
        var s = Session("abcdefghijklmnopqrstu")
        s.type("s")
        #expect(s.doc.text == "abcdefghijklmnopqrstus")
        #expect(s.kinds == [.seedPass])
        s.type("as ")
        #expect(s.doc.text == "abcdefghijklmnopqrstusas ")
        #expect(s.reads == 1)
        #expect(s.overCalls == 0)
    }

    @Test("a selection: no read, the key replaces it as the app does")
    func selection() {
        var s = Session("hoc")
        s.doc.selectionLength = 3
        s.type("j")
        #expect(s.doc.calls == [.selectedRange])
        #expect(s.kinds == [.seedNone])
    }

    // MARK: D18, odd clients

    @Test("D18: no document access → no read, and no read again until activation")
    func noAccess() {
        var s = Session("hoc")
        s.doc.noAccess = true
        s.type("j")
        #expect(s.doc.text == "hocj")
        #expect(s.doc.calls == [.selectedRange])
        s.type("←s")
        #expect(s.doc.calls == [.selectedRange])
        s.composer.activate()
        s.type("←s")
        #expect(s.doc.calls.count == 2)
    }

    @Test("D18: nil text → no seed, key passes; no read again until activation")
    func nilText() {
        var s = Session("hoc")
        s.doc.noText = true
        s.type("j")
        #expect(s.doc.text == "hocj")
        s.type("←s")
        #expect(s.reads == 1)
    }

    @Test("D18: text of the wrong length, or not letters, is not seeded")
    func oddText() {
        var s = Session("hoc")
        s.doc.oddText = "ho"
        s.type("j")
        #expect(s.doc.text == "hocj")
        var t = Session("hoc")
        t.doc.oddText = "h\u{1F600}"   // a surrogate pair: 3 UTF-16 units, not letters
        t.type("j")
        #expect(t.doc.text == "hocj")
    }

    // MARK: Backspace (D32) in apps that delete even a consumed ⌫ (COMPATIBILITY.md 6.4)

    /// Both kinds of app: one that honours a consumed key (AppKit, WebKit, Firefox) and
    /// one that runs its own Delete anyway (Chromium, Electron).
    private static func sessions(_ text: String = "") -> [Session] {
        var honours = Session(text)
        honours.interval = 0.12
        var chromium = Session(text)
        chromium.interval = 0.12
        chromium.doc.deletesConsumedBackspace = true
        return [honours, chromium]
    }

    @Test("hoaf ⌫ → hò in both kinds of app; the ⌫ is left to the app, same calls (N3)")
    func backspaceTone() {
        for var s in Self.sessions() {
            s.type("hoaf")
            let before = s.doc.calls.count
            s.type("⌫")
            #expect(s.doc.text == "hò")
            #expect(s.consumed.last == false)
            #expect(s.kinds.last == .replace)
            // The replacement keeps the last character for the app's own Delete.
            #expect(Array(s.doc.calls[before...]) == [.selectedRange, .insert("òà", NSRange(location: 1, length: 2))])
            s.type(" ")
            #expect(s.doc.text == "hò ")
            #expect(s.overCalls == 0)
        }
    }

    @Test("old behaviour reproduced: a consumed ⌫ loses one more letter in Chromium")
    func consumedBackspaceInChromium() {
        // What 0ac50c3 did: replace "oà" with "ò" and consume the key. Chromium still
        // deletes, giving the "h" measured in Chrome, Edge and VS Code.
        let doc = FakeDocument("hoà")
        doc.deletesConsumedBackspace = true
        doc.insertText("ò", replacementRange: NSRange(location: 1, length: 2))
        doc.defaultAction(.backspace)
        #expect(doc.text == "h")
    }

    @Test("longer words: D32 with ⌫ that passes, ⌫ that re-places the tone, keys after it",
          arguments: [
            ("hoaf⌫ ", "hò "), ("hoaf⌫a ", "hoà "), ("vieetj⌫⌫ ", "vị "),
            ("vieetj⌫s ", "việs "), ("tieengs⌫⌫ ", "tiế "), ("thuyr⌫ ", "thủ "),
            ("hoaf⌫⌫⌫ ", " "),
          ])
    func backspaceWords(_ keys: String, _ expected: String) {
        var engineOnly = VietEngine()
        var shown = ""
        for c in keys.unicodeScalars {
            let action = c == "⌫" ? engineOnly.backspace() : engineOnly.handle(c)
            switch action {
            case .passThrough:
                if c == "⌫" { if !shown.isEmpty { shown.unicodeScalars.removeLast() } } else { shown.unicodeScalars.append(c) }
            case .replace(let n, let insert):
                shown.unicodeScalars.removeLast(n)
                shown += insert.description
            }
        }
        // The engine's own answer (DauEngine tests check it against DECISIONS.md).
        #expect(shown == expected)
        for var s in Self.sessions() {
            s.type(keys)
            #expect(s.doc.text == expected, "deletesConsumedBackspace=\(s.doc.deletesConsumedBackspace)")
            #expect(s.overCalls == 0)
            #expect(!s.kinds.contains(.mismatch))
        }
    }

    @Test("text after the cursor is kept")
    func backspaceBeforeText() {
        for var s in Self.sessions(" xyz") {
            s.doc.cursor = 0
            s.type("hoaf⌫ ")
            #expect(s.doc.text == "hò  xyz")
        }
    }

    @Test("a word read by D20 (decomposed in the app), then ⌫ that re-places the tone")
    func backspaceAfterSeed() {
        for var s in Self.sessions("xin cha\u{0300}o") {
            s.type("←")
            s.type("s")   // D20 reads "chào" (NFD) → "cháo", rewritten precomposed
            #expect(s.kinds.last == .seed)
            #expect(s.doc.text == "xin cháo")
            s.type("⌫ ")  // "chá" is not a syllable: D4 restores what was shown after ⌫
            #expect(s.doc.text == "xin chá ")
            #expect(s.kinds.contains(.mismatch) == false)
        }
        for var s in Self.sessions("hoa") {
            s.type("f⌫")  // D20 → "hoà", ⌫ → "hò"
            #expect(s.kinds == [.seed, .replace])
            #expect(s.doc.text == "hò")
        }
    }

    @Test("stale snapshot right after a ⌫ the app deleted: the text read shows a late answer, same text as on time")
    func backspaceStale() {
        for var s in Self.sessions() {
            s.type("vieetj")
            #expect(s.doc.text == "việt")
            // The app answers from a snapshot 50 ms old; the next two ⌫ come 10 ms apart.
            s.doc.lag = 0.05
            s.interval = 0.01
            s.type("⌫⌫")
            // The second ⌫ sees the cursor before the first deletion. The text read there
            // ("việt") with that deletion is the engine's word, so the app is only late
            // (M6, keys in a burst): D32 replaces at the followed position, as on time.
            #expect(s.kinds.suffix(2) == [.pass, .late])
            #expect(s.doc.text == "vị")
            #expect(s.overCalls == 0)
        }
    }

    // MARK: Asynchronous apps: stale snapshot

    @Test("stale snapshot (keys faster than the app): no read, no damage")
    func staleFast() {
        var s = Session()
        s.doc.lag = 0.05
        s.interval = 0.01
        s.type("hoc ⌫j")
        // Keys 10 ms apart: D20 waits for the app to settle, so the key goes straight.
        #expect(s.doc.text == "hocj")
        #expect(s.reads == 0)
    }

    @Test("stale text with a fresh selection (Safari in M2): no damage when keys are fast")
    func staleTextFast() {
        // "tôi" was produced by a replacement just before: the text read would still be
        // "to" while the cursor is already after "tôi".
        var s = Session()
        s.doc.lag = 0.05
        s.doc.staleText = true
        s.interval = 0.02
        s.type("tooi ⌫s")
        #expect(s.doc.text == "tôis")
        #expect(s.reads == 0)
    }

    @Test("same keys once the app has settled: D20 applies")
    func settled() {
        var s = Session()
        s.doc.lag = 0.05
        s.doc.staleText = true
        s.interval = 0.1
        s.type("tooi ⌫s")
        #expect(s.doc.text == "tối")
        #expect(s.reads == 1)
    }

    @Test("settle interval: above the 10–20 ms lag of asynchronous apps (M2), below a person going back to a word")
    func settleInterval() {
        #expect(InPlaceComposer.settleInterval >= 0.05)
        #expect(InPlaceComposer.settleInterval <= 0.15)
    }

    // MARK: Mark keys

    @Test("mark keys per typing method")
    func markKeys() {
        for c in "sfrxjzaeowdSFRXJZAEOWD".unicodeScalars {
            #expect(InPlaceComposer.isMarkKey(c, method: .telex))
            #expect(InPlaceComposer.isMarkKey(c, method: .simpleTelex))
            #expect(!InPlaceComposer.isMarkKey(c, method: .vni))
        }
        for c in "bcghklmnpqtuvy1".unicodeScalars {
            #expect(!InPlaceComposer.isMarkKey(c, method: .telex))
        }
        for c in "0123456789".unicodeScalars {
            #expect(InPlaceComposer.isMarkKey(c, method: .vni))
        }
        #expect(!InPlaceComposer.isMarkKey("ă", method: .telex))
    }

    @Test("trailing word: letters, combining marks and digits before the cursor")
    func trailingWord() {
        #expect(InPlaceComposer.trailingWord("xin chào") == Array("chào".unicodeScalars))
        #expect(InPlaceComposer.trailingWord("a, ") == [])
        #expect(InPlaceComposer.trailingWord("vie\u{0302}t") == Array("vie\u{0302}t".unicodeScalars))
        #expect(InPlaceComposer.trailingWord("") == [])
    }
}

/// E8 (D20, "Chữ cái gõ sát chữ có sẵn", 05/11/2026): the first plain letter after a
/// reset also reads the word before the cursor, and joins it only while the word with
/// that letter is still a valid prefix (D30); otherwise the letter starts a new word.
/// `⟦x⟧` in the names is the text before the cursor after a click.
@Suite("InPlaceComposer: plain letter next to existing text (D20, E8)")
struct InPlaceComposerLetterTests {
    private static func telex(_ text: String) -> Session { Session(text) }

    @Test("joins when the word stays a valid prefix", arguments: [
        ("q", "uer ", "quẻ "),
        ("q", "uas ", "quá "),
        ("g", "ias ", "giá "),
        ("ngh", "ieengx ", "nghiễng "),
        ("tiê", "ngs ", "tiếng "),
        ("ba", "nj ", "bạn "),
        ("Ng", "uyeenx ", "Nguyễn "),
    ])
    func joins(_ before: String, _ keys: String, _ expected: String) {
        var s = Self.telex(before)
        s.type(keys)
        #expect(s.doc.text == expected)
        #expect(s.reads == 1)
        #expect(s.kinds.first == .seedPass || s.kinds.first == .seed)
        #expect(s.overCalls == 0)
    }

    @Test("starts a new word when the joined word is not a valid prefix", arguments: [
        ("tôi", "laf ", "tôilà "),
        ("sắc", "mauf ", "sắcmàu "),
        ("Xin chào", "banj ", "Xin chàobạn "),
    ])
    func newWord(_ before: String, _ keys: String, _ expected: String) {
        var s = Self.telex(before)
        s.type(keys)
        #expect(s.doc.text == expected)
        #expect(s.reads == 1)
        #expect(s.kinds.first == .seedNone)
        #expect(s.overCalls == 0)
    }

    @Test("a letter that does not join sends nothing beyond the read: the app types it")
    func rejectedLetterCalls() {
        var s = Self.telex("tôi")
        s.type("l")
        #expect(s.doc.calls == [.selectedRange, .read(NSRange(location: 0, length: 3))])
        #expect(s.consumed == [false])
        #expect(s.doc.text == "tôil")
        // The new word is tracked from the letter alone: the next mark key does not read.
        s.type("af")
        #expect(s.doc.text == "tôilà")
        #expect(s.reads == 1)
    }

    @Test("VNI: ⟦q⟧ue3 → quẻ")
    func vni() {
        var settings = DauSettings.defaults
        settings.typingMethod = .vni
        var s = Session("q", settings: settings)
        s.type("ue3 ")
        #expect(s.doc.text == "quẻ ")
        #expect(s.reads == 1)
    }

    @Test("after ⌫ over a Space: ba␣⌫nj → bạn, ddi␣⌫hocj → đihọc")
    func afterBackspace() {
        var s = Session()
        s.type("ba ⌫nj ")
        #expect(s.doc.text == "bạn ")
        var t = Session()
        t.type("ddi ⌫hocj ")
        #expect(t.doc.text == "đihọc ")
        #expect(s.overCalls == 0 && t.overCalls == 0)
    }

    @Test("known limit (D20): a new word glued to a Vietnamese word joins while a prefix is valid",
          arguments: [
              ("#hà", "nooij ", "#hànooij "),
              ("ba", "nawm ", "banawm "),
              ("HÀ", "NOOIJ ", "HÀNOOIJ "),
          ])
    func knownLimit(_ before: String, _ keys: String, _ expected: String) {
        var s = Self.telex(before)
        s.type(keys)
        #expect(s.doc.text == expected)
        #expect(s.kinds.first == .seedPass || s.kinds.first == .seed)
        // One D20 read, and at most one D11 check once the joined word stops being a prefix.
        #expect(s.reads <= 2)
        #expect(s.overCalls == 0)
    }

    @Test("duow␣⌫c shows dươc mid-word, the word end restores duơc (D31)")
    func duowc() {
        var s = Session()
        s.type("duow ⌫c")
        #expect(s.doc.text == "dươc")
        s.type(" ")
        #expect(s.doc.text == "duơc ")
    }

    @Test("a sentence with no reset reads at most once, at the first key")
    func sentence() {
        var s = Session("Xin chào ")
        s.type("tooi laf sinh vieen ")
        #expect(s.doc.text == "Xin chào tôi là sinh viên ")
        #expect(s.reads == 1)
        #expect(s.doc.calls.first == .selectedRange)
        var empty = Session()
        empty.type("tooi laf sinh vieen ")
        #expect(empty.reads == 0)   // start of the document: selectedRange only
        #expect(empty.doc.text == "tôi là sinh viên ")
    }

    @Test("reads at the first letter after an arrow, once, not mid-word")
    func readsAfterReset() {
        var s = Session()
        s.type("xin")           // start of the document: selectedRange only, no text to read
        #expect(s.reads == 0)
        s.type("←")
        let before = s.doc.calls.count
        s.type("b")             // unknown again: reads "xin", "xinb" is not a prefix
        #expect(s.reads == 1)
        s.type("cn")            // mid-word: no more calls
        #expect(s.reads == 1)
        #expect(s.doc.calls.count == before + 2)   // selectedRange + read of that key only
        #expect(s.doc.text == "xinbcn")
    }

    @Test("no read after a known no-word (Space typed here)")
    func noReadAfterSpace() {
        var s = Session()
        s.type("hoc ")
        let before = s.doc.calls.count
        s.type("q")
        #expect(s.doc.calls.count == before)
    }

    @Test("D20 off: a letter reads nothing")
    func off() {
        var settings = DauSettings.defaults
        settings.addMarksToTypedWords = false
        var s = Session("q", settings: settings)
        s.type("uer ")
        #expect(s.reads == 0)
        #expect(s.kinds.first == .pass)
        #expect(s.doc.text == "quer ")
    }

    @Test("keys under 50 ms apart: no read on a letter")
    func settleRule() {
        var s = Session("q")
        s.interval = 0.01
        s.composer.noteEvent(at: 0.0)
        s.type("u")
        #expect(s.doc.calls.isEmpty)
        #expect(s.reads == 0)
    }

    @Test("Return or Tab, then a word: the read finds no word, nothing is joined", arguments: ["\n", "\t"])
    func afterEndWord(_ key: String) {
        var s = Session()
        s.doc.endWordText = key
        s.type("ba⏎")
        s.type("nj ")
        #expect(s.doc.text == "ba" + key + "nj ")
        #expect(s.reads == 1)
        #expect(s.kinds[3] == .seedNone)
    }

    @Test("a selection: no seed, the letter replaces it as the app does")
    func selection() {
        var s = Session("q")
        s.doc.selectionLength = 1
        s.type("u")
        #expect(s.doc.calls == [.selectedRange])
        #expect(s.kinds == [.seedNone])
    }

    @Test("D18: no document access → no read, and no read again until activation")
    func noAccess() {
        var s = Session("q")
        s.doc.noAccess = true
        s.type("u←e")
        #expect(s.reads == 0)
        #expect(s.doc.calls.filter { $0 == .selectedRange }.count == 1)
    }

    @Test("a word that fills the read is not Vietnamese: the letters belong to it (D20 b)")
    func longWord() {
        var s = Session("abcdefghijklmnopq")
        s.type("u")
        #expect(s.doc.text == "abcdefghijklmnopqu")
        #expect(s.kinds == [.seedPass])
        s.type("as ")
        #expect(s.doc.text == "abcdefghijklmnopquas ")
        #expect(s.reads == 1)
    }

    @Test("a seeded 7-letter word plus a letter is past the longest syllable (D33): new word")
    func overflow() {
        var s = Session("nghiêng")
        s.type("bans ")
        #expect(s.doc.text == "nghiêngbán ")
        #expect(s.kinds.first == .seedNone)
    }

    #if DEBUG
    @Test("trace: trigger, seeded, and whether the seed changes the word shown")
    func trace() {
        // q + u: the key itself looks the same, the next keys show the difference.
        var s = Session("q")
        s.type("uer")
        #expect(s.doc.text == "quẻ")
        #expect(s.diffs == [false, false, true])
        #expect(s.traces.first == InPlaceComposer.D20Trace(trigger: .letter, seeded: true))
        #expect(s.traces.dropFirst().allSatisfy { $0 == nil })

        // tôi + l: read, not joined: not seeded, no diff.
        var l = Session("tôi")
        l.type("la")
        #expect(l.traces == [InPlaceComposer.D20Trace(trigger: .letter, seeded: false), nil])
        #expect(l.diffs == [nil, nil])

        // hoc + j: the seed is what makes "học" instead of "hocj".
        var h = Session("hoc")
        h.type("j")
        #expect(h.doc.text == "học")
        #expect(h.diffs == [true])

        // A read that finds no word is not seeded and has no diff; the next key has no trace.
        var n = Session("xin, ")
        n.type("as")
        #expect(n.traces == [InPlaceComposer.D20Trace(trigger: .mark, seeded: false), nil])
        #expect(n.diffs == [nil, nil])
    }
    #endif
}

/// The three exceptions of D20 (05/11/2026), on the first key after a reset. Every
/// decision uses the text the read already returned: no client call beyond the read (N3).
/// `⟦x⟧` in the names is the text before the cursor after a click.
@Suite("InPlaceComposer: the three exceptions of D20")
struct InPlaceComposerExceptionTests {
    private static func telex(_ text: String, autoRestore: Bool = true) -> Session {
        var settings = DauSettings.defaults
        settings.autoRestore = autoRestore
        return Session(text, settings: settings)
    }

    private static func inserts(_ s: Session) -> Int {
        s.doc.calls.filter { if case .insert = $0 { true } else { false } }.count
    }

    // MARK: (a) upper case after lower case

    @Test("(a) an upper-case letter after a lower-case one starts a new word", arguments: [
        ("#Hà", "Nooij ", "#HàNội "),
        ("Hà", "Nooij ", "HàNội "),
        ("#Đà", "Nawngx ", "#ĐàNẵng "),
        ("Hà", "Oi ", "HàOi "),             // O only adds a letter: new word "Oi"
    ])
    func upperAfterLower(_ before: String, _ keys: String, _ expected: String) {
        var s = Self.telex(before)
        s.type(keys)
        #expect(s.doc.text == expected)
        #expect(s.kinds.first == .seedNone)
        #expect(s.reads == 1)
        #expect(s.overCalls == 0)
    }

    @Test("(a) not for a mark key that places a tone or transform: ⟦hoc⟧J → học")
    func upperMarkKeyApplies() {
        var s = Self.telex("hoc")
        s.type("J ")
        #expect(s.doc.text == "học ")
        #expect(s.kinds.first == .seed)
        var t = Self.telex("hoc")
        t.type("j ")
        #expect(t.doc.text == "học ")
        #expect(s.overCalls == 0 && t.overCalls == 0)
    }

    @Test("(a) decomposed (NFD) text: the last character, not its mark, is lower case")
    func upperAfterDecomposed() {
        var s = Self.telex("Ha\u{0300}")
        s.type("Nooij ")
        #expect(s.doc.text == "Ha\u{0300}Nội ")
    }

    @Test("(a) upper after upper, lower after upper: still joins", arguments: [
        ("VI", "EEJT ", "VIỆT "),
        ("V", "ieejt ", "Việt "),
        ("NG", "UOWIF ", "NGƯỜI "),
    ])
    func sameCaseJoins(_ before: String, _ keys: String, _ expected: String) {
        var s = Self.telex(before)
        s.type(keys)
        #expect(s.doc.text == expected)
        #expect(s.kinds.first == .seed || s.kinds.first == .seedPass)
        #expect(s.overCalls == 0)
    }

    @Test("(a) VNI: ⟦Hà⟧No6i5 → HàNội")
    func upperAfterLowerVNI() {
        var settings = DauSettings.defaults
        settings.typingMethod = .vni
        var s = Session("Hà", settings: settings)
        s.type("No6i5 ")
        #expect(s.doc.text == "HàNội ")
        #expect(s.reads == 1)
    }

    // MARK: (b) a foreign word before the cursor

    @Test("(b) a word that is not Vietnamese takes the letters unchanged until it ends", arguments: [
        ("foo", "bar ", "foobar "),
        ("keyboard", "bar ", "keyboardbar "),
        ("iPhone", "mowis ", "iPhonemowis "),
        ("hello", "banj ", "hellobanj "),
        ("car", "s ", "cars "),
        ("keyboard", "sas ", "keyboardsas "),
        // (b) wins over (a): camelCase after a foreign word, short or long.
        ("foo", "Bar ", "fooBar "),
        ("keyboard", "Bar ", "keyboardBar "),
        ("abcdefghijklmnopq", "Bar ", "abcdefghijklmnopqBar "),
    ])
    func foreignWord(_ before: String, _ keys: String, _ expected: String) {
        var s = Self.telex(before)
        s.type(keys)
        #expect(s.doc.text == expected)
        #expect(s.kinds.first == .seedPass)
        #expect(Self.inserts(s) == 0)       // every key went to the app as typed
        #expect(s.reads == 1)               // no D11 re-read of a word just read
        #expect(s.overCalls == 0)
    }

    @Test("(b) also with auto restore off; the next word is Vietnamese again")
    func foreignWordThenVietnamese() {
        var s = Self.telex("foo", autoRestore: false)
        s.type("bar ")
        #expect(s.doc.text == "foobar ")
        var t = Self.telex("keyboard")
        t.type("bar vieetj ")
        #expect(t.doc.text == "keyboardbar việt ")
        var u = Self.telex("foo")
        u.type("bar tooi ")
        #expect(u.doc.text == "foobar tôi ")
    }

    @Test("(b) ⌫ over a long foreign word and its letters ends the pass-through (D33)")
    func foreignWordDeleted() {
        var s = Self.telex("keyboard")
        s.type("b⌫⌫⌫⌫⌫⌫⌫⌫⌫")
        #expect(s.doc.text == "")
        s.type("vieetj ")
        #expect(s.doc.text == "việt ")
    }

    @Test("(b) a word with digits is not taken for a foreign word: the key starts a new word")
    func wordWithDigits() {
        var s = Self.telex("abc12345")
        s.type("vieetj ")
        #expect(s.doc.text == "abc12345việt ")
    }

    // MARK: (c) a mark key that is not applied to a Vietnamese word

    @Test("(c) a mark key that does not apply starts a new word", arguments: [
        ("anh", "emx ", "anhẽm "),
        ("anh", "ems ", "anhém "),
        ("tôi", "ddi ", "tôiđi "),
        ("Hà", "ddi ", "Hàđi "),
        ("tôi", "awn ", "tôiăn "),
        ("ba", "ef ", "baè "),
    ])
    func markStartsWord(_ before: String, _ keys: String, _ expected: String) {
        var s = Self.telex(before)
        s.type(keys)
        #expect(s.doc.text == expected)
        #expect(s.kinds.first == .seedNone)
        #expect(s.reads == 1)
        #expect(s.overCalls == 0)
    }

    @Test("(c) unchanged: a double key is applied, and keys that apply or keep a prefix", arguments: [
        ("cả", "r", "car"),
        ("ca", "rr ", "car "),
        ("hoc", "f", "hòc"),
        ("hoc", "f ", "hocf "),
        ("viet", "j ", "vietj "),
        ("viet", "ej ", "việt "),
    ])
    func markUnchanged(_ before: String, _ keys: String, _ expected: String) {
        var s = Self.telex(before)
        s.type(keys)
        #expect(s.doc.text == expected)
        #expect(s.overCalls == 0)
    }
}
