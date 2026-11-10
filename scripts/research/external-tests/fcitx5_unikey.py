import sys, os, re
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import Sink, BRACKETS

ROOT = sys.argv[1]  # clone of fcitx/fcitx5-unikey
s = Sink("fcitx5-unikey")
ref = "test/testunikey.cpp"
src = open(os.path.join(ROOT, ref), encoding="utf-8").read()

C = "tone=classic"
SP = "src:spellcheck=off"

# testBasic, in order. Config accumulates in one RawConfig object.
basic = [
    ("awo␣", [C, SP], "ăo "),
    ("baao␣", [C, SP], "âo "),
    ("awo␣", [C, SP], "ăo "),
    ("awo⏎", [C, SP], "ăo"),
    ("awoo␣", [C], "awoo "),
    ("awo⏎", [C], "awo"),
    ("aao⏎", [C], "aao"),
    ("aao⏎", [C], "aao"),
    ("aao⏎", [C], "aao"),
    ("aao⏎", [C], "aao"),
    ("aaoß", [C], "aao"),
]
# With Macro off and ModifySurroundingText off, their engine sends a consonant typed at the
# start of a word straight to the app (word auto-commit in src/unikey-im.cpp) instead of
# committing it, so for "baao␣" the commit queue holds only "âo␣": the b is on screen but not
# in their expectation (the macro setting changes before the 2nd group, ModifySurroundingText
# stays off until the surrounding-text cases).
for i, (k, o, e) in enumerate(basic, 1):
    note = "commit expectations are a queue; pairing with key groups is by order (our reading)"
    if i == 2:
        note = ("committed part only: the first key b goes straight to the app (their auto-commit of a"
                " word-initial consonant), the commit queue holds the rest")
    s.add(f"testunikey.cpp:testBasic#{i}", "telex", o, k, ref, e, note)

# expectedTelexData: active (uncommented) entries; run with AutoNonVnRestore=False, SpellCheck=False, each + Return.
m = re.search(r"expectedTelexData\{(.*?)\n\};", src, re.S)
body = m.group(1)
active = re.findall(r'^\s*\{"([^"]*)",\s*"([^"]*)"\},?\s*$', body, re.M)
disabled = re.findall(r'^\s*//\s*\{"([^"]*)",\s*"([^"]*)"\}', body, re.M)
for k, e in active:
    if any(c in BRACKETS for c in k):
        s.skip("D27: [ ] { } as ơ ư")
        continue
    s.add(f"testunikey.cpp:expectedTelexData:{k}", "telex", [C, "autoRestore=off", SP], k + "⏎", ref, e,
          "committed with Return")
s.skip("expectedTelexData entries commented out in their source (not run by their test)", len(disabled))

# Surrounding-text cases at the end of testBasic (config: AutoNonVnRestore=False, SpellCheck=False).
sur = [
    ("⟦q⟧uer⏎", [C, "autoRestore=off", SP, "src:modifySurroundingText=off"], "uẻ"),
    ("⟦reset⟧e⏎", [C, "autoRestore=off", SP, "src:modifySurroundingText=off"], "e"),
    ("⟦nga⟧r⏎", [C, "autoRestore=off", SP], "ngả"),
    ("⟦ngả nghieng⟧e⏎", [C, "autoRestore=off", SP], "nghiêng"),
    ("⟦ngả|␣nghieng⟧s⏎", [C, "autoRestore=off", SP], "ngá"),
    ("⟦application⟧s⏎", [C, "autoRestore=off", SP], "s"),
]
for i, (k, o, e) in enumerate(sur, 1):
    s.add(f"testunikey.cpp:testBasic.surrounding#{i}", "telex", o, k.replace("ngả nghieng⟧", "ngả␣nghieng⟧"), ref, e,
          "their expectation is the committed part only; text before the cursor is not in it")

s.add("testunikey.cpp:testType#1", "telex", [C, "autoRestore=off", SP], "f0⌫", ref, None, "no expectation in their test")
s.write()
print("active", len(active), "disabled", len(disabled))
