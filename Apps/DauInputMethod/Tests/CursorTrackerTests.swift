import Foundation
import Testing

@Suite("CursorTracker (method A + D11 drift check)")
struct CursorTrackerTests {
    private let notFound = NSRange(location: NSNotFound, length: NSNotFound)

    private func at(_ location: Int, _ length: Int = 0) -> NSRange {
        NSRange(location: location, length: length)
    }

    @Test("first replacement of a word trusts selectedRange")
    func firstReplacement() {
        let t = CursorTracker()
        #expect(t.plan(selection: at(10), deleteCount: 1) == .replace(at(9, 1)))
        #expect(t.plan(selection: at(3), deleteCount: 3) == .replace(at(0, 3)))
    }

    @Test("no document access: NSNotFound is reported as unsupported")
    func unsupported() {
        let t = CursorTracker()
        #expect(t.plan(selection: notFound, deleteCount: 1) == .unsupported)
        #expect(t.plan(selection: NSRange(location: NSNotFound, length: 0), deleteCount: 1) == .unsupported)
    }

    @Test("too little text or negative values are a mismatch")
    func invalid() {
        let t = CursorTracker()
        #expect(t.plan(selection: at(1), deleteCount: 2) == .mismatch)
        #expect(t.plan(selection: at(1, 5), deleteCount: 2) == .mismatch)
        #expect(t.plan(selection: at(-1), deleteCount: 1) == .mismatch)
        #expect(t.plan(selection: at(5), deleteCount: -1) == .mismatch)
    }

    @Test("tooi: t o pass, o replaces, i passes; the next replacement must match")
    func followsTheWord() {
        // Document "x " then the word starts at 2.
        var t = CursorTracker()
        t.passedThrough("t") // nothing known yet
        t.passedThrough("o")
        #expect(t.expected == nil)
        guard case .replace(let r) = t.plan(selection: at(4), deleteCount: 1) else {
            Issue.record("expected a replacement"); return
        }
        t.didReplace(r, text: "ô")
        #expect(t.expected == 4)
        t.passedThrough("i")
        #expect(t.expected == 5)
        #expect(t.plan(selection: at(5), deleteCount: 2) == .replace(at(3, 2)))
    }

    @Test("D11: inline autocomplete — 'go' + selected 'ogle.com', x replaces word and suggestion")
    func inlineAutocomplete() {
        // First replacement of the word: nothing expected yet, the suggestion is selected.
        var t = CursorTracker()
        #expect(t.plan(selection: at(2, 8), deleteCount: 2) == .replace(at(0, 10)))
        // Later in the word the suggestion must start where the word ended.
        t.didReplace(at(0, 10), text: "gõ")
        #expect(t.plan(selection: at(2, 6), deleteCount: 2) == .replace(at(0, 8)))
        #expect(t.plan(selection: at(5, 6), deleteCount: 2) == .mismatch)
    }

    @Test("D11: the cursor moved without a reported click → mismatch")
    func drift() {
        var t = CursorTracker()
        t.didReplace(at(9, 1), text: "x")
        #expect(t.plan(selection: at(42), deleteCount: 1) == .mismatch)
        #expect(t.plan(selection: at(10), deleteCount: 1) == .replace(at(9, 1)))
    }

    @Test("pass-through Delete moves the expectation back by one")
    func backspace() {
        var t = CursorTracker()
        t.didReplace(at(9, 1), text: "xy")
        t.backspacePassedThrough()
        #expect(t.expected == 10)
        var z = CursorTracker()
        z.didReplace(at(0, 0), text: "")
        z.backspacePassedThrough()
        #expect(z.expected == nil)
    }

    @Test("insertion at the cursor and invalidation")
    func insertAndInvalidate() {
        var t = CursorTracker()
        t.didInsertAtCursor("x")
        #expect(t.expected == nil)
        t.didReplace(at(4, 1), text: "x")
        t.didInsertAtCursor("yz")
        #expect(t.expected == 7)
        t.invalidate()
        #expect(t.expected == nil)
        #expect(t.plan(selection: at(100), deleteCount: 1) == .replace(at(99, 1)))
    }

    // MARK: Following the cursor across words (an app that answers late, M6)

    @Test("the position is followed across a word end; the expected one is not")
    func knownAcrossWords() {
        var t = CursorTracker()
        t.anchor(at: 0)
        t.passedThrough("b"); t.passedThrough("a")
        t.didReplace(at(1, 1), text: "á")
        t.passedThrough(" ")
        t.endWord()
        #expect(t.expected == nil)
        #expect(t.known == 3)
        #expect(t.tail == Array("bá ".utf16))
        t.passedThrough("n")
        #expect(t.known == 4)
        #expect(t.edits.last == CursorTracker.Edit(cursor: 3, location: 3, deleted: 0, deletedText: [], inserted: Array("n".utf16),
                                                   atCaret: true))
    }

    @Test("an answer one edit late: the text read plus that edit, checked by the caller")
    func rebuildOneLate() {
        var t = CursorTracker()
        t.anchor(at: 4)
        for c in ["b", "a", "n"] { t.passedThrough(c) }
        // The app answers 6 with "xx, ba" while "ban" is typed (known 7).
        let snapshot = Array("xx, ba".utf16)
        #expect(t.rebuild(snapshot, at: at(6), accept: { _ in true }) == Array("xx, ban".utf16))
        // The caller refuses it (not the engine's word): nothing.
        #expect(t.rebuild(snapshot, at: at(6), accept: { _ in false }) == nil)
        // On time, a selection, or more than `lateLimit` edits behind: nothing.
        #expect(t.rebuild(Array("xx, ban".utf16), at: at(7), accept: { _ in true }) == nil)
        #expect(t.rebuild(snapshot, at: at(6, 1), accept: { _ in true }) == nil)
        #expect(t.rebuild(Array("xx, ".utf16), at: at(4), accept: { _ in true }) == nil)
    }

    @Test("a late answer must contain the text the edits removed")
    func rebuildChecksRemovedText() {
        var t = CursorTracker()
        t.anchor(at: 0)
        for c in ["H", "o", "c", " "] { t.passedThrough(c) }
        t.backspaceOutsideWord()
        #expect(t.known == 3)
        // Answer from before the ⌫: "Hoc " at 4.
        #expect(t.rebuild(Array("Hoc ".utf16), at: at(4), requireDeletedText: true, accept: { _ in true }) == Array("Hoc".utf16))
        // Something else before the cursor at 4: not a late answer.
        #expect(t.rebuild(Array("Hocx".utf16), at: at(4), requireDeletedText: true, accept: { _ in true }) == nil)
    }

    @Test("⌫ with no word: known only after a character this composer typed")
    func backspaceOutsideWord() {
        var t = CursorTracker()
        t.anchor(at: 5)
        t.backspaceOutsideWord()          // nothing typed here: unknown
        #expect(t.known == nil)
        t.anchor(at: 5)
        t.passedThrough(" ")
        t.backspaceOutsideWord()
        #expect(t.known == 5)
        #expect(t.edits.last?.deletedText == Array(" ".utf16))
        // A combining mark could join the character before it: unknown.
        t.passedThrough("\u{0301}")
        t.backspaceOutsideWord()
        #expect(t.known == nil)
    }

    @Test("an answer elsewhere starts following again from it")
    func reanchor() {
        var t = CursorTracker()
        t.anchor(at: 10)
        t.passedThrough("a")
        t.didReplace(at(20, 1), text: "á")
        #expect(t.known == 21)
        #expect(t.edits.count == 1)
        #expect(t.tail == Array("á".utf16))
        t.invalidate()
        #expect(t.known == nil && t.edits.isEmpty && t.tail.isEmpty)
    }
}
