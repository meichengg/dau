#!/bin/zsh
# Prints the team ID (OU field) of a signing certificate, nothing when the identity is
# self-signed. The team ID decides the App Group name, which is why CI cannot hard-code it:
# the certificate belongs to whoever's secrets are installed, not to the repo.
# Side effects: none
#
# Usage: scripts/release/team-id.sh <signing identity>
set -uo pipefail

identity=$1
[[ -n $identity ]] || { print -u2 -- 'dùng: team-id.sh <identity>'; exit 2 }
out=$(security find-certificate -c "$identity" -p 2>/dev/null) || exit 0
[[ -n $out ]] || exit 0
print -r -- "$out" | openssl x509 -noout -subject 2>/dev/null \
  | sed -n 's/.*OU *= *\([^,]*\).*/\1/p'
exit 0
