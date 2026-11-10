#!/bin/zsh
# Extract test inputs (key sequences) from other Vietnamese input methods' test suites.
# Side effects: writes repo files
#
# Usage: scripts/research/external-tests/extract.sh
#   EXT_IME_DIR=/some/dir overrides the clone directory (default /tmp/ext-ime).
#
# Fetches each source below at its pinned commit from GitHub into $EXT_IME_DIR/<name>
# (network; a clone already at the pinned commit is reused, any other is replaced), then
# reads their test files as plain text with the Python helpers in this directory
# (python3 -I). Nothing from the clones is built, run or imported; git hooks are disabled.
# Writes:
#   docs/research/external-test-inputs/<source>.tsv   key sequences, no expected outputs (committed)
#   build/external-answers/<source>.tsv               their expected outputs (git-ignored)
#   build/external-tests-stats/<source>.json          counts and skip reasons (git-ignored)
# With the pinned commits it re-creates the committed TSVs byte for byte
# (git diff --stat docs/research/external-test-inputs is empty afterwards).
# Method, notation, licences: docs/research/EXTERNAL-TEST-INPUTS.md; attribution:
# docs/research/external-test-inputs/NOTICE.md.
set -euo pipefail
here=${0:A:h}
source "${0:A:h:h:h}/lib/log.sh"
base=${EXT_IME_DIR:-/tmp/ext-ime}
mkdir -p $base

# name url commit
sources=(
  bamboo-core   https://github.com/BambooEngine/bamboo-core.git   b2e49a2b48c7d3772a3673142a7747eccd9d5f79
  ibus-bamboo   https://github.com/BambooEngine/ibus-bamboo.git   49e03d7a36b8a8b796950c158b545af8cf9707d4
  fcitx5-unikey https://github.com/fcitx/fcitx5-unikey.git        ed9170c35c1a6275d105e03d7f9bc4f674c1469c
  goxkey        https://github.com/huytd/goxkey.git               b197c57218ceb9096c341a9862acfabf7cb6932b
  vi-rs         https://github.com/zerox-dg/vi-rs.git             192e246d37e83094a1228e798b160f3cee14c879
  ibus-teni     https://github.com/teni-ime/ibus-teni.git         a3824854c0f5e85dcfea66d984b9bad0c16c2bf2
  uvie-rs       https://github.com/uvie-project/uvie-rs.git       555ef9dd31b6bf208343a70484e84db79f1bddfe
  ibus-telex    https://github.com/manhavn/ibus-telex.git         fb522b4804c2ef8496ec8746f7b1e4043b3716c2
  gonhanh.org   https://github.com/khaphanspace/gonhanh.org.git   1fdac7aec67663f2c23df6addfb13c59bbc5f374
  xkey          https://github.com/xmannv/xkey.git                398e78e9c1a92f740d5cbf1673914a3b3c458eff
)

fetch() {
  local name=$1 url=$2 sha=$3 dir=$base/$1
  if [[ -d $dir/.git ]] && [[ $(git -C $dir rev-parse HEAD 2>/dev/null) == $sha ]]; then
    return
  fi
  rm -rf $dir
  mkdir -p $dir
  git -C $dir init -q
  GIT_TERMINAL_PROMPT=0 git -C $dir -c core.hooksPath=/dev/null fetch -q --depth 1 $url $sha
  git -C $dir -c core.hooksPath=/dev/null -c advice.detachedHead=false checkout -q FETCH_HEAD
}

for name url sha in $sources; do
  log_step "$name $sha"
  fetch $name $url $sha
done

py() { python3 -I $here/$1 ${@:2} | cut -c1-160 }
py vi_rs.py         $base/vi-rs
py teni.py          $base/ibus-teni
py ibus_telex.py    $base/ibus-telex
py fcitx5_unikey.py $base/fcitx5-unikey
py manual.py        $base/ibus-bamboo   # also bamboo-core and goxkey (transcribed by hand at the pinned commits)
py gonhanh.py       $base/gonhanh.org
py uvie.py          $base/uvie-rs
py xkey.py          $base/xkey
log_done
log_hint "So với bản đã commit: git diff --stat docs/research/external-test-inputs"
