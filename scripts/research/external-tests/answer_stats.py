"""Heuristic count of their expected outputs that break Vietnamese orthography
(docs/research/EXTERNAL-TEST-INPUTS.md section 6). Reads build/external-answers/ and the
public TSVs; prints counts only (SHOW=1 also prints sample answers to the terminal, for the
person doing the comparison step, never for the engine developer). Writes nothing.
Usage: python3 -I scripts/research/external-tests/answer_stats.py [source ...]"""
import csv, os, sys, unicodedata, collections, re

REPO = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "../../.."))
TONES = {"́": "s", "̀": "f", "̉": "r", "̃": "x", "̣": "j"}

ONSETS = set("b c ch d đ g gh gi h k kh l m n ng ngh nh p ph q qu r s t th tr v x kr".split()) | {""}
RIMES = set("""
a ac ach ai am an ang anh ao ap at au ay ăc ăm ăn ăng ăp ăt âc âm ân âng âp ât âu ây
e ec em en eng eo ep et ê êch êm ên ênh êp êt êu
i ia ich im in inh ip it iu iêc iêm iên iêng iêp iêt iêu
y yêm yên yêng yêt yêu
o oc oi om on ong op ot oa oac oach oai oam oan oang oanh oao oap oat oay oăc oăm oăn oăng oăt oe oen oeo oet oong ooc
ô ôc ôi ôm ôn ông ôp ôt ơ ơi ơm ơn ơp ơt
u ua uc ui um un ung up ut uân uâng uât uây uy uya uych uyên uyêt uyn uynh uyp uyt uyu uê uêch uênh uơ uôc uôi uôm uôn uông uôt
ư ưa ưc ưi ưm ưn ưng ưt ưu ươc ươi ươm ươn ương ươp ươt ươu ăk
""".split())
STOP = ("c", "ch", "p", "t", "k")


VOW = set("aăâeêioôơuưy")


def split_tone(word):
    """-> (toneless NFC base, tone letter, index in base of the toned letter)"""
    nfd = unicodedata.normalize("NFD", word)
    tone, letters, cur = None, [], ""
    tidx = None
    for ch in nfd:
        if unicodedata.combining(ch):
            if ch in TONES:
                if tone: return None, None, None
                tone = TONES[ch]; tidx = len(letters) - 1
            else:
                letters[-1] += ch
        else:
            letters.append(ch)
    base = [unicodedata.normalize("NFC", l) for l in letters]
    return "".join(base), tone, tidx


def parse(base):
    for on in sorted(ONSETS, key=len, reverse=True):
        if base.startswith(on):
            rime = base[len(on):]
            if on == "gi" and rime == "":
                return "g", "i"
            if on == "gi" and rime[:1] in ("ê",) :
                return on, rime
            if rime in RIMES and not (on in ("gh", "ngh") and rime[:1] not in ("i", "e", "ê")):
                return on, rime
            if on == "qu" and ("u" + rime) in RIMES | {"ua", "uy"} or (on == "qu" and rime in RIMES):
                return on, rime
    return None


def tone_index(on, rime, modern):
    """index inside rime that should carry the tone"""
    vs = [i for i, c in enumerate(rime) if c in VOW]
    if not vs: return None
    # glide-final vowels: i/y/o/u at the end after another vowel
    nucleus = vs
    for i in vs:
        if rime[i] in "ăâêôơư":
            # ươ, uô, iê, yê: second; single marked vowel: that one
            marked = [j for j in vs if rime[j] in "ăâêôơư"]
            return marked[-1]
    has_coda = vs[-1] < len(rime) - 1
    if len(vs) == 1: return vs[0]
    if len(vs) == 3: return vs[1]
    if has_coda: return vs[-1]
    pair = rime[vs[0]] + rime[vs[1]]
    if pair in ("oa", "oe", "uy"):
        return vs[1] if modern else vs[0]
    if on == "qu" and pair in ("ua",):  # not reached: qu takes u
        return vs[1]
    return vs[0]


def check(word, modern):
    """0 ok, 1 not a syllable, 2 tone on the wrong letter, 3 tone not allowed with stop coda"""
    w = word.lower()
    base, tone, tidx = split_tone(w)
    if base is None: return 1
    p = parse(base)
    if not p: return 1
    on, rime = p
    if tone in ("f", "r", "x") and rime.endswith(STOP): return 3
    if tone:
        want = tone_index(on, rime, modern)
        if want is not None and tidx != len(on) + want:
            # both styles accepted when the style is not the point: only flag if wrong in both
            alt = tone_index(on, rime, not modern)
            return 2 if tidx != len(on) + alt else 4
    return 0


def valid(word):
    return check(word, True) in (0, 2, 4) and check(word, False) in (0, 2, 4)


def has_viet(word):
    return any(ord(c) > 127 and unicodedata.category(c).startswith("L") for c in word)


def words(text):
    return re.findall(r"[^\W\d_]+", text)


src = sys.argv[1:] or sorted(f[:-4] for f in os.listdir(os.path.join(REPO, "build/external-answers")))
for name in src:
    pub = {r["id"]: r for r in csv.DictReader(open(os.path.join(REPO, "docs/research/external-test-inputs", name + ".tsv"), encoding="utf-8"), delimiter="\t")}
    cnt, total, sample = collections.Counter(), 0, collections.defaultdict(list)
    for r in csv.DictReader(open(os.path.join(REPO, "build/external-answers", name + ".tsv"), encoding="utf-8"), delimiter="\t"):
        exp = r["their_expected"].replace("␣", " ").replace("⏎", "\n")
        p = pub[r["id"]]
        keys = p["keys"]
        if not exp:
            continue
        modern = "tone=classic" not in p["options"]
        final = keys.endswith(("␣", "⏎", ".", ",", "!", "?")) or "src:dictionary" in p["options"]
        res = set()
        for w in words(exp):
            if not has_viet(w): continue
            c = check(w, modern)
            if c == 1 and not final: continue
            if c: res.add(c)
        if final: total += 1
        for c in res:
            cnt[c] += 1
            sample[c].append((r["id"], keys, exp[:40]))
    print(name, "final:", total, "| not-a-syllable(final only):", cnt[1], "| tone on wrong letter (any style):", cnt[2],
          "| other style than option:", cnt[4], "| huyền/hỏi/ngã with p,t,c,ch:", cnt[3])
    if os.environ.get("SHOW"):
        for c in (2, 3, 4):
            for x in sample[c][:15]:
                print("   ", c, x)
