import sys, os, re, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Sink, keys_from_text
from rustlit import strip_comments, match_close, pairs, literals, lit_at, unroll_loops, print_only, UNKNOWN_LOOP

ROOT = sys.argv[1]  # clone of uvie-project/uvie-rs
REPORT = len(sys.argv) > 2
TD = os.path.join(ROOT, "tests")
s = Sink("uvie-rs")

CHAR = r"'((?:\\.|[^'\\]))'"


def map_settings(st):
    im = st.get("set_input_method", "")
    method = "vni" if "Vni" in im else ("simple-telex" if "Simple" in im else "telex")
    opts = []
    if st.get("set_modern_orthography") != "true":
        opts.append("tone=classic")
    if st.get("set_english_override", "true") != "false":
        opts.append("src:englishDictionary")
    if st.get("set_quick_start") == "true":
        opts.append("advanced=consonantShortcuts")
    if st.get("set_relaxed_coda") == "true":
        opts.append("src:relaxedCoda=on")
    skip = None
    if st.get("set_quick_telex") == "true":
        skip = "Quick Telex (cc → ch…), listed under 'Đã biết nhưng không làm' in DECISIONS.md"
    return method, opts, skip


def ch(c):
    return {"\\n": "\n", "\\t": "\t", "\\'": "'", "\\\\": "\\"}.get(c, c)


# A key call in a test body; a loop around one of these must have a count known from the source.
KEY_CALL = r"\.feed(?:_diff)?\(|\.backspace(?:_diff)?\(|\bpress_\w+\(|\btype_\w+\(|\.commit(?:_diff)?\(|\bbackspace\("

unextracted = collections.defaultdict(list)
for fname in sorted(os.listdir(TD)):
    if not fname.endswith(".rs"):
        continue
    text = strip_comments(open(os.path.join(TD, fname), encoding="utf-8").read())
    # Local helpers that press Backspace once (e.g. `fn backspace(e, screen)` calling
    # backspace_diff and patching the screen): a call to one is one ⌫ key.
    bs_helpers = set()
    for hm in re.finditer(r"\bfn (\w+)\(([^)]*)\)[^{]*\{", text):
        hb0 = hm.end() - 1
        hbody = text[hb0:match_close(text, hb0)]
        if "UltraFastViEngine" in hm.group(2) and re.search(r"\.backspace(?:_diff)?\(\)", hbody) \
                and not re.search(r"\.feed(?:_diff)?\(|\bfor\b", hbody):
            bs_helpers.add(hm.group(1))
    helpers = {}
    for hm in re.finditer(r"\nfn (\w+)\(\s*\w+\s*:\s*&str\s*,\s*\w+\s*:\s*&str\s*\)\s*\{", text):
        hb0 = hm.end() - 1
        hbody = text[hb0:match_close(text, hb0)]
        if "UltraFastViEngine::new" in hbody:
            helpers[hm.group(1)] = {m.group(1): m.group(2) for m in re.finditer(r"\.(set_\w+)\(\s*([^)]*?)\s*\)", hbody)}
    for tm in re.finditer(r"#\[test\]", text):
        fm = re.compile(r"fn\s+(\w+)\s*\(").search(text, tm.end())
        fn = fm.group(1)
        b0 = text.index("{", fm.end())
        body = text[b0:match_close(text, b0)]
        if re.search(r"include_str!|read_to_string|File::open|fs::read", body):
            s.skip("bulk: reads a data file (tests/data/*)")
            continue
        if print_only(body):
            s.skip("print-only test (no assertion; expected values are only printed or in comments)")
            continue
        body = unroll_loops(body, KEY_CALL)
        got, idx = 0, 0
        ev = []
        for m in re.finditer(r"let\s+(?:mut\s+)?(\w+)\s*=\s*UltraFastViEngine::new\(\)", body):
            ev.append((m.start(), "new", None))
        for m in re.finditer(r"\b\w+\.(set_\w+)\(\s*([^)]*?)\s*\)", body):
            ev.append((m.start(), "set", (m.group(1), m.group(2))))
        for m in re.finditer(r"\b\w+\.(reset|reset_diff)\(\)", body):
            ev.append((m.start(), "reset", None))
        for m in re.finditer(r"type_seq_vni\(\s*", body):
            ev.append((m.start(), "seqvni", lit_at(body, m.end())))
        for m in re.finditer(r"\b(type_seq|type_diff|type_seq_passthrough)\(\s*&mut\s+\w+\s*,\s*", body):
            ev.append((m.start(), "seq", lit_at(body, m.end())))
        for m in re.finditer(r"\btype_chars\(\s*&mut\s+\w+\s*,\s*&mut\s+\w+\s*,\s*", body):
            ev.append((m.start(), "chars", lit_at(body, m.end())))
        for m in re.finditer(r"\bpress_space\(", body):
            ev.append((m.start(), "key", " "))
        for m in re.finditer(r"(?<![\w.])(" + "|".join(sorted(bs_helpers | {"press_backspace"})) + r")\(", body):
            ev.append((m.start(), "key", "⌫"))
        for m in re.finditer(re.escape(UNKNOWN_LOOP), body):
            ev.append((m.start(), "unknown", None))
        for m in re.finditer(r"\bpress_arrow\(", body):
            ev.append((m.start(), "key", "←"))
        for m in re.finditer(r"\b(?:press_break|type_punct)\([^,]*,[^,]*,\s*" + CHAR, body):
            ev.append((m.start(), "key", ch(m.group(1))))
        for m in re.finditer(r"\b\w+\.(?:feed|feed_diff)\(\s*" + CHAR + r"\s*\)", body):
            ev.append((m.start(), "key", ch(m.group(1))))
        for m in re.finditer(r"\b\w+\.(?:backspace|backspace_diff)\(\)", body):
            ev.append((m.start(), "key", "⌫"))
        for m in re.finditer(r"\b\w+\.(?:commit|commit_diff)\(\)", body):
            ev.append((m.start(), "commit", None))
        for m in re.finditer(r"for\s+\w+\s+in\s+(?=r#*\"|\")", body):
            lv = lit_at(body, m.end())
            if lv and re.match(r"\s*\.chars\(\)", body[lv[1]:]):
                lb = body.index("{", lv[1])
                lbody = body[lb:match_close(body, lb)]
                if re.search(r"\.feed(_diff)?\(", lbody):
                    ev.append((m.start(), "loopchars", lv))
        # let chars: Vec<char> = "abc".chars().collect(); for (i, ch) in chars.iter().enumerate() { feed… }
        charvars = {}
        for m in re.finditer(r"let\s+(\w+)\s*:\s*Vec<char>\s*=\s*(?=r#*\"|\")", body):
            lv = lit_at(body, m.end())
            if lv and re.match(r"\s*\.chars\(\)\s*\.collect\(\)", body[lv[1]:]):
                charvars[m.group(1)] = lv
        for m in re.finditer(r"for\s+(?:\(\s*\w+\s*,\s*)?\w+\s*\)?\s+in\s+&?(\w+)(?:\.iter\(\))?(?:\.enumerate\(\))?\s*\{", body):
            if m.group(1) in charvars:
                lb = m.end() - 1
                if re.search(r"\.feed(_diff)?\(", body[lb:match_close(body, lb)]):
                    ev.append((m.start(), "loopchars", charvars[m.group(1)]))
        for m in re.finditer(r"assert_eq!\(\s*&?(\w+)(?:\.as_str\(\))?\s*,\s*", body):
            lv = lit_at(body, m.end())
            if lv and m.group(1) in ("screen", "s", "out", "result", "text"):
                ev.append((m.start(), "screen", lv[0]))
        ev.sort(key=lambda e: e[0])
        st, hist, unknown = {}, "", False
        for pos, kind, data in ev:
            if kind == "new":
                st, hist, unknown = {}, "", False
            elif kind == "set":
                st[data[0]] = data[1]
            elif kind == "reset":
                hist, unknown = "", False
            elif kind == "unknown":
                unknown = True
            elif kind in ("seq", "seqvni"):
                if not data:
                    continue
                keys = data[0]
                pre = body[max(0, pos - 30):pos]
                exp = None
                if re.search(r"assert_eq!\(\s*$", pre):
                    mm = re.match(r"\s*\)\s*,\s*", body[data[1]:])
                    if mm:
                        lv = lit_at(body, data[1] + mm.end())
                        exp = lv[0] if lv else None
                stt = dict(st)
                if kind == "seqvni":
                    stt = {"set_input_method": "InputMethod::Vni"}
                    prior = ""
                else:
                    prior = hist
                    hist = hist + keys
                method, opts, skip = map_settings(stt)
                got += 1
                if skip:
                    s.skip(skip); continue
                if unknown and kind == "seq":
                    s.skip("key count set at run time (loop bound computed in the test)"); continue
                idx += 1
                note = "" if not prior else f"same engine as earlier keys in this test; their result covers only the last {len(keys)} keys"
                s.add(f"{fname}:{fn}#{idx}", method, opts, keys_from_text(prior + keys), f"tests/{fname}", exp, note)
            elif kind == "chars" and data:
                hist += data[0]
            elif kind == "loopchars":
                hist += data[0]
            elif kind == "key":
                hist += data
            elif kind == "commit":
                hist += "␣" if False else ""
            elif kind == "screen":
                if not hist:
                    continue
                method, opts, skip = map_settings(st)
                got += 1
                if skip:
                    s.skip(skip); continue
                if unknown:
                    s.skip("key count set at run time (loop bound computed in the test)"); continue
                idx += 1
                s.add(f"{fname}:{fn}#{idx}", method, opts, keys_from_text(hist), f"tests/{fname}", data,
                      "their expected is the whole screen since the engine was created")
        for hname, hst in helpers.items():
            for hm in re.finditer(r"\b" + hname + r"\(\s*(?=r#*\"|\")", body):
                a = lit_at(body, hm.end())
                mm = re.match(r"\s*,\s*", body[a[1]:])
                b = lit_at(body, a[1] + mm.end()) if mm else None
                method, opts, skip = map_settings(hst)
                got += 1
                if skip:
                    s.skip(skip); continue
                idx += 1
                s.add(f"{fname}:{fn}#{idx}", method, opts, keys_from_text(a[0]), f"tests/{fname}", b[0] if b else None, f"local helper {hname}()")
        arrays = {}
        for am2 in re.finditer(r"let\s+(?:mut\s+)?(\w+)(?:\s*:\s*[^=]+)?\s*=\s*(?:vec!)?&?\[", body):
            a = am2.end() - 1
            arrays[am2.group(1)] = body[a:match_close(body, a, "[", "]")]
        for lm in re.finditer(r"for\s+\(\s*(\w+)\s*,\s*(\w+)\s*\)\s+in\s+(?:&?\[|&?(\w+)(?:\.iter\(\))?\s*\{)", body):
            if lm.group(3):
                if lm.group(3) not in arrays:
                    continue
                prs = [(x, y) for x, y, _ in pairs(arrays[lm.group(3)])]
                lb = lm.end() - 1
            else:
                a = lm.end() - 1
                arr = body[a:match_close(body, a, "[", "]")]
                prs = [(x, y) for x, y, _ in pairs(arr)]
                lb = body.index("{", a + len(arr))
            lbody = body[lb:match_close(body, lb)]
            st2 = {m.group(1): m.group(2) for m in re.finditer(r"\b\w+\.(set_\w+)\(\s*([^)]*?)\s*\)", body[:lb] + lbody)}
            if "type_seq_vni" in lbody:
                st2["set_input_method"] = "InputMethod::Vni"
            method, opts, skip = map_settings(st2)
            if print_only(lbody):
                s.skip("print-only loop (no assertion; expected values are only printed)", len(prs))
                got += len(prs)
                continue
            for x, y in prs:
                got += 1
                if skip:
                    s.skip(skip); continue
                idx += 1
                s.add(f"{fname}:{fn}#{idx}", method, opts, keys_from_text(x), f"tests/{fname}", y, "loop over pairs in the test body")
        if got == 0:
            unextracted[fname].append(fn)

for f, fns in unextracted.items():
    s.skip(f"not extracted ({f}): engine-API checks (diff sizes, internal tables, edit history, invariants)", len(fns))
if REPORT:
    for f, fns in unextracted.items():
        print(f, len(fns), fns[:12])
s.write()
