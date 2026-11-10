import Foundation
import DauEngine
import DauShared

/// An app that applies every edit in order (keys it types, `insertText` with absolute
/// ranges) but answers `selectedRange` and `attributedSubstring` from an earlier state
/// of its text: Chrome with a busy page (M6 step 1, log of 09/11/2026), and apps that
/// apply keys asynchronously when keys come in a burst (Chromium, Electron, Firefox;
/// `docs/COMPATIBILITY.md` 6.2).
///
/// Which earlier state: `lag` edits ago (set per key, so each word of a log can be
/// replayed exactly), or, with `clock` set, the latest state the app has reported by
/// then (`work`, `reportDelay`: the app applies one edit after the other).
///
/// Order: the app applies the input method's `insertText` after the keys sent before
/// it. Chromium source (main, read 09–10/11/2026): key events and `ImeCommitText` go
/// through the same `WidgetInputHandler` interface, and in the renderer both end in
/// `MainThreadEventQueue` (`WidgetInputHandlerImpl::RunOnMainThread`, `DispatchEvent`);
/// the compositor-thread hop of key events was not read. Firefox: the parent sends the
/// set-selection and insert-text events of a replacement to the content process after
/// the key events before them (`TextInputHandler.mm`, `InsertTextAsCommittingComposition`).
final class LateDocument: InPlaceClient {
    /// What the app answers from.
    enum Cache {
        /// The text and caret of the earlier state as they were (Firefox:
        /// `ContentCacheInParent` and `IMEInputHandler::mSelectedRange`, both updated
        /// only when the content process reports).
        case snapshot
        /// Chromium's browser-side cache (`render_widget_host_view_cocoa.mm`): the state
        /// the page reported last, plus every `insertText` with NSNotFound since (a key
        /// let through, the input method's own insertion at the caret), each written into
        /// `_availableText` at the caret the page reported (`_markedRange.location`), so
        /// later ones before earlier ones; `_textSelectionRange` is that caret plus the
        /// length of the latest one. `insertText` with a range is not written.
        case chromium
    }

    /// Where the caret goes when `insertText` replaces a range that ends before it.
    enum Replace {
        /// It stays after the text that follows, shifted by the change in length: Blink's
        /// `ReplaceTextAndKeepSelection` (Chrome text fields, contenteditable).
        case keepSelection
        /// It goes to the end of the inserted text: Blink's `EditContext::CommitText`
        /// (VS Code, whose editor uses the EditContext API by default, option
        /// `editor.editContext`), Firefox (selects the range, then inserts).
        case caretAfterText
    }

    struct State {
        var text: [UInt16]
        var cursor: Int
        /// Text inserted at the caret by this edit (`insertText` with NSNotFound).
        var atCaret: [UInt16]? = nil
        /// When the app has applied this edit and told the input method's side about it.
        var reportAt: TimeInterval = -.infinity
    }
    private(set) var states: [State]
    var cache = Cache.snapshot
    var replace = Replace.keepSelection
    /// Edits the answers are behind by (when `clock` is nil).
    var lag = 0
    /// Timed answers: the latest state reported at or before `clock`.
    var clock: TimeInterval?
    /// When the next edit reaches the app (timed answers).
    var sentAt: TimeInterval = 0
    /// Seconds the app takes to apply one edit, after the previous one (timed answers).
    var work: () -> TimeInterval = { 0 }
    var reportDelay: TimeInterval = 0
    private var lastApplied: TimeInterval = -.infinity
    /// For one key: answer with this text before the caret instead (a state no model
    /// above gives).
    var override: String?
    /// Calls during the current key (N3).
    var selections = 0, reads = 0, inserts = 0
    /// An `insertText` whose range is outside the real text (never expected).
    var badRanges = 0
    /// The largest number of edits an answer was behind (timed answers).
    private(set) var maxBehind = 0

    init(_ text: String = "") {
        let units = Array(text.utf16)
        states = [State(text: units, cursor: units.count)]
    }

    var text: String { String(decoding: states[states.count - 1].text, as: UTF16.self) }

    private var answer: State {
        if let override { let units = Array(override.utf16); return State(text: units, cursor: units.count) }
        let last = states.count - 1
        let index: Int
        if let clock {
            index = states.lastIndex { $0.reportAt <= clock } ?? 0
            maxBehind = max(maxBehind, last - index)
        } else {
            index = max(0, last - lag)
        }
        var state = states[index]
        if cache == .chromium, index < last {
            let caret = state.cursor
            var latest: [UInt16]?
            for later in states[(index + 1)...] {
                guard let units = later.atCaret, caret <= state.text.count else { continue }
                state.text.insert(contentsOf: units, at: caret)
                latest = units
            }
            if let latest { state.cursor = caret + latest.count }
        }
        return state
    }

    func selectedRange() -> NSRange {
        selections += 1
        return NSRange(location: answer.cursor, length: 0)
    }

    func text(in range: NSRange) -> String? {
        reads += 1
        let units = answer.text
        guard range.location >= 0, range.length >= 0, range.location + range.length <= units.count else { return nil }
        return String(decoding: units[range.location..<(range.location + range.length)], as: UTF16.self)
    }

    func insertText(_ string: String, replacementRange: NSRange) {
        inserts += 1
        var state = states[states.count - 1]
        let range = replacementRange.location == NSNotFound
            ? NSRange(location: state.cursor, length: 0) : replacementRange
        guard range.location >= 0, range.location + range.length <= state.text.count else {
            badRanges += 1
            return
        }
        let units = Array(string.utf16)
        state.text.replaceSubrange(range.location..<(range.location + range.length), with: units)
        let end = range.location + range.length
        if replacementRange.location == NSNotFound || state.cursor < end || replace == .caretAfterText {
            state.cursor = range.location + units.count
        } else {
            // The caret was after the range (keys the input method had not seen applied
            // yet): it stays after them, shifted by the change in length. The 1b texts
            // show this ("ạnn gửi", no stray "n" at the end of the text).
            state.cursor += units.count - range.length
        }
        state.atCaret = replacementRange.location == NSNotFound ? units : nil
        append(state)
    }

    private func append(_ state: State) {
        var state = state
        if clock != nil {
            let applied = max(sentAt, lastApplied) + work()
            lastApplied = applied
            state.reportAt = applied + reportDelay
        }
        states.append(state)
    }

    /// An edit the app makes on its own (autocorrect, smart dashes): the new state.
    func appEdit(_ text: String) {
        let units = Array(text.utf16)
        append(State(text: units, cursor: units.count))
    }

    /// What the app does with a key the input method left to it.
    func typed(_ route: KeyRoute) {
        switch route {
        case .character(let c):
            let n = inserts
            insertText(String(Character(c)), replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
            inserts = n
        case .backspace:
            var state = states[states.count - 1]
            guard state.cursor > 0 else { return }
            state.text.remove(at: state.cursor - 1)
            state.cursor -= 1
            state.atCaret = nil
            append(state)
        case .endWord:
            let n = inserts
            insertText("\n", replacementRange: NSRange(location: NSNotFound, length: NSNotFound))
            inserts = n
        case .ignore:
            break
        }
    }
}

/// Deterministic generator for the random sequences, lags and timings of the tests (SplitMix64).
struct SplitMix {
    var state: UInt64
    init(_ seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    /// Uniform in [low, high].
    mutating func uniform(_ low: Double, _ high: Double) -> Double {
        low + (high - low) * Double(next() >> 11) / Double(1 << 53)
    }
}
