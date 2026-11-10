// Real-window checker of the Settings window (docs/UI-CHECKS.md). run.sh launches the
// Debug app itself, as the user opens it (`open -n Dau.app --args … --settings-window`),
// once per state, and compiles this file together with Reference.swift (every expected
// value, with its source). Nothing here runs inside the app.
//
// Usage: ax-check <pid> <output-dir> <light|dark> <mode>…
//   <light|dark>   the appearance the app draws in (run.sh knows it); written to frames.json.
//   --geometry     (When scrolling scroll bars) The page and Back/Forward at launch. Then on
//                  every display, one pass per backing scale (rows labelled "2x" / "1x"):
//                  each section, selected through the sidebar's accessibility, against
//                  System Settings (toolbar, Back/Forward cluster, system title, sidebar,
//                  Form). On the primary display only: the sidebar search with a query
//                  nothing matches; the add-rule sheet ("+" on Ứng dụng): the app list
//                  (settles, overflows, scroll bar, wheel, always-installed apps, end of
//                  list), search and selection wiring, Huỷ. Then the window's size limits
//                  (by resizing it; the width is fixed, only the height changes).
//                  Last, the shell: Back/Forward through the buttons and ⌘[ ⌘] (key
//                  events), also under the sheet, and the sidebar's width at the widest
//                  and narrowest window. What a test can hold without a real window (the
//                  View menu's sidebar item, the divider's mouse area) is `swift test`
//                  "Settings window shell"; the not-enabled banner is `swift test`
//                  "Not-enabled banner".
//                  --geometry starts with the --focus launch rows.
//   --focus        At launch, before anything else: the sidebar list has the focus (not
//                  the search field) and the selected row shows the accent selection
//                  (pixels of `launch-focus.png` against the system's accent and inactive
//                  grey, in the app's appearance). Alone (run.sh --focus): then Tab and ⌘F
//                  into the sidebar search and the sidebar search rows, primary display.
//   --pixels       (Always scroll bars) Primary display: per section the scroll room rule
//                  (a) and a screenshot; on the section that overflows
//                  (Reference.scrollingSection) a scroll through its scroll bar, the
//                  scroll bar's lane (d) and a second screenshot. check.swift reads the
//                  screenshots for (b)–(d).
//   --sheet-shots  Primary display: screenshots of the add-rule sheet, empty and with a
//                  row selected (no rows: --geometry checks the sheet).
//   --shell        Only the Back/Forward rows (a quick pass on a running app).
// Screenshots are `screencapture -l` of the Settings window only (an attached sheet is
// in it), named <name>-<scale>x.png; <output-dir>/frames.json holds the frames of every
// screenshot (window points, origin at the window's top-left) for check.swift and
// scripts/snapshot-settings, plus "meta": the primary display's scale and the appearance.
//
// Results, one row each, `display | page | metric | expected | got | result`:
// - HARNESS only when the checker cannot run: no Accessibility permission, no window for
//   the pid, an Accessibility call that errors or times out, a screenshot the system
//   will not take, or a state the next steps need that does not come in time (rows
//   "wait: …"). Not a UI result.
// - Waits are for a state (`waitUntil`, `waitSettled`), not a fixed time; a fixed `wait`
//   is left only where nothing can be read, and says why.
// - FAIL for everything the window should show but does not, or shows in a wrong state: a
//   missing element (card, header, button, "+", search field, scroll bar), a list that
//   never settles or stays empty, a sheet that does not open, a value off Reference.
// - There is no skip. Every lookup goes through `require`, which records FAIL or HARNESS
//   when it finds nothing; a check that cannot run without it says so in that row. Every
//   return while the add-rule sheet is open goes back through `closeSheet`.
// Exit status 0 only when every row is ok.
import AppKit

// MARK: - Arguments

let usage = "usage: ax-check <pid> <output-dir> <light|dark> --geometry | --focus | --pixels | --sheet-shots | --shell …"
let modeFlags: Set = ["--geometry", "--focus", "--pixels", "--sheet-shots", "--shell"]
let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count >= 4, let pid = pid_t(arguments[0]), ["light", "dark"].contains(arguments[2]),
      Set(arguments.dropFirst(3)).isSubset(of: modeFlags) else {
    print(usage)
    exit(2)
}
let outDir = URL(fileURLWithPath: arguments[1], isDirectory: true)
let appearance = arguments[2]
let modes = Set(arguments.dropFirst(3))
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// MARK: - Results

// Top-level code is single-threaded; Swift 6 would isolate globals to the main actor.
nonisolated(unsafe) var rows: [String] = []
nonisolated(unsafe) var failures: [String] = []
nonisolated(unsafe) var harnessProblems: [String] = []
/// Frames of every screenshot taken, by file name (without ".png"), for frames.json.
nonisolated(unsafe) var shots: [String: [String: [Double]]] = [:]

func record(_ d: String, _ p: String, _ metric: String, expected: String, got: String, ok: Bool) {
    rows.append("\(d) | \(p) | \(metric) | \(expected) | \(got) | \(ok ? "ok" : "FAIL")")
    if !ok { failures.append("\(d) \(p) \(metric): expected \(expected), got \(got)") }
}
/// The checker could not do its part (see the header): not a UI result.
func harness(_ d: String, _ p: String, _ metric: String, expected: String, got: String) {
    rows.append("\(d) | \(p) | \(metric) | \(expected) | \(got) | HARNESS")
    harnessProblems.append("\(d) \(p) \(metric): \(expected) / \(got)")
}
/// A harness problem before any row can be measured: print it and stop.
func harnessAbort(_ metric: String, expected: String, got: String) -> Never {
    print("HARNESS - - \(metric): \(expected) / \(got)")
    print("1 harness problem(s): the checker could not run; not a UI result.")
    exit(1)
}

func fmt(_ v: CGFloat) -> String { v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v) }
func fmt(_ r: CGRect) -> String { "\(fmt(r.minX)),\(fmt(r.minY)) \(fmt(r.width))×\(fmt(r.height))" }
func near(_ a: CGFloat, _ b: CGFloat, _ tolerance: CGFloat = Reference.tolerance) -> Bool { abs(a - b) <= tolerance }
func check(_ d: String, _ p: String, _ metric: String, _ got: CGFloat, _ expected: CGFloat,
           tolerance: CGFloat = Reference.tolerance) {
    record(d, p, metric, expected: fmt(expected), got: fmt(got), ok: near(got, expected, tolerance))
}
func check(_ d: String, _ p: String, _ metric: String, _ got: CGRect, _ expected: CGRect) {
    let ok = near(got.minX, expected.minX) && near(got.minY, expected.minY)
        && near(got.width, expected.width) && near(got.height, expected.height)
    record(d, p, metric, expected: fmt(expected), got: fmt(got), ok: ok)
}

// MARK: - Accessibility

guard AXIsProcessTrusted() else {
    harnessAbort("Accessibility permission", expected: "granted to this terminal",
                 got: "missing (System Settings › Privacy & Security › Accessibility)")
}

nonisolated(unsafe) let app = AXUIElementCreateApplication(pid)
AXUIElementSetMessagingTimeout(app, 5)

/// Accessibility calls that failed (not "no such attribute" or "no value", which are
/// answers): a lookup that finds nothing while one of these happened is HARNESS.
nonisolated(unsafe) var axErrors: [String] = []

func attr(_ e: AXUIElement, _ name: String) -> CFTypeRef? {
    var v: CFTypeRef?
    let err = AXUIElementCopyAttributeValue(e, name as CFString, &v)
    switch err {
    case .success: return v
    // Answers: the element has no such attribute, no value, or is gone.
    case .noValue, .attributeUnsupported, .invalidUIElement, .notImplemented: return nil
    default:
        axErrors.append("read \(name): AXError \(err.rawValue)")
        return nil
    }
}
func string(_ e: AXUIElement, _ name: String) -> String? { attr(e, name) as? String }
func children(_ e: AXUIElement) -> [AXUIElement] { (attr(e, kAXChildrenAttribute) as? [AXUIElement]) ?? [] }
func frame(_ e: AXUIElement) -> CGRect {
    var p = CGPoint.zero, s = CGSize.zero
    if let v = attr(e, kAXPositionAttribute) { AXValueGetValue(v as! AXValue, .cgPoint, &p) }
    if let v = attr(e, kAXSizeAttribute) { AXValueGetValue(v as! AXValue, .cgSize, &s) }
    return CGRect(origin: p, size: s)
}
func label(_ e: AXUIElement) -> String {
    for name in [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute] {
        if let s = string(e, name), !s.isEmpty { return s }
    }
    // A Form row's control is titled by its row label (what VoiceOver reads).
    if let title = attr(e, kAXTitleUIElementAttribute), CFGetTypeID(title) == AXUIElementGetTypeID() {
        return string(title as! AXUIElement, kAXValueAttribute) ?? ""
    }
    return ""
}
func all(_ e: AXUIElement, depth: Int = 0, where match: (AXUIElement) -> Bool) -> [AXUIElement] {
    guard depth < 40 else { return [] }
    var out = match(e) ? [e] : []
    for c in children(e) { out += all(c, depth: depth + 1, where: match) }
    return out
}
func role(_ e: AXUIElement) -> String { string(e, kAXRoleAttribute) ?? "" }
func subrole(_ e: AXUIElement) -> String { string(e, kAXSubroleAttribute) ?? "" }
func enabled(_ e: AXUIElement) -> Bool { (attr(e, kAXEnabledAttribute) as? Bool) ?? false }
func rowCount(_ e: AXUIElement) -> Int { (attr(e, kAXRowsAttribute) as? [AXUIElement])?.count ?? 0 }
/// A fixed wait on the main run loop. Only for pacing where nothing can be observed
/// (between synthesized events, the pointer settling, or a window in which nothing may
/// change); everything else waits for a state with `waitUntil` or `waitSettled`.
func wait(_ seconds: Double) { RunLoop.main.run(until: Date().addingTimeInterval(seconds)) }

/// Polls `condition` every `interval` s on the main run loop until it holds or `timeout` s
/// have passed (it is read once more at the deadline). True when it held.
@discardableResult
func waitUntil(timeout: Double, interval: Double = 0.1, _ condition: () -> Bool) -> Bool {
    let start = Date()
    while !condition() {
        guard Date().timeIntervalSince(start) < timeout else { return condition() }
        wait(interval)
    }
    return true
}

/// Reads `read` every `interval` s until it gives the same value on `reads` reads in a row,
/// each accepted by `valid`, or `timeout` s have passed. Returns the last value, whether it
/// settled, and the time taken.
func waitSettled<T: Equatable>(timeout: Double, interval: Double = 0.2, reads: Int = 3,
                               valid: (T) -> Bool = { _ in true },
                               _ read: () -> T) -> (value: T, settled: Bool, seconds: Double) {
    let start = Date()
    var last = read(), same = valid(last) ? 1 : 0
    while same < reads && Date().timeIntervalSince(start) < timeout {
        wait(interval)
        let now = read()
        same = valid(now) && now == last ? same + 1 : (valid(now) ? 1 : 0)
        last = now
    }
    return (last, same >= reads, Date().timeIntervalSince(start))
}

/// `waitUntil` for a state the next steps rely on without checking it themselves: a
/// timeout is a HARNESS row (the checker could not bring the window into that state).
@discardableResult
func awaitState(_ d: String, _ p: String, _ what: String, timeout: Double, _ condition: () -> Bool) -> Bool {
    if waitUntil(timeout: timeout, condition) { return true }
    harness(d, p, "wait: \(what)", expected: "within \(fmt(CGFloat(timeout))) s", got: "not reached")
    return false
}

/// `waitSettled` for a frame or layout the next measurements rely on: a value still moving
/// at the timeout is a HARNESS row.
@discardableResult
func awaitSettled<T: Equatable>(_ d: String, _ p: String, _ what: String, timeout: Double = 3,
                                interval: Double = 0.1, reads: Int = 3, valid: (T) -> Bool = { _ in true },
                                _ read: () -> T) -> Bool {
    let r = waitSettled(timeout: timeout, interval: interval, reads: reads, valid: valid, read)
    if !r.settled {
        harness(d, p, "wait: \(what) settles", expected: "the same on \(reads) reads within \(fmt(CGFloat(timeout))) s",
                got: "still changing")
    }
    return r.settled
}

/// Dấu is the frontmost app (its windows draw active and get the keys).
func appIsFrontmost() -> Bool { (attr(app, kAXFrontmostAttribute) as? Bool) == true }
/// Brings Dấu to the front through accessibility and waits until it is.
@discardableResult
func bringToFront(_ d: String, _ p: String) -> Bool {
    guard drive(d, p, "bring Dấu to the front", set(app, kAXFrontmostAttribute, kCFBooleanTrue)) else { return false }
    return awaitState(d, p, "Dấu frontmost", timeout: 3, appIsFrontmost)
}

func set(_ e: AXUIElement, _ name: String, _ value: CFTypeRef) -> AXError {
    AXUIElementSetAttributeValue(e, name as CFString, value)
}
func press(_ e: AXUIElement) -> AXError { AXUIElementPerformAction(e, kAXPressAction as CFString) }
func axPoint(_ p: CGPoint) -> AXValue { var p = p; return AXValueCreate(.cgPoint, &p)! }
func axSize(_ s: CGSize) -> AXValue { var s = s; return AXValueCreate(.cgSize, &s)! }

/// Drives the window through accessibility (select, set a value, press, move). A refusal
/// means the checker cannot do its part: HARNESS under `what`. Success records no row.
@discardableResult
func drive(_ d: String, _ p: String, _ what: String, _ err: AXError) -> Bool {
    guard err != .success else { return true }
    harness(d, p, what, expected: "accessibility action done", got: "AXError \(err.rawValue)")
    return false
}

/// Every lookup of an element a check needs. Waits up to `seconds` for `find`; nothing
/// found records FAIL (the window does not show it; `diagnose` says what it shows
/// instead) or HARNESS (an Accessibility call failed meanwhile), and returns nil.
func require<T>(_ d: String, _ p: String, _ what: String, within seconds: Double = 0,
                diagnose: () -> String = { "missing" }, find: () -> T?) -> T? {
    let mark = axErrors.count
    var found = find()
    if found == nil {
        waitUntil(timeout: seconds, interval: 0.2) { found = find(); return found != nil }
    }
    if let found { return found }
    if axErrors.count > mark {
        harness(d, p, what, expected: "present", got: "Accessibility error: "
                + axErrors[mark...].suffix(2).joined(separator: "; "))
    } else {
        record(d, p, what, expected: "present", got: diagnose(), ok: false)
    }
    return nil
}

/// `require` for an element whose presence is itself a check users hit (a sheet that did
/// not open, a missing scroll bar): also an ok row when it is there.
func requireShown<T>(_ d: String, _ p: String, _ what: String, within seconds: Double = 0,
                     diagnose: () -> String = { "missing" }, find: () -> T?) -> T? {
    let found = require(d, p, what, within: seconds, diagnose: diagnose, find: find)
    if found != nil { record(d, p, what, expected: "present", got: "present", ok: true) }
    return found
}

// MARK: - The window

func standardWindows() -> [AXUIElement] {
    ((attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? [])
        .filter { role($0) == "AXWindow" && subrole($0) == "AXStandardWindow" }
}

/// The Settings window: with --settings-window the app opens no other standard window. Its
/// title is the page's, so it is no identity; a window without its sidebar still counts
/// here, and the sidebar lookups then FAIL.
nonisolated(unsafe) let window: AXUIElement = {
    var found: AXUIElement?
    if waitUntil(timeout: 15, interval: 0.2, { found = standardWindows().first; return found != nil }), let found {
        return found
    }
    let shown = ((attr(app, kAXWindowsAttribute) as? [AXUIElement]) ?? [])
        .map { "\(subrole($0)) \"\(string($0, kAXTitleAttribute) ?? "")\" \(fmt(frame($0)))" }
    harnessAbort("Settings window", expected: "a window for pid \(pid) within 15 s",
                 got: "none; windows: \(shown.isEmpty ? "none" : shown.joined(separator: "; "))")
}()

let sections = Reference.sections
/// System: the Always scroll bar's width (check (a)).
let alwaysBarWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy)
let appsIndex = sections.firstIndex(of: "apps")!
let sidebarWidth = Reference.sidebarWidth, formMargin = Reference.formMargin

/// Elements of the window itself, the add-rule sheet left out (it has outlines, search
/// fields and scroll areas of its own and can lie over the sidebar column).
func windowElements(where match: (AXUIElement) -> Bool) -> [AXUIElement] {
    children(window).filter { role($0) != "AXSheet" }.flatMap { all($0, where: match) }
}
/// Window-relative frame (origin at the window's top-left).
func rel(_ e: AXUIElement) -> CGRect {
    let w = frame(window)
    return frame(e).offsetBy(dx: -w.minX, dy: -w.minY)
}

/// Outlines in the sidebar column (no stable label: by where they lie).
func sidebarOutlines() -> [AXUIElement] {
    windowElements { role($0) == "AXOutline" }
        .filter { let x = rel($0).minX; return x >= -Reference.tolerance && x < sidebarWidth }
}
/// The sidebar list: the outline in the sidebar column with one row per section.
func findSidebarOutline(_ d: String, _ p: String) -> AXUIElement? {
    require(d, p, "sidebar list (\(sections.count) rows)", within: 3,
            diagnose: { "outlines in the sidebar column with rows: "
                + (sidebarOutlines().map { String(rowCount($0)) }.joined(separator: ", ").nonEmpty ?? "none") },
            find: { sidebarOutlines().first { rowCount($0) == sections.count } })
}
/// The sidebar's search field: the one in the sidebar column (no stable label known).
func sidebarSearchField() -> AXUIElement? {
    windowElements { subrole($0) == "AXSearchField" }
        .first { let x = rel($0).minX; return x >= -Reference.tolerance && x < sidebarWidth }
}
/// The window's toolbar: toolbars have no label, so the widest one in the window's upper
/// half; the highest wins a tie.
func toolbar() -> AXUIElement? {
    let height = frame(window).height
    return windowElements { role($0) == "AXToolbar" }
        .filter { rel($0).midY < height / 2 }
        .max { a, b in
            let fa = rel(a), fb = rel(b)
            return fa.width != fb.width ? fa.width < fb.width : fa.minY > fb.minY
        }
}
/// The close button: one per window, the subrole is the identity.
func closeButton() -> AXUIElement? { windowElements { subrole($0) == "AXCloseButton" }.first }
/// The window's title: the shown page's navigation title.
func windowTitle() -> String { string(window, kAXTitleAttribute) ?? "" }
/// The page title: the system's inline title, a static text in the toolbar band carrying
/// the window's title, leftmost.
func pageTitle() -> AXUIElement? {
    let title = windowTitle()
    guard !title.isEmpty else { return nil }
    return windowElements { role($0) == "AXStaticText" && label($0) == title && rel($0).midY < Reference.toolbarHeight }
        .min { rel($0).minX < rel($1).minX }
}
/// Static texts in the toolbar band, for a missing title's diagnosis.
func toolbarTexts() -> String {
    windowElements { role($0) == "AXStaticText" && rel($0).midY < Reference.toolbarHeight }
        .map { "\"\(label($0))\" \(fmt(rel($0)))" }.joined(separator: "; ").nonEmpty ?? "none"
}
/// A Back/Forward button, by its label, in the toolbar band.
func historyButton(_ name: String) -> AXUIElement? {
    windowElements { role($0) == "AXButton" && label($0) == name && rel($0).midY < Reference.toolbarHeight }.first
}
/// The toolbar "+" of Ứng dụng, by its label.
func toolbarAddButton() -> AXUIElement? {
    windowElements { role($0) == "AXToolbar" }.flatMap { children($0) }
        .first { role($0) == "AXButton" && label($0) == "Thêm ứng dụng" }
}
/// The toolbar's search field (Ứng dụng): right of the sidebar, in the toolbar band (no
/// stable label known).
func toolbarSearchField() -> AXUIElement? {
    windowElements { subrole($0) == "AXSearchField" }
        .first { rel($0).minX >= sidebarWidth && rel($0).minY < Reference.toolbarHeight }
}
/// The page's Form: scroll areas have no label, so the largest one in the detail column.
func pageScrollArea() -> AXUIElement? {
    windowElements { role($0) == "AXScrollArea" && rel($0).minX >= sidebarWidth - Reference.tolerance }
        .max { rel($0).width * rel($0).height < rel($1).width * rel($1).height }
}
/// The page's vertical scroll bar, if it shows one: by orientation, in the detail column.
/// Optional by nature: a Always bar shows only on a page that overflows.
func pageScrollBar() -> AXUIElement? {
    windowElements { role($0) == "AXScrollBar" && string($0, kAXOrientationAttribute) == "AXVerticalOrientation"
        && rel($0).minX >= sidebarWidth && rel($0).width > 0 }
        .max { rel($0).height < rel($1).height }
}
/// The Form's cards, section headers and texts, top to bottom.
func pageItems(_ area: AXUIElement) -> [(role: String, frame: CGRect, element: AXUIElement)] {
    children(area).map { (role($0), rel($0), $0) }
        .filter { ["AXGroup", "AXHeading", "AXStaticText"].contains($0.0) }
        .sorted { $0.1.minY < $1.1.minY }
}

extension String { var nonEmpty: String? { isEmpty ? nil : self } }

/// Selects section `index` through the sidebar's accessibility (no clicks).
func showSection(_ d: String, _ index: Int) -> Bool {
    let p = sections[index]
    guard let outline = findSidebarOutline(d, p),
          let row = require(d, p, "sidebar row \(index)", find: {
              ((attr(outline, kAXRowsAttribute) as? [AXUIElement]) ?? []).dropFirst(index).first }),
          drive(d, p, "select the section", set(outline, kAXSelectedRowsAttribute, [row] as CFArray))
    else { return false }
    // The page is shown when the window carries its title; it is laid out when its Form's
    // frame, item count and first item stay the same on 3 reads. A title that never comes
    // is also measured below ("title text" FAILs where it is checked).
    let title = Reference.sectionTitles[index]
    awaitState(d, p, "page \"\(title)\" shown", timeout: 5) { windowTitle() == title }
    awaitSettled(d, p, "page layout", timeout: 3, valid: { $0 != nil }) { () -> String? in
        guard let area = pageScrollArea() else { return nil }
        let items = pageItems(area)
        return "\(fmt(rel(area))) \(items.count) \(items.first.map { fmt($0.frame) } ?? "-")"
    }
    return true
}

func moveWindow(to screen: NSScreen, _ d: String) -> Bool {
    // Accessibility positions are top-left based on the primary display.
    let primaryHeight = NSScreen.screens.first?.frame.height ?? 0
    let visible = screen.visibleFrame
    let origin = CGPoint(x: visible.minX + 40, y: primaryHeight - visible.maxY + 40)
    guard drive(d, "window", "move the window to this display", set(window, kAXPositionAttribute, axPoint(origin)))
    else { return false }
    // Every pass measures the default size, whatever size the app opened at (macOS can
    // restore the frame a killed launch left, or the one the limits pass left).
    guard drive(d, "window", "set the default window size", set(window, kAXSizeAttribute, axSize(Reference.windowSize)))
    else { return false }
    awaitSettled(d, "window", "window frame after the move") { fmt(frame(window)) }
    return true
}

// MARK: - Screenshots

/// The window's number for `screencapture -l`.
func windowNumber(_ bounds: CGRect) -> Int? {
    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    for w in list where (w[kCGWindowOwnerPID as String] as? pid_t) == pid {
        guard let b = w[kCGWindowBounds as String] as? [String: CGFloat],
              let n = w[kCGWindowNumber as String] as? Int else { continue }
        if near(b["X"] ?? 0, bounds.minX) && near(b["Y"] ?? 0, bounds.minY) && near(b["Width"] ?? 0, bounds.width) { return n }
    }
    return nil
}

/// Captures the window (and an attached sheet) to <name>.png and keeps `frames` (window
/// points) for frames.json. A failure is HARNESS: the system did not give the image.
func screenshot(_ d: String, _ p: String, _ name: String, frames: [String: CGRect] = [:]) -> NSBitmapImageRep? {
    let w = frame(window)
    // The window can be briefly off the on-screen list (for example while another app
    // takes the front): look again a few times.
    var number = windowNumber(w), tries = 1
    if number == nil {
        waitUntil(timeout: 2, interval: 0.4) { tries += 1; number = windowNumber(w); return number != nil }
    }
    guard let number else {
        harness(d, p, "screenshot \(name)", expected: "window in the on-screen window list", got: "not listed after \(tries) tries")
        return nil
    }
    let url = outDir.appendingPathComponent("\(name).png")
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    task.arguments = ["-o", "-x", "-l", String(number), url.path]
    try? task.run()
    task.waitUntilExit()
    guard let rep = (try? Data(contentsOf: url)).flatMap(NSBitmapImageRep.init(data:)) else {
        harness(d, p, "screenshot \(name)", expected: "an image", got: "screencapture wrote none (Screen Recording permission?)")
        return nil
    }
    var all = frames
    all["window"] = CGRect(origin: .zero, size: w.size)
    shots[name] = all.mapValues { [$0.minX, $0.minY, $0.width, $0.height].map(Double.init) }
    return rep
}

/// First x (pt) in `xs` where the band `ys` has a pixel far from the color at `xs`'s
/// start: where a sidebar label's text begins.
func inkStart(_ rep: NSBitmapImageRep, width: CGFloat, xs: ClosedRange<CGFloat>, ys: ClosedRange<CGFloat>) -> CGFloat? {
    let scale = CGFloat(rep.pixelsWide) / width
    func px(_ x: Int, _ y: Int) -> [Int] { var p = [Int](repeating: 0, count: 4); rep.getPixel(&p, atX: x, y: y); return p }
    let y0 = Int(ys.lowerBound * scale), y1 = Int(ys.upperBound * scale)
    let background = px(Int(xs.lowerBound * scale), (y0 + y1) / 2)
    for x in Int(xs.lowerBound * scale)...Int(xs.upperBound * scale) {
        for y in y0...y1 {
            let p = px(x, y)
            if (0..<3).map({ abs(p[$0] - background[$0]) }).max()! > Reference.sidebarInkThreshold { return CGFloat(x) / scale }
        }
    }
    return nil
}

// MARK: - Sections (--geometry)

/// One section on one display, against System Settings (Reference).
func measureSection(_ d: String, _ tag: String, _ index: Int) {
    let page = sections[index]
    guard showSection(d, index) else { return }
    let w = frame(window)
    var shot: [String: CGRect] = [:]

    if let bar = require(d, page, "toolbar", find: toolbar) {
        shot["toolbar"] = rel(bar)
        check(d, page, "toolbar height", rel(bar).height, Reference.toolbarHeight)
    }
    if let close = require(d, page, "close button", find: closeButton) {
        shot["close"] = rel(close)
        check(d, page, "close button", rel(close), Reference.closeFrame)
    }
    // Back/Forward cluster, then the system title right of it (System Settings).
    for (name, expected, key) in [(Reference.backLabel, Reference.backButtonFrame, "back"),
                                  (Reference.forwardLabel, Reference.forwardButtonFrame, "forward")] {
        if let button = require(d, page, "toolbar button \"\(name)\"", find: { historyButton(name) }) {
            shot[key] = rel(button)
            check(d, page, "\(key) button", rel(button), expected)
        }
    }
    let title = require(d, page, "page title (system title in the toolbar)",
                        diagnose: { "no static text \"\(windowTitle())\" in the toolbar; texts there: \(toolbarTexts())" },
                        find: pageTitle).map(rel)
    if let title {
        shot["title"] = title
        record(d, page, "title text", expected: Reference.sectionTitles[index], got: windowTitle(),
               ok: windowTitle() == Reference.sectionTitles[index])
        check(d, page, "title x", title.minX, Reference.titleX)
        check(d, page, "title center y", title.midY, Reference.titleCenterY)
    }

    // Sidebar: search field, rows, icon tile.
    if let field = require(d, page, "sidebar search field", find: sidebarSearchField) {
        check(d, page, "sidebar search", rel(field), Reference.sidebarSearchFrame)
    }
    if let outline = findSidebarOutline(d, page) {
        let sidebarRows = (attr(outline, kAXRowsAttribute) as? [AXUIElement]) ?? []
        for (i, row) in sidebarRows.enumerated() {
            // A sidebar row has a single cell.
            if let cell = require(d, page, "sidebar row \(i) cell", find: { children(row).first }) {
                check(d, page, "sidebar row \(i)", rel(cell), Reference.sidebarRowFrame(i))
            }
        }
        // The row's texts have no label to tell them apart: the leftmost is the icon tile.
        if let first = require(d, page, "sidebar row 0", find: { sidebarRows.first }),
           let icon = require(d, page, "sidebar row 0 icon tile", find: {
               all(first) { role($0) == "AXStaticText" }.min { rel($0).minX < rel($1).minX } }) {
            check(d, page, "sidebar icon x", rel(icon).minX, Reference.sidebarIconX)
            check(d, page, "sidebar icon height", rel(icon).height, Reference.sidebarIconSize)
        }
    }

    // Detail: cards and section headers in the Form.
    if let area = require(d, page, "page Form (scroll area in the detail column)", find: pageScrollArea) {
        let column = rel(area)
        shot["column"] = column
        let items = pageItems(area)
        if let first = require(d, page, "first card or header", find: { items.first }) {
            check(d, page, "first item y", first.frame.minY, Reference.formFirstItemY)
        }
        let cards = items.filter { $0.role == "AXGroup" }
        // Item 1: the card spans the detail column with the Form's margins (When scrolling scroll
        // bars take no room), measured from the window, not from the app's own column.
        if let card = require(d, page, "first card", find: { cards.first }) {
            shot["firstCard"] = card.frame
            check(d, page, "first card", card.frame, CGRect(x: sidebarWidth + formMargin, y: card.frame.minY,
                                                            width: w.width - sidebarWidth - 2 * formMargin,
                                                            height: card.frame.height))
        }
        for (i, item) in items.enumerated() where item.role == "AXHeading" {
            let name = label(item.element)
            check(d, page, "header \"\(name)\" x", item.frame.minX, sidebarWidth + formMargin + Reference.cardInset)
            if i + 1 < items.count, items[i + 1].role == "AXGroup" {
                check(d, page, "header \"\(name)\" → card", items[i + 1].frame.minY - item.frame.maxY, Reference.headerToCard)
            }
            if i > 0, items[i - 1].role == "AXGroup" {
                check(d, page, "card → header \"\(name)\"", item.frame.minY - items[i - 1].frame.maxY, Reference.cardToHeader)
            }
        }

        // Controls inside the cards, in view (every page shows some).
        var measured = 0
        for card in cards where column.intersects(card.frame) {
            for e in all(card.element, where: { _ in true }) {
                let r = rel(e)
                guard column.contains(r) else { continue }
                switch (role(e), subrole(e)) {
                case ("AXCheckBox", "AXSwitch"):
                    measured += 1
                    if shot["switch"] == nil { shot["switch"] = r }
                    check(d, page, "switch \"\(label(e).prefix(24))\"", r, CGRect(origin: r.origin, size: Reference.switchSize))
                case ("AXButton", _) where label(e) == "Nâng cao":
                    // The "Nâng cao" disclosure row: a plain button with a chevron (D9),
                    // as tall as its text, not a bezel button.
                    break
                case ("AXButton", _), ("AXPopUpButton", _), ("AXRadioGroup", _):
                    measured += 1
                    if role(e) == "AXButton", shot["button"] == nil { shot["button"] = r }
                    check(d, page, "\(role(e).dropFirst(2)) \"\(label(e).prefix(24))\" height", r.height, Reference.controlHeight)
                default: break
                }
            }
        }
        record(d, page, "controls in view", expected: "at least one measured", got: "\(measured)", ok: measured > 0)

        // Item 6: "Kiểu gõ" has no row label and spans its row (macOS 26+, flexible
        // segments), as System Settings' Sound › Output/Input.
        if page == "typing",
           let segmented = require(d, page, "segmented \"Kiểu gõ\"", find: {
               cards.flatMap { all($0.element) { role($0) == "AXRadioGroup" && label($0) == "Kiểu gõ" } }.first }),
           let card = require(d, page, "card of \"Kiểu gõ\"", find: { cards.first { $0.frame.contains(rel(segmented)) } }) {
            let r = rel(segmented)
            shot["segmented"] = r
            record(d, page, "segmented \"Kiểu gõ\" spans its row", expected: "x \(fmt(card.frame.minX + Reference.cardInset)), width \(fmt(card.frame.width - 2 * Reference.cardInset))",
                   got: "x \(fmt(r.minX)), width \(fmt(r.width))",
                   ok: near(r.minX, card.frame.minX + Reference.cardInset) && near(r.width, card.frame.width - 2 * Reference.cardInset))
        }
    }

    // Ứng dụng: the toolbar's "+" (items 7, 8) and search field, right of the title.
    if page == "apps" {
        let add = require(d, page, "toolbar + (\"Thêm ứng dụng\")", find: toolbarAddButton).map(rel)
        let field = require(d, page, "toolbar search field", find: toolbarSearchField).map(rel)
        if let add { shot["headerAdd"] = add }
        if let field { shot["headerSearch"] = field }
        if let add, let title {
            record(d, page, "+ right of the title", expected: "≥ \(fmt(Reference.appsAddGapToTitle)) after the title",
                   got: "\(fmt(add.minX - title.maxX))", ok: add.minX - title.maxX >= Reference.appsAddGapToTitle)
        }
        if let add, let field {
            record(d, page, "+ before the search field", expected: "+ ends before the field", got: "\(fmt(add.maxX)) / \(fmt(field.minX))",
                   ok: add.maxX <= field.minX + Reference.tolerance)
        }
        if let field {
            let inset = w.width - field.maxX
            record(d, page, "search field right inset", expected: "\(fmt(Reference.appsSearchRightInset.lowerBound))…\(fmt(Reference.appsSearchRightInset.upperBound))",
                   got: fmt(inset), ok: Reference.appsSearchRightInset.contains(inset))
            record(d, page, "search field height", expected: "≥ \(fmt(Reference.controlHeight))", got: fmt(field.height),
                   ok: field.height >= Reference.controlHeight - Reference.tolerance)
        }
    }

    if let scroller = pageScrollBar() { shot["scroller"] = rel(scroller) }   // whenScrolling: for check.swift to leave out

    // Pixels: where the text of an unselected sidebar row begins.
    if let rep = screenshot(d, page, "\(page)-\(tag)", frames: shot) {
        let other = index == 1 ? 2 : 1
        let y = Reference.sidebarRowFrame(other).minY
        let band = Reference.sidebarTextProbeY
        let x = inkStart(rep, width: w.width, xs: Reference.sidebarTextProbeX, ys: (y + band.lowerBound)...(y + band.upperBound))
        record(d, page, "sidebar text x", expected: fmt(Reference.sidebarTextX), got: x.map(fmt) ?? "no text in the probe band",
               ok: x.map { near($0, Reference.sidebarTextX) } ?? false)
    }
}

// MARK: - Sidebar search (--geometry)

/// Wiring only (what matches is `swift test` "Sidebar search"): a query no section matches
/// leaves the sidebar without rows and shows the system's empty state naming the query,
/// the toolbar keeps its height; clearing brings the rows back.
func measureSidebarSearch(_ d: String, _ tag: String) {
    let p = "sidebar-search"
    let query = "zzzz-no-such-setting"
    guard let field = require(d, p, "sidebar search field", find: sidebarSearchField),
          let outline = findSidebarOutline(d, p),
          // The field reports a value as an edit only while it has focus (measured with
          // the earlier SwiftUI field: a value set without focus showed in the field but
          // filtered nothing; the NSSearchField's edits come through its field editor).
          drive(d, p, "focus the search field", set(field, kAXFocusedAttribute, kCFBooleanTrue)),
          drive(d, p, "type the query", set(field, kAXValueAttribute, query as CFString))
    else { return }
    // The two checks below report a timeout.
    func emptyStateTexts() -> [AXUIElement] {
        windowElements { role($0) == "AXStaticText" }
            .filter { rel($0).maxX <= sidebarWidth && rel($0).minY > Reference.sidebarFirstRowY && label($0).contains(query) }
    }
    waitUntil(timeout: 5, interval: 0.2) { rowCount(outline) == 0 && !emptyStateTexts().isEmpty }
    check(d, p, "rows without a match", CGFloat(rowCount(outline)), 0, tolerance: Reference.exact)
    let texts = emptyStateTexts()
    record(d, p, "empty state", expected: "text naming the query in the sidebar", got: texts.first.map(label) ?? "none", ok: !texts.isEmpty)
    if let bar = require(d, p, "toolbar", find: toolbar) {
        check(d, p, "toolbar height", rel(bar).height, Reference.toolbarHeight)
    }
    _ = screenshot(d, p, "sidebar-search-empty-\(tag)")
    guard drive(d, p, "clear the query", set(field, kAXValueAttribute, "" as CFString)) else { return }
    // The check below reports a timeout.
    waitUntil(timeout: 5, interval: 0.2) { rowCount(outline) == sections.count }
    check(d, p, "rows after clearing", CGFloat(rowCount(outline)), CGFloat(sections.count), tolerance: Reference.exact)
}

// MARK: - Add-rule sheet

let sheetPage = "add-sheet"

/// The sheet attached to the Settings window: a window has at most one, so the role is the identity.
func attachedSheet() -> AXUIElement? { children(window).first { role($0) == "AXSheet" } }
/// The app list, by its accessibility label, not by order. The list has been read with too
/// few rows for a reason not known (docs/history/LOG-M5.md); reading another outline (the
/// Form) was not confirmed as the cause: at open the sheet holds only this outline.
/// "app list settles" prints the outlines it finds.
func appList(_ sheet: AXUIElement) -> AXUIElement? {
    all(sheet) { role($0) == "AXOutline" && string($0, kAXDescriptionAttribute) == "Ứng dụng" }.first
}
func selectedRows(_ list: AXUIElement) -> [AXUIElement] { (attr(list, kAXSelectedRowsAttribute) as? [AXUIElement]) ?? [] }
func appRows(_ sheet: AXUIElement) -> [AXUIElement] { appList(sheet).flatMap { attr($0, kAXRowsAttribute) as? [AXUIElement] } ?? [] }
/// By label; if two carry it, the lower one (the button bar is the sheet's bottom row).
func sheetButton(_ sheet: AXUIElement, _ title: String) -> AXUIElement? {
    all(sheet) { role($0) == "AXButton" && label($0) == title }.max { frame($0).minY < frame($1).minY }
}
/// The element carrying `wanted`; if none does, the topmost candidate, so that a wrong text
/// shows as a FAIL at the text check, not as a missing element.
func intended(_ candidates: [AXUIElement], text wanted: String, _ text: (AXUIElement) -> String) -> AXUIElement? {
    candidates.first { text($0) == wanted } ?? candidates.min { frame($0).minY < frame($1).minY }
}

/// Presses "+" on Ứng dụng and returns the sheet it opens. Nil (recorded) when there is
/// no "+" or no sheet; a sheet that opens late is closed again.
func openSheet(_ d: String) -> AXUIElement? {
    guard showSection(d, appsIndex),
          let add = require(d, sheetPage, "toolbar + (\"Thêm ứng dụng\")", find: toolbarAddButton),
          drive(d, sheetPage, "press +", press(add))
    else { return nil }
    guard let sheet = requireShown(d, sheetPage, "sheet opened by +", within: 5, find: attachedSheet) else {
        if attachedSheet() != nil { closeSheet(d) }
        return nil
    }
    // Screenshots of an active window, as the user sees it.
    bringToFront(d, sheetPage)
    return sheet
}

/// Closes the sheet with Huỷ (a row: Huỷ closes it), or with Escape when Huỷ cannot be
/// pressed, so the next checks start without it. Called after every sheet visit.
func closeSheet(_ d: String) {
    guard let sheet = attachedSheet() else {
        record(d, sheetPage, "sheet open until Huỷ", expected: "open", got: "closed by itself", ok: false)
        return
    }
    if let cancel = require(d, sheetPage, "Huỷ button to close the sheet", find: { sheetButton(sheet, "Huỷ") }),
       drive(d, sheetPage, "press Huỷ", press(cancel)) {
        let closed = waitUntil(timeout: 5, interval: 0.2) { attachedSheet() == nil }
        record(d, sheetPage, "Huỷ closes the sheet", expected: "closed", got: closed ? "closed" : "still open", ok: closed)
    }
    guard attachedSheet() != nil else { return }
    for down in [true, false] {
        CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: down)?.post(tap: .cghidEventTap)
    }
    if !waitUntil(timeout: 5, interval: 0.2, { attachedSheet() == nil }) {
        record(d, sheetPage, "sheet closed for the next checks", expected: "closed (Huỷ, then Escape)", got: "still open", ok: false)
    }
}

/// Reads of the app list's row count that must agree, 0.2 s apart, before it counts as
/// settled: 2 s without a change. The list has been read at 1 and 13 rows for over a
/// second before it grew to the full list (docs/history/LOG-M5.md), so a short window
/// settled on a list still loading.
let appListSettleReads = 11

/// Waits for the app list (it is read off the main thread): the same row count, more than
/// none, on `appListSettleReads` reads 0.2 s apart, within 15 s. Returns that count; nil
/// (recorded FAIL) when it never settles, stays empty or there is no list.
func settledAppCount(_ d: String, _ sheet: AXUIElement) -> Int? {
    let outlinesAtOpen = all(sheet) { role($0) == "AXOutline" }
        .map { "\(string($0, kAXDescriptionAttribute) ?? "-"):\(rowCount($0))" }
    let mark = axErrors.count
    let read = waitSettled(timeout: 15, interval: 0.2, reads: appListSettleReads, valid: { $0 > 0 }) { appRows(sheet).count }
    let settled = read.settled, last = read.value
    let expected = "rows, the same on \(appListSettleReads) reads 0.2 s apart, within 15 s"
    let got = (appList(sheet) == nil ? "no outline labelled \"Ứng dụng\"" : "\(last) rows")
        + " after \(String(format: "%.1f", read.seconds)) s; outlines at open: "
        + (outlinesAtOpen.joined(separator: ", ").nonEmpty ?? "none")
    if !settled && axErrors.count > mark {
        harness(d, sheetPage, "app list settles", expected: expected,
                got: got + "; Accessibility error: " + axErrors[mark...].suffix(2).joined(separator: "; "))
    } else {
        record(d, sheetPage, "app list settles", expected: expected, got: got, ok: settled)
    }
    return settled ? last : nil
}

/// The add-rule sheet (primary display): its texts, the app list, search and selection
/// wiring, screenshots; then Huỷ.
func measureSheet(_ d: String, _ tag: String) {
    guard let sheet = openSheet(d) else { return }
    inspectSheet(d, tag, sheet)
    closeSheet(d)
}

func inspectSheet(_ d: String, _ tag: String, _ sheet: AXUIElement) {
    let p = sheetPage
    let s = frame(sheet)
    func srel(_ e: AXUIElement) -> CGRect { frame(e).offsetBy(dx: -s.minX, dy: -s.minY) }
    guard let total = settledAppCount(d, sheet),
          let list = require(d, p, "app list", find: { appList(sheet) }) else { return }

    // The sheet's texts and buttons are there (content, docs/UI.md). Where they sit is not
    // measured: what the window does with them is (the list, search, selection, Huỷ).
    // Preferring the placeholder / title it is known to carry, else the topmost (the Form's
    // section headings lie below): a wrong text is then a FAIL at the text check.
    let field = require(d, p, "search field", find: {
        intended(all(sheet) { subrole($0) == "AXSearchField" }, text: "Tìm trong Ứng dụng") { string($0, "AXPlaceholderValue") ?? label($0) } })
    if let field {
        let prompt = string(field, "AXPlaceholderValue") ?? label(field)
        record(d, p, "search prompt", expected: "Tìm trong Ứng dụng", got: prompt, ok: prompt == "Tìm trong Ứng dụng")
    }
    if let heading = require(d, p, "header", find: {
        intended(all(sheet) { role($0) == "AXHeading" }, text: "Thêm quy tắc cho ứng dụng", label) }) {
        record(d, p, "header", expected: "Thêm quy tắc cho ứng dụng", got: label(heading), ok: label(heading) == "Thêm quy tắc cho ứng dụng")
    }
    let segmented = require(d, p, "segmented \"Khi đang gõ\"", find: {
        intended(all(sheet) { role($0) == "AXRadioGroup" }, text: "Khi đang gõ", label) })
    if let segmented {
        record(d, p, "segmented label", expected: "Khi đang gõ", got: label(segmented), ok: label(segmented) == "Khi đang gõ")
    }
    _ = require(d, p, "Huỷ button", find: { sheetButton(sheet, "Huỷ") })
    _ = require(d, p, "Chọn ứng dụng khác… button", find: { sheetButton(sheet, "Chọn ứng dụng khác…") })
    let confirm = require(d, p, "Thêm button", find: { sheetButton(sheet, "Thêm") })
    if let confirm {
        record(d, p, "Thêm without selection", expected: "disabled", got: enabled(confirm) ? "enabled" : "disabled", ok: !enabled(confirm))
    }
    _ = screenshot(d, p, "apps-add-sheet-\(tag)", frames: ["sheet": frame(sheet).offsetBy(dx: -frame(window).minX, dy: -frame(window).minY)])

    // The list scrolls inside its card (the bug: a List nested in a grouped Form has its
    // scroller switched off; once, 3 rows and no scroll bar). /System/Applications alone
    // holds dozens of apps, so the list always overflows its card.
    guard let listArea = require(d, p, "app list scroll area", find: {
        // The smallest scroll area that holds the list.
        all(sheet) { role($0) == "AXScrollArea" && !all($0) { CFEqual($0, list) }.isEmpty }
            .min { frame($0).width * frame($0).height < frame($1).width * frame($1).height } })
    else { return }
    let rowsNow = appRows(sheet)
    let rowHeight = rowsNow.map { frame($0).height }.max() ?? 0
    let visibleHeight = frame(listArea).height
    record(d, p, "list overflows its card", expected: "rows taller than the card",
           got: "\(rowsNow.count) rows × \(fmt(rowHeight)) vs \(fmt(visibleHeight))", ok: CGFloat(rowsNow.count) * rowHeight > visibleHeight)
    let bar = requireShown(d, p, "list vertical scroll bar", within: 2,
                      diagnose: { "missing (the end-of-list checks need it and did not run)" }, find: {
        children(listArea).first { role($0) == "AXScrollBar" && string($0, kAXOrientationAttribute) == "AXVerticalOrientation" } })

    // A real mouse wheel over the list: the rows move up.
    if let firstRow = require(d, p, "first app row", find: { appRows(sheet).first }) {
        let before = frame(firstRow).minY
        let area = frame(listArea)
        let point = CGPoint(x: area.midX, y: area.midY)
        // The first wheel after the sheet opens can land before the window is under the
        // pointer (two of the first runs did not scroll; cause not found): up to 5 tries,
        // the count is in the row.
        var tries = 0
        while tries < 5 && frame(firstRow).minY >= before - 0.5 {
            tries += 1
            bringToFront(d, p)
            CGWarpMouseCursorPosition(point)
            CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
            // Fixed: time for the window server to put the pointer over the list; no
            // accessibility state shows it.
            wait(0.5)
            for _ in 0..<10 {
                let wheel = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: -40, wheel2: 0, wheel3: 0)
                wheel?.location = point
                wheel?.post(tap: .cghidEventTap)
                wait(0.05)   // Fixed: pacing between wheel events.
            }
            // The rows moving is what the row below checks; a try that moves nothing
            // within 1 s goes round again.
            waitUntil(timeout: 1) { frame(firstRow).minY < before - 0.5 }
        }
        let moved = before - frame(firstRow).minY
        record(d, p, "list scrolls with the wheel", expected: "rows move up", got: "\(fmt(moved)) pt after \(tries) \(tries == 1 ? "try" : "tries")", ok: moved > 0.5)
    }

    // Apps every macOS install has (Reference.alwaysInstalledApps), by visible name. Rows
    // out of view may carry no text, so the list is stepped through with its scroll bar.
    let wanted = Set(Reference.alwaysInstalledApps)
    func visibleNames() -> Set<String> {
        Set(appRows(sheet).flatMap { all($0) { role($0) == "AXStaticText" }.map(label) })
    }
    var names = visibleNames(), positions = 1
    if let bar, !wanted.isSubset(of: names), rowsNow.count > 0, rowHeight > 0 {
        let inView = max(1, visibleHeight / rowHeight)
        let step = max(0.01, (inView - 1) / max(1, CGFloat(rowsNow.count) - inView))
        var value: CGFloat = 0
        while value < 1 + step && !wanted.isSubset(of: names) {
            drive(d, p, "scroll the list", set(bar, kAXValueAttribute, NSNumber(value: Double(min(value, 1)))))
            // Rows that come into view get their texts as they are laid out: read until
            // the names stay the same on 2 reads (2 s at most), keep what was read.
            names.formUnion(waitSettled(timeout: 2, interval: 0.15, reads: 2) { visibleNames() }.value)
            positions += 1
            value += step
        }
    }
    for name in Reference.alwaysInstalledApps {
        let found = names.contains(name)
        record(d, p, "lists \"\(name)\"", expected: "a row named \(name)",
               got: found ? "present" : "absent after \(positions) scroll positions (a rule stored for it hides it from the sheet)", ok: found)
    }

    // The scroll bar to the end: the last app comes fully into the card, "Khi đang gõ"
    // stays in the sheet; then back to the top.
    if let bar {
        let area = srel(listArea)
        func lastInView() -> Bool {
            guard let last = appRows(sheet).last else { return false }
            let r = srel(last)
            return r.minY >= area.minY - Reference.tolerance && r.maxY <= area.maxY + Reference.tolerance
        }
        // Rows are sized as they appear, so the end moves while they do: push again until
        // the last app is in view, at most 15 times; the count is in the row. Each push
        // waits up to 1 s for the last app to come into view.
        var pushes = 0
        repeat {
            pushes += 1
            drive(d, p, "scroll the list to the end", set(bar, kAXValueAttribute, NSNumber(value: 1.0)))
        } while !waitUntil(timeout: 1, lastInView) && pushes < 15
        if let last = require(d, p, "last app row", find: { appRows(sheet).last }) {
            let r = srel(last)
            record(d, p, "last app visible at the end", expected: "inside \(fmt(area))", got: "\(fmt(r)) after \(pushes) \(pushes == 1 ? "push" : "pushes")",
                   ok: r.minY >= area.minY - Reference.tolerance && r.maxY <= area.maxY + Reference.tolerance)
        }
        if let segmented {
            let r = srel(segmented)
            record(d, p, "Khi đang gõ in view while scrolled", expected: "below the list, inside the sheet", got: fmt(r),
                   ok: r.minY > area.maxY && r.maxY < s.height)
        }
        _ = screenshot(d, p, "apps-add-sheet-bottom-\(tag)")
        if drive(d, p, "scroll the list to the top", set(bar, kAXValueAttribute, NSNumber(value: 0.0))) {
            awaitState(d, p, "first app in view after scrolling to the top", timeout: 3) {
                guard let first = appRows(sheet).first else { return false }
                return srel(first).minY >= area.minY - Reference.tolerance
            }
        }
    }

    // Search wiring (what matches is AddAppRuleSheetTests): a query no app matches leaves
    // no row; clearing it brings back every row the list settled on.
    // Each wait ends when the list shows what the check below expects; the check reports
    // a timeout (5 s).
    if let field, drive(d, p, "type a query", set(field, kAXValueAttribute, "zzzz-no-such-app" as CFString)) {
        waitUntil(timeout: 5, interval: 0.2) { appRows(sheet).isEmpty }
        check(d, p, "search with no match", CGFloat(appRows(sheet).count), 0, tolerance: Reference.exact)
        if drive(d, p, "clear the query", set(field, kAXValueAttribute, "" as CFString)) {
            waitUntil(timeout: 5, interval: 0.2) { appRows(sheet).count == total }
            check(d, p, "search cleared", CGFloat(appRows(sheet).count), CGFloat(total), tolerance: Reference.exact)
        }
    }

    // Selection wiring: a selected row enables Thêm; a query that hides it disables Thêm,
    // and clearing the query leaves it off (the selection was dropped, so Return cannot add
    // an app out of view).
    guard let row = require(d, p, "first app row", find: { appRows(sheet).first }),
          drive(d, p, "select the first app", set(list, kAXSelectedRowsAttribute, [row] as CFArray)) else { return }
    // Thêm turns on with the selection; the check below reports a timeout.
    waitUntil(timeout: 3, interval: 0.2) { confirm.map(enabled) ?? !selectedRows(list).isEmpty }
    if let confirm {
        record(d, p, "Thêm with selection", expected: "enabled", got: enabled(confirm) ? "enabled" : "disabled", ok: enabled(confirm))
    }
    _ = screenshot(d, p, "apps-add-sheet-selected-\(tag)")
    if let field, let confirm,
       drive(d, p, "type a query", set(field, kAXValueAttribute, "zzzz-no-such-app" as CFString)) {
        // The list empties with the query; then Thêm is read once it stays the same on 3
        // reads (the check below reports what it settled on).
        waitUntil(timeout: 5, interval: 0.2) { appRows(sheet).isEmpty }
        _ = waitSettled(timeout: 2, interval: 0.2, reads: 3) { enabled(confirm) }
        record(d, p, "Thêm after search hides selection", expected: "disabled", got: enabled(confirm) ? "enabled" : "disabled", ok: !enabled(confirm))
        if drive(d, p, "clear the query", set(field, kAXValueAttribute, "" as CFString)) {
            // Thêm is already off before the query is cleared, so waiting for "off" would
            // prove nothing: wait for the full list to come back, then for Thêm to stay
            // the same on 3 reads.
            waitUntil(timeout: 5, interval: 0.2) { appRows(sheet).count == total }
            _ = waitSettled(timeout: 2, interval: 0.2, reads: 3) { enabled(confirm) }
            record(d, p, "Thêm after search cleared", expected: "disabled", got: enabled(confirm) ? "enabled" : "disabled", ok: !enabled(confirm))
        }
    }
}

/// --sheet-shots: the sheet in this launch's appearance, empty and with a row selected.
func sheetShots(_ d: String, _ tag: String) {
    let p = sheetPage
    guard let sheet = openSheet(d) else { return }
    if settledAppCount(d, sheet) != nil, let list = require(d, p, "app list", find: { appList(sheet) }) {
        _ = screenshot(d, p, "apps-add-sheet-\(tag)")
        if let row = require(d, p, "first app row", find: { appRows(sheet).first }),
           drive(d, p, "select the first app", set(list, kAXSelectedRowsAttribute, [row] as CFArray)) {
            // Selected, and Thêm on with it (drawn in the same update as the row).
            awaitState(d, p, "first app selected", timeout: 3) {
                !selectedRows(list).isEmpty && (sheetButton(sheet, "Thêm").map(enabled) ?? true)
            }
            _ = screenshot(d, p, "apps-add-sheet-selected-\(tag)")
        }
    }
    closeSheet(d)
}

// MARK: - Window limits (--geometry)

/// Resizes the window past its limits (item 1): it stops at Reference's widths and height.
/// The width is fixed, so the widest window is the default one, whose cards "first card"
/// already checks.
func measureLimits() {
    let d = "-", p = "window"
    guard drive(d, p, "resize the window", set(window, kAXSizeAttribute, axSize(Reference.probeLargeSize))) else { return }
    awaitSettled(d, p, "window frame after resizing") { fmt(frame(window)) }
    check(d, p, "max window width", frame(window).width, Reference.maxWindowWidth)
    guard drive(d, p, "resize the window", set(window, kAXSizeAttribute, axSize(Reference.probeSmallSize))) else { return }
    awaitSettled(d, p, "window frame after resizing") { fmt(frame(window)) }
    check(d, p, "min window width", frame(window).width, Reference.minWindowWidth)
    // The content's minimum plus the toolbar.
    check(d, p, "min window height", frame(window).height, Reference.minWindowHeight)
    // Leave the default size: the app saves its frame, and the next launch must not open small.
    _ = drive(d, p, "restore the default window size", set(window, kAXSizeAttribute, axSize(Reference.windowSize)))
}

// MARK: - Shell: Back/Forward, fixed sidebar (--geometry)

/// Back and Forward as the buttons show them now: enabled or not.
func checkHistoryButtons(_ d: String, _ p: String, _ when: String, back: Bool?, forward: Bool?) {
    // The buttons follow the page; read them once their states stay the same on 3 reads.
    _ = waitSettled(timeout: 2, interval: 0.1, reads: 3) {
        [Reference.backLabel, Reference.forwardLabel].map { historyButton($0).map(enabled) }
    }
    for (name, want) in [(Reference.backLabel, back), (Reference.forwardLabel, forward)] {
        guard let want else { continue }
        if let button = require(d, p, "toolbar button \"\(name)\"", find: { historyButton(name) }) {
            record(d, p, "\(name) \(when)", expected: want ? "enabled" : "disabled",
                   got: enabled(button) ? "enabled" : "disabled", ok: enabled(button) == want)
        }
    }
}

/// The page shown, by the window's title, within 3 s (the callers used to wait 1 s before
/// a 2 s poll).
func checkShown(_ d: String, _ p: String, _ when: String, _ index: Int) {
    let want = Reference.sectionTitles[index]
    waitUntil(timeout: 3, interval: 0.2) { windowTitle() == want }
    record(d, p, "page \(when)", expected: want, got: windowTitle(), ok: windowTitle() == want)
}

/// Posts a key with modifiers to Dấu, brought to the front first; no key when it does not
/// come to the front (HARNESS), so nothing lands in another app. The caller waits for what
/// the key should change.
func postKey(_ d: String, _ p: String, _ virtualKey: CGKeyCode, _ flags: CGEventFlags) {
    guard bringToFront(d, p) else { return }
    for down in [true, false] {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: virtualKey, keyDown: down)
        event?.flags = flags
        event?.post(tap: .cghidEventTap)
    }
}

/// The focused element of the app, through accessibility.
func focusedElement() -> AXUIElement? {
    attr(app, kAXFocusedUIElementAttribute).map { $0 as! AXUIElement }
}
/// `e` is `ancestor` or lies inside it (AXParent chain).
func isInside(_ e: AXUIElement, _ ancestor: AXUIElement) -> Bool {
    var current: AXUIElement? = e
    for _ in 0..<12 {
        guard let c = current else { return false }
        if CFEqual(c, ancestor) { return true }
        current = attr(c, kAXParentAttribute).map { $0 as! AXUIElement }
    }
    return false
}
func describe(_ e: AXUIElement?) -> String {
    guard let e else { return "none" }
    return "\(role(e))\(subrole(e).isEmpty ? "" : "/" + subrole(e)) \(fmt(rel(e)))"
}
/// The list has the keyboard focus: its own AXFocused, or the app's focused element is
/// the list or inside it (a row).
func listHasFocus(_ outline: AXUIElement) -> Bool {
    (attr(outline, kAXFocusedAttribute) as? Bool) == true || focusedElement().map { isInside($0, outline) } == true
}
func searchHasFocus(_ field: AXUIElement) -> Bool {
    (attr(field, kAXFocusedAttribute) as? Bool) == true || focusedElement().map { isInside($0, field) } == true
}

/// Mean sRGB color (0…1) of a block of the screenshot, in window points.
func meanColor(_ rep: NSBitmapImageRep, width: CGFloat, _ r: CGRect) -> [CGFloat]? {
    let scale = CGFloat(rep.pixelsWide) / width
    var sum: [CGFloat] = [0, 0, 0], n: CGFloat = 0
    for y in Int(r.minY * scale)..<Int(r.maxY * scale) {
        for x in Int(r.minX * scale)..<Int(r.maxX * scale) {
            guard let c = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
            sum[0] += c.redComponent; sum[1] += c.greenComponent; sum[2] += c.blueComponent; n += 1
        }
    }
    return n > 0 ? sum.map { $0 / n } : nil
}
/// A system color in sRGB (0…1), resolved in the appearance the app draws in.
func systemColor(_ color: NSColor) -> [CGFloat] {
    var out: [CGFloat] = [0, 0, 0]
    NSAppearance(named: appearance == "dark" ? .darkAqua : .aqua)?.performAsCurrentDrawingAppearance {
        if let c = color.usingColorSpace(.sRGB) { out = [c.redComponent, c.greenComponent, c.blueComponent] }
    }
    return out
}
func distance(_ a: [CGFloat], _ b: [CGFloat]) -> CGFloat { sqrt(zip(a, b).map { ($0 - $1) * ($0 - $1) }.reduce(0, +)) }
func rgb(_ c: [CGFloat]) -> String { c.map { String(Int(($0 * 255).rounded())) }.joined(separator: ",") }

/// The window as it opens, before the checker selects, moves or types anything: the
/// sidebar list has the keyboard focus (not its search field, not nothing), so the
/// selected row (Gõ phím) is drawn with the accent selection, as on the canvas and as
/// before the fixed sidebar. Without care the list gets no focus at launch, and the
/// selection is drawn grey (inactive). Dấu is brought to the front first: a window that
/// is not key draws every selection grey.
func measureLaunchFocus() {
    let d = "-", p = "launch-focus"
    bringToFront(d, p)
    awaitState(d, p, "Settings window is the main window", timeout: 3) { (attr(window, kAXMainAttribute) as? Bool) == true }
    // Fixed: the selection is redrawn in the active style after the window becomes key,
    // and no accessibility state says when that drawing is done.
    wait(0.3)
    guard let outline = findSidebarOutline(d, p) else { return }
    let field = require(d, p, "sidebar search field", find: sidebarSearchField)
    record(d, p, "sidebar list has the focus at launch", expected: "the list (AXFocused, or the app's focused element in it)",
           got: listHasFocus(outline) ? "the list" : "focused: \(describe(focusedElement()))", ok: listHasFocus(outline))
    if let field {
        record(d, p, "search field without focus at launch", expected: "not focused",
               got: searchHasFocus(field) ? "focused" : "not focused", ok: !searchHasFocus(field))
    }
    // The selected row's background, right of its text, against the system's accent color
    // and the inactive selection grey, in the app's appearance: nearer the accent passes.
    guard let row = require(d, p, "selected sidebar row", find: {
              ((attr(outline, kAXSelectedRowsAttribute) as? [AXUIElement]) ?? []).first }),
          let cell = require(d, p, "selected sidebar row cell", find: { children(row).first }) else { return }
    let r = rel(cell)
    let sample = CGRect(x: r.maxX - Reference.selectionSampleRightInset - Reference.selectionSampleSize,
                        y: r.midY - Reference.selectionSampleSize / 2,
                        width: Reference.selectionSampleSize, height: Reference.selectionSampleSize)
    guard let rep = screenshot(d, p, "launch-focus", frames: ["selectedRow": r, "selectionSample": sample]) else { return }
    let w = frame(window)
    guard let got = meanColor(rep, width: w.width, sample) else {
        harness(d, p, "selected row color", expected: "pixels in \(fmt(sample))", got: "none in the screenshot")
        return
    }
    let accent = systemColor(.controlAccentColor), grey = systemColor(.unemphasizedSelectedContentBackgroundColor)
    let toAccent = distance(got, accent), toGrey = distance(got, grey)
    record(d, p, "selected row drawn with the accent selection (\(appearance))",
           expected: "nearer accent \(rgb(accent)) than inactive grey \(rgb(grey))",
           got: "\(rgb(got)) (to accent \(String(format: "%.2f", toAccent)), to grey \(String(format: "%.2f", toGrey)))",
           ok: toAccent < toGrey)
}

/// Edit › Find › Find…: opens Edit and its Find submenu through accessibility (AppKit
/// validates items when their menu opens, so "enabled" is the state for the current
/// focus), reads the item, closes both menus with Escape.
func findMenuItemState() -> (ok: Bool, description: String) {
    let editTitles = systemTitles([Reference.editMenuKey])
    let findTitles = systemTitles([Reference.findSubmenuKey])
    let itemTitles = systemTitles([Reference.findItemKey])
    guard !editTitles.isEmpty, !findTitles.isEmpty, !itemTitles.isEmpty else { return (false, "system menu strings unreadable") }
    func escape() {
        for down in [true, false] { CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: down)?.post(tap: .cghidEventTap) }
        // Fixed: pacing between Escapes; a closed submenu shows no state read here.
        wait(0.3)
    }
    func menuItems(_ e: AXUIElement) -> [AXUIElement] {
        children(e).first { role($0) == "AXMenu" }.map { children($0).filter { role($0) == "AXMenuItem" } } ?? []
    }
    guard let bar = attr(app, kAXMenuBarAttribute).map({ $0 as! AXUIElement }) else { return (false, "no menu bar") }
    guard let edit = children(bar).first(where: { editTitles.contains(label($0)) }) else {
        return (false, "no Edit menu; menus: " + children(bar).map(label).joined(separator: ", "))
    }
    func editOpen() -> Bool { (attr(edit, kAXSelectedAttribute) as? Bool) == true }
    guard press(edit) == .success else { return (false, "Edit menu did not open") }
    // Open: the menu bar item is selected. Not seen within 2 s: read anyway.
    waitUntil(timeout: 2, editOpen)
    let editItems = menuItems(edit)
    guard let find = editItems.first(where: { findTitles.contains(label($0)) }) else {
        escape()
        return (false, "no Find submenu; Edit: " + editItems.map(label).filter { !$0.isEmpty }.joined(separator: ", "))
    }
    _ = press(find)
    // Fixed: no accessibility state seen for an open submenu (its items are listed while
    // it is closed too); AppKit validates them when it opens.
    wait(0.6)
    let findItems = menuItems(find)
    escape(); escape()
    if !waitUntil(timeout: 2, { !editOpen() }) { escape() }
    guard let item = findItems.first(where: { itemTitles.contains(label($0)) }) else {
        return (false, "no Find… item; Find: " + findItems.map(label).filter { !$0.isEmpty }.joined(separator: ", "))
    }
    let char = string(item, "AXMenuItemCmdChar") ?? "", mods = (attr(item, "AXMenuItemCmdModifiers") as? Int) ?? -1
    let on = enabled(item)
    return (char == Reference.findShortcut.0 && mods == Reference.findShortcut.1 && on,
            "\(label(item)) [\(char) \(mods)] \(on ? "enabled" : "disabled")")
}

/// The search field stays reachable from the keyboard: Tab (or Shift-Tab) from the list,
/// and Edit › Find (⌘F). The list gets the focus back through accessibility between
/// the two.
func measureKeyboardToSearch() {
    let d = "-", p = "search-keyboard"
    guard let outline = findSidebarOutline(d, p),
          let field = require(d, p, "sidebar search field", find: sidebarSearchField) else { return }
    func focusList() -> Bool {
        drive(d, p, "focus the sidebar list", set(outline, kAXFocusedAttribute, kCFBooleanTrue))
            && awaitState(d, p, "sidebar list focused", timeout: 2) { listHasFocus(outline) }
    }
    guard focusList() else { return }
    // kVK_Tab 48. The rows below report a timeout (2 s).
    postKey(d, p, 48, [])
    var how = "Tab"
    if !waitUntil(timeout: 2, { searchHasFocus(field) }) {
        guard focusList() else { return }
        postKey(d, p, 48, .maskShift)
        waitUntil(timeout: 2) { searchHasFocus(field) }
        how = "Shift-Tab"
    }
    record(d, p, "Tab from the list reaches the search field", expected: "focused by Tab or Shift-Tab",
           got: searchHasFocus(field) ? "focused by \(how)" : "focused: \(describe(focusedElement()))", ok: searchHasFocus(field))
    guard focusList() else { return }
    // What ⌘F should hit, read before pressing it, so a failure says why: the menu item's
    // title (system strings, D38), shortcut and whether it is on with the list focused.
    let findItem = findMenuItemState()
    record(d, p, "Edit › Find › Find… before ⌘F", expected: "present, \(Reference.findShortcut.0) with modifiers \(Reference.findShortcut.1), enabled",
           got: findItem.description, ok: findItem.ok)
    guard focusList() else { return }
    // kVK_ANSI_F 3 with ⌘: Edit › Find › Find…. The row below reports a timeout (2 s).
    postKey(d, p, 3, .maskCommand)
    waitUntil(timeout: 2) { searchHasFocus(field) }
    record(d, p, "⌘F from the list focuses the search field", expected: "focused",
           got: searchHasFocus(field) ? "focused" : "focused: \(describe(focusedElement()))", ok: searchHasFocus(field))
    _ = focusList()
}

/// At launch, before anything is selected: the window opens on Gõ phím with nothing
/// visited, so Back and Forward are both off (artboard "SettingsTyping").
func measureLaunchState() {
    let d = "-", p = "launch"
    checkShown(d, p, "at launch", 0)
    checkHistoryButtons(d, p, "at launch", back: false, forward: false)
}

/// Back/Forward wiring (what the history does is `swift test` "Settings history"):
/// visiting another section turns Back on; Back and Forward, through the buttons and
/// through ⌘[ ⌘] (View menu), move between the two pages.
func measureHistory() {
    let d = "-", p = "history"
    guard showSection(d, 0), showSection(d, 1) else { return }
    checkShown(d, p, "after selecting \(sections[1])", 1)
    checkHistoryButtons(d, p, "after selecting another section", back: true, forward: false)
    guard let back = require(d, p, "toolbar button \"\(Reference.backLabel)\"", find: { historyButton(Reference.backLabel) }),
          drive(d, p, "press \(Reference.backLabel)", press(back)) else { return }
    checkShown(d, p, "after \(Reference.backLabel)", 0)
    checkHistoryButtons(d, p, "after \(Reference.backLabel)", back: nil, forward: true)
    guard let forward = require(d, p, "toolbar button \"\(Reference.forwardLabel)\"", find: { historyButton(Reference.forwardLabel) }),
          drive(d, p, "press \(Reference.forwardLabel)", press(forward)) else { return }
    checkShown(d, p, "after \(Reference.forwardLabel)", 1)
    checkHistoryButtons(d, p, "after \(Reference.forwardLabel)", back: true, forward: false)
    // kVK_ANSI_LeftBracket / RightBracket: "[" and "]" on the ANSI layout.
    postKey(d, p, 33, .maskCommand)
    checkShown(d, p, "after ⌘[", 0)
    postKey(d, p, 30, .maskCommand)
    checkShown(d, p, "after ⌘]", 1)
}

/// A sheet on the window (the add-rule sheet): ⌘[ ⌘] and View › Back / Forward must leave
/// the page behind it alone, and the two items must be off while the sheet is up (as in a
/// modal state; a page changing behind a sheet is not seen by the user). Back and Forward
/// both have somewhere to go when the sheet opens: the pages visited are 0, apps, last,
/// and Back returned to apps.
func measureHistoryUnderSheet() {
    let d = "-", p = "history-under-sheet"
    let last = sections.count - 1
    guard last > appsIndex, showSection(d, 0), showSection(d, appsIndex), showSection(d, last),
          let back = require(d, p, "toolbar button \"\(Reference.backLabel)\"", find: { historyButton(Reference.backLabel) }),
          drive(d, p, "press \(Reference.backLabel)", press(back)) else { return }
    checkShown(d, p, "before the sheet", appsIndex)
    checkHistoryButtons(d, p, "before the sheet", back: true, forward: true)
    guard let add = require(d, p, "toolbar + (\"Thêm ứng dụng\")", find: toolbarAddButton),
          drive(d, p, "press +", press(add)),
          requireShown(d, p, "sheet opened by +", within: 5, find: attachedSheet) != nil else {
        if attachedSheet() != nil { closeSheet(d) }
        return
    }
    // kVK_ANSI_LeftBracket / RightBracket. Under the sheet nothing may change, and no
    // state shows that a key was ignored: each key gets a fixed 1 s before the rows.
    postKey(d, p, 33, .maskCommand)
    wait(1.0)
    checkShown(d, p, "under the sheet after ⌘[", appsIndex)
    record(d, p, "sheet after ⌘[", expected: "shown", got: attachedSheet() == nil ? "closed" : "shown", ok: attachedSheet() != nil)
    postKey(d, p, 30, .maskCommand)
    wait(1.0)
    checkShown(d, p, "under the sheet after ⌘]", appsIndex)
    record(d, p, "sheet after ⌘]", expected: "shown", got: attachedSheet() == nil ? "closed" : "shown", ok: attachedSheet() != nil)
    // The View menu's items while the sheet is up.
    let viewTitles = systemTitles([Reference.viewMenuKey])
    if let bar = require(d, p, "menu bar", find: { attr(app, kAXMenuBarAttribute).map { $0 as! AXUIElement } }),
       let viewItem = require(d, p, "View menu", find: { children(bar).first { viewTitles.contains(label($0)) } }),
       drive(d, p, "open the View menu", press(viewItem)) {
        waitForMenu(viewItem)
        let items = children(viewItem).first { role($0) == "AXMenu" }.map { children($0).filter { role($0) == "AXMenuItem" } } ?? []
        for title in [Reference.backLabel, Reference.forwardLabel] {
            let item = items.first { label($0) == title }
            record(d, p, "menu item \"\(title)\" under the sheet", expected: "disabled",
                   got: item.map { enabled($0) ? "enabled" : "disabled" } ?? "missing", ok: item.map { !enabled($0) } ?? false)
        }
        if let menu = children(viewItem).first(where: { role($0) == "AXMenu" }) { _ = AXUIElementPerformAction(menu, kAXCancelAction as CFString) }
        closeMenu(viewItem)
    }
    closeSheet(d)
    checkShown(d, p, "after the sheet closed", appsIndex)
    checkHistoryButtons(d, p, "after the sheet closed", back: true, forward: true)
}

/// Values of `keys` in the system's string tables, in the app's languages.
func systemTitles(_ keys: [String]) -> Set<String> {
    var titles = Set<String>()
    for path in Reference.menuStringTables {
        guard let data = FileManager.default.contents(atPath: path),
              let table = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else { continue }
        for language in Reference.menuLanguages {
            guard let strings = table[language] as? [String: String] else { continue }
            for key in keys { if let v = strings[key] { titles.insert(v) } }
        }
    }
    return titles
}

/// After pressing a menu bar item: until it is selected (open; 2 s at most, then read
/// anyway), then until its items' titles and enabled states stay the same on 3 reads
/// (AppKit validates them as the menu opens).
func waitForMenu(_ item: AXUIElement) {
    waitUntil(timeout: 2) { (attr(item, kAXSelectedAttribute) as? Bool) == true }
    _ = waitSettled(timeout: 2, interval: 0.1, reads: 3) {
        (children(item).first { role($0) == "AXMenu" }.map { children($0).filter { role($0) == "AXMenuItem" } } ?? [])
            .map { "\(label($0)) \(enabled($0))" }
    }
}
/// After cancelling a menu: until its menu bar item is no longer selected; if it still is
/// after 2 s, Escape, and the same wait again.
func closeMenu(_ item: AXUIElement) {
    func open() -> Bool { (attr(item, kAXSelectedAttribute) as? Bool) == true }
    if waitUntil(timeout: 2, { !open() }) { return }
    for down in [true, false] { CGEvent(keyboardEventSource: nil, virtualKey: 53, keyDown: down)?.post(tap: .cghidEventTap) }
    waitUntil(timeout: 2) { !open() }
}

/// The split group that holds the sidebar: the widest one in the window.
func splitGroup() -> AXUIElement? {
    windowElements { role($0) == "AXSplitGroup" }.max { rel($0).width < rel($1).width }
}
/// The sidebar's divider.
func splitter() -> AXUIElement? {
    splitGroup().flatMap { children($0).first { role($0) == "AXSplitter" } }
}
/// The sidebar's width: the split group's leftmost pane, else where the divider ends.
func shownSidebarWidth() -> CGFloat? {
    guard let group = splitGroup() else { return nil }
    if let pane = children(group).filter({ role($0) != "AXSplitter" }).min(by: { rel($0).minX < rel($1).minX }) {
        return rel(pane).width
    }
    return splitter().map { rel($0).maxX }
}
func checkSidebarWidth(_ d: String, _ p: String, _ when: String) {
    let width = shownSidebarWidth()
    record(d, p, "sidebar width \(when)", expected: fmt(sidebarWidth),
           got: width.map(fmt) ?? "no split group (sidebar gone?)", ok: width.map { near($0, sidebarWidth) } ?? false)
}

/// D9 "Sidebar cố định như System Settings": the sidebar keeps its width when the window
/// is at its widest and narrowest (resized through accessibility). That the divider has
/// no mouse area and the sidebar cannot collapse is `swift test` "Settings window shell".
func measureFixedSidebar() {
    let d = "-", p = "sidebar-fixed"
    guard showSection(d, 0) else { return }
    checkSidebarWidth(d, p, "at the start")
    for (name, size) in [("widest", Reference.probeLargeSize), ("narrowest", Reference.probeSmallSize)] {
        guard drive(d, p, "resize the window", set(window, kAXSizeAttribute, axSize(size))) else { continue }
        awaitSettled(d, p, "window frame and sidebar after resizing") { "\(fmt(frame(window))) \(shownSidebarWidth().map(fmt) ?? "-")" }
        checkSidebarWidth(d, p, "at the \(name) window")
    }
    if drive(d, p, "restore the default window size", set(window, kAXSizeAttribute, axSize(Reference.windowSize))) {
        awaitSettled(d, p, "window frame after resizing") { fmt(frame(window)) }
    }
}

// MARK: - Always scroll bars (--pixels)

/// Per section: the scroll room rule (a) and a screenshot for check.swift (b), (c). On
/// Reference.scrollingSection: scrolled through its scroll bar, the bar's lane (d) and a
/// second screenshot (check.swift compares the header).
func measurePixels(_ d: String, _ tag: String) {
    for index in sections.indices {
        let page = sections[index]
        guard showSection(d, index),
              let area = require(d, page, "page Form (scroll area in the detail column)", find: pageScrollArea),
              let card = require(d, page, "first card", find: { pageItems(area).first { $0.role == "AXGroup" } }),
              let first = require(d, page, "first card or header", find: { pageItems(area).first })
        else { continue }
        let w = frame(window)
        let full = w.width - sidebarWidth - 2 * formMargin
        // (a) Always bars: only a page that needs one shows it; the page may get narrower
        // by exactly the system's Always bar width, and nothing moves.
        check(d, page, "(a) first card x", card.frame.minX, sidebarWidth + formMargin)
        check(d, page, "(a) first item y", first.frame.minY, Reference.formFirstItemY)
        var shot: [String: CGRect] = ["column": rel(area), "firstCard": card.frame]
        let bar = pageScrollBar()
        if let bar {
            let r = rel(bar)
            shot["scroller"] = r
            // The bar's accessibility frame is not the lane the page gives up: it measured
            // 19 pt wide, reaching 1 pt past the window, against the system's 17.
            // So the bar's width is not compared; the card width below holds the lane rule.
            record(d, page, "(a) first card width with the scroll bar", expected: "\(fmt(full)) or \(fmt(full - alwaysBarWidth)) (narrower by the bar)",
                   got: fmt(card.frame.width), ok: near(card.frame.width, full) || near(card.frame.width, full - alwaysBarWidth))
        } else {
            check(d, page, "(a) first card width without a scroll bar", card.frame.width, full)
        }
        _ = screenshot(d, page, "\(page)-\(tag)", frames: shot)

        guard page == Reference.scrollingSection else { continue }
        // (d) Item 10: the page that overflows shows a scroll bar; scrolled through it, the
        // header keeps covering the content (check.swift) and the bar stays in its lane.
        guard let scrollBar = requireShown(d, page, "(d) scroll bar of the page that overflows",
                                      diagnose: { "missing (Always bars show on overflowing pages; the scrolled checks did not run)" },
                                      find: { bar }) else { continue }
        // How far the page moved: the item nearest the column's middle, which stays in view.
        let column = rel(area)
        guard let anchor = require(d, page, "(d) item in the middle of the page", find: {
            pageItems(area).min { abs($0.frame.midY - column.midY) < abs($1.frame.midY - column.midY) } })
        else { continue }
        func offset() -> CGFloat? {
            let r = rel(anchor.element)
            return r.height > 0 ? anchor.frame.minY - r.minY : nil
        }
        // The bar's value is a fraction of the scrollable height: try a tenth, then scale
        // to the probe offset.
        guard drive(d, page, "scroll the page", set(scrollBar, kAXValueAttribute, NSNumber(value: 0.1))) else { continue }
        // Until the page has moved and stops moving (3 reads); the rows below report
        // where it ended.
        _ = waitSettled(timeout: 3, interval: 0.1, reads: 3, valid: { ($0 ?? 0) > 0.5 }, offset)
        if let tenth = offset(), tenth > 0.5 {
            let value = min(1, 0.1 * Reference.scrollProbeOffset / tenth)
            drive(d, page, "scroll the page", set(scrollBar, kAXValueAttribute, NSNumber(value: Double(value))))
            _ = waitSettled(timeout: 3, interval: 0.1, reads: 3, offset)
        }
        guard let scrolled = offset() else {
            harness(d, page, "(d) page scrolls with its bar", expected: "≥ \(fmt(Reference.scrollProbeMinOffset)) pt",
                    got: "the item measured before scrolling is gone from the accessibility tree")
            continue
        }
        record(d, page, "(d) page scrolls with its bar", expected: "≥ \(fmt(Reference.scrollProbeMinOffset)) pt",
               got: "\(fmt(scrolled)) pt", ok: scrolled >= Reference.scrollProbeMinOffset)
        let lane = rel(scrollBar)
        record(d, page, "(d) scroll bar lane", expected: "right \(fmt(Reference.scrollerLane)) pt of the window, below y \(fmt(Reference.scrollerMinY))",
               got: fmt(lane), ok: lane.maxX <= w.width + Reference.tolerance && lane.minX >= w.width - Reference.scrollerLane
                && lane.minY >= Reference.scrollerMinY)
        var scrolledShot = shot
        scrolledShot["scroller"] = lane
        _ = screenshot(d, page, "\(page)-scrolled-\(tag)", frames: scrolledShot)
        if drive(d, page, "scroll the page back", set(scrollBar, kAXValueAttribute, NSNumber(value: 0.0))) {
            awaitState(d, page, "page scrolled back to the top", timeout: 3) { (offset() ?? 1) <= 0.5 }
        }
    }
}

// MARK: - Run

// One pass per backing scale, the primary display first.
var seenScales = Set<CGFloat>()
let displays = NSScreen.screens.filter { seenScales.insert($0.backingScaleFactor).inserted }
guard let primary = NSScreen.screens.first else { harnessAbort("displays", expected: "at least one", got: "none") }
func tag(_ screen: NSScreen) -> String { "\(fmt(screen.backingScaleFactor))x" }

// `--focus` (also first in --geometry): the launch focus before anything moves; then the
// keyboard ways into the sidebar search and, with --focus alone, the search rows on the
// primary display (run.sh --focus: a quick pass in both appearances).
if modes.contains("--focus") || modes.contains("--geometry") {
    measureLaunchFocus()
}
if modes.contains("--focus") && !modes.contains("--geometry"), moveWindow(to: primary, tag(primary)) {
    measureKeyboardToSearch()
    measureSidebarSearch(tag(primary), "\(tag(primary))-\(appearance)")
}
if modes.contains("--geometry") {
    measureLaunchState()
    // The sections on every display (layout follows the backing scale); the sidebar search
    // and the add-rule sheet are wiring and behaviour, the same on any display: the
    // primary one only (`displays` starts with it).
    for screen in displays where moveWindow(to: screen, tag(screen)) {
        for index in sections.indices { measureSection(tag(screen), tag(screen), index) }
        if screen == primary {
            measureSidebarSearch(tag(screen), tag(screen))
            measureSheet(tag(screen), tag(screen))
        }
    }
    measureLimits()
    measureKeyboardToSearch()
    measureHistory()
    measureHistoryUnderSheet()
    // Last: it resizes the window.
    measureFixedSidebar()
}
// `--shell` alone: only the Back/Forward rows (a quick pass on a running app).
if modes.contains("--shell") && !modes.contains("--geometry") {
    measureHistory()
    measureHistoryUnderSheet()
}
if modes.contains("--pixels") || modes.contains("--sheet-shots"), moveWindow(to: primary, tag(primary)) {
    if modes.contains("--pixels") { measurePixels(tag(primary), tag(primary)) }
    if modes.contains("--sheet-shots") { sheetShots(tag(primary), tag(primary)) }
}

shots["meta"] = ["primaryScale": [Double(primary.backingScaleFactor)], "dark": [appearance == "dark" ? 1 : 0]]
if let data = try? JSONSerialization.data(withJSONObject: shots, options: [.sortedKeys, .prettyPrinted]) {
    try? data.write(to: outDir.appendingPathComponent("frames.json"))
}

print("display | page | metric | expected | Dấu | result")
rows.forEach { print($0) }
failures.forEach { print("FAIL", $0) }
harnessProblems.forEach { print("HARNESS", $0) }
if !harnessProblems.isEmpty { print("\(harnessProblems.count) harness problem(s): the checker could not do its part; not a UI result.") }
if !failures.isEmpty { print("\(failures.count) real-window check(s) failed.") }
if failures.isEmpty && harnessProblems.isEmpty { print("Real-window checks passed (\(rows.count)).") }
exit(failures.isEmpty && harnessProblems.isEmpty ? 0 : 1)
