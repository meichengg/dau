import Foundation
import os

/// Timing of one key, for the open question A/B (cost of `selectedRange` per app), and
/// when it arrived (`t_ns`, `ev_ns`), for the gaps between keys under load (M6).
///
/// D8: only numbers, a fixed event kind and the client's bundle ID are logged. Never the
/// characters typed, the engine output or any text read from the client.
///
/// Debug builds only (D8): Release builds log nothing per key and emit no signposts,
/// whatever the defaults say. Even without text, per-key times and apps are typing
/// metadata, and anyone running code as the user could switch them on with
/// `defaults write` and read them with `log show`, without the Input Monitoring
/// permission a keylogger needs. In Debug, the per-key `os.Logger` line is on only while
/// `DauPerfLog` is set; `scripts/perf/perf-report.sh` reads it with `log show`.
struct PerfLog {
    static let subsystem = Bundle.main.bundleIdentifier ?? "DauInputMethod"
    static let logger = Logger(subsystem: subsystem, category: "perf")
    #if DEBUG
    static let signposter = OSSignposter(subsystem: subsystem, category: "perf")
    #else
    static let signposter = OSSignposter.disabled
    #endif

    /// Event kinds. Raw values are parsed by scripts/perf/perf-report.sh.
    enum Kind: String {
        /// Key went to the app unchanged, no client call.
        case pass
        /// selectedRange + insertText(replacementRange:).
        case replace
        /// insertText at the cursor without selectedRange (deleteCount 0).
        case insert
        /// selectedRange disagreed with the expected position (D11): engine reset.
        case mismatch
        /// selectedRange returned NSNotFound (no document access): engine reset.
        case unsupported
        /// Shortcut, navigation key, mouse click: engine reset (D4).
        case reset
        /// Underline mode (D13): setMarkedText with the word, no selectedRange.
        case mark
        /// Underline mode (D13): insertText of the marked word (word end or reset event),
        /// replacementRange NSNotFound, no selectedRange.
        case commit
        /// D20: selectedRange + attributedSubstring read a word before the cursor, the
        /// engine was seeded with it and the key replaced it (one insertText).
        case seed
        /// D20: a word was read and seeded, but the key does not apply to it
        /// ("viet" + j): the key went to the app unchanged.
        case seedPass = "seed_pass"
        /// D20: selectedRange (and attributedSubstring if there was text before the
        /// cursor) found no word to seed, or a plain letter did not join the word read
        /// (E8); the key was handled as the first of a word.
        case seedNone = "seed_none"
        /// D11: a mismatch, then the word before the cursor was read and seeded, and the
        /// key replaced it (one more attributedSubstring than a plain mismatch).
        case resync
        /// D11: re-synced as above, but the key does not apply to the word read: it went
        /// to the app unchanged.
        case resyncPass = "resync_pass"
        /// selectedRange answered from before the input method's latest edits (the app
        /// had not applied them yet: Chrome with a busy page, M6); one attributedSubstring
        /// showed that text plus those edits is the engine's word, and the key replaced
        /// it at the position the input method followed (one insertText).
        case late
        /// As `late`, but the text read did not prove it: the first replacement of a word,
        /// the answer at most `CursorTracker.lateLimit` behind, and the whole word not before
        /// it (which an app that edited the text would show). Replaced at the followed
        /// position (`InPlaceComposer.replace`).
        case lateGuess = "late_guess"
    }

    /// Off unless `DauPerfLog` is set, in Debug builds too: even without text, one line
    /// per key with its time and app is typing metadata (D8). Set in the global domain,
    /// which a shell can write and the sandboxed input method reads
    /// (`defaults write -g DauPerfLog -bool true`); read when a client session starts,
    /// so it applies to the next text field. The measuring scripts set it and remove it.
    static let defaultsKey = "DauPerfLog"
    let enabled: Bool

    init() {
        #if DEBUG
        enabled = UserDefaults.standard.bool(forKey: Self.defaultsKey)
        #else
        enabled = false
        #endif
    }

    @inline(__always) static func now() -> UInt64 {
        clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
    }

    /// `NSEvent.timestamp` (seconds since boot, the same uptime clock as `now()`) in ns,
    /// or 0 when IMK passed something that is not a usable time (D18: never trap on a
    /// negative, NaN or huge value).
    static func eventNs(_ timestamp: TimeInterval) -> UInt64 {
        guard timestamp.isFinite, timestamp > 0, timestamp < 1e9 else { return 0 }
        return UInt64(timestamp * 1e9)
    }

    /// - Parameters:
    ///   - startNs: `now()` when `handle` started (`t_ns`): when the key reached the input
    ///     method. Gaps between keys, and `t_ns - ev_ns` (time from the event's creation
    ///     to the input method), tell keys a busy app delivered in a burst from keys sent
    ///     close together (scripts/perf/perf-report.sh).
    ///   - eventNs: the event's own time (`ev_ns`, `eventNs(_:)`), 0 if unknown.
    ///   - selectedRangeNs: duration of the `selectedRange()` call, or -1 if not called.
    ///   - insertTextNs: duration of the `insertText` call (or, for `mark`, of the
    ///     `setMarkedText` call), or -1 if not called.
    ///   - readNs: duration of the `attributedSubstring` call (D20), or -1 if not called.
    ///   - extra: D20 fields, each with a leading space (` d20=letter seeded=1 diff=0`);
    ///     only numbers and fixed words, never text (D8).
    func record(_ kind: Kind, startNs: UInt64, eventNs: UInt64, handleNs: UInt64,
                selectedRangeNs: Int64, insertTextNs: Int64,
                readNs: Int64 = -1, extra: String = "", app: String) {
        #if DEBUG
        guard enabled else { return }
        PerfLog.logger.notice(
            "key kind=\(kind.rawValue, privacy: .public) t_ns=\(startNs, privacy: .public) ev_ns=\(eventNs, privacy: .public) handle_ns=\(handleNs, privacy: .public) sel_ns=\(selectedRangeNs, privacy: .public) ins_ns=\(insertTextNs, privacy: .public) read_ns=\(readNs, privacy: .public) app=\(app, privacy: .public)\(extra, privacy: .public)"
        )
        #endif
    }

    /// Non-key events worth counting while testing (client changed, mode changed…).
    func note(_ event: StaticString, app: String) {
        #if DEBUG
        guard enabled else { return }
        PerfLog.logger.notice("event name=\(String(describing: event), privacy: .public) app=\(app, privacy: .public)")
        #endif
    }
}
