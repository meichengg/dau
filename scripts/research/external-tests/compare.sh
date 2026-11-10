#!/bin/zsh
# Compare Dấu's output on the external test inputs with the other projects' expected output.
# Side effects: builds
#
# Usage: scripts/research/external-tests/compare.sh [--set FILE]... [source...]
#   --set FILE   hand classifications to apply (TSV: source, id, class, rule_notes)
#   source       e.g. gonhanh uvie-rs (default: every TSV in docs/research/external-test-inputs)
#
# Reads docs/research/external-test-inputs/<source>.tsv (keys), build/external-dau-output/<source>.tsv
# (Dấu's output, written by the engine's ExternalCasesTests) and build/external-answers/<source>.tsv
# (their expected output, written by extract.sh), joins them by id, normalises by their_note
# (what their test checks), compares in NFC, and writes build/external-review/<source>.tsv
# (git-ignored; it holds their answers). A disagreement keeps the class (A–E, X) of the previous
# review file when keys, Dấu output and their expected text are unchanged; otherwise it is
# "unreviewed" (with the old class in rule_notes). Prints the per-source counts and the
# per-class table of docs/research/EXTERNAL-TEST-INPUTS.md section 9.2.
# Writes only under build/ (git-ignored; hence "builds", though nothing is compiled). Runs nothing
# from the other projects.
set -euo pipefail
source "${0:A:h:h:h}/lib/log.sh"
python3 -I ${0:A:h}/compare.py "$@"
log_done
