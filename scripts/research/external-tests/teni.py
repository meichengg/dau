import sys, os, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Sink, BRACKETS

ROOT = sys.argv[1]  # clone of teni-ime/ibus-teni
s = Sink("ibus-teni")
td = os.path.join(ROOT, "test-data")

for name in sorted(os.listdir(td)):
    if not name.endswith(".tdata"):
        continue
    lines = open(os.path.join(td, name), encoding="utf-8").read().replace("\r", "").split("\n")
    n_valid = sum(1 for l in lines if len(l.split(" ")) == 2)
    if name.startswith("vietnamese.cm.dict"):
        s.skip(f"bulk corpus not extracted: {name} (generated from the common-word list)", n_valid)
        continue
    method = "vni" if ".vni" in name else "telex"
    bracket_im = ".telexw" in name  # their IMTelexEx: Telex with [ ] { } shortcuts
    opts = ["src:dictionary"]
    if ".new." not in name:
        opts.insert(0, "tone=classic")
    for ln, line in enumerate(lines, 1):
        parts = line.split(" ")
        if len(parts) != 2:
            if line.strip():
                s.skip("line their harness ignores (not two space-separated fields)")
            continue
        out, keys = parts
        if bracket_im and any(c in BRACKETS for c in keys):
            s.skip("D27: needs [ ] { } as letters (their Telex W/Ex)")
            continue
        s.add(f"{name}:{ln}", method, opts, keys, f"test-data/{name}", out, "")

ref = "src/teni/teni_coverage_test.go"
s.add("teni_coverage_test.go:TestTeniCoverage#1", "telex", ["tone=classic", "src:dictionary"], "tieesng", ref, None, "they check lengths only")
s.add("teni_coverage_test.go:TestTeniCoverage#2", "telex", ["tone=classic", "src:dictionary"], "tieesnga", ref, "tieesnga", "")
s.add("teni_coverage_test.go:TestTeniCoverage#3", "telex", ["tone=classic", "src:dictionary"], "tieesnga⌫", ref, "tiếng", "")
s.add("teni_coverage_test.go:TestTeniCoverage#4", "telex", ["tone=classic", "src:dictionary"], "tieesnga⌫aaaaaaaaaaaaaaaaaa", ref, "tieesngaaaaaaaaaaaaaaaaaa", "")
s.write()
