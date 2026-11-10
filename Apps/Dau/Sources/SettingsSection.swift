import AppKit
import SwiftUI

/// The four sections of the Settings window (docs/UI.md).
enum SettingsSection: String, CaseIterable, Identifiable, Hashable {
    case typing
    case smart
    case apps
    case updates

    var id: String { rawValue }

    var title: String { String(localized: titleResource) }

    /// The title as a catalog entry: the sidebar row and the page title.
    var titleResource: LocalizedStringResource {
        switch self {
        case .typing: "Typing"
        case .smart: "Smart Typing"
        case .apps: "Apps"
        case .updates: "Updates & Support"
        }
    }

    var symbol: String {
        switch self {
        case .typing: "keyboard"
        case .smart: "wand.and.stars"
        case .apps: "square.grid.2x2"
        case .updates: "arrow.triangle.2.circlepath"
        }
    }

    /// Words the sidebar search matches, besides the title, as catalog entries: the
    /// visible row titles, section headers, choices and buttons of the section, so the
    /// search finds the words in the language the window shows them.
    var keywordResources: [LocalizedStringResource] {
        switch self {
        case .typing:
            ["Preview", "Typing method", "Telex", "VNI", "Simple Telex", "Tone mark placement",
             "Modern", "Classic", "Free mark placement", "Input source shortcut",
             "Switch Vietnamese ↔ English"]
        case .smart:
            ["Foreign words", "Restore non-Vietnamese words", "Editing typed words",
             "Add marks to typed words", "Advanced", "Consonant shortcuts",
             "Allow consonants z, f, w, j"]
        case .apps:
            ["Input source per window", "Remember the input source for each window",
             "App rules", "Add App", "Underline", "No Underline", "Suggested", "Turn On Underline"]
        case .updates:
            ["Version", "Check Now", "Language", "Automatically check for updates",
             "Automatically download and install", "Release channel", "Stable", "Beta",
             "Problems typing in an app?", "Report a Problem…", "Go back to the previous version",
             "Remove Dấu from this Mac", "Uninstall…", "Privacy"]
        }
    }

    /// Words of the section that are macOS's own (D38), in the system's language.
    var systemKeywords: [String] {
        self == .apps ? [SystemUINames.system().automaticallySwitchOption] : []
    }

    /// Case- and diacritic-insensitive match on the words as shown ("go phim" finds
    /// "Gõ phím" in Vietnamese, "typing" finds "Typing" in English).
    func matches(_ query: String) -> Bool {
        matches(query) { String(localized: $0) }
    }

    /// `localize` turns a catalog entry into the shown words: `String(localized:)` in the
    /// app; tests pass one that reads a chosen language of the catalog.
    func matches(_ query: String, localize: (LocalizedStringResource) -> String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return true }
        let words = ([titleResource] + keywordResources).map(localize) + systemKeywords
        return words.contains { $0.searchContains(query) }
    }
}

extension String {
    /// Whether `query` occurs in the string, ignoring case and diacritics, with "đ" read
    /// as "d" too (it is a letter of its own, not a "d" with a mark, so diacritic folding
    /// keeps it): "de xuat" finds "Đề xuất", as people type without marks.
    func searchContains(_ query: String) -> Bool {
        func fold(_ s: String) -> String {
            s.folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: nil)
                .replacingOccurrences(of: "đ", with: "d")
        }
        return fold(self).contains(fold(query))
    }
}

/// Sidebar icon: a tile at System Settings' sidebar icon size (20 pt, measured; see
/// docs/research/SYSTEM-SETTINGS-REFERENCE.md) in a system color, with the mockup's
/// line glyph (canvas artboards "Settings…": viewBox 24, white stroke, round caps and
/// joins, no fill) scaled with the tile as in the mockup (glyph 14 in a 22 tile).
/// Drawn into a non-template image so the sidebar's vibrancy does not wash it out.
/// Decorative; the label beside it carries the meaning.
struct SectionIcon: View {
    let section: SettingsSection

    static let size: CGFloat = 20

    var body: some View {
        Image(nsImage: SectionIcon.tile(section))
            .frame(width: Self.size, height: Self.size)
            .accessibilityHidden(true)
    }

    @MainActor private static var cache: [SettingsSection: NSImage] = [:]

    @MainActor static func tile(_ section: SettingsSection) -> NSImage {
        if let image = cache[section] { return image }
        let size = Self.size
        let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { rect in
            section.tileColor.setFill()
            // Mockup proportions: radius 6 and glyph 14 in a 22 tile.
            let radius = size * 6 / 22
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            // The 24-unit glyph scaled to the glyph size, centered.
            let glyphSize = size * 14 / 22
            let k = glyphSize / 24
            let inset = (size - glyphSize) / 2
            let glyph = section.glyph
            glyph.transform(using: AffineTransform(m11: k, m12: 0, m21: 0, m22: k, tX: inset, tY: inset))
            glyph.lineWidth = 2 * k
            glyph.lineCapStyle = .round
            glyph.lineJoinStyle = .round
            NSColor.white.setStroke()
            glyph.stroke()
            return true
        }
        image.isTemplate = false
        cache[section] = image
        return image
    }
}

extension SettingsSection {
    /// Tile colors: the system colors of the mockup's hues (D9: no custom colors).
    var tileColor: NSColor {
        switch self {
        case .typing: .systemBlue
        case .smart: .systemPurple
        case .apps: .systemOrange
        case .updates: .systemGreen
        }
    }

    /// The mockup's SVG paths, in its 24-unit viewBox (y down).
    var glyph: NSBezierPath {
        let p = NSBezierPath()
        func poly(_ points: [(CGFloat, CGFloat)], close: Bool = true) {
            p.move(to: NSPoint(x: points[0].0, y: points[0].1))
            for pt in points.dropFirst() { p.line(to: NSPoint(x: pt.0, y: pt.1)) }
            if close { p.close() }
        }
        func dot(_ x: CGFloat, _ y: CGFloat) { poly([(x, y), (x + 0.01, y)], close: false) }
        func rect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) {
            p.append(NSBezierPath(roundedRect: NSRect(x: x, y: y, width: w, height: h), xRadius: r, yRadius: r))
        }
        switch self {
        case .typing:
            // rect x2.5 y6 w19 h12 rx3; M6.5 10h.01 M10 10h.01 M13.5 10h.01 M17 10h.01 M8 14h8
            rect(2.5, 6, 19, 12, 3)
            dot(6.5, 10); dot(10, 10); dot(13.5, 10); dot(17, 10)
            poly([(8, 14), (16, 14)], close: false)
        case .smart:
            // M12 3l1.9 4.8L19 9.5l-5.1 1.7L12 16l-1.9-4.8L5 9.5l5.1-1.7z
            poly([(12, 3), (13.9, 7.8), (19, 9.5), (13.9, 11.2), (12, 16), (10.1, 11.2), (5, 9.5), (10.1, 7.8)])
            // M18.5 15.5l.7 1.8 1.8.7-1.8.7-.7 1.8-.7-1.8-1.8-.7 1.8-.7z
            poly([(18.5, 15.5), (19.2, 17.3), (21, 18), (19.2, 18.7), (18.5, 20.5), (17.8, 18.7), (16, 18), (17.8, 17.3)])
        case .apps:
            for (x, y) in [(4.0, 4.0), (13.5, 4.0), (4.0, 13.5), (13.5, 13.5)] { rect(x, y, 6.5, 6.5, 1.8) }
        case .updates:
            // M20 12a8 8 0 1 1-2.4-5.7: the large clockwise arc of the circle at (12,12), r 8
            // (y down), from (20,12) to (17.6,6.3).
            p.move(to: NSPoint(x: 20, y: 12))
            let end = atan2(6.3 - 12, 17.6 - 12) * 180 / .pi + 360
            p.appendArc(withCenter: NSPoint(x: 12, y: 12), radius: 8, startAngle: 0, endAngle: end, clockwise: false)
            // M20 4.5v4h-4
            poly([(20, 4.5), (20, 8.5), (16, 8.5)], close: false)
        }
        return p
    }
}
