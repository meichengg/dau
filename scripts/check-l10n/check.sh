#!/bin/zsh
# Checks the String Catalogs of the app and the input method (D41).
# Side effects: none
#
# Usage: scripts/check-l10n/check.sh [<build-dir>]
#
# For every Apps/**/*.xcstrings:
#   1. sourceLanguage is "en" (English keys, Vietnamese translation);
#   2. every key, except those marked shouldTranslate false, has an "en" and a "vi"
#      text, and every text (each plural or device variation included) is in state
#      "translated": none left "new", "needs_review" or "stale";
#   3. every text has the format specifiers (%@, %lld, …) of its reference, in the same
#      argument order (positions like %2$@ reorder them): the key itself in Localizable
#      catalogs, the "en" text in InfoPlist catalogs. A plural form may leave its number
#      out ("one");
#   4. no key is marked stale (Xcode no longer finds it in the code);
#   5. keys and "en" texts hold no Vietnamese besides the phrases listed in
#      allowed-vietnamese.txt (docs/GLOSSARY.md, "Không dịch");
#   6. the name is "Dấu" in every language (D24, a brand like Phở): no text, and no key
#      of a Localizable catalog, has "Dau" without diacritics as a word (technical ids
#      like com.codefastlabs.dau are fine; "dầu", "đau" are real Vietnamese words).
# With <build-dir> (a DerivedData or build/…noindex directory of a finished build), also:
#   7. every key the compiler extracted from the code (*.stringsdata) is in the catalog
#      of its target, and the reverse, so no text shows its English key untranslated
#      and no entry is left over.
# Exit status 0 only if every check passes; the failures are listed one per line.
# Output (Vietnamese, via scripts/lib/log.sh): "✗" heading, "    " detail lines, verdict line.
set -uo pipefail
here=${0:A:h}
root=${here:h:h}
cd "$root"
source "$root/scripts/lib/log.sh"
fail=0

catalogs=(Apps/**/*.xcstrings(N))
if (( ${#catalogs} == 0 )); then
  log_die "Không có file .xcstrings nào dưới Apps/"
fi

allowed=$(grep -vE '^(#|$)' $here/allowed-vietnamese.txt | jq -R . | jq -s .)

for file in $catalogs; do
  out=$(jq -r --arg file "$file" --argjson allowed "$allowed" '
    # Format specifiers of a text in argument order, positions dropped
    # ("%2$@ %1$lld" → ["%lld","%@"]; "%@ %lld" → ["%@","%lld"]).
    def specs: [gsub("%%"; "") | scan("%(?:([0-9]+)\\$)?(ll[du]|l[du]|[@dufxXs]|\\.[0-9]+f)")]
               | to_entries | map({i: (if .value[0] then (.value[0] | tonumber) else .key + 1 end),
                                   s: ("%" + .value[1])})
               | sort_by(.i) | map(.s);
    # Vietnamese letters left once the allowed phrases are taken out.
    def vietnamese: reduce $allowed[] as $a (.; split($a) | join(""))
                    | test("[àáảãạăắằẳẵặâấầẩẫậđèéẻẽẹêếềểễệìíỉĩịòóỏõọôốồổỗộơớờởỡợùúủũụưứừửữựỳýỷỹỵ]"; "i");
    # Every text of one language: (path label, unit) pairs, variations included.
    def units: [(if has("stringUnit") then {where: "", unit: .stringUnit} else empty end),
                (paths(objects and has("stringUnit")) as $p
                 | {where: ($p | map(tostring) | join(".")), unit: (getpath($p).stringUnit)})];
    (if .sourceLanguage != "en" then "\($file): sourceLanguage là \(.sourceLanguage), phải là en" else empty end),
    (.strings | to_entries[] | select(.value.extractionState == "stale")
     | "\($file): \(.key): stale (mã không còn dùng)"),
    (.strings | to_entries[]
     | .key as $key
     | ([$key] + [.value.localizations.en // {} | .. | .value? // empty | strings] | unique)[]
     | select(vietnamese)
     | "\($file): \($key): có tiếng Việt trong khoá hoặc bản en: \(.)"),
    (.strings | to_entries[]
     | .key as $key
     | ((if ($file | test("InfoPlist")) then [] else [$key] end)
        + [.value.localizations // {} | .. | .value? // empty | strings] | unique)[]
     | select(test("(^|[^.\\p{L}])dau($|[^.\\p{L}])"; "i"))
     | "\($file): \($key): tên phải viết Dấu (D24): \(.)"),
    (.strings | to_entries[] | select(.value.shouldTranslate != false)
     | .key as $key | (.value.localizations // {}) as $loc
     | ($loc.en // {} | units) as $en
     | (if ($file | test("InfoPlist")) then
          ($en | map(select(.where == "" or (.where | endswith("other")))) | first // {unit: {value: ""}} | .unit.value // "")
        else $key end | specs) as $ref
     | ("en", "vi") as $lang
     | ($loc[$lang] // {} | units) as $units
     | if ($units | length) == 0 then "\($file): \($key): thiếu bản \($lang)"
       else $units[]
         | (if .unit.state != "translated" then "\($file): \($key): \($lang)\(if .where == "" then "" else " " + .where end) có trạng thái \(.unit.state // "không có")" else empty end),
           ((.unit.value // "" | specs) as $got
            | if (.where | test("plural")) then
                (if ($got - $ref) != [] then "\($file): \($key): \($lang) \(.where) có \($got), khoá có \($ref)" else empty end)
              elif $got != $ref then "\($file): \($key): \($lang)\(if .where == "" then "" else " " + .where end) có \($got), cần \($ref)"
              else empty end)
       end)
  ' "$file" 2>&1)
  if (( $? != 0 )); then
    log_error "$file: không đọc được: $out"
    fail=1
  elif [[ -n $out ]]; then
    log_error "Catalog $file có chỗ không đạt:"
    log_detail "${(@f)out}"
    fail=1
  fi
done

# 4. Keys the compiler extracted (Swift's -emit-localized-strings), per target.
if (( $# > 0 )); then
  build=${1:A}
  for target in Dau DauInputMethod; do
    catalog=Apps/$target/Resources/Localizable.xcstrings
    files=($build/**/$target.build/Objects-normal/**/*.stringsdata(N))
    if (( ${#files} == 0 )); then
      log_error "$target: không có .stringsdata dưới $build (build scheme trước)"
      fail=1
      continue
    fi
    extracted=$(for f in $files; do plutil -convert json -o - "$f" 2>/dev/null; print; done \
      | jq -r 'select(type == "object") | .tables? // {} | to_entries[] | select(.key == "Localizable") | .value[] | .key' | sort -u)
    known=$(jq -r '.strings | keys[]' "$catalog" | sort -u)
    missing=$(comm -23 <(print -r -- "$extracted") <(print -r -- "$known") | sed '/^$/d')
    unused=$(comm -13 <(print -r -- "$extracted") <(print -r -- "$known") | sed '/^$/d')
    if [[ -n $missing ]]; then
      log_error "$target: có trong mã, không có trong $catalog:"
      log_detail "${(@f)missing}"
      fail=1
    fi
    if [[ -n $unused ]]; then
      log_error "$target: có trong $catalog, không có trong mã:"
      log_detail "${(@f)unused}"
      fail=1
    fi
  done
fi

if (( fail == 0 )); then
  log_ok "String Catalog khớp (${#catalogs} catalog)."
else
  log_error "String Catalog không đạt: sửa các chỗ trên rồi chạy lại."
fi
exit $fail
