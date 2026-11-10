"""Shared writer for external test inputs (scripts/research/external-tests/extract.sh).
Reads nothing executable; only writes TSV and a JSON of counts.

Public file:  docs/research/external-test-inputs/<source>.tsv
              columns: id, method, options, keys, source_ref
Answers file: build/external-answers/<source>.tsv (git-ignored)
              columns: id, their_expected, their_note
"""
import os, sys, json, collections

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../.."))
PUB = os.path.join(REPO, "docs/research/external-test-inputs")
ANS = os.path.join(REPO, "build/external-answers")
STATS = os.path.join(REPO, "build/external-tests-stats")  # counts and skip reasons, no answers

METHODS = {"telex", "vni", "simple-telex"}
BRACKETS = set("[]{}")


def keys_from_text(s):
    """Literal typed text -> key notation. Space, Tab, Return get symbols."""
    return s.replace(" ", "␣").replace("\t", "⇥").replace("\n", "⏎").replace("\r", "⏎")


def clean(field):
    assert "\t" not in field and "\n" not in field, repr(field)
    return field


class Sink:
    def __init__(self, source):
        self.source = source
        self.rows = []
        self.ids = set()
        self.skipped = collections.Counter()
        self.seen = {}

    def skip(self, reason, n=1):
        self.skipped[reason] += n

    def add(self, id, method, options, keys, ref, expected=None, note=""):
        assert method in METHODS, method
        assert keys, id
        if id in self.ids:
            raise SystemExit(f"duplicate id {id}")
        self.ids.add(id)
        if isinstance(options, (list, tuple)):
            options = ";".join(o for o in options if o)
        self.rows.append(dict(id=id, method=method, options=options or "", keys=keys,
                              ref=ref, expected=expected, note=note))

    def write(self):
        os.makedirs(PUB, exist_ok=True)
        os.makedirs(ANS, exist_ok=True)
        os.makedirs(STATS, exist_ok=True)
        with open(os.path.join(PUB, self.source + ".tsv"), "w", encoding="utf-8") as f:
            f.write("id\tmethod\toptions\tkeys\tsource_ref\n")
            for r in self.rows:
                f.write("\t".join(clean(x) for x in (r["id"], r["method"], r["options"], r["keys"], r["ref"])) + "\n")
        with open(os.path.join(ANS, self.source + ".tsv"), "w", encoding="utf-8") as f:
            f.write("id\ttheir_expected\ttheir_note\n")
            for r in self.rows:
                exp = "" if r["expected"] is None else keys_from_text(r["expected"])
                f.write("\t".join(clean(x) for x in (r["id"], exp, r["note"])) + "\n")
        by_method = collections.Counter(r["method"] for r in self.rows)
        with_answer = sum(1 for r in self.rows if r["expected"] is not None)
        stats = dict(source=self.source, total=len(self.rows), by_method=by_method,
                     with_answer=with_answer, skipped=self.skipped,
                     options=collections.Counter(r["options"] for r in self.rows))
        with open(os.path.join(STATS, self.source + ".json"), "w") as f:
            json.dump(stats, f, ensure_ascii=False, indent=1)
        print(json.dumps(stats, ensure_ascii=False))
