import sys, os, re, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Sink, keys_from_text, BRACKETS
from rustlit import strip_comments, match_close, lit_at, literals, unroll_loops

ROOT = sys.argv[1]  # clone of xmannv/xkey
REPORT = len(sys.argv) > 2
TD = os.path.join(ROOT, "XKeyTests")
s = Sink("xkey")

FILES = ["VNEngineTests.swift", "VNEngineBackspaceRestoreTests.swift", "VNEngineBufferIntegrationTests.swift",
         "TypingBufferTests.swift"]
QT = "src:quickTelex=on"
QT_PAIRS = ("cc", "gg", "kk", "nn", "qq", "pp", "tt")


def quick_telex_gate(opts, keys):
    """XKey's default engine has Quick Telex on. Keep the case only if no doubled consonant could trigger it."""
    if QT not in opts:
        return opts, False
    low = keys.lower()
    if any(p in low for p in QT_PAIRS):
        return opts, True
    return [o for o in opts if o != QT], False


def map_settings(st):
    method = "vni" if st.get("vInputType") == "1" else "telex"
    opts = []
    if st.get("vUseModernOrthography") == "0":
        opts.append("tone=classic")
    if st.get("vRestoreIfWrongSpelling") == "0":
        opts.append("autoRestore=off")
    if st.get("vCheckSpelling") == "0":
        opts.append("src:spellcheck=off")
    if st.get("vQuickStartConsonant") == "1" or st.get("vQuickEndConsonant") == "1":
        opts.append("advanced=consonantShortcuts")
    cc = st.get("vCustomConsonants", "")
    letters = "".join(sorted(set(re.findall(r"KEY_([A-Z])", cc))))
    if cc.startswith("allCustom") or cc.strip() == "[":
        letters = "FJKWZ"
    if letters:
        if set(letters) & set("FJWZ"):
            opts.append("advanced=allowZFWJ")
        opts.append("src:customConsonants=" + letters)
    if st.get("vQuickTelex", "1") == "1" and method == "telex":
        opts.append(QT)
    skip = None
    if st.get("vUseMacro") == "1":
        skip = "D3: macro"
    if st.get("vUpperCaseFirstChar") == "1":
        skip = "D3: capitalise first letter"
    if st.get("vAdaptiveEnabled") == "true" or st.get("vInputType") == "2":
        skip = "their adaptive Telex+VNI method, no Dấu equivalent"
    if st.get("vLanguage") == "0":
        skip = "D2: their English mode"
    if st.get("vCodeTable", "0") != "0":
        skip = "D3: legacy code table"
    return method, opts, skip


def sw_char(lit):
    v = lit.replace("\\u{8}", "\b").replace("\\u{08}", "\b").replace("\\n", "\n").replace("\\t", "\t").replace('\\"', '"').replace("\\\\", "\\")
    return v


SWIFT_STR = r'"((?:[^"\\]|\\.|\\u\{[0-9a-fA-F]+\})*)"'
# A key call in a test body; loops around one must have a count known from the source.
KEY_CALL = r"processKey|processBackspace|processWordBreak|typeBackspace|typeWord|processSpace|typeTelex|\btype\(|\bvni\("

unextracted = collections.defaultdict(list)
for fname in FILES:
    text = strip_comments(open(os.path.join(TD, fname), encoding="utf-8").read())
    for tm in re.finditer(r"func (test\w+)\(\)\s*(?:throws\s*)?\{", text):
        fn = tm.group(1)
        b0 = tm.end() - 1
        body = text[b0:match_close(text, b0)]
        if "vAutoCaps" in body or "UpperCaseFirstChar" in body:
            s.skip("D3: capitalise first letter / macro caps (tests)")
            continue
        body = unroll_loops(body, KEY_CALL)
        ev = []
        # if/else chains: each branch starts from the key history at its `if`, and rows
        # inside a branch say which condition on their engine state it depends on.
        branches = []
        for m in re.finditer(r"\bif\s+([^{\n]+?)\s*\{", body):
            lb = m.end() - 1
            end = match_close(body, lb)
            ev.append((m.start(), "if", m.start()))
            cond = m.group(1).strip()
            branches.append((lb, end, f"if {cond}"))
            em = re.match(r"\s*else\s*\{", body[end:])
            if em:
                elb = end + em.end() - 1
                ev.append((end, "else", m.start()))
                branches.append((elb, match_close(body, elb), f"not ({cond})"))
            elif re.match(r"\s*else\s+if\b", body[end:]):
                ev.append((end, "else", m.start()))
        for m in re.finditer(r"__UNKNOWN_LOOP__\(\)", body):
            ev.append((m.start(), "key", None))
        for m in re.finditer(r"engine\.(reset|resetWithCursorMoved|notifyFocusChanged|startNewSession)\(", body):
            ev.append((m.start(), "reset", None))
        for m in re.finditer(r"engine\.(v\w+)\s*=\s*([^\n]+)", body):
            ev.append((m.start(), "set", (m.group(1), m.group(2).strip())))
        for m in re.finditer(r"engine\.processKey\(\s*character:\s*(" + SWIFT_STR + r"|\w+)[^)]*?isUppercase:\s*(true|false|[\w.]+)", body):
            if m.group(2) is None:
                ev.append((m.start(), "key", None))
            else:
                c = sw_char(m.group(2))
                if m.group(3) == "true":
                    c = c.upper()
                ev.append((m.start(), "key", "⌫" if c == "\b" else c))
        for m in re.finditer(r"engine\.processBackspace\(", body):
            ev.append((m.start(), "key", "⌫"))
        for m in re.finditer(r"engine\.processWordBreak\(\s*character:\s*" + SWIFT_STR, body):
            ev.append((m.start(), "key", sw_char(m.group(1))))
        for m in re.finditer(r"\btypeWord\(\s*" + SWIFT_STR, body):
            ev.append((m.start(), "keys", sw_char(m.group(1))))
        for m in re.finditer(r"\btypeBackspace\(\)", body):
            ev.append((m.start(), "key", "⌫"))
        for m in re.finditer(r"\bprocessSpace\(\)", body):
            ev.append((m.start(), "key", " "))
        for m in re.finditer(r"\b(typeTelex|type)\(\s*" + SWIFT_STR + r"\s*\)", body):
            ev.append((m.start(), "fresh", sw_char(m.group(2))))
        for m in re.finditer(r"\bvni\(\s*\[", body):
            a = m.end() - 1
            arr = body[a:match_close(body, a, "[", "]")]
            ks = "".join(sw_char(x) for x in re.findall(r'\(\s*"((?:[^"\\]|\\.)*)"\s*,', arr))
            ev.append((m.start(), "freshvni", ks))
        for m in re.finditer(r"\btype(Adaptive|Upper)\(", body):
            ev.append((m.start(), "adaptive", None))
        for m in re.finditer(r"for\s+\w+\s+in\s+" + SWIFT_STR + r"\s*\{", body):
            lb = m.end() - 1
            lbody = body[lb:match_close(body, lb)]
            if "processKey" in lbody:
                ev.append((m.start(), "keys", sw_char(m.group(1))))
                ev.append((m.end(), "skipkeys", (lb, lb + len(lbody))))
        for m in re.finditer(r"XCTAssertEqual\(\s*engine\.getCurrentWord\(\)\s*,\s*" + SWIFT_STR, body):
            ev.append((m.start(), "check", sw_char(m.group(1))))
        for m in re.finditer(r"let\s+(\w+)\s*=\s*engine\.getCurrentWord\(\)", body):
            am = re.compile(r"XCTAssertEqual\(\s*" + m.group(1) + r"\s*,\s*" + SWIFT_STR).search(body, m.end())
            if am:
                ev.append((m.start(), "check", sw_char(am.group(1))))
        ev.sort(key=lambda e: e[0])
        st, hist, bad, idx, got = {}, "", False, 0, 0
        skip_range = None
        last_check_hist = None
        snap = {}

        def branch_note(pos):
            conds = [c for a, b, c in branches if a < pos < b]
            return "; their test branch: " + " and ".join(conds) if conds else ""
        for pos, kind, data in ev:
            if skip_range and skip_range[0] <= pos < skip_range[1] and kind == "key":
                continue
            if kind == "skipkeys":
                skip_range = data; continue
            if kind == "if":
                snap[data] = (hist, bad)
            elif kind == "else":
                hist, bad = snap[data]
            elif kind == "reset":
                hist, bad = "", False
            elif kind == "set":
                st[data[0]] = data[1]
            elif kind == "key":
                if data is None:
                    bad = True
                else:
                    hist += data
            elif kind == "keys":
                hist += data
            elif kind == "adaptive":
                s.skip("their adaptive Telex+VNI method, no Dấu equivalent"); got += 1
            elif kind in ("fresh", "freshvni"):
                # inline: XCTAssertEqual(typeTelex("x"), "y")
                after = body[pos:pos + 400]
                mm = re.match(r"\w+\(\s*(?:\[.*?\]|" + SWIFT_STR + r")\s*\)\s*,\s*" + SWIFT_STR, after, re.S)
                exp = sw_char(mm.group(2)) if mm else None
                stt = dict(st)
                if kind == "freshvni":
                    stt["vInputType"] = "1"
                method, opts, skp = map_settings(stt)
                got += 1
                hist, bad = data, False
                if skp:
                    s.skip(skp); continue
                if QT in opts and any(c in BRACKETS for c in data):
                    s.skip("D27: [ ] as ơ ư"); continue
                opts, qt = quick_telex_gate(opts, data)
                if qt:
                    s.skip("Quick Telex (on by default in their engine) may rewrite a doubled consonant in these keys"); continue
                idx += 1
                s.add(f"{fname}:{fn}#{idx}", method, opts, keys_from_text(data), f"XKeyTests/{fname}", exp,
                      "getCurrentWord(): current word only")
            elif kind == "check":
                if bad or not hist:
                    continue
                method, opts, skp = map_settings(st)
                got += 1
                if skp:
                    s.skip(skp); continue
                if any(c in BRACKETS for c in hist):
                    s.skip("D27: [ ] as ơ ư"); continue
                opts, qt = quick_telex_gate(opts, hist)
                if qt:
                    s.skip("Quick Telex (on by default in their engine) may rewrite a doubled consonant in these keys"); continue
                idx += 1
                s.add(f"{fname}:{fn}#{idx}", method, opts, keys_from_text(hist), f"XKeyTests/{fname}", data,
                      "getCurrentWord(): current word only" + branch_note(pos))
        if got == 0:
            if fn.startswith("testMacro"):
                s.skip("D3: macro (tests)")
            else:
                unextracted[fname].append(fn)

# ScreenSimulationTests.corpus: inputs only (their test checks an invariant, not a text).
t = open(os.path.join(TD, "ScreenSimulationTests.swift"), encoding="utf-8").read()
m = re.search(r"static let corpus: \[String\] = \[(.*?)\]", t, re.S)
for i, (v, _) in enumerate(literals(m.group(1)), 1):
    o, qt = quick_telex_gate([QT], v)
    if qt:
        s.skip("Quick Telex (on by default in their engine) may rewrite a doubled consonant in these keys"); continue
    s.add(f"ScreenSimulationTests.swift:corpus#{i}", "telex", o, keys_from_text(v), "XKeyTests/ScreenSimulationTests.swift",
          None, "their check: screen equals engine buffer (invariant), no expected text")

s.skip("telex_test_suite.csv: corpus produced by another engine (origin and licence not stated), not used", 8046)
s.skip("VNEngineAutoCapitalizeTests.swift: D3 capitalise first letter (whole file)", 1)
s.skip("VNEngineAdaptiveTests.swift: adaptive Telex+VNI method (whole file)", 1)
s.skip("other XKeyTests files: app plumbing (event tap, AX, settings, sync, macro manager), not typing", 1)
for f, fns in unextracted.items():
    s.skip(f"not extracted ({f}): no key sequence with a text check (engine state, flags, undo API)", len(fns))
if REPORT:
    for f, fns in unextracted.items():
        print(f, len(fns), fns[:15])
s.write()
