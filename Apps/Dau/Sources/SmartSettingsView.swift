import SwiftUI
import DauShared

/// "Thông minh" (mockups "SettingsSmart", "SettingsSmartAdvanced"): automatic restore
/// of foreign words (D4), adding marks to a typed word (D20), and the collapsed
/// "Nâng cao" group (D21, D22, D23).
struct SmartSettingsView: View {
    @Environment(SettingsModel.self) private var model
    @Environment(\.smartAdvancedExpanded) private var expandedAtStart
    @State private var advancedExpanded = false

    var body: some View {
        @Bindable var model = model
        let method = model.settings.typingMethod
        SettingsPage {
            Section(header: Text("Foreign words")) {
                Toggle(isOn: $model.settings.autoRestore) {
                    Text("Restore non-Vietnamese words")
                    Text("When you finish a word (Space, punctuation, Return), a word that isn’t Vietnamese stays as you typed it")
                }
                .layoutProbe("firstRow")
                VStack(alignment: .leading, spacing: 8) {
                    WrappingHStack {
                        ForEach(SettingsSamples.restore(method)) { ExampleChips(example: $0) }
                    }
                    let wins = SettingsSamples.vietnameseWins(method)
                    let keep = SettingsSamples.keepOriginal(method)
                    Subtitle(Text("A word that is also Vietnamese stays Vietnamese: “\(wins.keys)” gives “\(wins.result)”. To keep the letters you typed, press the mark key twice: “\(keep.keys)” gives “\(keep.result)”."))
                }
            }

            Section(header: Text("Editing typed words")) {
                Toggle(isOn: $model.settings.addMarksToTypedWords) {
                    HStack(spacing: 6) {
                        Text("Add marks to typed words")
                        NewBadge()
                    }
                    // D20 scope (30/10/2026): only the text right before the cursor,
                    // never in apps with a "Có gạch chân" rule. N5: stability on web
                    // editors is an open question in DECISIONS.md; the placeholder
                    // stays until it is measured.
                    Text("Put the cursor right after a word, then type a mark key. Not available in apps with an “Underline” rule. [Test results on Google Docs, Notion…]")
                }
                WrappingHStack {
                    ExampleChips(example: SettingsSamples.addMarks(method))
                }
            }

            Section {
                // D9: a system button with a chevron, accepted for "Nâng cao" (the
                // disclosure group indents the options).
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) { advancedExpanded.toggle() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(advancedExpanded ? 90 : 0))
                        Text("Advanced")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(advancedSummary(model.settings.advanced))
                            .foregroundStyle(.secondary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Advanced"))
                .accessibilityValue(Text(advancedSummary(model.settings.advanced)))
                .accessibilityHint(advancedExpanded ? Text("Collapse") : Text("Expand"))

                if advancedExpanded {
                    AdvancedOptions(settings: $model.settings)
                }
            }
        }
        .onAppear { if expandedAtStart { advancedExpanded = true } }
    }

    private func advancedSummary(_ advanced: DauSettings.Advanced) -> String {
        advanced == .off
            ? String(localized: "2 options, both off")
            : String(localized: "2 options, 1 on")
    }
}

/// The two mutually exclusive advanced switches (D22).
struct AdvancedOptions: View {
    @Binding var settings: DauSettings

    var body: some View {
        Toggle(isOn: $settings.consonantShortcuts) {
            Text("Consonant shortcuts")
            Text(shortcutsHint)
        }
        Toggle(isOn: $settings.allowZFWJ) {
            Text("Allow consonants z, f, w, j")
            Text(zfwjHint)
        }
    }

    private var shortcutsHint: String {
        // D21; w → qu exists only in VNI (D23). D22: say that this turns the other off.
        String(localized: "Word start: f → ph, j → gi (VNI also w → qu) · Word end: g → ng, h → nh, k → ch. Applied when you finish a word, only if the result is a valid Vietnamese word. Turning this on turns off Allow consonants z, f, w, j.")
    }

    private var zfwjHint: String {
        // D22, D23: in Telex a leading w is always ư, noted only while Telex is used.
        settings.typingMethod == .telex
            ? String(localized: "For loanwords and names. Turning this on turns off Consonant shortcuts. In Telex, w at the start of a word always becomes ư, so this only affects z, f, j.")
            : String(localized: "For loanwords and names. Turning this on turns off Consonant shortcuts.")
    }
}

extension EnvironmentValues {
    /// Opens "Nâng cao" when the page appears (snapshots of the expanded state).
    @Entry var smartAdvancedExpanded = false
}
