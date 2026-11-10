import AppKit
import SwiftUI

/// "Cập nhật & hỗ trợ" (mockup "SettingsAbout"). Updates (Sparkle, D7) and the report
/// and roll-back actions (D8, D19) arrive in M7, so their controls are disabled and
/// promise nothing yet (N5). No network access until then. "Gỡ cài đặt…" (D16) works:
/// `InputMethodActions.confirmUninstall`. "Ngôn ngữ" (D41): `LanguageRow`.
struct UpdatesSupportView: View {
    @Environment(\.inputMethodActions) private var actions

    var body: some View {
        SettingsPage {
            Section {
                HStack(spacing: 12) {
                    // System Settings' pane header card (Notifications, Siri: icon,
                    // title, description) shows its icon 26 pt; Dấu's app icon fills
                    // about 80% of its frame, so 32 draws it at that size.
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: AppIcon.twoLine, height: AppIcon.twoLine)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: AppVersion.nameAndVersion)
                            .font(.headline)
                        // TODO(M7): one of the six update states from docs/UI.md.
                        Subtitle(Text("[Update check status]"))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    // TODO(M7): Sparkle check.
                    Button("Check Now") {}
                        .disabled(true)
                }
                .layoutProbe("firstRow")
            }

            // A card of its own right under the version card, no header (D41).
            Section {
                LanguageRow()
            }

            // TODO(M7): bind to Sparkle (D7).
            Section(header: Text("Updates")) {
                Toggle("Automatically check for updates", isOn: .constant(false))
                Toggle(isOn: .constant(false)) {
                    Text("Automatically download and install")
                    Text("[How updates install — to be verified in M7]")
                }
                Picker("Release channel", selection: .constant(0)) {
                    Text("Stable").tag(0)
                    Text("Beta").tag(1)
                }
                .pickerStyle(.segmented)
            }
            .disabled(true)

            Section {
                LabeledContent {
                    // TODO(M7): report sheet with a pre-filled GitHub issue (D8).
                    Button("Report a Problem…") {}
                } label: {
                    Text("Problems typing in an app?")
                    Text("Send us a description so we can look into it")
                }
                .disabled(true)
                LabeledContent {
                    // TODO(M7): roll back with confirmation (D16, D19), with Sparkle.
                    Button("Roll Back…") {}
                } label: {
                    Text("Go back to the previous version")
                    Text("Use this when a new version causes problems")
                }
                .disabled(true)
                LabeledContent("Remove Dấu from this Mac") {
                    // The system's destructive button, enabled and disabled look
                    // included (D9). macOS 27.2 draws it as a plain push button, text
                    // not red (measured 02/11/2026); docs/UI.md follows the system.
                    Button("Uninstall…", role: .destructive) {
                        actions?.confirmUninstall(in: NSApp.keyWindow)
                    }
                    .disabled(actions == nil || actions?.isUninstalling == true)
                }
            } header: {
                Text("Support")
            } footer: {
                // Wording fixed by docs/UI.md (D8, N2). The page's closing note, after
                // the last card (a footer, not a section description).
                Subtitle(Text("Dấu never sends what you type off your Mac. The input method has no network access; only the updater connects, to download new versions and the app compatibility list. Open source under the GPLv3 license."))
            }
        }
    }
}
