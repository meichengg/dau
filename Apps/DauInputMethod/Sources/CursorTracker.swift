import Foundation

/// Method A of the open question A/B (DECISIONS.md): ask the client for `selectedRange`
/// on every key whose result replaces text, and compute the absolute replacement range
/// from it. On top of that, remember where the cursor should be after each key of the
/// current word, so a cursor that moved without the input method noticing (a click IMK
/// did not report, an app that edited the text) is caught before anything is replaced
/// (D11: "selectedRange khác vị trí dự đoán").
///
/// It also follows the cursor across word boundaries (`known`), with the edits this
/// composer made or let through (`edits`), so an app that answers from before its latest
/// edits (Chrome with a busy page, M6: the page applies keys late, `selectedRange` and
/// `attributedSubstring` answer from the text as it was) can be told from an app whose
/// text really changed: the text the app gives, plus the edits it has not applied yet,
/// must be the word the engine holds (`rebuild`). The caller decides; nothing here talks
/// to the client.
///
/// Ranges are UTF-16 offsets from the start of the client's document (NSRange).
/// Pure value type, no IMK calls, unit tested in DauInputMethodTests.
struct CursorTracker: Equatable {
    /// Where the cursor should be now, if known. Only kept inside one word: across a word
    /// boundary apps may legitimately edit text (autocorrect, smart quotes), so a mismatch
    /// there would throw away good state.
    private(set) var expected: Int?

    /// Where the cursor is once the app has applied every edit this composer made or let
    /// through, kept across word boundaries; nil when unknown (after a reset, Return,
    /// arrows, a click). Unlike `expected`, a different answer from the app is not a
    /// mismatch by itself: the app may have edited the text at a word boundary.
    private(set) var known: Int?
    /// The text right before `known` that this composer typed or inserted, oldest first
    /// (UTF-16, at most `tailLimit` units; may be shorter than the text that is there).
    private(set) var tail: [UInt16] = []
    /// The latest edits, oldest first (at most `editLimit`).
    private(set) var edits: [Edit] = []
    /// Enough for an app that falls far behind a burst of keys (M6: in the simulation of
    /// VS Code and Firefox at 0 ms, `RapidKeysTests`, answers were over a hundred edits
    /// behind); one edit is a few dozen bytes, and `rebuild` replays only the counts
    /// whose caret matches the answer.
    static let editLimit = 256
    /// Long enough to check, past `editLimit` units of edits, the text the app answers
    /// with before them (`rebuild`, `InPlaceComposer.readLength` units).
    static let tailLimit = 512
    /// How many edits an app may be behind for `rebuild` when the keys came at a human
    /// pace. In the 1b run (M6, Chrome with a page blocked 300 ms every second, keys
    /// 100 ± 30 ms apart) every late answer was one key behind. More would also take for
    /// late an app whose text was replaced by the same letters at the same place (⌘A the
    /// input method never sees, then the word typed again), which D11 must re-read
    /// instead. Edits made by keys that came in a burst add to it (`burst`), with a
    /// stricter check.
    static let lateLimit = 2

    /// The key being handled came less than `InPlaceComposer.settleInterval` after the
    /// previous one (set by the composer for each key).
    var keyInBurst = false
    /// How many of the latest edits were made by keys that came in a burst, one after
    /// the other: no person can click or press ⌘A between them, and an app that applies
    /// keys late may be behind all of them (M3: Chrome, VS Code, Firefox wrong under
    /// 10 ms; `docs/COMPATIBILITY.md` 6.2).
    private(set) var burst = 0

    /// One edit of the document made by this composer or by a key it let through.
    struct Edit: Equatable {
        /// The cursor before the edit.
        var cursor: Int
        /// The range replaced (it ends at or before `cursor`).
        var location: Int
        var deleted: Int
        /// The units removed, when this composer knows them (`tail`).
        var deletedText: [UInt16]?
        var inserted: [UInt16]
        /// Inserted at the app's caret without a range (`insertText` with NSNotFound: a
        /// key let through, or this composer's insertion at the cursor). Chromium writes
        /// such text into the cache it answers from at once (`rebuild`).
        var atCaret = false
    }

    enum Plan: Equatable {
        /// Replace this range (deleteCount UTF-16 units before the cursor).
        case replace(NSRange)
        /// The client does not support document access (selectedRange is NSNotFound):
        /// `replacementRange` would be ignored, so in-place replacement cannot work.
        case unsupported
        /// The cursor (or the start of the selection) is not where this word left it, or
        /// there is not enough text before the cursor. The engine state no longer matches the app.
        case mismatch
    }

    /// Decides the replacement range for `deleteCount` UTF-16 units before the cursor,
    /// given the selection the client reported.
    func plan(selection: NSRange, deleteCount: Int) -> Plan {
        if selection.location == NSNotFound || selection.length == NSNotFound { return .unsupported }
        if selection.location < 0 || selection.length < 0 || deleteCount < 0 { return .mismatch }
        if let expected, expected != selection.location { return .mismatch }
        if selection.location < deleteCount { return .mismatch }
        // A selection that starts at the cursor while the engine holds a word is an app's
        // inline autocomplete (browser address bars, Spotlight): every way the user selects
        // text (mouse, ⇧ + arrows, ⌘A) resets the engine first. Replace the suggestion
        // with the word, as any typed key replaces a selection (D11).
        return .replace(NSRange(location: selection.location - deleteCount,
                                length: deleteCount + selection.length))
    }

    // MARK: - Edits

    /// The input method replaced `range` with `text`, the cursor being at the end of
    /// `range` (or `cursor`, when the range ends before it: keys the app applies after).
    /// `atCaret`: the text was in fact inserted at the app's caret without a range (a
    /// key let through at a position read from the app, D20).
    mutating func didReplace(_ range: NSRange, text: String, cursor: Int? = nil, atCaret: Bool = false) {
        record(cursor: cursor ?? range.location + range.length, location: range.location,
               deleted: range.length, inserted: Array(text.utf16), atCaret: atCaret)
        expected = known
    }

    /// The input method inserted `text` at the cursor without asking for its position
    /// (deleteCount 0, replacementRange NSNotFound).
    mutating func didInsertAtCursor(_ text: String) {
        let length = text.utf16.count
        if let e = expected { expected = e + length }
        if let k = known { record(cursor: k, location: k, deleted: 0, inserted: Array(text.utf16), atCaret: true) }
    }

    /// The key went to the app unchanged and the app inserts `text`.
    mutating func passedThrough(_ text: String) {
        didInsertAtCursor(text)
    }

    /// The Delete key went to the app unchanged inside a word: it removes one character.
    /// Every letter the engine tracks is one UTF-16 unit (Vietnamese precomposed letters
    /// are in the BMP).
    mutating func backspacePassedThrough() {
        if let e = expected { expected = e > 0 ? e - 1 : nil }
        if let k = known {
            if k > 0 { record(cursor: k, location: k - 1, deleted: 1, inserted: []) } else { forgetPosition() }
        }
    }

    /// The Delete key went to the app with no word: it removes the character before the
    /// cursor, which is known only if this composer typed it and it is one unit that
    /// cannot combine with what precedes it (a space, a punctuation mark, a precomposed
    /// letter).
    mutating func backspaceOutsideWord() {
        expected = nil
        guard let k = known, k > 0, let last = tail.last, Self.isWholeCharacter(last) else {
            forgetPosition()
            return
        }
        record(cursor: k, location: k - 1, deleted: 1, inserted: [])
    }

    /// The word ended (a word-ending key typed here, D4; or ⌫ removed its last letter):
    /// the next word starts with no expected position (`expected`), the position itself
    /// stays known.
    mutating func endWord() {
        expected = nil
    }

    /// The position is known from the app (D20 read): start following from there.
    mutating func anchor(at location: Int) {
        if known != location { forgetPosition() }
        known = location
    }

    /// Forget the expected position: engine reset, focus or client changed.
    mutating func invalidate() {
        expected = nil
        forgetPosition()
    }

    private mutating func forgetPosition() {
        known = nil
        tail = []
        edits = []
        burst = 0
    }

    private mutating func record(cursor: Int, location: Int, deleted: Int, inserted: [UInt16],
                                 atCaret: Bool = false) {
        if known != cursor {
            // Not where this composer thought: follow from the app's answer.
            tail = []
            edits = []
            burst = 0
        }
        burst = keyInBurst ? min(burst + 1, Self.editLimit) : 0
        let back = cursor - location      // units from the start of the range to the cursor
        var deletedText: [UInt16]?
        if back >= 0, deleted >= 0, deleted <= back, back <= tail.count {
            let start = tail.count - back
            deletedText = Array(tail[start..<(start + deleted)])
            tail.replaceSubrange(start..<(start + deleted), with: inserted)
        } else {
            tail = back == deleted ? inserted : []
        }
        if tail.count > Self.tailLimit { tail.removeFirst(tail.count - Self.tailLimit) }
        edits.append(Edit(cursor: cursor, location: location, deleted: deleted,
                          deletedText: deletedText, inserted: inserted, atCaret: atCaret))
        if edits.count > Self.editLimit { edits.removeFirst(edits.count - Self.editLimit) }
        known = cursor + inserted.count - deleted
    }

    /// One UTF-16 unit that the app's Delete removes alone: not half of a surrogate pair,
    /// not a combining mark or joiner.
    static func isWholeCharacter(_ unit: UInt16) -> Bool {
        guard let scalar = Unicode.Scalar(unit) else { return false }
        switch scalar.properties.generalCategory {
        case .nonspacingMark, .spacingMark, .enclosingMark, .format, .control, .surrogate: return false
        default: return true
        }
    }

    // MARK: - An app that answers late

    /// The app answered `selection` while it had not applied the last `m` edits yet (its
    /// cursor then was before them). Returns the text before `known`: the text the app
    /// gave (`snapshot`, ending at `selection`) with those edits applied, for the first
    /// `m` (latest edits first) that fits and that `accept` takes. nil: not an app
    /// answering late (or no way to tell).
    ///
    /// The text the app gives is one of two forms (sources in `docs/ARCHITECTURE.md`,
    /// "App trả lời chậm"): the text as it was before those edits (Firefox, and Chrome
    /// when none of them was inserted at the caret); or that text plus the latest of
    /// them that was inserted at the caret (`Edit.atCaret`), which Chromium writes into
    /// its cache at once at the caret the page last reported, the answer then ending
    /// after it.
    ///
    /// Every edit whose removed text is known must find that text where it applies;
    /// `requireDeletedText`: an edit that removes text this composer does not know fails.
    /// `m` is at most `lateLimit`, plus the edits made in the latest burst of keys
    /// (`burst`); past `lateLimit`, the text the app gave before those edits must also be
    /// the text this composer typed there (`tail`), over at least two units.
    func rebuild(_ snapshot: [UInt16], at selection: NSRange,
                 requireDeletedText: Bool = false, accept: ([UInt16]) -> Bool) -> [UInt16]? {
        let end = selection.location
        guard let known, selection.length == 0, end != NSNotFound, end != known else { return nil }
        let count = min(Self.lateLimit + burst, edits.count)
        var latestAtCaret: [UInt16]?
        for m in stride(from: 1, through: count, by: 1) {
            let first = edits[edits.count - m]
            if latestAtCaret == nil, first.atCaret, !first.inserted.isEmpty { latestAtCaret = first.inserted }
            var forms: [[UInt16]] = []
            if first.cursor == end { forms.append(snapshot) }
            if let units = latestAtCaret, first.cursor + units.count == end, snapshot.count >= units.count,
               snapshot.suffix(units.count).elementsEqual(units) {
                forms.append(Array(snapshot.dropLast(units.count)))
            }
            for before in forms {
                guard let text = replay(before, endingAt: first.cursor, last: m, requireDeletedText: requireDeletedText),
                      first.cursor - before.count + text.count == known else { continue }
                if m > Self.lateLimit,
                   !typedHere(text, before: before.count, fromStart: first.cursor == before.count) { continue }
                if accept(text) { return text }
            }
        }
        // Chrome's cache is not always the text as it was some edits ago, plus the latest
        // key: the page may answer between its own updates (1d run: "hoi" + r answered
        // one behind, and neither form above fit). So the text read may be the text this
        // composer typed with any `d` of its latest units missing.
        let d = known - end
        if d >= 1, d <= Self.lateLimit, let text = withMissingUnits(snapshot, missing: d), accept(text) {
            return text
        }
        return nil
    }

    /// `before` (the app's text, ending at `cursor`) with the last `m` edits applied, or
    /// nil if one of them does not fit there.
    private func replay(_ before: [UInt16], endingAt cursor: Int, last m: Int, requireDeletedText: Bool) -> [UInt16]? {
        let base = cursor - before.count
        var text = before
        for edit in edits.suffix(m) {
            let start = edit.location - base, stop = start + edit.deleted
            guard edit.cursor == base + text.count, start >= 0, stop <= text.count else { return nil }
            if let removed = edit.deletedText {
                guard text[start..<stop].elementsEqual(removed) else { return nil }
            } else if requireDeletedText && edit.deleted > 0 {
                return nil
            }
            text.replaceSubrange(start..<stop, with: edit.inserted)
        }
        return text
    }

    /// `text` (ending at `known`, its first `count` units read from the app) ends with
    /// `tail`, and `tail` reaches at least two units into the part read: the app's own
    /// text, not only this composer's edits, is what was typed there. `fromStart`: the
    /// part read starts the document; then one unit is enough if `tail` covers all of it.
    /// With less than that (nothing read, a short `tail`), nothing tells a late answer
    /// from a text that was replaced (a field cleared and typed again).
    private func typedHere(_ text: [UInt16], before count: Int, fromStart: Bool) -> Bool {
        let n = min(text.count, tail.count)
        let reach = n - (text.count - count)
        guard reach >= 2 || (fromStart && count >= 1 && reach == count) else { return false }
        return text.suffix(n).elementsEqual(tail.suffix(n))
    }

    /// `snapshot` (ending `missing` units before `known`) is `tail` with `missing` of its
    /// last `missing + lateLimit` units left out, compared over at least two units: then
    /// the text before `known` is the start of `snapshot` followed by `tail`. nil if not.
    private func withMissingUnits(_ snapshot: [UInt16], missing d: Int) -> [UInt16]? {
        let n = min(snapshot.count, tail.count - d)
        guard n >= 2 else { return nil }
        let seen = Array(snapshot.suffix(n))
        let window = min(tail.count, d + Self.lateLimit)
        func fits(_ left: [UInt16], dropping: Int, from start: Int) -> Bool {
            if dropping == 0 { return Array(left.suffix(n)) == seen }
            for i in stride(from: start, to: left.count, by: 1) {
                var shorter = left
                shorter.remove(at: i)
                if fits(shorter, dropping: dropping - 1, from: i) { return true }
            }
            return false
        }
        guard fits(tail, dropping: d, from: tail.count - window) else { return nil }
        return Array(snapshot.dropLast(n)) + Array(tail.suffix(n + d))
    }
}
