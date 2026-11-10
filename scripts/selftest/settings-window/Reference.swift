// Every pass value of the Settings window UI checks, in one place. Compiled together
// with ax-check.swift (the real window, through the Accessibility API) and check.swift
// (pixels of its screenshots, and the in-app onboarding and uninstall captures) by
// run.sh; docs/UI-CHECKS.md holds no numbers, it points here. Unit: pt, origin at the
// window's (or sheet's) top-left, unless a name says otherwise.
//
// Where a number comes from:
// - System Settings: measured on macOS 27.2 with the Accessibility API and pixels
//   (docs/research/SYSTEM-SETTINGS-REFERENCE.md); D9 makes it the layout reference.
// - Deliberate: Dấu's own choice, noted where it differs from System Settings.
// - System: a value the system or SwiftUI fixes (measured, not chosen).
// - Mockup: the artboards in docs/UI.md (content only under D9; noted where a size
//   still comes from one).
// - Content: follows from what a page holds (docs/UI.md), not from a metric.
// - Probe: how the check looks, not a property of the window; changing it changes what
//   is sampled, not what is expected.
import CoreGraphics

enum Reference {
    // MARK: Pages

    /// The four sections of the Settings window, in sidebar order.
    static let sections = ["typing", "smart", "apps", "updates"]
    /// Content (docs/UI.md): their titles, in the same order: the system's page title and
    /// the window's title.
    static let sectionTitles = ["Gõ phím", "Thông minh", "Ứng dụng", "Cập nhật & hỗ trợ"]

    // MARK: Tolerance

    /// Frames read through accessibility are compared within ±1 pt.
    static let tolerance: CGFloat = 1
    /// Counts and rows (no tolerance).
    static let exact: CGFloat = 0

    // MARK: Window size and limits (System Settings; the minimum height is deliberate)

    /// System Settings opens every pane at 740 × 560; every pass sets Dấu's window to it
    /// before measuring (a launch can open at a frame macOS restored).
    static let windowWidth: CGFloat = 740
    static let windowHeight: CGFloat = 560
    static var windowSize: CGSize { CGSize(width: windowWidth, height: windowHeight) }
    /// Narrowest window: System Settings' width.
    static let minWindowWidth: CGFloat = windowWidth
    /// The content column's minimum height (deliberate); the window adds the toolbar.
    static let contentMinHeight: CGFloat = 400
    static let minWindowHeight: CGFloat = contentMinHeight + toolbarHeight
    /// Widest window: System Settings' window has a fixed width (setting another width
    /// reads back 740, measured on macOS 27.2; SYSTEM-SETTINGS-REFERENCE.md, "Cửa sổ có đổi
    /// rộng được không"), and so has Dấu's.
    static let maxWindowWidth: CGFloat = windowWidth
    /// Probe: sizes the real window is asked for to read its limits.
    static let probeLargeSize = CGSize(width: 1400, height: 700)
    static let probeSmallSize = CGSize(width: 600, height: 300)

    // MARK: Toolbar (System Settings)

    /// Title bar + toolbar height.
    static let toolbarHeight: CGFloat = 52
    /// Apps toolbar: the "+" is at least this far right of the title.
    static let appsAddGapToTitle: CGFloat = 8
    /// Apps toolbar: the search field's right edge is this far from the window's edge
    /// (lower to upper bound).
    static let appsSearchRightInset: ClosedRange<CGFloat> = 4...24
    /// Apps toolbar "+": the drawn button is as wide as tall within this (its
    /// accessibility frame is the toolbar item's, taller than wide, so the round shape
    /// is read from pixels; check.swift (e)).
    static let addButtonRoundTolerance: CGFloat = 2
    /// Probe: a pixel belongs to the "+" button when a channel is this far (of 255) from
    /// the toolbar color at the top of the button's frame.
    static let addButtonInkThreshold = 8

    // MARK: Back/Forward (System Settings; labels: Mockup)

    /// Mockup: the buttons' accessibility labels (artboards "Settings…", aria-label), in the
    /// String Catalog.
    static let backLabel = "Lùi"
    static let forwardLabel = "Tiến"
    /// System Settings' pair is one cluster, 73 × 36 at x 240, y 8. Probe (a test app
    /// with the same `ControlGroup`, matched System Settings pixel for pixel):
    /// Back 36 wide at 240, Forward 37 wide at 276, the separator at 276.
    static let backButtonFrame = CGRect(x: 240, y: 8, width: 36, height: 36)
    static let forwardButtonFrame = CGRect(x: 276, y: 8, width: 37, height: 36)

    // MARK: Title (System Settings, after the Back/Forward cluster)

    /// The system's page title (an AXStaticText in the toolbar) starts here. Probe
    /// (the same toolbar in a test app): text frame at x ≈ 317, glyphs from
    /// ≈ 326; System Settings' glyphs start at ≈ 324 (SYSTEM-SETTINGS-REFERENCE.md). Not
    /// yet measured on Dấu: the first run.sh of the new shell confirms or replaces it.
    static let titleX: CGFloat = 317
    /// ... and is centered in the toolbar.
    static let titleCenterY: CGFloat = toolbarHeight / 2

    // MARK: System menus (D38: titles read from the system's string tables)

    /// System: run.sh launches the app with `-AppleLanguages (vi)`, so the system's own
    /// menu items are in that language; English is accepted too. Read from the
    /// system's string tables, never typed here (D38).
    static let menuLanguages = ["vi", "en"]
    static let menuStringTables = [
        "/System/Library/Frameworks/SwiftUI.framework/Versions/A/Resources/MainMenu.loctable",
        "/System/Library/Frameworks/SwiftUI.framework/Versions/A/Resources/Localizable.loctable",
        "/System/Library/Frameworks/AppKit.framework/Resources/MenuCommands.loctable",
    ]
    /// Key (the English text) of the View menu: its Back and Forward items are read while
    /// the add-rule sheet is up.
    static let viewMenuKey = "View"
    /// Edit › Find › Find… (the Find submenu of `TextEditingCommands`, added by `DauApp`):
    /// present, ⌘F, enabled while the sidebar list has the focus; ⌘F puts the focus in the
    /// sidebar search field (D9).
    static let editMenuKey = "Edit"
    static let findSubmenuKey = "Find"
    static let findItemKey = "Find…"
    /// Character and the Accessibility API's modifier mask (0 = ⌘ alone).
    static let findShortcut = ("F", 0)

    // MARK: Close button (System Settings)

    /// Traffic light as the Accessibility API reports it.
    static let closeFrame = CGRect(x: 18, y: 18, width: 16, height: 16)

    // MARK: Sidebar (System Settings)

    static let sidebarWidth: CGFloat = 232
    /// Inset of the search field and the selection cell from the column's edges.
    static let sidebarInset: CGFloat = 10
    /// Search field: x 10, 212 × 28 as System Settings. Deliberate y: Dấu's field is an
    /// `NSSearchField` at the large size with the sidebar's standard 10 pt inset under the
    /// toolbar (D9, fixed sidebar), so it sits at 62 where System Settings' is at 61; D9
    /// accepts the 1–2 pt rather than an offset tuned to the pixel. Probe (a test app
    /// with the same split view): 10,62 212×28.
    static let sidebarSearchY: CGFloat = 62
    static let sidebarSearchHeight: CGFloat = 28
    static var sidebarSearchFrame: CGRect {
        CGRect(x: sidebarInset, y: sidebarSearchY, width: sidebarWidth - 2 * sidebarInset, height: sidebarSearchHeight)
    }
    static let sidebarRowHeight: CGFloat = 32
    /// First row's y (below the search field). Deliberate, as the search field: 100,
    /// System Settings 98 (D9 accepts 1–2 pt). Probe: 100.
    static let sidebarFirstRowY: CGFloat = 100
    /// Selection cell of row `i`: x 10, as wide as the column minus both insets.
    static func sidebarRowFrame(_ i: Int) -> CGRect {
        CGRect(x: sidebarInset, y: sidebarFirstRowY + sidebarRowHeight * CGFloat(i),
               width: sidebarWidth - 2 * sidebarInset, height: sidebarRowHeight)
    }
    /// Probe: the selected row's background is sampled in a square of this side, this far
    /// left of the selection cell's right edge (clear of the label), at the row's middle
    /// (--focus: accent selection at launch).
    static let selectionSampleSize: CGFloat = 8
    static let selectionSampleRightInset: CGFloat = 12
    /// Icon tile: x 19, 20 tall.
    static let sidebarIconX: CGFloat = 19
    static let sidebarIconSize: CGFloat = 20
    /// Where an unselected row's text begins (pixels, so the pixel probe below).
    static let sidebarTextX: CGFloat = 46
    /// Probe: ink search for the text start, x range and y band inside a row.
    static let sidebarTextProbeX: ClosedRange<CGFloat> = 40...70
    static let sidebarTextProbeY: ClosedRange<CGFloat> = 9...23
    /// Probe: a pixel counts as ink when a channel is this far from the background (of 255).
    static let sidebarInkThreshold = 60

    // MARK: Form (System Settings, one deliberate difference)

    /// Margin of the cards to the column's edges, left and right.
    static let formMargin: CGFloat = 20
    /// Toolbar to the first card or header. Deliberate: SwiftUI's grouped Form gives 20,
    /// System Settings has 12 (`.contentMargins` adds to it instead of replacing it).
    static let formTopMargin: CGFloat = 20
    /// First card or section header's y.
    static let formFirstItemY: CGFloat = toolbarHeight + formTopMargin
    /// Inside a card: a row's left and right inset, which is also a section header's
    /// offset from the card's edge.
    static let cardInset: CGFloat = 10
    /// Section header to its card.
    static let headerToCard: CGFloat = 10
    /// A card to the next section header.
    static let cardToHeader: CGFloat = 30

    // MARK: Controls (System Settings)

    static let switchSize = CGSize(width: 36, height: 16)
    /// Buttons, pop-ups, segmented controls.
    static let controlHeight: CGFloat = 24

    // MARK: Add-rule sheet

    /// Content: apps every macOS install has in /System/Applications and its Utilities
    /// folder, whose visible names are the same in English and Vietnamese (the sheet
    /// shows localized names; checked on macOS 27.2). The sheet must list
    /// them unless the user stored a rule for one.
    static let alwaysInstalledApps = ["TextEdit", "FaceTime", "QuickTime Player", "Terminal"]
    /// Capture check (g): the uninstall alerts' sheets are at least this big (deliberate
    /// floor, not a System Settings number).
    static let alertMinSize = CGSize(width: 200, height: 120)

    // MARK: Onboarding window, check (f) (Mockup: "OnboardingConflict", "OnboardingEnable", "Onboarding")

    static let onboardingSize = CGSize(width: 720, height: 500)
    static let onboardingAppNameOrigin = CGPoint(x: 20, y: 50)
    static let onboardingTitleOrigin = CGPoint(x: 266, y: 40)
    /// The title's y moves with the text's line height.
    static let onboardingTitleYTolerance: CGFloat = 2
    static let onboardingCardX: CGFloat = 266
    static let onboardingCardWidth: CGFloat = 418
    static let onboardingButtonsMaxX: CGFloat = 684
    static let onboardingButtonsMaxY: CGFloat = 472

    // MARK: Scroll and background checks, (a)–(d) (System for the scroller; the rest deliberate, content or probe)

    /// Content: a section taller than the default window, so check (d) has a scroll bar to
    /// drive. Every section measured taller than the default window on the in-app
    /// captures (since removed); this is the one the earlier check (d) scrolled, and
    /// `scrolledProbeStartX` starts right of its title.
    static let scrollingSection = "updates"
    /// Probe: how far check (d) scrolls the page (through the scroll bar's value), and the
    /// least that counts: past the Form's top margin, content is under the toolbar.
    static let scrollProbeOffset: CGFloat = 60
    static let scrollProbeMinOffset: CGFloat = formTopMargin
    /// A color differs when a channel is more than 6 of 255 away (page, toolbar band).
    static let colorTolerance = 6.0
    /// Mean per-sample color difference allowed in the header once scrolled (of 255). The
    /// system's scroll edge blurs content under the toolbar, it does not hide it. Measured
    /// on Cập nhật & hỗ trợ with the banner, Always bars, 2x: Dấu 6.8 dark / 5.2
    /// light; a build without `HardTopScrollEdge` (content sharp over the title, item 9)
    /// 31.8 / 31.2. System Settings (Appearance, General; 1x, dark, same sampling) 18–20.
    /// The limit lies halfway between Dấu and the broken build.
    static let scrolledHeaderMeanDiff = 19.0
    /// The scroll bar's lane: it sits in the right margin, at most `formMargin` wide
    /// from the window's edge (System: Always bar), and starts no higher than the
    /// toolbar's bottom edge minus 1.
    static let scrollerLane: CGFloat = formMargin
    static let scrollerMinY: CGFloat = toolbarHeight - 1
    /// Probe: a scroller that reaches at least 10 pt in from the right edge (and below the
    /// page sample) covers the edge: (b) then reads the page color 2 pt left of it.
    static let scrollerEdgeBand: CGFloat = 10
    static let scrollerPageColorGap: CGFloat = 2
    /// Probe: the page color is read this far above the window's bottom, in the Form's
    /// left margin (x = sidebar + half a margin).
    static let pageSampleBottomInset: CGFloat = 40
    static let pageSampleX: CGFloat = sidebarWidth + formMargin / 2
    /// Probe: toolbar band samples at y 44, from the middle (+ 60) and 3 from the edge.
    static let toolbarSampleY: CGFloat = 44
    static let toolbarSampleMidOffset: CGFloat = 60
    static let toolbarSampleEdgeInset: CGFloat = 3
    static let rightEdgeInset: CGFloat = 2
    /// Probe: right-margin strip, sampled from `formMargin - strayStripInset` pt left of
    /// the edge, y 64 down to `pageSampleBottomInset` above the bottom, every 16.
    static let strayStripInset: CGFloat = 2
    static let straySampleTop: CGFloat = 64
    static let straySampleStep: CGFloat = 16
    /// Probe: header region compared when scrolled; x from just right of the page title
    /// ("Cập nhật & hỗ trợ", 127 wide at 15 pt bold, from `titleX` + 9: ends near 453) to
    /// 24 from the edge every 6; y 6...46 every 4.
    static let scrolledProbeStartX: CGFloat = 470
    static let scrolledProbeRightInset: CGFloat = 24
    static let scrolledProbeStepX: CGFloat = 6
    static let scrolledProbeY: Range<CGFloat> = 6..<46
    static let scrolledProbeStepY: CGFloat = 4
}
