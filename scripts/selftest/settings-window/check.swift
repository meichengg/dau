// Pixel checks of the real Settings window's screenshots, and frame checks of the in-app
// onboarding and uninstall captures (docs/UI-CHECKS.md). run.sh compiles this file with
// Reference.swift (every pass value) and runs it after the app launches.
//
// Usage: check <out-dir> whenScrolling:<dir> always:<dir>…
//   whenScrolling:<dir>  ax-check --geometry output (When scrolling scroll bars): (b), (c), (e)
//   always:<dir>   ax-check --pixels output (Always scroll bars): (b), (c), (d), (e)
// Each <dir> holds the screenshots and frames.json written by ax-check (window points,
// origin at the window's top-left; "meta": the primary display's scale and the
// appearance). Only the primary display's screenshots are checked. Sample positions are
// in points, so the checks follow the image's scale; the probe offsets in Reference.swift
// were set on a 2x display, which the output says when the primary display is 1x.
//   (b) The page color reaches the right edge (or the scroll bar sitting there), the
//       toolbar band is one color from the middle to the right edge.
//   (c) No strip of another color in the Form's right margin: every When scrolling screenshot,
//       and a Always one only on a page without a scroll bar (a Always bar fills the strip).
//   (d) Scrolled (Reference.scrollingSection, Always): the header looks as when not scrolled.
//   (e) The Ứng dụng toolbar "+" is drawn round.
//   (f) onboarding/, onboarding-no-shortcut/ (Dau --capture-onboarding): every shot has
//       the app name, title, card and buttons where the mockup puts them, and the window
//       shows no title text; a view missing from a shot is FAIL (the app drops a view's
//       frame when it disappears).
//   (g) uninstall/ (Dau --capture-uninstall): both alerts and both sheets of "Bỏ Dấu khỏi
//   nguồn đầu vào" in both appearances, not cut.
// Results as ax-check: FAIL for a UI result off Reference; HARNESS when an input the
// check needs is missing (the step that writes it says why in its own table); no skip.
// Exit status 0 only when every row is ok.
import AppKit

let args = Array(CommandLine.arguments.dropFirst())
guard let rootArg = args.first else { print("usage: check <out-dir> whenScrolling:<dir> always:<dir>…"); exit(2) }
let root = URL(fileURLWithPath: rootArg, isDirectory: true)
let windowDirs: [(style: String, dir: String)] = args.dropFirst().compactMap {
    let parts = $0.split(separator: ":", maxSplits: 1).map(String.init)
    return parts.count == 2 && ["whenScrolling", "always"].contains(parts[0]) ? (parts[0], parts[1]) : nil
}
guard windowDirs.count == args.count - 1 else { print("usage: check <out-dir> whenScrolling:<dir> always:<dir>…"); exit(2) }

// MARK: - Results

nonisolated(unsafe) var rows: [String] = []
nonisolated(unsafe) var failures: [String] = []
nonisolated(unsafe) var harnessProblems: [String] = []
func record(_ where_: String, _ metric: String, expected: String, got: String, ok: Bool) {
    rows.append("\(where_) | \(metric) | \(expected) | \(got) | \(ok ? "ok" : "FAIL")")
    if !ok { failures.append("\(where_) \(metric): expected \(expected), got \(got)") }
}
func harness(_ where_: String, _ metric: String, _ missing: String) {
    rows.append("\(where_) | \(metric) | input | \(missing) | HARNESS")
    harnessProblems.append("\(where_) \(metric): \(missing)")
}
func fmt(_ v: CGFloat) -> String { v == v.rounded() ? String(Int(v)) : String(format: "%.1f", v) }
func fmt(_ r: CGRect) -> String { "\(fmt(r.minX)),\(fmt(r.minY)) \(fmt(r.width))×\(fmt(r.height))" }
func near(_ a: CGFloat?, _ b: CGFloat, _ tolerance: CGFloat = Reference.tolerance) -> Bool { a.map { abs($0 - b) <= tolerance } ?? false }

// MARK: - Inputs

typealias Frames = [String: CGRect]
/// frames.json of a directory: frames by shot, plus the raw "meta" entry.
func loadFrames(_ dir: URL) -> (shots: [String: Frames], meta: [String: [Double]])? {
    guard let data = try? Data(contentsOf: dir.appendingPathComponent("frames.json")),
          let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: [Double]]] else { return nil }
    var shots: [String: Frames] = [:]
    for (key, entries) in json where key != "meta" {
        var frames: Frames = [:]
        for (name, v) in entries where v.count == 4 { frames[name] = CGRect(x: v[0], y: v[1], width: v[2], height: v[3]) }
        shots[key] = frames
    }
    return (shots, json["meta"] ?? [:])
}
func image(_ url: URL) -> NSBitmapImageRep? { (try? Data(contentsOf: url)).flatMap(NSBitmapImageRep.init(data:)) }

struct Pixel {
    var r, g, b: Double
    func distance(_ o: Pixel) -> Double { max(abs(r - o.r), abs(g - o.g), abs(b - o.b)) }
}
/// A screenshot with its window size in points: samples are taken in points, whatever the scale.
struct Shot {
    let rep: NSBitmapImageRep
    let width: CGFloat, height: CGFloat
    var scale: CGFloat { CGFloat(rep.pixelsWide) / width }
    func pixel(_ x: CGFloat, _ y: CGFloat) -> Pixel {
        var p = [Int](repeating: 0, count: 4)
        rep.getPixel(&p, atX: min(max(Int(x * scale), 0), rep.pixelsWide - 1),
                     y: min(max(Int(y * scale), 0), rep.pixelsHigh - 1))
        return Pixel(r: Double(p[0]), g: Double(p[1]), b: Double(p[2]))
    }
}

let colorTol = Reference.colorTolerance

// MARK: - Settings window: (b)–(e)

for (style, dirName) in windowDirs {
    let dir = root.appendingPathComponent(dirName)
    guard let (shots, meta) = loadFrames(dir) else {
        harness(dirName, "frames.json", "missing (see \(dirName).txt)")
        continue
    }
    guard let scale = meta["primaryScale"]?.first, let dark = meta["dark"]?.first else {
        harness(dirName, "frames.json meta", "no primary display scale or appearance (see \(dirName).txt)")
        continue
    }
    let tag = "\(fmt(CGFloat(scale)))x"
    let mode = dark == 1 ? "dark" : "light"
    if scale == 1 {
        print("note: \(dirName): the primary display is 1x, so one pixel per point; the probe offsets in Reference.swift were set on a 2x display.")
    }
    /// The screenshot `key` and its frames; nil (HARNESS) when ax-check did not write them.
    func load(_ key: String, _ metric: String) -> (Shot, Frames)? {
        guard let frames = shots[key], let window = frames["window"],
              let rep = image(dir.appendingPathComponent("\(key).png")) else {
            harness("\(dirName)/\(key)", metric, "no screenshot (see \(dirName).txt)")
            return nil
        }
        return (Shot(rep: rep, width: window.width, height: window.height), frames)
    }

    for section in Reference.sections {
        let key = "\(section)-\(tag)"
        let at = "\(dirName)/\(key) \(mode)"
        guard let (shot, f) = load(key, "(b)–(c) \(style)") else { continue }
        let W = shot.width, H = shot.height
        let scroller = f["scroller"].flatMap { $0.width > 0 ? $0 : nil }
        // Page color: the Form's left margin, between the sidebar and the cards.
        let low = H - Reference.pageSampleBottomInset
        let page = shot.pixel(Reference.pageSampleX, low)

        // (b) Page background reaches the right edge (or the system scroll bar, which then
        // sits at the edge); the toolbar band is one color from the middle to the edge.
        let atEdge = scroller.map { $0.minX <= W - Reference.scrollerEdgeBand && $0.maxY > low } ?? false
        let edgeX = atEdge ? scroller!.minX - Reference.scrollerPageColorGap : W - Reference.rightEdgeInset
        let edge = shot.pixel(edgeX, low)
        record(at, "(b) page color at the right edge", expected: "within \(Int(colorTol)) of the left margin (x \(fmt(edgeX)))",
               got: "\(Int(page.distance(edge)))", ok: page.distance(edge) <= colorTol)
        if atEdge, let s = scroller {
            record(at, "(b) scroll bar ends at the window edge", expected: fmt(W), got: fmt(s.maxX), ok: near(s.maxX, W))
        }
        if section != "apps" {   // the Ứng dụng toolbar holds "+" and the search field there
            let y = Reference.toolbarSampleY
            let mid = shot.pixel((Reference.sidebarWidth + W) / 2 + Reference.toolbarSampleMidOffset, y)
            let edge = shot.pixel(W - Reference.toolbarSampleEdgeInset, y)
            record(at, "(b) toolbar color at the right edge", expected: "within \(Int(colorTol)) of its middle",
                   got: "\(Int(mid.distance(edge)))", ok: mid.distance(edge) <= colorTol)
        }

        // (c) No strip of another color in the Form's right margin (item 11). When scrolling bars
        // are not drawn at rest, so the whole strip is sampled. A Always bar fills the
        // strip (it lies in the margin), so (c) runs only on a page without one; on a page
        // with one, (a) in ax-check holds the lane to the bar's width and (b) reads the page
        // color left of it.
        if style == "whenScrolling" || scroller == nil {
            var stray = 0, samples = 0
            for x in stride(from: W - Reference.formMargin + Reference.strayStripInset, to: W, by: 1) {
                for y in stride(from: Reference.straySampleTop, to: low, by: Reference.straySampleStep) {
                    samples += 1
                    if shot.pixel(x, y).distance(page) > colorTol { stray += 1 }
                }
            }
            record(at, "(c) right margin is page color", expected: "0 of \(samples) samples differ", got: "\(stray)", ok: stray == 0 && samples > 0)
        }

        // (e) Item 8: the toolbar "+" is drawn round. Its accessibility frame is the toolbar
        // item's (taller than wide), so the drawn button is found in pixels: the box of the
        // pixels that differ from the toolbar at the top of the frame, scanning a little to
        // its left (the drawn button starts at or before the frame) and not past it to the
        // right (the search field follows).
        // The toolbar does not depend on the scroll-bar style: (e) runs on the geometry
        // launch's captures (When scrolling), the only ones that record the "+" frame.
        if section == "apps" && style == "whenScrolling" {
            guard let add = f["headerAdd"] else {
                harness(at, "(e) + drawn round", "no \"+\" frame (see \(dirName).txt)")
                continue
            }
            let background = shot.pixel(add.minX + 1, add.minY + 1)
            var box = CGRect.null
            var x = add.minX - 4
            while x < add.maxX {
                var y = add.minY
                while y < add.maxY {
                    let p = shot.pixel(x, y)
                    if max(abs(p.r - background.r), abs(p.g - background.g), abs(p.b - background.b)) > Double(Reference.addButtonInkThreshold) {
                        box = box.union(CGRect(x: x, y: y, width: 1 / shot.scale, height: 1 / shot.scale))
                    }
                    y += 1 / shot.scale
                }
                x += 1 / shot.scale
            }
            record(at, "(e) + drawn round", expected: "width = height ± \(fmt(Reference.addButtonRoundTolerance))",
                   got: box.isNull ? "nothing drawn in \(fmt(add))" : "\(fmt(box.width))×\(fmt(box.height))",
                   ok: !box.isNull && abs(box.width - box.height) <= Reference.addButtonRoundTolerance)
        }
    }

    // (d) Scrolled through the bar: the header right of the title looks as when not
    // scrolled (the system's hard scroll edge, item 9).
    if style == "always" {
        let section = Reference.scrollingSection
        let at = "\(dirName)/\(section)-scrolled-\(tag) \(mode)"
        if let (base, _) = load("\(section)-\(tag)", "(d) header when scrolled"),
           let (scrolled, _) = load("\(section)-scrolled-\(tag)", "(d) header when scrolled") {
            var diff = 0.0, n = 0.0
            for x in stride(from: Reference.scrolledProbeStartX, to: scrolled.width - Reference.scrolledProbeRightInset, by: Reference.scrolledProbeStepX) {
                for y in stride(from: Reference.scrolledProbeY.lowerBound, to: Reference.scrolledProbeY.upperBound, by: Reference.scrolledProbeStepY) {
                    diff += scrolled.pixel(x, y).distance(base.pixel(x, y))
                    n += 1
                }
            }
            let mean = n > 0 ? diff / n : .infinity
            record(at, "(d) header when scrolled", expected: "mean difference ≤ \(fmt(CGFloat(Reference.scrolledHeaderMeanDiff)))",
                   got: String(format: "%.1f", mean), ok: mean <= Reference.scrolledHeaderMeanDiff)
        }
    }
}

// MARK: - Onboarding (f)

/// The system's Always scroll bar width (what a scrolling step gives up when the bars are Always).
let alwaysScrollerWidth = NSScroller.scrollerWidth(for: .regular, scrollerStyle: .legacy)

// Mockup positions ("OnboardingConflict", "OnboardingConflictDone", "OnboardingEnable", "OnboardingEnableNotes",
// "OnboardingEnableWaiting", "OnboardingEnableFailed", "OnboardingEnableError",
// "OnboardingEnableDone", "OnboardingEnableDoneNoShortcut", "Onboarding"; window at
// 50,40 in the artboard), the same in every step and both appearances.
let onboardingShots = ["1", "2", "1-done", "2-notes", "2-waiting", "2-failed", "2-error", "2-done", "2-done-noshortcut", "3"]
    .flatMap { step in ["light", "dark"].map { "onboarding-\(step)-\($0)" } }
for dirName in ["onboarding", "onboarding-no-shortcut"] {
    guard let (shots, _) = loadFrames(root.appendingPathComponent(dirName)) else {
        harness(dirName, "(f)", "no frames.json (see the capture step in run.sh's output)")
        continue
    }
    // Flags beside the frames: "titleHidden" is the window's `titleVisibility == .hidden`.
    let flags = (try? Data(contentsOf: root.appendingPathComponent(dirName).appendingPathComponent("frames.json")))
        .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: [String: [Double]]] } ?? [:]
    for key in onboardingShots {
        let at = "\(dirName)/\(key)"
        guard let f = shots[key] else { harness(at, "(f)", "no capture (see the capture step in run.sh's output)"); continue }
        // The mockup has no title text; `.hiddenTitleBar` alone hides it (no window code).
        let hidden = flags[key]?["titleHidden"]?.first
        record(at, "(f) window title hidden", expected: "hidden", got: hidden.map { $0 == 1 ? "hidden" : "shown" } ?? "missing",
               ok: hidden == 1)
        func place(_ name: String, _ ok: (CGRect) -> Bool, expected: String) {
            guard let r = f[name] else {
                record(at, "(f) \(name)", expected: expected, got: "missing (view not shown)", ok: false)
                return
            }
            record(at, "(f) \(name)", expected: expected, got: fmt(r), ok: ok(r))
        }
        place("window", { near($0.width, Reference.onboardingSize.width) && near($0.height, Reference.onboardingSize.height) },
              expected: "\(fmt(Reference.onboardingSize.width))×\(fmt(Reference.onboardingSize.height))")
        let name = Reference.onboardingAppNameOrigin, title = Reference.onboardingTitleOrigin
        place("onbAppName", { near($0.minX, name.x) && near($0.minY, name.y) }, expected: "at \(fmt(name.x)),\(fmt(name.y))")
        place("onbTitle", { near($0.minX, title.x) && near($0.minY, title.y, Reference.onboardingTitleYTolerance) },
              expected: "at \(fmt(title.x)),\(fmt(title.y)) (y ± \(fmt(Reference.onboardingTitleYTolerance)))")
        // The step scrolls when its content is taller than the window (the divider above
        // the buttons shows then). With the system's Always scroll bars (Always, or Automatic
        // with a mouse) the bar takes its own width from the cards; When scrolling bars take none.
        // Same rule as the Settings window: full width, or one system scroller less, and only
        // while the content scrolls.
        let scrolls = f["onbDivider"] != nil
        let cardWidths = scrolls ? [Reference.onboardingCardWidth, Reference.onboardingCardWidth - alwaysScrollerWidth]
                                 : [Reference.onboardingCardWidth]
        place("onbCard", { r in near(r.minX, Reference.onboardingCardX) && cardWidths.contains { w in near(r.width, w) } },
              expected: "x \(fmt(Reference.onboardingCardX)), width \(fmt(Reference.onboardingCardWidth))"
                + (scrolls ? " or \(fmt(Reference.onboardingCardWidth - alwaysScrollerWidth)) (scrolls, Always scroll bar)" : ""))
        place("onbButtons", { near($0.maxX, Reference.onboardingButtonsMaxX) && near($0.maxY, Reference.onboardingButtonsMaxY) },
              expected: "ending at \(fmt(Reference.onboardingButtonsMaxX)),\(fmt(Reference.onboardingButtonsMaxY))")
    }
}

// MARK: - Uninstall alerts (g)

let uninstallDir = root.appendingPathComponent("uninstall")
let uninstallShots = loadFrames(uninstallDir)?.shots
for key in ["confirm", "done", "remove", "remove-hint"].flatMap({ k in ["light", "dark"].map { "uninstall-\(k)-\($0)" } }) {
    let at = "uninstall/\(key)"
    guard let sheet = uninstallShots?[key]?["sheet"], image(uninstallDir.appendingPathComponent("\(key).png")) != nil else {
        harness(at, "(g)", "no capture (see the capture step in run.sh's output)")
        continue
    }
    let min = Reference.alertMinSize
    record(at, "(g) alert not cut", expected: "≥ \(fmt(min.width))×\(fmt(min.height))", got: "\(fmt(sheet.width))×\(fmt(sheet.height))",
           ok: sheet.width >= min.width && sheet.height >= min.height)
}

print("where | check | expected | got | result")
rows.forEach { print($0) }
failures.forEach { print("FAIL", $0) }
harnessProblems.forEach { print("HARNESS", $0) }
if !harnessProblems.isEmpty { print("\(harnessProblems.count) harness problem(s): an input was missing; not a UI result.") }
if !failures.isEmpty { print("\(failures.count) check(s) failed.") }
if failures.isEmpty && harnessProblems.isEmpty { print("Pixel and capture checks passed (\(rows.count)).") }
exit(failures.isEmpty && harnessProblems.isEmpty ? 0 : 1)
