// Reads the design canvas layout (canvas.json) for scripts/design/render-canvas.sh, which
// builds this file once with scripts/lib/swift-tool.sh.
//
//   canvas-index boards canvas.json   name<TAB>width<TAB>height, design page only
//   canvas-index readme canvas.json   docs/ui/canvas/README.md (index by section)
//
// Boards on the archive page ("page": "archive") are left out. Order: the canvas order.
// A board's section is the part of its title before " – " ("Cài đặt – bản tối" → "Cài đặt").
import Foundation

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

let usage = "Cách dùng: canvas-index boards|readme canvas.json"

/// A JSON number as Python prints it: "762" for an integer, "762.5" for a fraction.
func number(_ value: Any?) -> String {
    guard let n = value as? NSNumber else { fail("canvas.json: kích thước không phải số") }
    return CFNumberIsFloatType(n) ? "\(n.doubleValue)" : "\(n.int64Value)"
}

/// (name, board) for every board not on the archive page, in canvas order.
func designBoards(_ path: String) -> [(String, [String: Any])] {
    guard let data = FileManager.default.contents(atPath: path) else { fail("Không đọc được \(path)") }
    guard let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          let boards = root["boards"] as? [String: Any],
          let order = root["order"] as? [String] else { fail("\(path): thiếu \"boards\" hoặc \"order\"") }
    return order.compactMap { name in
        guard let board = boards[name] as? [String: Any] else { fail("\(path): \"order\" có \(name) nhưng \"boards\" không có") }
        return board["page"] as? String == "archive" ? nil : (name, board)
    }
}

func readme(_ path: String) {
    var sections: [(String, [(title: String, stem: String)])] = []
    for (name, board) in designBoards(path) {
        guard let title = board["title"] as? String else { fail("\(path): \(name) không có \"title\"") }
        let section = title.range(of: " – ").map { String(title[..<$0.lowerBound]) } ?? "Khác"
        let stem = name.hasSuffix(".dc.html") ? String(name.dropLast(".dc.html".count)) : name
        if let i = sections.firstIndex(where: { $0.0 == section }) {
            sections[i].1.append((title, stem))
        } else {
            sections.append((section, [(title, stem)]))
        }
    }
    print("# Bản chụp canvas thiết kế\n")
    print("Ảnh chụp các artboard trên trang \"Thiết kế\" của canvas mockup, để xem thiết kế đã duyệt mà "
        + "không cần mở canvas trên claude.ai. Canvas vẫn là nơi sửa thiết kế (CLAUDE.md, mục Điều phối); "
        + "thư mục này chỉ là bản chụp, sinh bằng `scripts/design/render-canvas.sh`, không sửa tay.\n")
    print("- `*.png`: ảnh chụp từng artboard.")
    print("- `src/*.dc.html`: nguồn của artboard (nội dung, câu chữ chính xác); agent đọc file này thay cho canvas.")
    print("- `canvas.json`: vị trí, kích thước và tiêu đề các artboard.\n")
    for (section, items) in sections {
        print("## \(section)\n")
        for item in items {
            print("- [\(item.title)](\(item.stem).png) · [nguồn](src/\(item.stem).dc.html)")
        }
        print()
    }
}

let arguments = Array(CommandLine.arguments.dropFirst())
guard arguments.count == 2 else { fail(usage) }
switch arguments[0] {
case "boards":
    for (name, board) in designBoards(arguments[1]) {
        print("\(name)\t\(number(board["w"]))\t\(number(board["h"]))")
    }
case "readme":
    readme(arguments[1])
default:
    fail(usage)
}
