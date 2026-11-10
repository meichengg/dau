import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Sink

ROOT = sys.argv[1]  # clone of ZeroX-DG/vi-rs
s = Sink("vi-rs")


def snap_lines(path):
    text = open(path, encoding="utf-8").read()
    # insta snapshot: header between the first two '---' lines, body after.
    parts = text.split("---\n", 2)
    return parts[2].split("\n")


files = [
    ("simple_telex.txt", "telex__simple_telex.snap", "telex"),
    ("non_vietnamese_telex.txt", "telex__non_vietnamese_telex.snap", "telex"),
    ("simple_vni.txt", "vni__simple_vni.snap", "vni"),
    ("non_vietnamese_vni.txt", "vni__non_vietnamese_vni.snap", "vni"),
]
for inp, snap, method in files:
    lines = open(os.path.join(ROOT, "testdata/input", inp), encoding="utf-8").read().split("\n")
    outs = snap_lines(os.path.join(ROOT, "testdata/output", snap))
    for ln, line in enumerate(lines, 1):
        words = line.split()
        if not words:
            continue
        expw = outs[ln - 1].split() if ln - 1 < len(outs) else []
        if len(expw) != len(words):
            raise SystemExit(f"misaligned {inp}:{ln}")
        for wi, w in enumerate(words, 1):
            s.add(f"{inp}:{ln}.{wi}", method, "", w, f"testdata/input/{inp}",
                  expw[wi - 1], "per-word transform, no word boundary")

# tests/incremental.rs: key pushes with a checked view (transcribed by hand, keys only from the test).
inc = [
    ("test_incremental_buffer_basic_telex#1", "telex", "v"),
    ("test_incremental_buffer_basic_telex#2", "telex", "vi"),
    ("test_incremental_buffer_basic_telex#3", "telex", "vie"),
    ("test_incremental_buffer_basic_telex#4", "telex", "viet"),
    ("test_incremental_buffer_basic_telex#5", "telex", "viets"),
    ("test_incremental_buffer_basic_vni#1", "vni", "viet65"),
    ("test_incremental_buffer_tone_removal#1", "telex", "vietsz"),
    ("test_incremental_buffer_letter_modification#1", "telex", "aa"),
    ("test_incremental_buffer_letter_modification#2", "telex", "oo"),
    ("test_incremental_buffer_letter_modification#3", "telex", "uw"),
    ("test_incremental_buffer_complex_word#1", "telex", "nghieeng"),
    ("test_incremental_buffer_w_insertion#1", "telex", "w"),
    ("test_incremental_buffer_w_insertion#2", "telex", "ww"),
    ("test_incremental_buffer_accent_style#1", "telex", "hoas"),
    ("test_incremental_buffer_non_vietnamese_chars#1", "telex", "hello"),
    ("test_incremental_buffer_non_vietnamese_chars#2", "telex", "123!"),
]
their = {
    "test_incremental_buffer_basic_telex#1": "v",
    "test_incremental_buffer_basic_telex#2": "vi",
    "test_incremental_buffer_basic_telex#3": "vie",
    "test_incremental_buffer_basic_telex#4": "viet",
    "test_incremental_buffer_basic_telex#5": "viét",
    "test_incremental_buffer_basic_vni#1": "việt",
    "test_incremental_buffer_tone_removal#1": "viet",
    "test_incremental_buffer_letter_modification#1": "â",
    "test_incremental_buffer_letter_modification#2": "ô",
    "test_incremental_buffer_letter_modification#3": "ư",
    "test_incremental_buffer_complex_word#1": "nghiêng",
    "test_incremental_buffer_w_insertion#1": "ư",
    "test_incremental_buffer_w_insertion#2": "w",
    "test_incremental_buffer_accent_style#1": "hoá",
    "test_incremental_buffer_non_vietnamese_chars#1": "hello",
    "test_incremental_buffer_non_vietnamese_chars#2": "123!",
}
for id, method, keys in inc:
    s.add(f"incremental.rs:{id}", method, "", keys, "tests/incremental.rs", their[id], "buffer view, no word boundary")
s.add("incremental.rs:test_incremental_buffer_accent_style#2", "telex", "tone=classic", "hoas",
      "tests/incremental.rs", "hóa", "AccentStyle::Old")
# test_incremental_vs_batch_consistency: compares two code paths of their own, no expected text.
for m in ("telex", "vni"):
    for k in ["viet65", "nghienge", "ddaaysf", "chuw", "hoaas", "tuyet"]:
        s.add(f"incremental.rs:test_incremental_vs_batch_consistency:{m}:{k}", m, "", k,
              "tests/incremental.rs", None, "their test only checks two code paths agree")

s.skip("bulk corpus not extracted: testdata/input/all_telex.txt (24226 lines, generated)", 24226)
s.skip("bulk corpus not extracted: testdata/input/all_vni.txt (24226 lines, generated)", 24226)
s.skip("unit tests of internal functions, not key sequences (src/*.rs)", 20)
s.skip("incremental.rs tests with no key sequence (clear, constructors)", 2)
s.write()
