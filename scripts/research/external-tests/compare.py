"""Step 3 of docs/research/EXTERNAL-TEST-INPUTS.md: join the key sequences, Dấu's output and the
other projects' expected output per case, normalise by `their_note`, and count agreement.
Called by compare.sh (python3 -I). Reads only TSVs; writes build/external-review/<source>.tsv.

Classes (section 9 of the doc): agree, no-answer, A–E, X (with a rule note "X-…"), and
"unreviewed" for a disagreement nobody has classified yet. Classification needs judgement:
this script only carries a class forward from the previous review file when the case is the
same (same keys, same Dấu output, same expected text), and applies hand classifications given
with --set FILE (TSV: source, id, class, rule_notes).
"""
import argparse, collections, os, re, sys, unicodedata

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../.."))
SEP = "␣⏎⇥"
CLASSES = ["A", "B", "C", "D", "E", "X"]


def read_tsv(path):
    if not os.path.exists(path):
        return {}
    rows = {}
    with open(path, encoding="utf-8") as f:
        head = f.readline().rstrip("\n").split("\t")
        for line in f:
            cols = line.rstrip("\n").split("\t")
            cols += [""] * (len(head) - len(cols))
            rows[cols[0]] = dict(zip(head, cols))
    return rows, head


def load(path):
    r = read_tsv(path)
    return r[0] if r else {}


def nfc(s):
    return unicodedata.normalize("NFC", s)


def last_word(s):
    return re.split("[" + SEP + "]", s)[-1]


def normalise(dau, their, note, keys=""):
    """Return (dau', their') to compare, following what their test checks (their_note)."""
    commit = re.search(r"committed with Return|commit on Return|committed part only|commit expectations are a queue", note)
    if commit:
        # text after the cursor (⟦before|after⟧) stays after the committed text; drop it
        m = re.match(r"⟦[^⟧|]*\|([^⟧]*)⟧", keys)
        if m and m.group(1) and dau.endswith(m.group(1)):
            dau = dau[:-len(m.group(1))]
        # the key that commits (Return, ß…) is not part of the committed text
        if keys and dau.endswith(keys[-1]) and not their.endswith(keys[-1]):
            dau = dau[:-1]
    if "harness types a final Space and drops one trailing space" in note:
        if dau.endswith("␣"):
            dau = dau[:-1]
        if dau[-1:] in ("⏎", "⇥") and not their.endswith(dau[-1]):
            dau = dau[:-1]
    if re.search(r"current word only|^preedit|; preedit$|buffer view", note):
        if not any(c in their for c in SEP):
            return last_word(dau), their
    if re.search(r"covers only the (output of the )?last \d+ keys|committed part only", note):
        return (their if dau.endswith(their) else dau), their
    return dau, their


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--set", action="append", default=[], help="hand classifications: TSV source, id, class, rule_notes")
    ap.add_argument("sources", nargs="*")
    a = ap.parse_args()
    pub = os.path.join(REPO, "docs/research/external-test-inputs")
    out_dir = os.path.join(REPO, "build/external-review")
    os.makedirs(out_dir, exist_ok=True)
    sources = a.sources or sorted(f[:-4] for f in os.listdir(pub) if f.endswith(".tsv"))
    manual = collections.defaultdict(dict)
    for p in a.set:
        with open(p, encoding="utf-8") as f:
            for line in f:
                if not line.strip() or line.startswith("#"):
                    continue
                c = line.rstrip("\n").split("\t")
                manual[c[0]][c[1]] = (c[2], c[3] if len(c) > 3 else "")
    table, ctable = [], []
    for src in sources:
        inp = load(os.path.join(pub, src + ".tsv"))
        dau = load(os.path.join(REPO, "build/external-dau-output", src + ".tsv"))
        ans = load(os.path.join(REPO, "build/external-answers", src + ".tsv"))
        prev = load(os.path.join(out_dir, src + ".tsv"))
        if not inp or not dau or not ans:
            sys.exit(f"{src}: missing inputs, Dấu output or answers (run extract.sh and the engine's ExternalCasesTests)")
        rows, cnt, cls = [], collections.Counter(), collections.Counter()
        for id, r in inp.items():
            if id not in dau or id not in ans:
                sys.exit(f"{src}: {id} missing from Dấu output or answers; re-run extract.sh, then ExternalCasesTests")
            d = nfc(dau[id]["dau_output"])
            t = nfc(ans[id]["their_expected"])
            note = ans[id]["their_note"]
            has_src = any(o.startswith("src:") for o in r["options"].split(";") if o)
            notes = ""
            if not t:
                c = "no-answer"
                notes = "their test checks no text" + (f" ({note})" if note else "")
            else:
                dn, tn = normalise(d, t, note, r["keys"])
                if dn == tn:
                    c = "agree"
                else:
                    c = "unreviewed"
                    p = prev.get(id)
                    if p and p["class"] in CLASSES + ["unreviewed"]:
                        same = (p["keys"], nfc(p["dau_output"]), nfc(p["their_expected"])) == (r["keys"], d, t)
                        if same:
                            c, notes = p["class"], p["rule_notes"]
                        elif p["class"] != "unreviewed":
                            notes = f"was {p['class']} with keys {p['keys']} and Dấu output {p['dau_output']}: {p['rule_notes']}"
                    if id in manual[src]:
                        c, notes = manual[src][id]
            rows.append((id, r["keys"], d, t, c, notes))
            if c == "no-answer":
                cnt["no-answer"] += 1
            else:
                cnt[("agree" if c == "agree" else "differ") + ("-src" if has_src else "")] += 1
            if c not in ("agree", "no-answer"):
                cls[c] += 1
        with open(os.path.join(out_dir, src + ".tsv"), "w", encoding="utf-8") as f:
            f.write("id\tkeys\tdau_output\ttheir_expected\tclass\trule_notes\n")
            for row in rows:
                f.write("\t".join(row) + "\n")
        table.append((src, len(rows), cnt["no-answer"], cnt["agree"], cnt["differ"], cnt["agree-src"], cnt["differ-src"]))
        ctable.append((src, *[cls[k] for k in CLASSES], cls["unreviewed"]))

    def fmt(n):
        return f"{n:,}".replace(",", ".")
    print("| Nguồn | Ca | Họ không kiểm chữ | Khớp, không `src:` | Khác, không `src:` | Khớp, có `src:` | Khác, có `src:` |")
    print("|---|---|---|---|---|---|---|")
    for r in sorted(table, key=lambda x: -x[1]):
        print("| " + " | ".join([r[0]] + [fmt(x) for x in r[1:]]) + " |")
    tot = [sum(r[i] for r in table) for i in range(1, 7)]
    print("| **Tổng** | " + " | ".join(f"**{fmt(x)}**" for x in tot) + " |")
    print()
    print("| Nguồn | A | B | C | D | E | X | chưa xếp |")
    print("|---|---|---|---|---|---|---|---|")
    order = {r[0]: -r[1] for r in table}
    for r in sorted(ctable, key=lambda x: order[x[0]]):
        print("| " + " | ".join([r[0]] + [fmt(x) for x in r[1:]]) + " |")
    tot = [sum(r[i] for r in ctable) for i in range(1, 8)]
    print("| **Tổng** | " + " | ".join(f"**{fmt(x)}**" for x in tot) + " |")


if __name__ == "__main__":
    main()
