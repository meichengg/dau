import Carbon
import SwiftUI

/// "Bỏ Dấu khỏi nguồn đầu vào": the sheet over the Settings window after "Tiếp tục
/// gỡ" (D16). macOS lets only the user remove an input source, so it lists what is done
/// and what the user does, and waits until Dấu is gone from the list; then Dấu stops the
/// input method and moves it to the Trash (`InputMethodActions.performUninstall`). Built
/// like the add-rule sheet (D9): the sheet's own button bar from the toolbar's
/// cancellation and primary placements, no default button (Return must not cancel or
/// open anything by accident). Names of macOS's own screens come from the system's strings
/// in the user's macOS language (D38, `SystemUINames`).
struct UninstallRemoveSheet: View {
    let actions: InputMethodActions
    @Environment(\.controlActiveState) private var activeState
    /// macOS's own names (D38), in the system's language.
    private var ui: SystemUINames { SystemUINames.system() }

    static let width: CGFloat = 470

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Remove Dấu from Your Input Sources")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Text("Only you can remove an input source from macOS. \(ui.systemSettings) has the \(ui.inputSources) list open for you.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            OnboardingCard(spacing: 10) {
                NumberedLine(number: 1,
                             text: Text("Select **\(ui.dauInputSource)** in the list on the left, click **–**, then **\(ui.done)**."),
                             isCurrent: true)
            }
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                    .accessibilityHidden(true)
                Text("Once Dấu is gone from the list, the input method is moved to \(ui.trash).")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.updatesFrequently)
            // Only while Dấu is the selected input source, which can dim "–": it goes away
            // when the user switches to another keyboard.
            if actions.dauIsSelected {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Hint(Text("You’re using Dấu. If the – button is dimmed, first choose another keyboard from the Input menu."))
                }
                .accessibilityElement(children: .combine)
            }
        }
        .padding(20)
        .frame(width: Self.width, alignment: .leading)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel Uninstall", role: .cancel) { actions.cancelUninstall() }
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Open \(ui.systemSettings)") { actions.showInputSources() }
            }
        }
        // Read again when the sheet appears, when its window becomes key again and whenever
        // the selected input source changes, so the hint follows the user's switch.
        .onAppear { actions.refreshDauIsSelected() }
        .onChange(of: activeState) { _, state in
            if state == .key { actions.refreshDauIsSelected() }
        }
        .onReceive(DistributedNotificationCenter.default().publisher(
            for: Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String))) { _ in
            // The notification can come before this process's input source state has
            // changed: read now and again shortly after; the wait's poll covers the rest.
            actions.refreshDauIsSelected()
            Task {
                try? await Task.sleep(for: .milliseconds(300))
                actions.refreshDauIsSelected()
            }
        }
    }
}
