"""Hand-transcribed key sequences from small Go/Rust suites (bamboo-core, ibus-bamboo, goxkey).
Keys are re-expressed in our notation; their asserted text goes to the answers file only."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Sink

# ---------------- bamboo-core (bamboo_test.go): "Telex 2", EstdFlags = free marking + classic tone.
s = Sink("bamboo-core")
R = "bamboo_test.go"
C = "tone=classic"
VIEW = "GetProcessedString(VietnameseMode): current word only"
cases = [
    ("TestProcessString", "telex", C, "aw", "ă", VIEW),
    ("TestProcessString", "telex", C, "uwow", "ươ", VIEW),
    ("TestProcessString", "telex", C, "chuaarn", "chuẩn", VIEW),
    ("TestProcessString", "telex", C, "giamaf", "giầm", VIEW),
    ("TestProcessDDString", "telex", C, "dd", None, "their check: IsValid(false) is true"),
    ("TestProcessDDString", "telex", C, "ddafi", "đài", VIEW),
    ("TestProcessMuoiwqString", "telex", C, "Muoiwq", "Muoiwq", "raw-keys view (EnglishMode)"),
    ("TestProcessMuoiwqString", "telex", C, "mootj", "một", VIEW),
    ("TestProcessThuowString", "telex", C, "Thuow", "Thuơ", VIEW),
    ("TestProcessThuowString", "telex", C, "Thuow⌫", "Thu", VIEW),
    ("TestBambooEngine_RemoveLastChar", "telex", C, "⌫␣⌫loanj", "loạn", VIEW + "; the space was fed in their EnglishMode"),
    ("TestBambooEngine_RemoveLastChar", "telex", C, "⌫␣⌫loanj⌫", "lọa", VIEW),
    ("TestBambooEngine_RemoveLastChar", "telex", C, "⌫␣⌫loanj⌫:⌫", "lọa", VIEW + "; ':' fed in their EnglishMode"),
    ("TestProcessUpperString", "telex", C, "VIEETJ", "VIỆT", VIEW),
    ("TestProcessUpperString", "telex", C, "VIEETJ⌫", "VIỆ", VIEW),
    ("TestProcessUpperString", "telex", C, "VIEETJ⌫Q", "VIEEJQ", "raw-keys view (EnglishMode)"),
    ("TestSpellingCheck", "telex", C, "noww", "now", VIEW + "; raw-keys view also checked: noww"),
    ("TestSpellingCheck", "telex", C, "sawss", "săs", VIEW + "; raw-keys view also checked: sawss"),
    ("TestProcessDD", "telex", C, "dd", "đ", VIEW + "; also IsValid"),
    ("TestProcessDD", "telex", C, "SDD", "SĐ", VIEW),
    ("TestProcessNguwowfiString", "telex", C, "wowfi", "ười", VIEW),
    ("TestRemoveLastChar", "telex", C, "hanhj⌫", "hạn", VIEW),
    ("TestProcessCatrString", "telex", C, "catr", "catr", VIEW),
    ("TestProcessToowiString", "telex", C, "toowi", "tơi", VIEW),
    ("TestProcessAlooString", "telex", C, "aloo", "alô", VIEW),
    ("TestSpellingCheckForGiw", "telex", C, "giw", None, "their check: IsValid(false) is true"),
    ("TestDoubleBracketso", "telex", C, "tooss", "tôs", VIEW),
    ("TestDoubleBracketso", "telex", C, "tosos", "tôs", VIEW),
    ("TestDoubleW", "telex", C, "ww", "w", VIEW + "; raw-keys view also checked: w"),
    ("TestDoubleW2", "telex", C, "wiw", "uiw", VIEW + "; raw-keys view also checked: wiw"),
    ("TestProcessDuwoi", "telex", C, "duwoi", "dươi", VIEW),
    ("TestProcessRefresh2", "telex", C, "reff⌫f", "rè", VIEW),
    ("TestProcessDDSeq", "telex", C, "oddp", "ođp", VIEW),
    ("TestProcessGisa", "telex", C, "gisa", "giá", VIEW),
    ("TestProcessKimso", "telex", C, "kimso", "kímo", VIEW),
    ("TestProcessTo", "telex", C, "to", None, "their check: IsValid(true) is true"),
    ("TestProcessToorr", "telex", C, "toorr", "tôr", VIEW),
    ("TestProcessTnoss", "telex", C, "tnoss", "tnos", VIEW),
    ("TestProcessEenghf", "telex", C, "ddawks", "đắk", VIEW),
    ("TestProcessHIEEUR", "telex", C, "tooi␣oo␣HIEEUR", "HIỂU", VIEW),
    ("TestProcessNGUOIW", "telex", C, "NGUOIW", "NGƯƠI", VIEW),
    ("TestProcessTo5", "vni", C, "o55", "o5", VIEW),
    ("TestProcesshuoswc", "telex", C, "duwongwj", "duongwj", VIEW),
    ("TestProcesschoas", "telex", "", "choas", "choá", VIEW + "; their flags without EstdToneStyle"),
    ("TestProcesschoas", "telex", "", "bieecs", "biếc", VIEW),
    ("TestProcesschoas", "telex", "", "uese", "uế", VIEW),
    ("TestBambooEngine_Zprocessing", "telex", C, "loz", "loz", VIEW),
    ("TestBambooEngine_Zprocessing", "telex", C, "losz", "lo", VIEW + "; raw-keys view also checked: losz"),
    ("TestProcessVNWord", "telex", C, "⟦tôi⟧fs", "tối", "their input fed precomposed letters 'tôi' then f, s; raw-keys view also checked"),
    ("TestProcessVNWord", "telex", C, "⟦tối⟧f", "tồi", "their input fed precomposed 'tối' then f; raw-keys view also checked"),
    ("TestProcessVNWord", "telex", C, "⟦tối⟧z", "tôi", "their input fed precomposed 'tối' then z"),
    ("TestDoubleTyping", "telex", C, "linuxx", "linux", VIEW),
    ("TestDoubleTyping", "telex", C, "buwoo", "buô", VIEW),
    ("TestDoubleTyping", "telex", C, "buowco", "buôc", VIEW),
    ("TestDoubleTyping", "telex", C, "cuoiwo", "cuôi", VIEW),
    ("TestDoubleTyping", "telex", C, "acha", "acha", VIEW),
    ("TestDoubleTyping", "telex", C, "nhuw", "như", VIEW + "; also IsValid(true)"),
    ("TestDoubleTyping", "telex", C, "thuw", None, "their check: IsValid(true) is true"),
    ("TestDoubleTyping", "telex", C, "thow", None, "their check: IsValid(true) is true"),
    ("TestDoubleTyping", "telex", C, "tooi", "tôi", VIEW + "; also IsValid(true)"),
    ("TestDoubleTyping", "telex", C, "arch", None, "their check: IsValid(false) is false"),
    ("TestDoubleTyping", "telex", C, "chury", None, "their check: IsValid(true) is true"),
    ("TestDoubleTyping", "telex", C, "turyn⌫⌫", "tủ", VIEW),
    ("TestDoubleTyping", "telex", C, "⟦chuyển⟧z", "chuyên", "their input fed precomposed 'chuyển' then z"),
    ("TestDoubleTyping", "telex", C, "nhueej", "nhuệ", VIEW),
    ("TestDoubleTyping", "telex", C, "cuongw", "cương", VIEW),
    ("TestDoubleTyping", "telex", C, "quawcj", "quặc", VIEW),
]
count = {}
for fn, m, o, k, e, note in cases:
    count[fn] = count.get(fn, 0) + 1
    s.add(f"{R}:{fn}#{count[fn]}", m, o, k, R, e, note)
s.skip("D27: [ ] { } as ơ ư (TestTelex23 x3, TestDoubleBrackets, TestProcessTOs, TestDoubleTyping x2)", 7)
s.skip("D2: keys fed in their EnglishMode inside a word (TestTelex23 't ]', TestProcessRefresh, TestProcessUpperString 'IB', TestDoubleTyping 'tôi）t')", 4)
s.skip("restore-last-word command, no Dấu equivalent (TestBambooEngine_RestoreLastWord, TestRestoreLastWord)", 2)
s.skip("Microsoft (TCVN) keyboard layout, no Dấu equivalent (TestBambooEngine_RestoreLastWord_TCVN)", 3)
s.skip("duplicate of the previous check in the same test (TestDoubleTyping quawcj)", 1)
s.skip("benchmarks (BenchmarkRemoveLastChar…)", 1)
s.skip("utils_test.go, rules_parser_test.go: internal functions, not key sequences", 6)
s.write()

# ---------------- ibus-bamboo (engine_test.go): bamboo "Telex" (w only on u, o, a), EstdFlags, IBstdFlags.
s = Sink("ibus-bamboo")
R = "engine_test.go"
SC = ["tone=classic"]
pre = ["d", "du", "duo", "duow", "duowi", "duowid", "duowidr", "duowidro"]
their = ["d", "du", "duo", "dươ", "dươi", "đươi", "đưởi", "đuổi"]
for i, (k, e) in enumerate(zip(pre, their), 1):
    s.add(f"{R}:TestPreeditEngine/duowidro#{i}", "simple-telex", SC, k, R, e, "preedit after each key")
s.add(f"{R}:TestPreeditEngine/duowidro_enter#1", "simple-telex", SC, "duowidro⏎", R, "đuổi", "commit on Return")
for i, (k, e) in enumerate(zip(["vow", "vowl", "vowl␣"], ["vơ", "vơl", "vowl "]), 1):
    s.add(f"{R}:TestPreeditEngine/macro_vowl_space#{i}", "simple-telex", SC, k, R, e,
          "a macro table is loaded but these keys match no macro" + ("; commit text" if k.endswith("␣") else "; preedit"))
s.add(f"{R}:TestPreeditEngine/macro_vowl_enter#1", "simple-telex", SC, "vowl⏎", R, "vowl", "commit on Return; macro table loaded, no match")
s.add(f"{R}:TestPreeditEngine/workaround_spreadsheet_number_enter#1", "simple-telex", SC, "12⏎", R, None,
      "their check: digits are not processed by the engine")
s.add(f"{R}:TestBsEngine/vn_dot_enter#1", "simple-telex", SC, "vn.", R, "vn.", "backspace mode, text after each key")
s.add(f"{R}:TestBsEngine/vn_dot_enter#2", "simple-telex", SC, "vn.⏎", R, "vn.", "commit on Return")
s.skip("D3: macro expansion (macro_vn_*, macro_arrow_*, macro_csao*, both engines)", 12)
s.skip("repeats of key sequences already listed (TestPreeditEngine macro_duowidro_enter; TestBsEngine duowidro, duowidro_enter, macro_vowl_space, macro_vowl_enter, macro_duowidro_enter, workaround_spreadsheet_number_enter, macro_12)", 8)
s.skip("Ctrl+A / empty key event: no text produced (control_a, macro_control_a, empty_key_events, both engines)", 6)
s.skip("emoji_test.go, utils_test.go: emoji picker and helpers, not typing", 3)
X = "tests/xtest.data"
import sys as _s
lines = open(os.path.join(_s.argv[1], X), encoding="utf-8").read().split("\n")
for ln, line in enumerate(lines, 1):
    if not line.strip():
        continue
    s.add(f"xtest.data:{ln}", "simple-telex", SC, line.replace(" ", "␣") + "⏎", X, None,
          "X11 typing script input, no expected text in their repo")
s.write()

# ---------------- goxkey (src/main.rs tests); engine is vi-rs, default accent style New.
s = Sink("goxkey")
R = "src/main.rs"
s.add(f"main.rs:no_restore_for_valid_word#1", "telex", "", "tieens␣", R, "tiến ", "their check: word is not restored at word end")
s.add(f"main.rs:no_restore_for_vni_numeric_shorthand#1", "vni", "", "d9m␣", R, "đm ", "their check: not restored at word end")
s.add(f"main.rs:capslock_path_keeps_telex_tone_position#1", "telex", "", "DUYEETJ", R, "DUYỆT", "typed with Caps Lock on (their test feeds lowercase keys plus the Caps Lock state)")
s.add(f"main.rs:no_send_needed_for_plain_letter_with_capslock_only_case_change#1", "telex", "", "z", R, "z", "")
s.skip("restore decision called with a made-up transformed word that the keys cannot produce (restore_when_invalid_and_not_allowed 'maaa', restore_for_vni_invalid_without_numeric_shorthand 'dam')", 2)
s.skip("D4: per-user allow list of words (no_restore_for_allowed_word)", 1)
s.skip("Telex+VNI combined method, no Dấu equivalent (telexvni_tests)", 1)
s.skip("internal helpers, not key sequences (input.rs diff_tests 18, mask_w_tests 6, tracking_tests 4; main.rs normalize_input_char, apply_capslock_to_transformed_output; hotkey.rs 6; scripting/parser.rs 40)", 18 + 6 + 4 + 2 + 6 + 40)
s.write()
