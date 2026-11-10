// Builds the typing cases for scripts/research/compare-ims/run.sh and scores the result;
// run.sh builds this file once with scripts/lib/swift-tool.sh.
//
//   cases keys            prints the Telex keys of every case, one line
//   cases expect          prints the text the keys must give, one line
//   cases score FILE...   scores the text read back from each run
//
// Cases: vi-sentences.txt (group "vi"), mixed-sentences.txt ("mixed"), en-words.txt ("en"),
// read from the folder this source file is in (its path is compiled in with #filePath).
// Vietnamese letters become standard-order Telex: aa ee oo aw ow uw dd for the letters,
// the tone key (s f r x j) at the end of the word, modifier keys in lower case after a
// capital ("Đ" → "Dd"). ASCII tokens are typed as they are. Tokens are separated by one
// space and the line ends with a space, so every word is ended.
//
// Scoring compares token by token after NFC and after moving the tone mark out of the
// word, so old and new tone placement ("hòa", "hoà") both count as right. That also hides
// a tone placed on the wrong vowel: it is a limit of this comparison, not a finding.
// Tokens are aligned the way Python's difflib.SequenceMatcher (no junk) does it, so the
// score matches the one the earlier Python helper gave.
import Foundation

func fail(_ message: String, code: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(code)
}

let usage = """
    Cách dùng:
      cases keys            phím Telex của mọi ca, một dòng
      cases expect          chữ mà các phím phải cho ra, một dòng
      cases score FILE...   chấm chữ đọc lại của từng lượt
    """

/// The folder of this source file, recorded at compile time: the case files sit next to it.
let here = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let groups = [("vi", "vi-sentences.txt"), ("mixed", "mixed-sentences.txt"), ("en", "en-words.txt")]
let tones: [Unicode.Scalar: String] = ["\u{301}": "s", "\u{300}": "f", "\u{309}": "r", "\u{303}": "x", "\u{323}": "j"]
let punctuation: Set<Unicode.Scalar> = [".", ",", "?", "!", ":", ";"]

func nfc(_ s: String) -> String { s.precomposedStringWithCanonicalMapping }
func nfd(_ s: String) -> String { s.decomposedStringWithCanonicalMapping }

// MARK: Text as Python's str sees it (code points)

/// Python's str.isspace().
func isSpace(_ c: Unicode.Scalar) -> Bool { c.properties.isWhitespace || (0x1C...0x1F).contains(c.value) }

/// Python's str.split() with no argument.
func words(_ s: Substring) -> [String] {
    s.unicodeScalars.split(whereSeparator: isSpace).map { String(String.UnicodeScalarView($0)) }
}

/// Python's str.splitlines().
func lines(_ s: String) -> [Substring] {
    let breaks: Set<UInt32> = [0x0A, 0x0B, 0x0C, 0x0D, 0x1C, 0x1D, 0x1E, 0x85, 0x2028, 0x2029]
    var out: [Substring] = []
    let scalars = s.unicodeScalars
    var start = scalars.startIndex, i = start
    while i < scalars.endIndex {
        let c = scalars[i]
        guard breaks.contains(c.value) else { i = scalars.index(after: i); continue }
        out.append(Substring(scalars[start..<i]))
        var next = scalars.index(after: i)
        if c == "\r", next < scalars.endIndex, scalars[next] == "\n" { next = scalars.index(after: next) }
        start = next; i = next
    }
    if start < scalars.endIndex { out.append(Substring(scalars[start...])) }
    return out
}

/// Python's str.strip() with no argument.
func strip(_ s: Substring) -> Substring {
    let scalars = s.unicodeScalars
    guard let first = scalars.firstIndex(where: { !isSpace($0) }),
          let last = scalars.lastIndex(where: { !isSpace($0) }) else { return "" }
    return Substring(scalars[first...last])
}

func read(_ url: URL) -> String {
    guard let data = FileManager.default.contents(atPath: url.path),
          let text = String(data: data, encoding: .utf8) else { fail("Không đọc được \(url.path)") }
    return text
}

/// Code point equality (String == treats canonically equivalent strings as equal).
func same(_ a: String, _ b: String) -> Bool { a.unicodeScalars.elementsEqual(b.unicodeScalars) }

// MARK: Cases

func tokens() -> [(group: String, token: String)] {
    var seen: [[UInt32]] = []
    var out: [(String, String)] = []
    for (group, name) in groups {
        for raw in lines(read(here.appendingPathComponent(name))) {
            let line = strip(raw)
            if line.isEmpty || line.unicodeScalars.first == "#" { continue }
            if group == "en" {
                let key = line.unicodeScalars.map(\.value)
                if seen.contains(key) { continue }
                seen.append(key)
            }
            for w in words(line) { out.append((group, nfc(w))) }
        }
    }
    return out
}

func telexWord(_ word: String) -> String {
    if word.unicodeScalars.allSatisfy(\.isASCII) { return word }
    var core = Array(word.unicodeScalars)
    var tail: [Unicode.Scalar] = []
    while let last = core.last, punctuation.contains(last) { tail.insert(core.removeLast(), at: 0) }
    var keys = ""
    var tone = ""
    for ch in core {
        if ch == "đ" || ch == "Đ" {
            keys += ch == "Đ" ? "Dd" : "dd"
            continue
        }
        let parts = Array(nfd(String(ch)).unicodeScalars)
        let base = String(parts[0])
        keys += base
        for mark in parts.dropFirst() {
            if let key = tones[mark] {
                tone = key
            } else if mark == "\u{302}" {
                keys += base.lowercased()
            } else if mark == "\u{306}" || mark == "\u{31B}" {
                keys += "w"
            } else {
                fail("Không chuyển được dấu U+\(String(format: "%04X", mark.value)) trong \"\(word)\"")
            }
        }
    }
    var scalars = String.UnicodeScalarView()
    scalars.append(contentsOf: tail)
    return keys + tone + String(scalars)
}

/// NFC token with the tone mark taken out and appended, so tone placement is ignored.
func canon(_ token: String) -> String {
    var tone = ""
    var kept = String.UnicodeScalarView()
    for ch in nfd(token).unicodeScalars {
        if let key = tones[ch] { tone = key } else { kept.append(ch) }
    }
    return nfc(String(kept)) + (tone.isEmpty ? "" : "/" + tone)
}

// MARK: Alignment: difflib.SequenceMatcher(a, b, autojunk=False), no junk

struct Matcher {
    let a: [Int], b: [Int]
    var b2j: [Int: [Int]] = [:]

    init(a: [Int], b: [Int]) {
        self.a = a; self.b = b
        for (j, element) in b.enumerated() { b2j[element, default: []].append(j) }
    }

    func longestMatch(_ alo: Int, _ ahi: Int, _ blo: Int, _ bhi: Int) -> (Int, Int, Int) {
        var (besti, bestj, bestsize) = (alo, blo, 0)
        var j2len: [Int: Int] = [:]
        for i in alo..<ahi {
            var newj2len: [Int: Int] = [:]
            for j in b2j[a[i]] ?? [] {
                if j < blo { continue }
                if j >= bhi { break }
                let k = (j2len[j - 1] ?? 0) + 1
                newj2len[j] = k
                if k > bestsize { (besti, bestj, bestsize) = (i - k + 1, j - k + 1, k) }
            }
            j2len = newj2len
        }
        while besti > alo, bestj > blo, a[besti - 1] == b[bestj - 1] {
            (besti, bestj, bestsize) = (besti - 1, bestj - 1, bestsize + 1)
        }
        while besti + bestsize < ahi, bestj + bestsize < bhi, a[besti + bestsize] == b[bestj + bestsize] {
            bestsize += 1
        }
        return (besti, bestj, bestsize)
    }

    func matchingBlocks() -> [(Int, Int, Int)] {
        var queue = [(0, a.count, 0, b.count)]
        var blocks: [(Int, Int, Int)] = []
        while let (alo, ahi, blo, bhi) = queue.popLast() {
            let (i, j, k) = longestMatch(alo, ahi, blo, bhi)
            guard k > 0 else { continue }
            blocks.append((i, j, k))
            if alo < i && blo < j { queue.append((alo, i, blo, j)) }
            if i + k < ahi && j + k < bhi { queue.append((i + k, ahi, j + k, bhi)) }
        }
        blocks.sort { ($0.0, $0.1, $0.2) < ($1.0, $1.1, $1.2) }
        var (i1, j1, k1) = (0, 0, 0)
        var merged: [(Int, Int, Int)] = []
        for (i2, j2, k2) in blocks {
            if i1 + k1 == i2 && j1 + k1 == j2 {
                k1 += k2
            } else {
                if k1 > 0 { merged.append((i1, j1, k1)) }
                (i1, j1, k1) = (i2, j2, k2)
            }
        }
        if k1 > 0 { merged.append((i1, j1, k1)) }
        merged.append((a.count, b.count, 0))
        return merged
    }

    /// The non-equal opcodes: (i1, i2, j1, j2).
    func changes(_ blocks: [(Int, Int, Int)]) -> [(Int, Int, Int, Int)] {
        var (i, j) = (0, 0)
        var out: [(Int, Int, Int, Int)] = []
        for (ai, bj, size) in blocks {
            if i < ai || j < bj { out.append((i, ai, j, bj)) }
            (i, j) = (ai + size, bj + size)
        }
        return out
    }
}

// MARK: Score

func score(_ paths: [String]) {
    let cases = tokens()
    // Tokens as integers, one per distinct code point sequence.
    var ids: [[UInt32]: Int] = [:]
    func id(_ s: String) -> Int {
        let key = s.unicodeScalars.map(\.value)
        if let n = ids[key] { return n }
        ids[key] = ids.count
        return ids.count - 1
    }
    let expected = cases.map { id(canon($0.token)) }
    for path in paths {
        let gotRaw = words(Substring(read(URL(fileURLWithPath: path))))
        let got = gotRaw.map { id(canon($0)) }
        var right: [String: Int] = [:], total: [String: Int] = [:]
        var wrong: [(String, String, String)] = []
        let matcher = Matcher(a: expected, b: got)
        let blocks = matcher.matchingBlocks()
        var ok = Set<Int>()
        for (a, _, size) in blocks { ok.formUnion(a..<a + size) }
        // Pair the non-matching expected tokens with what stands in their place.
        for (i1, i2, j1, j2) in matcher.changes(blocks) {
            for k in i1..<i2 {
                let j = j1 + (k - i1)
                wrong.append((cases[k].group, cases[k].token, j < j2 ? gotRaw[j] : "∅"))
            }
        }
        for (k, c) in cases.enumerated() {
            total[c.group, default: 0] += 1
            right[c.group, default: 0] += ok.contains(k) ? 1 : 0
        }
        let file = path as NSString
        print("## \((file.deletingLastPathComponent as NSString).lastPathComponent)/\(file.lastPathComponent)")
        print("| Nhóm | Đúng | Tổng | Tỉ lệ |")
        print("|---|---|---|---|")
        for (g, _) in groups {
            let r = right[g] ?? 0, t = total[g] ?? 0
            let pct = t > 0 ? 100 * Double(r) / Double(t) : 0
            print("| \(g) | \(r) | \(t) | \(String(format: "%.1f", pct))% |")
        }
        if gotRaw.count != cases.count {
            print("(số từ đọc lại \(gotRaw.count), mong đợi \(cases.count))")
        }
        print("\nSai (nhóm, mong đợi, ra):")
        for (g, e, o) in wrong { print("\(g)\t\(e)\t\(o)") }
        print()
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
switch (arguments.first, arguments.count) {
case ("keys"?, _): print(tokens().map { telexWord($0.token) }.joined(separator: " ") + " ")
case ("expect"?, _): print(tokens().map(\.token).joined(separator: " ") + " ")
case ("score"?, 2...): score(Array(arguments.dropFirst()))
default:
    print(usage)
    exit(2)
}
