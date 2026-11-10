import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Sink, BRACKETS

ROOT = sys.argv[1]  # clone of manhavn/ibus-telex
s = Sink("ibus-telex")

TOK = {"space": "␣", "SPACE": "␣", "BACK": "⌫", "RET": "⏎", "TAB": "⇥",
       "LEFT": "←", "RIGHT": "←", "UP": "←", "DOWN": "←", "HOME": "←", "END": "←",
       "PGUP": "←", "PGDN": "←", "ESC": "⎋"}

ref = "tests/parity_corpus.tsv"
for ln, line in enumerate(open(os.path.join(ROOT, ref), encoding="utf-8").read().split("\n"), 1):
    if not line or line.startswith("#"):
        continue
    keys_s, expected = line.split("\t", 1)
    out = []
    for t in keys_s.split(" "):
        if t in TOK:
            out.append(TOK[t])
        elif len(t) == 2 and t[0] == "S":
            out.append(t[1].upper())
        elif len(t) == 1:
            out.append(t)
        else:
            raise SystemExit(f"unknown token {t!r} line {ln}")
    keys = "".join(out)
    if any(c in BRACKETS for c in keys):
        s.skip("D27: [ ] { } as ơ ư (Unikey Telex)")
        continue
    s.add(f"parity_corpus.tsv:{ln}", "telex", "tone=classic", keys + "␣", ref, expected,
          "captured from ibus-unikey 0.7.0; harness types a final Space and drops one trailing space from the result")

T = "tests/typing.rs"
def add(fn, i, method, opts, keys, exp, note=""):
    s.add(f"typing.rs:{fn}#{i}", method, opts, keys.replace(" ", "␣"), T, exp, note)

C = "tone=classic"
pairs = {
    "telex_words": [("tieengs", "tiếng"), ("Tieengs", "Tiếng"), ("VIEETJ", "VIỆT"), ("nuowcs", "nước"), ("dduowngf", "đường")],
    "tone_placement_old_and_modern:default": [("hoas", "hóa"), ("thuys", "thúy"), ("tuowngs", "tướng"), ("tieengs", "tiếng"), ("quas", "quá"), ("gias", "giá")],
    "tone_placement_old_and_modern:modern": [("hoaf", "hoà"), ("hoas", "hoá"), ("thuys", "thuý"), ("thuyr", "thuỷ")],
    "vni_method": [("a1", "á"), ("a61", "ấ"), ("a81", "ắ"), ("o71", "ớ"), ("u71", "ứ"), ("d9", "đ"), ("d9uo7ng2", "đường"), ("tie6ng1", "tiếng"), ("vie6t5", "việt"), ("a10", "a")],
    "misspelled_words_stay_as_typed": [("kof", "kof"), ("kas", "kas"), ("kuw ", "kuw "), ("kom", "kom"), ("kaf", "kaf"), ("kas ", "kas "),
        ("kis", "kí"), ("kys", "ký"), ("kif", "kì"), ("kysf", "kỳ"), ("kes", "ké"), ("kees", "kế"), ("kins", "kín"), ("cas", "cá"), ("cof", "cò"),
        ("aaz ", "aaz "), ("ooz ", "ooz "), ("awz ", "awz "), ("tiez ", "tiez "), ("tiengs ", "tiengs "), ("hello ", "hello "), ("dd", "đ"), ("ddi", "đi"),
        ("kuw", "kư")],
    "free_marking_can_be_switched_off:default": [("taosn", "taón")],
    "retyping_a_modifier_cancels_it": [("aaa", "aa"), ("ass", "as"), ("aww", "aw"), ("ooo", "oo"), ("ddd", "dd"), ("uww", "uw"), ("asz", "a"), ("tieengsz", "tiêng")],
    "standalone_w_is_optional:default": [("w", "ư")],
}
for fn, items in pairs.items():
    method = "vni" if fn == "vni_method" else "telex"
    opts = "" if fn.endswith(":modern") else C
    for i, (k, e) in enumerate(items, 1):
        add(fn.replace(":", "."), i, method, opts, k, e)

add("spell_check_can_be_switched_off", 1, "telex", C, "ook ", "ook ")
add("spell_check_can_be_switched_off", 2, "telex", [C, "src:spellcheck=off"], "ook ", "ôk ", "spell check off")
add("free_marking_can_be_switched_off.strict", 1, "telex", [C, "freeMarking=off"], "taosn", "taosn")
add("free_marking_can_be_switched_off.strict", 2, "telex", [C, "freeMarking=off"], "toans", "toán")
add("standalone_w_is_optional.no_standalone", 1, "simple-telex", C, "w", "w", "their standalone_w=false")
add("standalone_w_is_optional.no_standalone", 2, "simple-telex", C, "uw", "ư", "their standalone_w=false")
s.skip("D27: [ as ơ (standalone_w_is_optional)")
add("backspace_removes_one_rendered_character", 1, "telex", C, "tieengs", "tiếng")
add("backspace_removes_one_rendered_character", 2, "telex", C, "tieengs⌫", "tiến")
add("backspace_removes_one_rendered_character", 3, "telex", C, "tieengs⌫⌫", "tiế")
add("backspace_removes_one_rendered_character", 4, "telex", C, "tieengs⌫⌫⌫", "ti")
add("backspace_removes_one_rendered_character", 5, "telex", C, "aw", "ă")
add("backspace_removes_one_rendered_character", 6, "telex", C, "aw⌫", "")
add("navigation_commits_and_passes_the_key_through", 1, "telex", C, "vieetj←", "việt", "navigation key commits the word")
add("flush_commits_a_pending_word", 1, "telex", C, "dd", "đ")
s.skip("typing.rs: engine API only (empty-word space, discard)", 2)
s.skip("keys.rs: keyval/modifier classification, not key sequences", 5)
s.skip("protocol.rs: IBus D-Bus protocol test against a running engine, not extracted", 1)
s.write()
