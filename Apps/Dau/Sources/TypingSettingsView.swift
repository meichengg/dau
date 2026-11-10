import SwiftUI
import DauShared

/// "Gõ phím" (mockup "SettingsTyping"): preview, typing method, tone placement, free
/// marking, and the system shortcut that switches input sources, e.g. Dấu ↔ U.S. (D2).
struct TypingSettingsView: View {
    @Environment(SettingsModel.self) private var model
    var shortcut: InputSourceShortcut? = InputSourceShortcut.current()

    var body: some View {
        @Bindable var model = model
        SettingsPage {
            Section {
                PreviewCard(settings: model.settings)
            }

            Section(header: Text("Typing method")) {
                // No row label: the section title names it (mockup). System Settings
                // spans such a segmented control across the row (Sound, Output/Input).
                Picker("Typing method", selection: $model.settings.typingMethod) {
                    ForEach(DauSettings.TypingMethod.allCases, id: \.self) { method in
                        Text(verbatim: method.title).tag(method)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .modifier(FlexibleSegments())
                .layoutProbe("segmented")
                Picker(selection: $model.settings.tonePlacement) {
                    ForEach(DauSettings.TonePlacement.allCases, id: \.self) { placement in
                        Text(verbatim: placement.title).tag(placement)
                    }
                } label: {
                    Text("Tone mark placement")
                    Text("Modern: hoà, thuý · Classic: hòa, thúy")
                }
                .pickerStyle(.segmented)
                Toggle(isOn: $model.settings.freeMarking) {
                    Text("Free mark placement")
                    Text("Type mark keys anywhere after the vowel")
                }
            }

            Section(header: Text("Switch Vietnamese ↔ English")) {
                LabeledContent {
                    HStack(spacing: 8) {
                        ShortcutKeycaps(shortcut: shortcut)
                        Button("Change…") { SystemSettings.openKeyboard() }
                            .layoutProbe("button")
                            .accessibilityHint(Text("Open \(SystemUINames.system().systemSettings)"))
                    }
                } label: {
                    Text("Input source shortcut")
                    Text("Uses the macOS shortcut; change it in \(SystemUINames.system().keyboardPath)")
                }
            }
        }
    }
}

/// Segments of equal width across the row (macOS 26+: flexible button sizing); the
/// system's intrinsic width on macOS 14–15.
struct FlexibleSegments: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26, *) {
            content.buttonSizing(.flexible)
        } else {
            content
        }
    }
}

/// The "Xem trước" row: chips for the configuration, then keys › result computed by
/// the engine with the current settings, in two boxes set into the card. Custom
/// content of the mockup; the Form draws the card around it.
struct PreviewCard: View {
    let settings: DauSettings

    var body: some View {
        let example = SettingsSamples.preview(settings)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text("Preview")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.isHeader)
                Chip(Text(settings.typingMethod.title))
                Chip(Text(settings.tonePlacement.title))
            }
            HStack(spacing: 10) {
                // The keys box takes the width of its text, the result box the rest:
                // two equal boxes cut the keys at the 740 pt window.
                PreviewBox(fills: false) {
                    Text(verbatim: example.keys)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                    .accessibilityHidden(true)
                PreviewBox {
                    Text(verbatim: example.result)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("\(example.keys) becomes \(example.result)"))
        }
        .layoutProbe("firstRow")
    }
}

/// One of the two boxes of the preview: height 40, a system fill so it reads as set
/// into the card. `fills`: takes the room left in the row; otherwise as wide as its
/// content.
struct PreviewBox<Content: View>: View {
    var fills = true
    @ViewBuilder var content: Content

    var body: some View {
        content
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 12)
            .frame(maxWidth: fills ? .infinity : nil, minHeight: 40, maxHeight: 40, alignment: .leading)
            .fixedSize(horizontal: !fills, vertical: false)
            .background(.fill.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

/// The input-source shortcut as keycaps, or the placeholder when it cannot be read.
/// `inSentence`: drawn inside running text (onboarding, `ShortcutSentence`), so "hoặc"
/// takes the sentence's font and color instead of the Settings row's value style.
struct ShortcutKeycaps: View {
    let shortcut: InputSourceShortcut?
    var size: Keycap.Size = .regular
    var inSentence = false

    var body: some View {
        if let shortcut, !shortcut.isEmpty {
            HStack(spacing: size.spacing) {
                ForEach(Array(shortcut.keys.enumerated()), id: \.offset) { _, key in
                    cap(key)
                }
                if shortcut.globeKey {
                    if !shortcut.keys.isEmpty {
                        if inSentence {
                            Text("or")
                                .padding(.horizontal, 1)
                        } else {
                            // System Settings' value text: 13 pt, secondary.
                            Text("or")
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 2)
                        }
                    }
                    cap("🌐")
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Current shortcut"))
            .accessibilityAddTraits(.isStaticText)
            .accessibilityValue(Text(verbatim: spokenValue(shortcut)))
        } else {
            // Not readable: keep the placeholder rather than guess (N5).
            // System Settings' value text: 13 pt, secondary.
            Text("[System shortcut]")
                .foregroundStyle(.secondary)
        }
    }

    /// In a sentence the caps keep the primary color, also inside a secondary hint
    /// (artboard OnboardingNotSelected).
    @ViewBuilder private func cap(_ key: String) -> some View {
        if inSentence {
            Keycap(key, size: size).foregroundStyle(.primary)
        } else {
            Keycap(key, size: size)
        }
    }

    private func spokenValue(_ shortcut: InputSourceShortcut) -> String {
        var parts = [shortcut.keys.joined(separator: " ")]
        if shortcut.globeKey { parts.append("🌐") }
        return parts.filter { !$0.isEmpty }.joined(separator: ", ")
    }
}

/// A key cap: radius 6, height 24, 12 pt text; system fill and separator. Mockup
/// content (System Settings shows shortcuts as text, not keycaps): kept as drawn in
/// the mockup, see the header of Components.swift. `.small` is the artboards' keycap
/// inside a 12 pt hint (OnboardingNotSelected): radius 4, height 18, 11 pt text.
struct Keycap: View {
    enum Size {
        case regular, small

        var height: CGFloat { self == .regular ? 24 : 18 }
        var fontSize: CGFloat { self == .regular ? 12 : 11 }
        var padding: CGFloat { self == .regular ? 6 : 4 }
        var radius: CGFloat { self == .regular ? 6 : 4 }
        /// Between the caps of one shortcut.
        var spacing: CGFloat { self == .regular ? 4 : 3 }
    }

    let key: String
    var size: Size = .regular
    init(_ key: String, size: Size = .regular) {
        self.key = key
        self.size = size
    }

    var body: some View {
        Text(verbatim: key)
            .font(.system(size: size.fontSize))
            .padding(.horizontal, size.padding)
            .frame(minWidth: size.height, minHeight: size.height, maxHeight: size.height)
            .background(.fill, in: RoundedRectangle(cornerRadius: size.radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: size.radius, style: .continuous)
                    .strokeBorder(.separator, lineWidth: 1)
            }
    }
}

extension DauSettings.TypingMethod {
    var title: String {
        switch self {
        case .telex: String(localized: "Telex")
        case .vni: String(localized: "VNI")
        case .simpleTelex: String(localized: "Simple Telex")
        }
    }
}

extension DauSettings.TonePlacement {
    var title: String {
        switch self {
        case .modern: String(localized: "Modern")
        case .classic: String(localized: "Classic")
        }
    }
}
