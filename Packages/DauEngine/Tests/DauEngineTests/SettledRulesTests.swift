import Testing
import DauEngine

/// Group 8 — rules settled on 05/11/2026 from the comparison with other input
/// methods' test inputs (docs/research/EXTERNAL-TEST-INPUTS.md section 9, classes D
/// and E). Expected values follow Vietnamese orthography and DECISIONS.md, never
/// another input method's output (D10).
@Suite("8. Luật chốt 05/11/2026")
struct SettledRulesTests {
    /// D23, D31: in Telex a lone w after the initial "gi" is ư (gi + ư is a valid
    /// syllable: giữ, giữa), like "tw" → "tư".
    @Test(arguments: [
        Case("giw", "giư"), Case("Giw", "Giư"), Case("GIW", "GIƯ"),
        Case("giwax", "giữa"), Case("giwx ", "giữ "), Case("giwa ", "giưa "),
        Case("giww", "giw"), Case("giww ", "giw "),   // D26: ww → w, the word stays locked
        Case("giuwx", "giữ"), Case("giuwax", "giữa"),
    ])
    func wAfterGi(_ c: Case) { expectTyped(c.keys, c.expected) }

    /// D29: Telex đơn giản keeps w as a letter when the word has no a, o, u, so "gi" + w
    /// stays "giw"; with a u in the word the horn still applies.
    @Test(arguments: [
        Case("giw", "giw"), Case("giw ", "giw "),
        Case("giuwx", "giữ"), Case("giuwax", "giữa"),
    ])
    func wAfterGiSimpleTelex(_ c: Case) { expectTyped(c.keys, c.expected, simpleTelex) }

    /// D26: a second w on "ưa" removes the horn like on every other vowel and keeps
    /// the letter w; the word is locked, so a later z is a letter and the tone already
    /// typed stays (on u, where "ua" puts it: "của").
    @Test(arguments: [
        Case("huaww", "huaw"), Case("chuaww ", "chuaw "), Case("muaww", "muaw"),
        Case("muaww ", "muaw "), Case("chuawrwz", "chủawz"), Case("chuawrwz ", "chủawz "),
        // A lone-w ư has no horn to remove (D23): with a vowel after it the second w
        // stays a letter and the word is restored at the boundary (D4).
        Case("waw", "ưaw"), Case("waw ", "waw "), Case("Warwick ", "Warwick "),
        Case("waxwing ", "waxwing "), Case("wraw ", "wraw "),
        Case("aww", "aw"), Case("tuongww", "tuongw"), Case("ww", "w"),
    ])
    func secondWOnHornedUA(_ c: Case) { expectTyped(c.keys, c.expected) }

    @Test(arguments: [
        Case("huaww", "huaw"), Case("chuawrwz", "chủawz"), Case("chuawrwz ", "chủawz "),
    ])
    func secondWOnHornedUASimpleTelex(_ c: Case) { expectTyped(c.keys, c.expected, simpleTelex) }

    /// D35: Telex "uwo" is the u-o pair with a horn, like "uow": "uơ" while the pair
    /// ends the word, "ươ" once a letter follows. A w typed after it adds the horn on u
    /// (the D35 example "nguwowif" → "người"), not a double.
    @Test(arguments: [
        Case("uwo", "uơ"), Case("uwo ", "uơ "), Case("huwo ", "huơ "), Case("nguwo", "nguơ"),
        Case("buwo", "buơ"), Case("buwo ", "buơ "), Case("thuwor", "thuở"),
        Case("thuwor ", "thuở "), Case("THUWOR", "THUỞ"),
        Case("nguwoif", "người"), Case("nguwowif", "người"), Case("uwon", "ươn"),
        Case("huwou", "hươu"), Case("nguwow", "ngươ"),
        // A lone-w ư is not a typed u: no u-o pair (English "two", "wood").
        Case("two ", "two "), Case("wood ", "wood "), Case("wo ", "wo "),
    ])
    func uwoPair(_ c: Case) { expectTyped(c.keys, c.expected) }

    /// D35 "Thứ tự u + móc + o": VNI "u7o" follows the same rule as Telex "uwo"; a
    /// further 7 on that pair adds the horn on u, it does not undo (D26).
    /// "thu7o73": the second 7 gives "ươ" (D35), the tone sits on ơ ("thưở" mid-word);
    /// an open "ươ" is not a syllable (D31), so the word end restores the keys (D4).
    @Test(arguments: [
        Case("u7o", "uơ"), Case("u7o ", "uơ "), Case("hu7o ", "huơ "), Case("thu7o3", "thuở"),
        Case("thu7o3 ", "thuở "), Case("ngu7o2i", "người"), Case("ngu7o72i", "người"),
        Case("hu7o7ng ", "hương "), Case("mu7o7n ", "mươn "), Case("u7on ", "ươn "),
        Case("u7o7ng", "ương"), Case("thu7o73", "thưở"), Case("thu7o73 ", "thu7o73 "),
        Case("uo77", "uo7"),   // D26: 7 again on a pair hooked by "uo7" undoes it
        Case("thuwowr ", "thuwowr "),
    ])
    func u7oPairVNI(_ c: Case) {
        // Telex comparison case mixed in: route by the keys.
        let telex = c.keys.contains("w")
        expectTyped(c.keys, c.expected, telex ? EngineOptions() : vni)
    }

    /// D31: the rhyme table has "oao" (ngoao, ngoáo) and "uêu" (nguều).
    @Test(arguments: [
        Case("ngoaos", "ngoáo"), Case("ngoaos ", "ngoáo "), Case("ngoafo ", "ngoào "),
        Case("ngoao ", "ngoao "),
        Case("ngueeuf", "nguều"), Case("ngueeuf ", "nguều "), Case("ngueue", "nguêu"),
    ])
    func newRhymes(_ c: Case) { expectTyped(c.keys, c.expected) }

    /// D28 "Phím biến đổi khác loại": a modifier key of another kind replaces the
    /// diacritic already there, also on the two-vowel cluster ươ (+ o → uô).
    @Test(arguments: [
        Case("cuoiwo", "cuôi"), Case("cuoiwo ", "cuôi "), Case("nguoiwo", "nguôi"),
        Case("buwoo", "buô"), Case("thuongwo", "thuông"),
        Case("aaw", "ă"), Case("owo", "ô"), Case("awa", "â"), Case("oow", "ơ"),
        Case("cuooiw", "cươi"),   // the other way: horn replaces the circumflex on uô
    ])
    func otherKindModifier(_ c: Case) { expectTyped(c.keys, c.expected) }

    @Test(arguments: [
        Case("buong76", "buông"), Case("cuoi76", "cuôi"), Case("buong67", "bương"),
    ])
    func otherKindModifierVNI(_ c: Case) { expectTyped(c.keys, c.expected, vni) }

    /// D31 "Bổ sung": a tone key right after "qu" is taken like after "gi" and moves to
    /// the vowel that follows ("qusa" → "quá"); "qui" stays invalid.
    @Test(arguments: [
        Case("qusa", "quá"), Case("qusa ", "quá "), Case("Qusa", "Quá"), Case("qury ", "quỷ "),
        Case("qujy", "quỵ"), Case("qus ", "qus "),   // "qú" alone is not a syllable (D4)
        Case("quas", "quá"),
        Case("quis ", "quis "), Case("qui ", "qui "), Case("quits ", "quits "),
        Case("quips ", "quips "),
    ])
    func toneAfterQu(_ c: Case) { expectTyped(c.keys, c.expected) }

    @Test func toneAfterQuOtherOptions() {
        expectTyped("qusa", "quá", noFreeMarking)   // right after the vowel u
        expectTyped("qusa", "quá", simpleTelex)
        expectTyped("qu1a", "quá", vni)
        expectTyped("qusa", "quá", classic)
    }

    /// Cross-checks that must stay as they are (D4, D26, D30 "Dấu thanh trên vần tắc",
    /// D31, D20).
    @Test(arguments: [
        Case("hocfj", "học"), Case("matfs", "mát"), Case("cafts", "cát"),
        Case("metric ", "metric "), Case("quits ", "quits "), Case("quips ", "quips "),
        Case("wood ", "wood "), Case("two ", "two "), Case("carr ", "car "),
        Case("xooongf", "xoòng"), Case("buyts ", "buýt "),
        Case("car ", "cả "), Case("sex ", "sẽ "), Case("has ", "há "), Case("as ", "á "),
        Case("test ", "tét "), Case("tesst ", "test "), Case("catr ", "catr "),
        Case("hoc ", "hoc "), Case("gias", "giá"), Case("giuwax", "giữa"),
    ])
    func crossChecks(_ c: Case) { expectTyped(c.keys, c.expected) }

    /// D21 × D4 with the new rules: shortcuts still apply only when the result is valid.
    @Test(arguments: [
        Case("fan ", "phan "), Case("big ", "big "), Case("bag ", "bang "), Case("wa ", "ưa "),
        Case("giw ", "giư "), Case("jw ", "giư "),
    ])
    func crossChecksShortcuts(_ c: Case) { expectTyped(c.keys, c.expected, shortcuts) }

    /// D20: the first key after a seed reads the text shown as letters, with the same
    /// rules.
    @Test(arguments: [
        SeedTests.SeedCase("gi", "w", "giư"),
        SeedTests.SeedCase("hưa", "w", "huaw"),
        SeedTests.SeedCase("cươi", "o", "cuôi"),
        SeedTests.SeedCase("ngoao", "s", "ngoáo"),
        SeedTests.SeedCase("nguêu", "f", "nguều"),
        SeedTests.SeedCase("huơ", "w", "huow"),      // D26: a double on a read word undoes
        SeedTests.SeedCase("cả", "r", "car"),
    ])
    func seeded(_ c: SeedTests.SeedCase) {
        var t = Typist()
        do { let result = t.seed(c.displayed); #expect(result) }
        t.type(c.keys)
        #expect(t.text.map(\.value) == scalars(c.expected), "got \"\(t.string)\"")
    }
}

/// D32 × D31: ⌫ re-places the tone on the rhyme that is left; a bare "qu" has none,
/// so the tone goes ("qú" from "qus" is only a mid-word step).
@Suite("8b. Backspace sau qu")
struct BackspaceAfterQuTests {
    @Test(arguments: [
        Case("quas⌫", "qu"), Case("quas⌫ ", "qu "), Case("qusa⌫", "qu"),
        Case("quas⌫a", "qua"), Case("gias⌫", "gí"), Case("qus⌫", "q"),
    ])
    func backspace(_ c: Case) { expectTyped(c.keys, c.expected) }
}

/// D28 × D23: only the cluster ươ loses the horn on u when o takes a circumflex; a
/// lone-w "ư" followed by a plain o is not that cluster ("ưô" is no syllable), so the
/// key is a letter (then D35 hooks the pair before it) and the word is restored at
/// the boundary (D4).
@Suite("8c. ươ + o chỉ trên cụm ươ")
struct HatOnHornedClusterTests {
    @Test(arguments: [
        Case("woo", "ươo"), Case("woo ", "woo "), Case("ngwoo", "ngươo"), Case("chwoon ", "chwoon "),
        Case("twon ", "tươn "), Case("twono", "tuôn"),   // ươ (D35) + o → uô (D28)
    ])
    func loneWThenO(_ c: Case) { expectTyped(c.keys, c.expected) }

    @Test(arguments: [Case("u7o6", "uô"), Case("u7on6", "uôn")])   // D35 uơ, then D28
    func loneHornVNI(_ c: Case) { expectTyped(c.keys, c.expected, vni) }
}
