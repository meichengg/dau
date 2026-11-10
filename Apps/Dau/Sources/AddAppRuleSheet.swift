import AppKit
import SwiftUI
import UniformTypeIdentifiers
import DauShared

/// "Thêm quy tắc cho ứng dụng" sheet (mockup "SettingsAppsAdd" for the content: title,
/// search, the apps without a stored rule (apps of the compatibility list carry the
/// "Đề xuất" chip), "Khi đang gõ" (the rule's only setting, D5), Huỷ / Thêm).
///
/// Built from system parts as System Settings builds its sheets (D9; measured on macOS
/// 27.2, Displays › Advanced… and Keyboard › Input Sources › Edit…): a header row
/// (title left, the system search field right), the app list in a `GroupBox` card, the
/// "Khi đang gõ" card of a grouped `Form` (cards 20 pt from the sheet's edges, 10 pt
/// apart) and the sheet's own button bar under a divider, from the toolbar's
/// cancellation and confirmation placements (64 × 24 buttons, 20 pt from the right and
/// bottom edges). The list is outside the Form because a `List` nested in a grouped
/// Form cannot scroll. `searchable` would put the field in a toolbar band of its own,
/// apart from the title (and a sheet shows no toolbar title), so the header row holds
/// an `NSSearchField` instead. "Chọn ứng dụng khác…" (an automatic toolbar item, at the
/// leading end of the button bar) opens the system open panel for apps stored elsewhere.
struct AddAppRuleSheet: View {
    @Environment(SettingsModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var query = ""
    @State private var candidates: [AppCandidate] = []
    @State private var selection: AppCandidate.ID?
    @State private var underline = false

    /// System Settings' grouped-Form sheet (Displays › Advanced…) is 470 wide.
    static let width: CGFloat = 470
    /// Height of the app list: the mockup's list card.
    static let listHeight: CGFloat = 188
    /// The sheet's margin, and the search field's size, as `searchable` has it in a sheet.
    static let margin: CGFloat = 20
    static let headerToCard: CGFloat = 10
    static let cardGap: CGFloat = 10
    static let searchWidth: CGFloat = 183
    static let searchHeight: CGFloat = 24

    private var visibleCandidates: [AppCandidate] {
        AppCandidate.matching(candidates, query: query)
    }

    /// The selection while it is on screen: "Thêm" and Return add only a visible app.
    private var visibleSelection: AppCandidate.ID? {
        AppCandidate.selection(selection, among: visibleCandidates)
    }

    var body: some View {
        VStack(spacing: 0) {
            // One header row, title left and the system search field right.
            HStack {
                Text("Add App Rule")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                SheetSearchField(text: $query, prompt: String(localized: "Search Applications"))
                    .frame(width: Self.searchWidth, height: Self.searchHeight)
            }
            .padding([.horizontal, .top], Self.margin)
            // Outside the Form: a List nested in a grouped Form has its scrolling
            // switched off, so the list sits in its own card and scrolls there.
            GroupBox {
                List(visibleCandidates, selection: $selection) { candidate in
                    row(candidate)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .accessibilityLabel(Text("Apps"))
            }
            .frame(height: Self.listHeight)
            .padding(.horizontal, Self.margin)
            .padding(.top, Self.headerToCard)
            Form {
                Section {
                    Picker("While typing", selection: $underline) {
                        Text("No Underline").tag(false)
                        Text("Underline").tag(true)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            // The grouped Form starts its card 20 below its top (SwiftUI's default);
            // pull it up so the two cards are `cardGap` apart. If macOS changes that
            // margin, ax-check's "list card → Khi đang gõ card" fails.
            .contentMargins(.top, Self.cardGap - 20, for: .scrollContent)
            .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width: Self.width)
        // A query that hides the selected app clears the selection.
        .onChange(of: query) { selection = visibleSelection }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("Choose Another App…", action: chooseApp)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add", action: add)
                    .keyboardShortcut(.defaultAction)
                    .disabled(visibleSelection == nil)
            }
        }
        .task { await loadApps() }
    }

    private func row(_ candidate: AppCandidate) -> some View {
        HStack {
            // System Settings' app list rows (Privacy & Security › Accessibility): a
            // 24 pt icon (`AppIcon.singleLine`).
            Image(nsImage: candidate.icon)
                .resizable()
                .frame(width: AppIcon.singleLine, height: AppIcon.singleLine)
                .accessibilityHidden(true)
            Text(verbatim: candidate.name)
                .lineLimit(1)
            if candidate.suggested {
                Chip(Text("Suggested"), height: 20, fontSize: 11)
            }
        }
        .tag(candidate.id)
    }

    /// Apps in the Applications folders plus running apps, without the ones that
    /// already have a stored rule and without Dấu itself.
    private func loadApps() async {
        let ruled = Set(model.settings.appRules.map(\.bundleID))
        let list = model.compatibility
        let own = Bundle.main.bundleIdentifier
        var running: [AppListing] = []
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            if let id = app.bundleIdentifier, let url = app.bundleURL {
                running.append(AppListing(bundleID: id, name: AppDirectory.name(at: url), path: url.path))
            }
        }
        let installed = await Task.detached(priority: .userInitiated) { AppListing.installed() }.value
        var seen = Set<String>()
        candidates = (installed + running)
            .filter { $0.bundleID != own && !ruled.contains($0.bundleID) && seen.insert($0.bundleID).inserted }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { AppCandidate(bundleID: $0.bundleID, name: $0.name,
                                icon: NSWorkspace.shared.icon(forFile: $0.path),
                                suggested: list.suggestion(for: $0.bundleID) != nil) }
    }

    /// Picks any app with the system open panel; only the bundle ID is kept.
    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.prompt = String(localized: "Choose")
        panel.message = String(localized: "Choose an app that needs its own rule")
        guard panel.runModal() == .OK, let url = panel.url,
              let id = Bundle(url: url)?.bundleIdentifier else { return }
        if !candidates.contains(where: { $0.bundleID == id }) {
            candidates.insert(
                AppCandidate(bundleID: id, name: AppDirectory.name(at: url),
                             icon: NSWorkspace.shared.icon(forFile: url.path),
                             suggested: model.compatibility.suggestion(for: id) != nil),
                at: 0)
        }
        query = ""
        selection = id
    }

    /// Stores the rule. An app of the compatibility list keeps its "Đề xuất" chip in
    /// "Quy tắc riêng" (source `.suggested`), as when it is accepted from "Đề xuất".
    private func add() {
        guard let id = visibleSelection, let candidate = candidates.first(where: { $0.id == id }) else { return }
        model.settings.upsert(AppRule(
            bundleID: candidate.bundleID, displayName: candidate.name,
            underline: underline, source: candidate.suggested ? .suggested : .user))
        dismiss()
    }
}

struct AppCandidate: Identifiable {
    let bundleID: String
    let name: String
    let icon: NSImage
    /// In the compatibility list: shown with the "Đề xuất" chip.
    var suggested = false
    var id: String { bundleID }

    /// The candidates whose name or bundle ID contains `query`, ignoring case and
    /// diacritics (`searchContains`); all of them for an empty query.
    static func matching(_ candidates: [AppCandidate], query: String) -> [AppCandidate] {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return candidates }
        return candidates.filter { $0.name.searchContains(query) || $0.bundleID.searchContains(query) }
    }

    /// `selection` if it is among `visible`, else nil: a selected app hidden by the
    /// search is no longer selected, so "Thêm" turns off.
    static func selection(_ selection: ID?, among visible: [AppCandidate]) -> ID? {
        guard let selection, visible.contains(where: { $0.id == selection }) else { return nil }
        return selection
    }
}

/// An app found on disk (Sendable, built off the main thread).
struct AppListing: Sendable {
    let bundleID: String
    let name: String
    let path: String

    static let folders = ["/Applications", "/Applications/Utilities",
                          "/System/Applications", "/System/Applications/Utilities"]

    /// Apps in the standard Applications folders. Folders that cannot be read are
    /// skipped; running apps and the open panel cover the rest.
    static func installed() -> [AppListing] {
        let fm = FileManager.default
        var result: [AppListing] = []
        for folder in folders {
            guard let names = try? fm.contentsOfDirectory(atPath: folder) else { continue }
            for name in names where name.hasSuffix(".app") {
                let url = URL(fileURLWithPath: folder).appendingPathComponent(name)
                guard let id = Bundle(url: url)?.bundleIdentifier else { continue }
                result.append(AppListing(bundleID: id, name: AppDirectory.name(at: url), path: url.path))
            }
        }
        return result
    }
}

/// The system search field (`NSSearchField`), the one `searchable` shows, placed in the
/// sheet's header row: `searchable` itself puts it in a toolbar band of its own, apart
/// from the title. Focused when the sheet opens, as `searchable` does.
struct SheetSearchField: NSViewRepresentable {
    @Binding var text: String
    let prompt: String

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    func makeNSView(context: Context) -> NSSearchField {
        let field = NSSearchField()
        field.placeholderString = prompt
        field.delegate = context.coordinator
        field.setAccessibilityLabel(prompt)
        DispatchQueue.main.async { field.window?.makeFirstResponder(field) }
        return field
    }

    func updateNSView(_ field: NSSearchField, context: Context) {
        if field.stringValue != text { field.stringValue = text }
    }

    final class Coordinator: NSObject, NSSearchFieldDelegate {
        var text: Binding<String>
        init(text: Binding<String>) { self.text = text }

        func controlTextDidChange(_ notification: Notification) {
            guard let field = notification.object as? NSSearchField else { return }
            text.wrappedValue = field.stringValue
        }
    }
}
