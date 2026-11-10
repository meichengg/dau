import sys, os, re, collections
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Sink, BRACKETS, keys_from_text
from rustlit import strip_comments, match_close, pairs, literals, lit_at

ROOT = sys.argv[1]  # clone of khaphanspace/gonhanh.org
REPORT = len(sys.argv) > 2
TD = os.path.join(ROOT, "core/tests")
s = Sink("gonhanh")

AR_OFF = "autoRestore=off"
EN = "src:englishDictionary"
RUNNERS = {
    "telex": ("telex", [AR_OFF], "pairs"),
    "vni": ("vni", [AR_OFF], "pairs"),
    "telex_auto_restore": ("telex", [EN], "pairs"),
    "telex_traditional": ("telex", ["tone=classic", AR_OFF], "pairs"),
    "vni_traditional": ("vni", ["tone=classic", AR_OFF], "pairs"),
    "telex_auto_capitalize": None,  # D3
    "telex_foreign": ("telex", ["advanced=allowZFWJ", AR_OFF], "pairs"),
    "telex_no_foreign": ("telex", [AR_OFF], "pairs"),
    "telex_foreign_with_w": ("simple-telex", ["advanced=allowZFWJ", AR_OFF], "pairs"),
    "telex_foreign_with_auto_restore": ("telex", ["advanced=allowZFWJ", EN], "pairs"),
    "assert_no_transform": ("telex", [AR_OFF], "words"),
    "assert_auto_restore": ("telex", [EN], "words_space"),
}
RUNNER_RE = re.compile(r"\b(" + "|".join(RUNNERS) + r")\(\s*")

SETTERS = {
    "set_method": None,
    "set_modern_tone": None,
    "set_english_auto_restore": None,
    "set_allow_foreign_consonants": None,
    "set_skip_w_shortcut": None,
    "set_free_tone": None,
    "set_bracket_shortcut": None,
    "set_esc_restore": None,
    "set_auto_capitalize": None,
    "set_enabled": None,
}


def map_settings(st):
    """their engine settings dict -> (method, options, skip_reason)"""
    method = "vni" if st.get("set_method") == "1" else "telex"
    opts = []
    if st.get("set_modern_tone") == "false":
        opts.append("tone=classic")
    if st.get("set_english_auto_restore") == "true":
        opts.append(EN)
    else:
        opts.append(AR_OFF)
    if st.get("set_allow_foreign_consonants") == "true":
        opts.append("advanced=allowZFWJ")
    if st.get("set_skip_w_shortcut") == "true" and method == "telex":
        method = "simple-telex"
    if st.get("set_free_tone") == "true":
        opts.append("src:spellcheck=off")
    skip = None
    if st.get("set_auto_capitalize") == "true":
        skip = "D3: auto-capitalize"
    if st.get("set_enabled") == "false":
        skip = "engine disabled mid-test (their on/off toggle; D2)"
    if st.get("set_bracket_shortcut") == "true":
        opts.append("src:bracketShortcut=on")
    if st.get("set_esc_restore") == "true":
        opts.append("src:escRestore=on")
    return method, opts, skip


def to_keys(raw):
    """their test notation -> ours: '<' is Backspace, ESC char is Esc, space/tab/newline symbols."""
    k = raw.replace("<", "⌫").replace("\x1b", "⎋")
    return keys_from_text(k)


def emit(fileid, fn, idx, method, opts, raw_keys, expected, note=""):
    if "src:bracketShortcut=on" in opts and any(c in BRACKETS for c in raw_keys):
        s.skip("D27: [ ] as ơ ư (their bracket shortcut on)")
        return
    if "src:escRestore=on" in opts and "\x1b" in raw_keys:
        s.skip("Esc restores the raw keys (their option), Dấu has no such feature (D4: Esc only resets)")
        return
    opts = [o for o in opts if o not in ("src:bracketShortcut=on", "src:escRestore=on")]
    s.add(f"{fileid}:{fn}#{idx}", method, opts, to_keys(raw_keys), f"core/tests/{fileid}", expected, note)


KEYNAME = {"SPACE": "␣", "DELETE": "⌫", "RETURN": "⏎", "TAB": "⇥", "ESC": "⎋", "LEFT": "←", "RIGHT": "←",
           "UP": "←", "DOWN": "←", "DOT": ".", "COMMA": ",", "SEMICOLON": ";", "SLASH": "/", "MINUS": "-",
           "LBRACKET": "[", "RBRACKET": "]"}
SHIFTED = {"N1": "!", "N2": "@", "N3": "#", "N4": "$", "N5": "%", "N6": "^", "N7": "&", "N8": "*", "N9": "(", "N0": ")",
           "MINUS": "_", "SEMICOLON": ":", "SLASH": "?", "DOT": ">", "COMMA": "<", "LBRACKET": "{", "RBRACKET": "}"}


def keyname_to_char(name, caps, shift):
    if shift and name in SHIFTED:
        return SHIFTED[name]
    if len(name) == 1 and name.isalpha():
        return name.upper() if caps else name.lower()
    if len(name) == 2 and name[0] == "N" and name[1].isdigit():
        return name[1]
    return KEYNAME.get(name)


def raw_sequences(body):
    """Key sequences fed through on_key / on_key_ext / char arrays, split at Engine::new()."""
    out, cur, st, cur_st = [], [], {}, {}
    toks = []
    for m in re.finditer(r"Engine::new\(\)|\.(set_\w+)\(\s*([^)]*?)\s*\)|\.clear\(\)|on_key(_ext)?\(\s*keys::([A-Z_0-9]+)\s*,\s*(true|false)\s*,\s*(true|false)(?:\s*,\s*(true|false))?|for\s+\w+\s+in\s+\[((?:\s*'(?:\\\\.|[^'])'\s*,?)+)\]|let\s+inputs\s*=\s*\[((?:\s*'(?:\\\\.|[^'])'\s*,?)+)\]", body):
        toks.append(m)
    def flush():
        if cur:
            out.append(("".join(cur), dict(cur_st)))
    for m in toks:
        txt = m.group(0)
        if txt.startswith("Engine::new"):
            flush(); cur.clear(); cur_st.clear()
        elif m.group(1):
            cur_st[m.group(1)] = m.group(2)
        elif txt == ".clear()":
            if cur: cur.append("←")
        elif m.group(4):
            name, caps, ctrl, shift = m.group(4), m.group(5) == "true", m.group(6) == "true", m.group(7) == "true"
            if ctrl:
                cur.append("←")
                continue
            c = keyname_to_char(name, caps, shift)
            if c is None:
                return []
            cur.append(c)
        else:
            chars = re.findall(r"'((?:\\.|[^']))'", m.group(8) or m.group(9))
            for c in chars:
                c = {"\\n": "\n", "\\t": "\t", "\\x1b": "\x1b"}.get(c, c)
                cur.append(to_keys(c))
    flush()
    return out


unextracted = collections.defaultdict(list)
for fname in sorted(os.listdir(TD)):
    if not fname.endswith(".rs"):
        continue
    text = strip_comments(open(os.path.join(TD, fname), encoding="utf-8").read())
    consts, words = {}, {}
    for m in re.finditer(r"const ([A-Z_0-9]+): &\[\(&str, &str\)\] = &\[", text):
        a = m.end() - 1
        consts[m.group(1)] = pairs(text[a:match_close(text, a, "[", "]")])
    for m in re.finditer(r"const ([A-Z_0-9]+): &\[&str\] = &\[", text):
        a = m.end() - 1
        words[m.group(1)] = [v for v, _ in literals(text[a:match_close(text, a, "[", "]")])]
    used_consts = set()
    # Factory helpers `fn engine_on() -> Engine { let mut e = Engine::new(); e.set_…(…); e }`:
    # a test's `let mut e = engine_on();` is inlined as Engine::new() plus the same setters.
    factories = {}
    for fm2 in re.finditer(r"\nfn (\w+)\(\s*\)\s*->\s*Engine\s*\{", text):
        fb0 = fm2.end() - 1
        fbody = text[fb0:match_close(text, fb0)]
        sets = [(m.group(1), m.group(2)) for m in re.finditer(r"\.(set_\w+)\(\s*([^)]*?)\s*\)", fbody)]
        factories[fm2.group(1)] = (sets, bool(re.search(r"shortcuts?_mut|add_shortcut|Shortcut::", fbody)))
    helpers = {}
    for hm in re.finditer(r"\nfn (\w+)\(\s*\w+\s*:\s*&str\s*\)\s*->\s*String\s*\{", text):
        hb0 = hm.end() - 1
        hbody = text[hb0:match_close(text, hb0)]
        if "type_word" in hbody:
            st = {m.group(1): m.group(2) for m in re.finditer(r"\.(set_\w+)\(\s*([^)]*?)\s*\)", hbody)}
            helpers[hm.group(1)] = st
    for tm in re.finditer(r"#\[(test|rstest)\]", text):
        fm = re.compile(r"fn\s+(\w+)\s*\(").search(text, tm.end())
        fn = fm.group(1)
        b0 = text.index("{", fm.end())
        body = text[b0:match_close(text, b0)]
        for fname2, (sets, has_sc) in factories.items():
            def inline(m, sets=sets, has_sc=has_sc):
                v = m.group(1)
                return (f"let mut {v} = Engine::new();" + "".join(f" {v}.{k}({x});" for k, x in sets)
                        + (f" {v}.shortcuts_mut();" if has_sc else ""))
            body = re.sub(r"let\s+(?:mut\s+)?(\w+)(?:\s*:\s*Engine)?\s*=\s*" + fname2 + r"\(\s*\)\s*;", inline, body)
        if tm.group(1) == "rstest":
            n = len(re.findall(r"#\[case", text[tm.end():fm.start()]))
            s.skip("rstest generated cases (inputs built from parameters at run time), not extracted", max(n, 1))
            continue
        got = 0
        idx = 0
        if re.search(r"shortcuts?_mut|add_shortcut|Shortcut::", body) or ("shortcut" in fn and "w_shortcut" not in fn):
            s.skip("D3: macro/abbreviation shortcuts")
            continue
        if "auto_capitalize" in body or "capitalize" in fn:
            s.skip("D3: auto-capitalize")
            continue
        if re.search(r"include_str!|read_to_string|File::open|fs::read|generate_", body):
            s.skip("bulk/generated: reads a data file or generates inputs at run time")
            continue
        lets = {}
        for lm2 in re.finditer(r"let\s+(?:mut\s+)?(\w+)(?:\s*:\s*[^=]+)?\s*=\s*(?=r#*\"|\")", body):
            lv = lit_at(body, lm2.end())
            if lv:
                lets[lm2.group(1)] = lv[0]
        arrays = {}
        for am2 in re.finditer(r"let\s+(?:mut\s+)?(\w+)(?:\s*:\s*[^=]+)?\s*=\s*(?:vec!)?&?\[", body):
            a = am2.end() - 1
            arrays[am2.group(1)] = body[a:match_close(body, a, "[", "]")]
        # (a) runner calls
        for rm in RUNNER_RE.finditer(body):
            name = rm.group(1)
            spec = RUNNERS[name]
            arg = body[rm.end():]
            items, is_words = None, False
            if arg.startswith("&["):
                a = rm.end() + 1
                inner = body[a:match_close(body, a, "[", "]")]
                if spec and spec[2] != "pairs":
                    items = [(v, v) for v, _ in literals(inner)]
                else:
                    items = [(x, y) for x, y, _ in pairs(inner)]
                    for im in re.finditer(r"\(\s*(\w+)\s*,\s*(\w+)\s*\)", inner):
                        if im.group(1) in lets and im.group(2) in lets:
                            items.append((lets[im.group(1)], lets[im.group(2)]))
            else:
                cm = re.match(r"([A-Z][A-Z_0-9]+)", arg)
                if cm and cm.group(1) in consts:
                    items = [(x, y) for x, y, _ in consts[cm.group(1)]]
                    used_consts.add(cm.group(1))
                elif cm and cm.group(1) in words:
                    items = [(v, v) for v in words[cm.group(1)]]
                    used_consts.add(cm.group(1))
            if items is None:
                continue
            got += len(items)
            if spec is None:
                s.skip("D3: auto-capitalize (telex_auto_capitalize)", len(items))
                continue
            method, opts, kind = spec
            for x, y in items:
                idx += 1
                if kind == "words_space":
                    x, y = x + " ", y + " "
                emit(fname, fn, idx, method, list(opts), x, y)
        # (b) direct engine flows on one engine: type_word calls, raw keys, clear, restore_word.
        settings = collections.defaultdict(dict)
        history = collections.defaultdict(str)
        events = []
        for m in re.finditer(r"let\s+(?:mut\s+)?(\w+)(?:\s*:\s*Engine)?\s*=\s*Engine::new\(\)", body):
            events.append((m.start(), "new", m.group(1), None))
        for m in re.finditer(r"\b(\w+)\.(set_\w+)\(\s*([^)]*?)\s*\)", body):
            events.append((m.start(), "set", m.group(1), (m.group(2), m.group(3))))
        for m in re.finditer(r"\b(\w+)\.clear(?:_all)?\(\)", body):
            events.append((m.start(), "clear", m.group(1), None))
        for m in re.finditer(r"\b(\w+)\.restore_word\(\s*", body):
            lv = lit_at(body, m.end())
            events.append((m.start(), "restore", m.group(1), lv))
        for m in re.finditer(r"\b(\w+)\.on_key(_ext)?\(\s*keys::([A-Z_0-9]+)\s*,\s*(true|false)\s*,\s*(true|false)(?:\s*,\s*(true|false))?", body):
            name, caps, ctrl, shift = m.group(3), m.group(4) == "true", m.group(5) == "true", m.group(6) == "true"
            if ctrl or (shift and name in ("LEFT", "RIGHT", "UP", "DOWN")):
                c = "←"
            else:
                c = keyname_to_char(name, caps, shift)
                c = {"⌫": "<", "␣": " ", "⏎": "\n", "⇥": "\t", "⎋": "\x1b"}.get(c, c)
            events.append((m.start(), "raw", m.group(1), c))
        tw_re = re.compile(r"type_word\(\s*&mut\s+(\w+)\s*,\s*")
        tw_pos = [m.start() for m in tw_re.finditer(body)]
        for m in tw_re.finditer(body):
            lv = lit_at(body, m.end())
            events.append((m.start(), "type", m.group(1), lv))
        events.sort(key=lambda e: e[0])
        for pos, kind, var, data in events:
            if kind == "new":
                settings[var] = {}
                history[var] = ""
            elif kind == "set":
                settings[var][data[0]] = data[1]
            elif kind == "clear":
                history[var] = ""
            elif kind == "restore":
                history[var] = ("⟦" + data[0] + "⟧") if data else ""
            elif kind == "raw":
                if data is None:
                    history[var] += "�"
                else:
                    history[var] += data
            elif kind == "type":
                if not data:
                    continue  # keys from a variable (loop or generated): handled below or not extracted
                keys = data[0]
                nxt = min([p for p in tw_pos if p > pos] + [len(body)])
                exp = None
                pre = body[max(0, pos - 40):pos]
                if re.search(r"assert_eq!\(\s*$", pre):
                    mm = re.match(r"\s*\)\s*,\s*", body[data[1]:])
                    if mm:
                        lv = lit_at(body, data[1] + mm.end())
                        exp = lv[0] if lv else None
                else:
                    vm = re.search(r"let\s+(?:mut\s+)?(\w+)\s*=\s*$", pre)
                    if vm:
                        seg = body[data[1]:nxt]
                        am = re.search(r"assert_eq!\(\s*&?" + vm.group(1) + r"(?:\.as_str\(\))?\s*,\s*", seg)
                        if am:
                            lv = lit_at(seg, am.end())
                            exp = lv[0] if lv else None
                method, opts, skip = map_settings(settings[var])
                prior = history[var]
                history[var] = prior + keys
                if "�" in prior + keys:
                    s.skip("raw key code with no character mapping")
                    got += 1
                    continue
                if skip:
                    s.skip(skip)
                    got += 1
                    continue
                idx += 1
                got += 1
                note = ""
                if prior:
                    note = f"same engine as earlier keys in this test; their result covers only the output of the last {len(keys)} keys"
                emit(fname, fn, idx, method, opts, prior + keys, exp, note)
        # (c) loops: for (input, expected) in [ ... ] { ... type_word(&mut e, input) ... }
        for lm in re.finditer(r"for\s+\(\s*(\w+)\s*,\s*(\w+)\s*\)\s+in\s+(?:&?\[|&?(\w+)(?:\.iter\(\))?\s*\{)", body):
            if lm.group(3):
                name = lm.group(3)
                if name in consts:
                    prs0 = [(x, y) for x, y, _ in consts[name]]; used_consts.add(name)
                elif name in arrays:
                    prs0 = [(x, y) for x, y, _ in pairs(arrays[name])]
                else:
                    continue
                lb = lm.end() - 1
            else:
                a = lm.end() - 1
                arr = body[a:match_close(body, a, "[", "]")]
                prs0 = [(x, y) for x, y, _ in pairs(arr)]
                lb = body.index("{", a + len(arr))
            loop_body = body[lb:match_close(body, lb)]
            if "type_word" not in loop_body:
                continue
            st = {}
            for m in re.finditer(r"\b\w+\.(set_\w+)\(\s*([^)]*?)\s*\)", body[:lb] + loop_body):
                st[m.group(1)] = m.group(2)
            method, opts, skip = map_settings(st)
            prs = prs0
            got += len(prs)
            for x, y in prs:
                if skip:
                    s.skip(skip); continue
                idx += 1
                emit(fname, fn, idx, method, opts, x, y, "loop over pairs in the test body")
        for hname, hst in helpers.items():
            for hm in re.finditer(r"assert_eq!\(\s*" + hname + r"\(\s*", body):
                kv = lit_at(body, hm.end())
                if not kv:
                    continue
                rest = re.match(r"\s*\)\s*,\s*", body[kv[1]:])
                ev = lit_at(body, kv[1] + rest.end()) if rest else None
                method, opts, skip = map_settings(hst)
                got += 1
                if skip:
                    s.skip(skip); continue
                idx += 1
                emit(fname, fn, idx, method, opts, kv[0], ev[0] if ev else None, f"local helper {hname}()")
        for rm2 in re.finditer(r"restore_and_type\(\s*&mut\s+(\w+)\s*,\s*", body):
            a1 = lit_at(body, rm2.end())
            mm = re.match(r"\s*,\s*", body[a1[1]:])
            a2 = lit_at(body, a1[1] + mm.end())
            after = body[a2[1]:]
            am = re.search(r"assert_eq!\(\s*\w+\s*,\s*", after)
            ev = lit_at(after, am.end()) if am and am.start() < 400 else None
            st = {m.group(1): m.group(2) for m in re.finditer(r"\b\w+\.(set_\w+)\(\s*([^)]*?)\s*\)", body[:rm2.start()])}
            method, opts, skip = map_settings(st)
            got += 1
            if skip:
                s.skip(skip); continue
            idx += 1
            s.add(f"{fname}:{fn}#{idx}", method, opts, "⟦" + keys_from_text(a1[0]) + "⟧" + to_keys(a2[0]),
                  f"core/tests/{fname}", ev[0] if ev else None,
                  "their restore_word(): text already on screen is loaded into the engine (like D20)")
        if got == 0:
            seq = raw_sequences(body)
            for keys_raw, st in seq:
                method, opts, skip = map_settings(st)
                got += 1
                if skip:
                    s.skip(skip); continue
                idx += 1
                if "src:bracketShortcut=on" in opts and any(c in BRACKETS for c in keys_raw):
                    idx -= 1
                    s.skip("D27: [ ] as ơ ư (their bracket shortcut on)")
                    continue
                s.add(f"{fname}:{fn}#{idx}", method, opts, keys_raw, f"core/tests/{fname}", None,
                      "key codes fed one by one; their checks are on engine result fields, not transcribed")
        if got == 0:
            unextracted[fname].append(fn)
    for c in set(consts) - used_consts:
        unextracted[fname].append("const " + c)

for f, fns in unextracted.items():
    s.skip(f"not extracted ({f}): tests driven by data files, generated permutations, raw key codes or engine-state checks", len([x for x in fns if not x.startswith("const ")]))
if REPORT:
    for f, fns in unextracted.items():
        print(f, fns)
s.write()
