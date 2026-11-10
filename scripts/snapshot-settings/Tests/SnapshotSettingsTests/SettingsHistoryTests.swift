import Testing
@testable import SnapshotSettings

/// Back/Forward of the Settings window (D9, "Vỏ cửa sổ Cài đặt"): the sections shown,
/// browser style. The window and the View menu only call these.
@Suite("Settings history")
struct SettingsHistoryTests {
    @Test("at window open both Back and Forward are off")
    func atOpen() {
        let history = SectionHistory(.typing)
        #expect(history.current == .typing)
        #expect(!history.canGoBack)
        #expect(!history.canGoForward)
    }

    @Test("visiting another section turns Back on")
    func select() {
        var history = SectionHistory(.typing)
        history.select(.smart)
        #expect(history.current == .smart)
        #expect(history.canGoBack)
        #expect(!history.canGoForward)
    }

    @Test("choosing the section already shown adds no step")
    func selectSame() {
        var history = SectionHistory(.typing)
        history.select(.typing)
        #expect(!history.canGoBack)
        history.select(.apps)
        history.select(.apps)
        history.goBack()
        #expect(history.current == .typing)
        #expect(!history.canGoBack)
    }

    @Test("Back and Forward walk the visited sections in order")
    func backAndForward() {
        var history = SectionHistory(.typing)
        history.select(.smart)
        history.select(.apps)
        history.select(.updates)
        history.goBack()
        #expect(history.current == .apps)
        #expect(history.canGoForward)
        history.goBack()
        history.goBack()
        #expect(history.current == .typing)
        #expect(!history.canGoBack)
        history.goForward()
        #expect(history.current == .smart)
        history.goForward()
        history.goForward()
        #expect(history.current == .updates)
        #expect(!history.canGoForward)
        #expect(history.canGoBack)
    }

    @Test("under a sheet Back and Forward are off, whatever the history holds")
    func underSheet() {
        var history = SectionHistory(.typing)
        history.select(.smart)
        history.select(.apps)
        history.goBack()
        #expect(history.canGoBack(sheetShown: false))
        #expect(history.canGoForward(sheetShown: false))
        #expect(!history.canGoBack(sheetShown: true))
        #expect(!history.canGoForward(sheetShown: true))
    }

    @Test("a new choice after Back drops the forward steps")
    func newChoiceClearsForward() {
        var history = SectionHistory(.typing)
        history.select(.smart)
        history.select(.apps)
        history.goBack()
        history.select(.updates)
        #expect(history.current == .updates)
        #expect(!history.canGoForward)
        history.goBack()
        #expect(history.current == .smart)
        history.goBack()
        #expect(history.current == .typing)
    }

    @Test("Back and Forward with nothing to go to change nothing")
    func emptyStacks() {
        var history = SectionHistory(.apps)
        history.goBack()
        history.goForward()
        #expect(history == SectionHistory(.apps))
    }

    @Test("the search's jump to its first match is a step; Back returns to the page before")
    func searchJump() {
        var history = SectionHistory(.typing)
        let visible = SettingsSection.allCases.filter { $0.matches("underline") }
        #expect(visible == [.apps])
        history.showFirstMatch(of: visible)
        #expect(history.current == .apps)
        #expect(history.canGoBack)
        history.goBack()
        #expect(history.current == .typing)
        #expect(history.canGoForward)
    }

    @Test("no jump while the page shown still matches, nor when nothing matches")
    func searchNoJump() {
        var history = SectionHistory(.updates)
        history.showFirstMatch(of: SettingsSection.allCases.filter { $0.matches("") })
        #expect(history == SectionHistory(.updates))
        history.showFirstMatch(of: SettingsSection.allCases.filter { $0.matches("xyzzy") })
        #expect(history == SectionHistory(.updates))
    }
}
