import AppKit
import SwiftUI
import DauShared

// Pieces shared by the Settings pages, the add-rule sheet and the onboarding window.
// The Settings pages and the add-rule sheet are grouped `Form`s with the system's
// metrics (D9, System Settings as the reference); the custom pieces are content from
// the mockup that has no system equivalent, kept as the mockup draws them: the preview
// (`PreviewCard`, `PreviewBox`), example chips (`Chip`, `ExampleChips`), "Mới"
// (`NewBadge`), the shortcut keycaps (`Keycap`, TypingSettingsView.swift; System
// Settings writes shortcuts as text) and the "Dấu chưa được bật" banner. The card
// primitive (`SettingsCard`), `SettingsColors` and `settingsButton` remain for the
// onboarding window only. Colors are system colors only.

/// Page and card backgrounds of the onboarding window (the Settings pages and the
/// add-rule sheet use the grouped Form's own colors), chosen among system colors (no
/// blending, no opacity) so the card is lighter than the page in both appearances, as
/// in the mockup. Resolved on macOS 27:
/// - light: page `underPageBackgroundColor` (light gray), card `controlBackgroundColor`
///   (white), as the mockup's light gray page and white cards;
/// - dark: page `controlBackgroundColor` (near black), card `underPageBackgroundColor`
///   (dark gray), as the mockup's dark page and lighter cards.
/// Both are dynamic system colors, so they follow Increase Contrast too.
enum SettingsColors {
    static let page = Color(nsColor: NSColor(name: "DauSettingsPage") { appearance in
        appearance.isDark ? .controlBackgroundColor : .underPageBackgroundColor
    })

    static let card = Color(nsColor: NSColor(name: "DauSettingsCard") { appearance in
        appearance.isDark ? .underPageBackgroundColor : .controlBackgroundColor
    })

    static let separator = Color(nsColor: .separatorColor)
}

extension NSAppearance {
    var isDark: Bool { bestMatch(from: [.aqua, .darkAqua]) == .darkAqua }
}

/// The "+" of the Apps page: a toolbar button beside the page's search field.
struct HeaderAdd {
    var label: String
    var action: () -> Void
}

/// A Settings page: a grouped `Form` whose sections are the page's content, after the
/// "Dấu chưa được bật" banner when it shows. The Form brings System Settings' metrics:
/// 20 pt margins, cards, section headers, row heights, separators, and it scrolls
/// under the toolbar with the system's scroll edge.
///
/// The title is the system's navigation title (`SettingsDetail`). `search` and `add`:
/// the Apps page's header controls, as toolbar items: the system search field
/// (`searchable`) and a "+" button.
struct SettingsPage<Content: View>: View {
    var search: Binding<String>?
    var searchPrompt: Text?
    var add: HeaderAdd?
    @ViewBuilder var content: Content

    init(search: Binding<String>? = nil, searchPrompt: Text? = nil,
         add: HeaderAdd? = nil, @ViewBuilder content: () -> Content) {
        self.search = search
        self.searchPrompt = searchPrompt
        self.add = add
        self.content = content()
    }

    var body: some View {
        Form {
            TamperedBanner()
            NotEnabledBanner()
            content
        }
        .formStyle(.grouped)
        // Content scrolled under the toolbar must not show through the title (UI-CHECKS
        // item 9): the system's hard scroll edge on macOS 26+.
        .modifier(HardTopScrollEdge())
        .modifier(PageSearch(text: search, prompt: searchPrompt, add: add))
    }
}

/// macOS 26+: the system's hard scroll-edge effect under the toolbar (solid material
/// and edge) instead of the soft fade, so content scrolled under the header never
/// shows through the title. A system style, not a custom metric.
struct HardTopScrollEdge: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.scrollEdgeEffectStyle(.hard, for: .top)
        } else {
            content
        }
    }
}

/// The page's toolbar search field and "+" (Apps), on the trailing side of the
/// toolbar, after the Back/Forward cluster and the title. The system puts the search
/// field of `searchable` last, after the "+" (macOS 27.2: a
/// `DefaultToolbarItem(kind: .search)` placed before the "+" does not move it), the
/// order of the "SettingsApps" artboard.
private struct PageSearch: ViewModifier {
    let text: Binding<String>?
    let prompt: Text?
    let add: HeaderAdd?

    func body(content: Content) -> some View {
        if let text {
            if #available(macOS 26, *) {
                content
                    .toolbar {
                        // Pushes the "+" and the search field to the trailing edge.
                        ToolbarSpacer(.flexible)
                        if let add {
                            ToolbarItem(placement: .primaryAction) { HeaderAddButton(add: add) }
                        }
                    }
                    .searchable(text: text, placement: .toolbar, prompt: prompt)
            } else {
                content
                    .toolbar {
                        if let add {
                            ToolbarItem(placement: .primaryAction) { HeaderAddButton(add: add) }
                        }
                    }
                    .searchable(text: text, placement: .toolbar, prompt: prompt)
            }
        } else {
            content
        }
    }
}

/// The toolbar "+": a system toolbar button with the "plus" symbol.
struct HeaderAddButton: View {
    let add: HeaderAdd

    var body: some View {
        Button(action: add.action) {
            Label { Text(verbatim: add.label) } icon: { Image(systemName: "plus") }
        }
        .help(Text(verbatim: add.label))
    }
}

/// Secondary text in a Form row or section header: System Settings' subtitle, 11 pt
/// regular, secondary color.
struct Subtitle: View {
    let text: Text
    init(_ text: Text) { self.text = text }

    var body: some View {
        text
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A section header with a description under the title, above the card, as System
/// Settings does (Notifications pane).
struct SectionHeader: View {
    let title: Text
    let description: Text

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            title
            Subtitle(description)
                .fontWeight(.regular)
        }
    }
}

/// A rounded card holding rows (onboarding): radius 14, 1 pt separator border.
struct SettingsCard<Content: View>: View {
    var padding: CGFloat = 0
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SettingsColors.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(SettingsColors.separator, lineWidth: 1)
        }
    }
}

/// 12 pt secondary text.
struct Hint: View {
    let text: Text
    init(_ text: Text) { self.text = text }

    var body: some View {
        text
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    /// Onboarding buttons as in the mockup: capsule, about 30 pt tall.
    func settingsButton() -> some View {
        self.controlSize(.large).buttonBorderShape(.capsule)
    }

}

/// Capsule label: configuration chips, "Đề xuất", example keys. A label, not a control.
struct Chip: View {
    let text: Text
    var height: CGFloat = 22
    var fontSize: CGFloat = 12
    var monospaced = false
    /// Emphasized: the result of an example.
    var emphasized = false

    init(_ text: Text, height: CGFloat = 22, fontSize: CGFloat = 12,
         monospaced: Bool = false, emphasized: Bool = false) {
        self.text = text
        self.height = height
        self.fontSize = fontSize
        self.monospaced = monospaced
        self.emphasized = emphasized
    }

    var body: some View {
        text
            .font(.system(size: fontSize, weight: emphasized ? .semibold : .regular,
                          design: monospaced ? .monospaced : .default))
            .foregroundStyle(emphasized ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 9)
            .frame(height: height)
            .background(.fill.tertiary, in: Capsule())
    }
}

/// "Mới" badge: accent fill with the system's text-on-accent color.
struct NewBadge: View {
    var body: some View {
        Text("New")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(Color(nsColor: .alternateSelectedControlTextColor))
            .padding(.horizontal, 7)
            .padding(.vertical, 1)
            .background(Color.accentColor, in: Capsule())
    }
}

/// "keys › result" as two chips (mockup "Thông minh"); the result is emphasized.
/// Both come from the engine (`TypingExample`). VoiceOver reads "keys thành result".
struct ExampleChips: View {
    let example: TypingExample

    var body: some View {
        HStack(spacing: 6) {
            Chip(Text(verbatim: keysText), monospaced: true)
            Image(systemName: "chevron.right")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondary)
            Chip(Text(verbatim: example.result), emphasized: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(keysText) becomes \(example.result)"))
    }

    private var keysText: String {
        example.displayed.isEmpty ? example.keys : "\(example.displayed) + \(example.keys)"
    }
}

/// Lays chips out left to right and wraps to the next line when the row is full.
struct WrappingHStack: Layout {
    var spacing: CGFloat = 14
    var lineSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, lineHeight: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width {
                y += lineHeight + lineSpacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            lineHeight = max(lineHeight, size.height)
        }
        return CGSize(width: proposal.width ?? maxX, height: y + lineHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, lineHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += lineHeight + lineSpacing
                x = bounds.minX
                lineHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}

/// "Dấu chưa được bật" banner (docs/UI.md, "Các trạng thái bổ sung", mockup
/// "SettingsNotEnabled", "SettingsBannerStates"), first on every page while Dấu is not
/// among the enabled input sources: a tile (orange with a white warning symbol), title,
/// subtitle, button.
///
/// "Bật lại" enables Dấu (N4: the user's click, read back from Text Input Sources). While
/// macOS waits for the user's Allow the banner waits too (spinner, "Thử lại" cancels the
/// wait and asks again); when macOS keeps Dấu off it says so with the way to add it by
/// hand and "Thử lại"; once enabled it turns into a green confirmation with the real
/// shortcut and "Ẩn", which hides it for this session. No undo: Dấu cannot switch itself
/// off. Not installed or not listed yet: the onboarding window opens.
struct NotEnabledBanner: View {
    @Environment(InputSourceStatus.self) private var status
    @Environment(\.inputMethodActions) private var actions
    @Environment(\.openWindow) private var openWindow
    /// The Settings scene's `openWindow`: the pages live in a hosting controller of the
    /// window's split view (`SettingsEnvironment`).
    @Environment(\.settingsOpenWindow) private var settingsOpenWindow

    var body: some View {
        let ui = SystemUINames.system()   // macOS's own names (D38)
        let state = actions?.banner ?? .idle
        switch state {
        case .enabled:
            noticeBanner(probe: "banner.enabled", leading: tile(.green, symbol: "checkmark"),
                         title: Text("Dấu Is On"), hint: enabledHint) {
                Button("Hide") { actions?.dismissBanner() }
            }
        case .working:
            noticeBanner(probe: "banner.working", leading: ProgressView().controlSize(.small).frame(width: 28, height: 28).accessibilityHidden(true),
                         title: Text("Waiting for you to click \(ui.allow)"),
                         hint: Text("The dialog is in the \(ui.systemSettings) window. Click \(ui.allow) to turn on Dấu.")) {
                Button("Try Again") { enable() }
            }
            .accessibilityAddTraits(.updatesFrequently)
        case .notEnabled, .failed:
            noticeBanner(probe: "banner.notEnabled", leading: tile(.orange, symbol: "exclamationmark.triangle.fill"),
                         title: Text("Couldn’t Turn On Dấu"),
                         hint: Text("Click Try Again, then \(ui.allow), or add it yourself: \(ui.inputSourcesPath) › \(ui.edit) › + › \(ui.vietnamese) › Dấu.")) {
                Button("Try Again") { enable() }
            }
            .onChange(of: status.isEnabled) { _, isEnabled in actions?.inputSourcesChanged(isEnabled: isEnabled) }
        case .idle:
            if status.isEnabled == false {
                noticeBanner(probe: "banner.idle", leading: tile(.orange, symbol: "exclamationmark.triangle.fill"),
                             title: Text("Dấu isn’t turned on in your input sources"),
                             hint: Text("You can still change settings, but you can’t type Vietnamese yet.")) {
                    Button("Turn On Again") { enable() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    /// "Chọn Dấu trong menu nhập liệu, hoặc bấm ⌃Space để chuyển giữa Dấu và U.S.": the
    /// real shortcut (N5); without a readable one, only the first half.
    private var enabledHint: Text {
        guard let actions else { return Text("Choose Dấu from the Input menu.") }
        switch (actions.shortcut.shortcut, actions.englishLayout) {
        case (let shortcut?, let layout?):
            return Text("Choose Dấu from the Input menu, or press \(shortcut.inlineText) to switch between Dấu and “\(layout)”.")
        case (let shortcut?, nil):
            return Text("Choose Dấu from the Input menu, or press \(shortcut.inlineText) to switch between Dấu and an English keyboard.")
        default:
            return Text("Choose Dấu from the Input menu.")
        }
    }

    private func tile(_ tint: Color, symbol: String) -> some View {
        // Mockup "SettingsNotEnabled": a tile in a system color with a white symbol, at
        // the size of the app icons in Form rows. System colors only (D9).
        Image(systemName: symbol)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 28, height: 28)
            .background(tint, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
            .accessibilityHidden(true)
    }

    private func enable() {
        guard let actions else {
            // Snapshots and previews: no installer, only guide (N4).
            SystemSettings.openKeyboard()
            return
        }
        Task {
            if await actions.enableFromBanner() {
                (settingsOpenWindow ?? openWindow)(id: OnboardingScene.id)
            }
        }
    }
}

/// "Bộ gõ trên máy không phải bản Dấu đã cài" (mockup "SettingsTampered"): the input
/// method in ~/Library/Input Methods does not carry this app's signature, so whatever
/// replaced it gets every key typed with the enabled "Dấu – Tiếng Việt". "Cài lại"
/// installs the app's own copy.
struct TamperedBanner: View {
    @Environment(\.inputMethodActions) private var actions

    var body: some View {
        if let actions, actions.installedTampered {
            noticeBanner(leading: Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color.red, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                            .accessibilityHidden(true),
                         title: Text("Dấu’s input method on this Mac has been changed"),
                         hint: actions.reinstall == .failed
                            ? Text("Couldn’t reinstall. Uninstall Dấu, then install it again from a fresh download.")
                            : Text("The input method was replaced or modified after it was installed. Reinstall to type with Dấu’s own copy.")) {
                Button("Reinstall") { Task { await actions.reinstallInputMethod() } }
                    .buttonStyle(.borderedProminent)
                    .disabled(actions.reinstall == .working)
            }
        }
    }
}

/// A notice as the first section of the page's Form: one row with the tile, the
/// title and its subtitle, and the buttons, on the Form's card like System
/// Settings' own notices (a grouped Form on macOS draws no row background set with
/// `listRowBackground`, measured on macOS 27.2); the tile carries the color.
@MainActor @ViewBuilder
private func noticeBanner<Leading: View, Buttons: View>(probe: String = "banner", leading: Leading, title: Text, hint: Text,
                                                        @ViewBuilder buttons: () -> Buttons) -> some View {
    Section {
        HStack(alignment: .center, spacing: 10) {
            leading
            VStack(alignment: .leading, spacing: 2) {
                title
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Subtitle(hint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            buttons()
        }
        .accessibilityElement(children: .contain)
        .layoutProbe(probe)
    }
}

/// Version string for display ("1.0.0"), or nil when the bundle has none: never "?".
enum AppVersion {
    static var marketing: String? {
        guard let v = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
              !v.isEmpty, !v.contains("$(") else { return nil }
        return v
    }

    /// The git commit of this build (Resources/BuildCommit.txt, written by
    /// scripts/build/stamp-build-commit.sh), "+" when built with uncommitted changes; nil when
    /// the build had no git.
    static let commit: String? = {
        guard let url = Bundle.main.url(forResource: "BuildCommit", withExtension: "txt"),
              let c = try? String(contentsOf: url, encoding: .utf8),
              !c.isEmpty, c.count <= 12 else { return nil }
        return c
    }()

    /// "Dấu 1.0.0 (a1b2c3d)", "Dấu 1.0.0" without a commit, or "Dấu" without a version.
    static var nameAndVersion: String {
        guard let marketing else { return "Dấu" }
        return commit.map { "Dấu \(marketing) (\($0))" } ?? "Dấu \(marketing)"
    }
}

// MARK: - Layout probe (tests only)

/// Reports a view's frame in window coordinates, and `.null` when the view disappears.
/// Nil in the app; the onboarding captures (`DebugCapture`, check (f) of
/// scripts/selftest/settings-window) and `scripts/snapshot-settings` (its mockup
/// comparison table) set it.
struct LayoutProbeKey: EnvironmentKey {
    static let defaultValue: (@MainActor @Sendable (String, CGRect) -> Void)? = nil
}

extension EnvironmentValues {
    var layoutProbe: (@MainActor @Sendable (String, CGRect) -> Void)? {
        get { self[LayoutProbeKey.self] }
        set { self[LayoutProbeKey.self] = newValue }
    }
}

/// Always the same view structure, probe or not: a probe that changed the structure
/// (an `if` around the modifier) once made the off-screen captures lay out a sidebar
/// row 8 pt away from the real window. Put probes on a row's content or on a whole
/// control, never outside list-row modifiers (`listRowInsets`, `listRowBackground`).
struct LayoutProbeModifier: ViewModifier {
    @Environment(\.layoutProbe) private var probe
    let name: String

    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frame in
                probe?(name, frame)
            }
            // A view that is gone must not keep reporting its last frame (check (f)).
            .onDisappear { probe?(name, .null) }
    }
}

extension View {
    func layoutProbe(_ name: String) -> some View {
        modifier(LayoutProbeModifier(name: name))
    }
}
