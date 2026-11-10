#!/bin/zsh
# Xcode build phase (project.yml, Dau and DauInputMethod, before the other phases).
# Side effects: builds
# It writes the git commit the build comes from to build/generated/BuildCommit.txt, short
# hash, with "+" when tracked files had uncommitted changes ("6d7bf97+"). Both targets
# copy the file into their Resources, so a new commit is copied and the bundle signed
# again like any changed resource (stamping the built Info.plist after the fact broke
# the signature of builds that had nothing else to re-sign). The app shows the commit
# next to the version; scripts/dev/dau-version.sh reads it from the installed bundles.
#
# The file is rewritten only when the commit changes, so it costs no rebuild otherwise.
# Without git (or outside a checkout) it holds an empty string and the version shows alone.
set -uo pipefail
# Also run by xcodegen (preGenCommand) from the repo root, without SRCROOT.
SRCROOT=${SRCROOT:-${0:A:h:h:h}}
out="${SRCROOT}/build/generated/BuildCommit.txt"
mkdir -p "${out:h}"
commit=$(git -C "$SRCROOT" rev-parse --short=7 HEAD 2>/dev/null) || commit=""
if [[ -n $commit && -n $(git -C "$SRCROOT" status --porcelain --untracked-files=no 2>/dev/null) ]]; then
  commit+="+"
fi
[[ -f "$out" && "$(<"$out")" == "$commit" ]] || print -rn -- "$commit" > "$out"
