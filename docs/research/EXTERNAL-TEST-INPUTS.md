# Đầu vào test lấy từ bộ gõ khác (thu thập và so sánh)

Ghi công nguồn và giấy phép: `docs/research/external-test-inputs/NOTICE.md`.

Mục đích: lấy **chuỗi phím** trong bộ test của các bộ gõ tiếng Việt khác để engine của Dấu được thử trên những ca người khác thấy đáng test.

- Dấu tự viết kết quả mong đợi theo chính tả tiếng Việt và `docs/DECISIONS.md` mà **không nhìn** đáp án của họ.
- Chỉ sau đó mới so với đáp án của họ để tìm ca đáng xem lại (người dùng duyệt cách làm này ngày 05/11/2026).
- Mục 1–8 là bước 1: tìm nguồn, kiểm giấy phép, trích chuỗi phím, để riêng đáp án của họ.
- Mục 9 là kết quả bước 3 (so với đáp án của họ).
- Không có kết quả mong đợi nào của dự án khác trong `docs/research/external-test-inputs/`.
- Trong file này chỉ mục 9.7 và 9.8 trích nguyên văn đáp án của họ cho vài ca ví dụ thuộc lớp D và lớp E, có ghi nguồn (các lớp xếp ca khác nhau: xem mục Hiện trạng ngay dưới).

## Hiện trạng (05/11/2026)

- **Các lớp xếp ca khác nhau** (dùng khắp file này và ở `scripts/research/external-tests/compare.py`; mỗi ca mà Dấu và đáp án của họ khác nhau được xếp vào đúng một lớp):
  - **A**: Dấu cố ý khác, chỉ khi quyết định được dẫn thật sự sinh ra đầu ra của Dấu.
  - **B**: khác do tuỳ chọn `src:` của nguồn mà Dấu không có (mục 2.2).
  - **C**: đáp án của họ sai chính tả.
  - **D**: Dấu có vẻ sai, không quyết định nào biện minh.
  - **E**: `docs/DECISIONS.md` chưa nói hoặc nói chưa rõ, cần người dùng chọn.
  - **X**: không so được (mục 9.6).
  - Ca vừa thuộc B vừa có quyết định cụ thể của Dấu xếp vào A.
  - Các ca còn lại: `agree` (khớp), `no-answer` (họ không kiểm chữ), `unreviewed` (khác nhưng chưa ai xếp lớp). Cách script ghi các lớp: mục 9.1.
- **Bước 1 xong.**
  - Giữ 10 nguồn, tổng **10.303 ca**: Telex 8.222, VNI 2.028, Telex đơn giản 53.
  - Mỗi nguồn một file TSV trong `docs/research/external-test-inputs/`; đáp án của họ nằm riêng ở `build/external-answers/` (thư mục bị git bỏ qua, xem mục 3).
  - `extract.sh` đã sửa cho 43 ca trích sai lúc đầu (mục 9.6):
    - bỏ 14 ca của test chỉ in kết quả;
    - ghi đủ số ⌫ của vòng lặp và hàm phụ;
    - đọc đúng tuỳ chọn của hàm tạo engine ở gonhanh;
    - tách nhánh `if` ở XKey;
    - đọc lại hàng đợi commit của fcitx5-unikey.
  - So với bản trước:
    - gonhanh bỏ 3 ca (test macro, D3 (Không macro, chỉ Unicode dựng sẵn)), đổi 12;
    - uvie-rs bỏ 14, đổi 38;
    - XKey đổi 6 ca;
    - fcitx5-unikey đổi ghi chú 1 ca;
    - sáu nguồn còn lại ra đúng từng byte như trước.
- **Bỏ:**
  - ibus-unikey, OpenKey, fcitx5-bamboo (không có bộ test chuỗi phím);
  - bộ ca CSV của XKey (8.046 dòng, chính tác giả ghi là do một engine khác sinh ra, không nêu engine nào và giấy phép gì).
  - Mọi nguồn giữ lại có giấy phép tương thích GPLv3 (mục 4).
- **Bước 2 xong** theo cách khác kế hoạch ở mục 1:
  - thay cho đáp án mù từng ca, test `ExternalCasesTests` của engine kiểm các bất biến rút từ DECISIONS.md và ghi đầu ra của Dấu vào `build/external-dau-output/` (nhật ký `docs/PROGRESS.md` ngày 05/11/2026);
  - từ commit f39f066 khung test này mô phỏng cả việc đọc chữ trước con trỏ của D20 (Thêm dấu cho từ đã gõ) như lớp IMK;
  - từ ngày 05/11/2026 mô phỏng cả việc đọc ở chữ cái đầu tiên của từ cùng ba ngoại lệ của D20 (mục 9.8);
  - chưa chạy gì từ các bản clone: chỉ đọc file.
- **Bước 3** (mục 9): đo lại 05/11/2026 bằng `scripts/research/external-tests/compare.sh`, trên engine sau commit 0a9bb4b (từ dài quá 7 chữ bị xoá hết bằng ⌫ thì hết trạng thái đi thẳng, D33 (Độ dài từ)) và khung test mô phỏng D20 theo cách đọc ở chữ cái đầu tiên cùng ba ngoại lệ của D20.
  - 10.303 ca, 235 ca họ không kiểm chữ, 8.063 ca khớp, 2.005 ca khác.
  - Trong 2.005 ca khác:
    - 435 ca lớp A: Dấu cố ý khác theo một quyết định;
    - 1.493 ca lớp B: do tuỳ chọn của nguồn mà Dấu không có;
    - 73 ca lớp C: đáp án của họ sai chính tả;
    - **0 ca lớp D (lỗi của Dấu)**: bốn kiểu lỗi của lần xét đầu đã sửa (mục 9.7);
    - **0 ca lớp E (cần người dùng quyết định)**: chín câu hỏi của lần xét đầu người dùng đã chốt (D20, D26 (Gõ đúp phím dấu), D28 (Bỏ dấu tự do), D30 (Kiểm tra chính tả), D31 (Âm tiết tiếng Việt hợp lệ), D32 (Backspace), D33, D40 (Chữ dựng sẵn và phím z); mục 9.8); ca nào còn khác nay thuộc lớp A;
    - 4 ca lớp X, không so được (mục 9.6): lỗi trích đã sửa, ca thiếu mô phỏng D20 nay khớp hết.
- **Đếm sơ bộ trên đáp án của họ** (mục 6) đã được xem từng ca ở bước 3.
  - Các từ có dấu không phải âm tiết hợp lệ trong đáp án của họ phần lớn đúng là do cấu hình test của họ (lớp B): từ điển của ibus-teni, danh sách từ tiếng Anh của gonhanh và uvie-rs, tắt kiểm tra chính tả của fcitx5-unikey.
  - Phần còn lại là đáp án sai chính tả (lớp C).
- **Người dùng chốt (05/11/2026):**
  1. Ghi công nguồn trong `docs/research/external-test-inputs/NOTICE.md` (tên, URL, commit, SPDX, dòng bản quyền nguyên văn, toàn văn giấy phép MIT/BSD-3-Clause).
  2. Giữ ibus-telex dù repo không có file LICENSE, ghi chú rằng giấy phép chỉ được khai trong `Cargo.toml`.
  3. Chưa trích các kho lớn sinh máy móc, để làm sau (mục 7).
  4. Script trích nằm ở `scripts/research/external-tests/extract.sh`, ghim commit của từng nguồn và tạo lại đúng từng byte các TSV đã commit (kiểm 05/11/2026 bằng `git diff` sau khi chạy lại trên bản clone ở đúng commit).
- Không có khẳng định nào về API Apple trong file này.

## 1. Quy trình mù

1. Engine-dev chỉ đọc `docs/research/external-test-inputs/*.tsv` và file này, viết kết quả mong đợi theo chính tả tiếng Việt và `docs/DECISIONS.md` (D10 (Engine tự viết): không lấy kết quả của bộ gõ khác làm đáp án).
2. Chạy engine của Dấu trên các ca đó; ca nào Dấu khác đáp án của chính Dấu là lỗi của Dấu. (Đã làm bằng bất biến thay cho đáp án từng ca, xem Hiện trạng.)
3. Chỉ sau bước 2, người so sánh mới mở `build/external-answers/` và đánh dấu các ca Dấu khác họ.
   - Mỗi ca khác nhau được xét theo DECISIONS.md. Kết quả là một trong ba:
     - Dấu cố ý khác (ghi vào `docs/OPENKEY-NOTES.md` hoặc ghi chú test);
     - đáp án của Dấu sai;
     - cần quyết định mới (hỏi người dùng).
   - Đáp án của họ không bao giờ được chép thẳng vào test.

Lưu ý: engine của XKey ghi trong mã là bản chuyển trực tiếp từ engine OpenKey (`XKey/Core/Engine/VNEngine.swift` của họ), nên đáp án của XKey gần với hành vi OpenKey; theo D10 nó chỉ được dùng để tìm ca đáng xem lại, như mọi nguồn khác.

## 2. Ký hiệu

### 2.1 Cột `keys`

Mỗi ký tự là một phím gửi vào engine theo thứ tự, như `Typist.type` trong test của Dấu.
Chữ hoa là phím chữ có Shift (hoặc Caps Lock).
Ký hiệu thêm:

| Ký hiệu | Nghĩa |
|---|---|
| `␣` | phím Space |
| `⏎` | Return |
| `⇥` | Tab |
| `⌫` | Backspace |
| `←` | sự kiện **reset engine của họ**: `clear()`/`reset()`, hoặc phím mũi tên, Home/End, tổ hợp có ⌃/⌘ mà engine của họ chỉ coi là reset. Không phải lệnh dời con trỏ và không nói gì về chữ trước con trỏ: trong test của họ, `clear()` thường là ô nhập mới. Khung test của Dấu chạy `←` như phím mũi tên (D4 (Từ nước ngoài): chỉ reset, không khôi phục), nên D20 có thể đọc từ ngay trước con trỏ. Ca nào họ dùng `clear()` để mở ô mới rồi gõ tiếp sát chữ cũ thì không so được (lớp X, nhãn `X-reset`, mục 9.6) |
| `⎋` | Esc (với Dấu: chỉ reset, D4) |
| `⟦chữ⟧` ở đầu chuỗi | chữ đã có sẵn trước con trỏ, engine được nạp từ chữ đó (D20, `Typist.seed`); các phím sau đó gõ tiếp |
| `⟦trước|sau⟧` | như trên, `|` là vị trí con trỏ; phần sau con trỏ nằm trong ô nhưng D20 không đọc |
| chữ tiếng Việt dựng sẵn ngoài `⟦⟧` (7 ca) | ký tự đó tới engine như một phím (bố cục bàn phím khác, nhập kiểu dán); D40: Dấu coi là một chữ cái của từ |

Các phím khác (chữ số, dấu câu, `ß`…) là chính ký tự đó.
Không có ca nào chứa ký tự tab hay xuống dòng thật trong TSV.

### 2.2 Cột `options`

Các mục cách nhau bằng `;`.
Rỗng nghĩa là mặc định của Dấu (D15 (Cài đặt mặc định): Telex, đặt dấu kiểu mới, bỏ dấu tự do bật, tự khôi phục bật, Nâng cao tắt).
Cột `method` ghi kiểu gõ: `telex`, `vni`, `simple-telex` (D29 (Telex đơn giản)).

| Mục | Cài đặt của Dấu |
|---|---|
| `tone=classic` | đặt dấu kiểu cũ (hòa, thúy) — `EngineOptions.tonePlacement = .classic` |
| `freeMarking=off` | tắt bỏ dấu tự do (D28) |
| `autoRestore=off` | tắt "Tự khôi phục từ không phải tiếng Việt" (D4, D30) |
| `advanced=consonantShortcuts` | gõ tắt phụ âm (D21 (Gõ tắt phụ âm)) |
| `advanced=allowZFWJ` | cho phép z, f, w, j (D22 (Gõ tắt loại trừ z, f, w, j)) |

Mục bắt đầu bằng `src:` là **tuỳ chọn của nguồn mà Dấu không có**.
Ca vẫn chạy với cài đặt Dấu gần nhất, nhưng khi so đáp án phải nhớ rằng họ test trong điều kiện khác:

| Mục | Nghĩa ở nguồn | Ở Dấu |
|---|---|---|
| `src:spellcheck=off` | họ tắt kiểm tra chính tả | kiểm tra chính tả luôn chạy (D30) |
| `src:dictionary` | ibus-teni quyết định bằng từ điển từ (có cả viết tắt, từ mượn) | không dùng từ điển (D4, D31) |
| `src:englishDictionary` | khôi phục từ tiếng Anh dựa vào danh sách từ tiếng Anh (gonhanh "English auto-restore", uvie-rs "english override") | khôi phục theo luật âm tiết hợp lệ, không có từ điển tiếng Anh (D4) |
| `src:modifySurroundingText=off` | fcitx5-unikey đọc chữ xung quanh nhưng không được sửa nó | D20 sửa được chữ trước con trỏ |
| `src:relaxedCoda=on` | uvie-rs nới luật âm cuối | không có (D31) |
| `src:customConsonants=…` | XKey cho phép thêm phụ âm đầu (liệt kê chữ) | gần nhất là D22 (chỉ z, f, w, j). Với `K`: suy luận, cần kiểm chứng, là cho k đứng trước a, o, u; D31 đã nhận điều này nên Dấu không cần tuỳ chọn |

Cách quy đổi kiểu gõ của nguồn sang `method` nằm ở mục 5 của từng nguồn.

## 3. Bố cục file

- `docs/research/external-test-inputs/<nguồn>.tsv`:
  - hàng tiêu đề rồi một ca mỗi hàng, cột `id`, `method`, `options`, `keys`, `source_ref`;
  - `id` ổn định, dạng `file:tên test#thứ tự` (hoặc `file:dòng`), đủ để tìm lại ca trong repo của họ ở commit ghi ở mục 5;
  - `source_ref` là đường dẫn file trong repo của họ;
  - không có cột đáp án.
- `build/external-answers/<nguồn>.tsv` (git bỏ qua, không commit):
  - cột `id`, `their_expected`, `their_note`;
  - `their_expected` dùng cùng ký hiệu `␣`/`⏎` như cột `keys`; để trống khi test của họ không kiểm chữ (chỉ kiểm cờ hợp lệ, số Backspace…);
  - cột thứ ba `their_note` (thêm so với yêu cầu ban đầu) ghi họ kiểm cái gì, ví dụ "chỉ từ đang gõ", "chỉ phần chữ do các phím cuối sinh ra", "khung test tự thêm một Space cuối";
  - thư mục này dựng lại được bằng cách trích lại từ đúng commit ở mục 5.
- `build/external-review/<nguồn>.tsv` (git bỏ qua, không commit; bước 3, do `scripts/research/external-tests/compare.sh` ghi):
  - mọi ca của nguồn, cột `id`, `keys`, `dau_output` (đầu ra bước 2), `their_expected`, `class`, `rule_notes`;
  - `class` là `agree`, `no-answer`, A–E, X (mục Hiện trạng), hoặc `unreviewed` cho ca khác chưa ai xếp;
  - `rule_notes` là nhãn lớp như `A-D32`, luật, đề xuất cho lớp D;
  - file này có đáp án của họ.
- Script trích: `scripts/research/external-tests/extract.sh`.
  - Lấy từng nguồn ở đúng commit ghi ở mục 5 vào `/tmp/ext-ime/`, rồi gọi các helper Python cùng thư mục bằng `python3 -I`.
  - Chỉ đọc file văn bản, không build, không chạy gì của các bản clone.
  - Chạy lại thì ra đúng các TSV đã commit, cùng `build/external-answers/` và `build/external-tests-stats/` (số đếm, lý do bỏ; không có đáp án).
  - Ghi công: `docs/research/external-test-inputs/NOTICE.md`.
  - Vòng lặp có số lần ghi trong mã (`for _ in 0..N`, Swift `0..<N`, vòng qua mảng chữ) được trải ra trước khi đọc, nên mỗi phím trong vòng được ghi đủ số lần.
  - Vòng có số lần tính lúc chạy mà chứa phím thì các ca sau nó trong test bị bỏ.
  - Test không kiểm gì mà chỉ in kết quả (`println!`) thì bỏ.
- Script so (bước 3): `scripts/research/external-tests/compare.sh` (helper `compare.py`), mục 9.1.

Một số ca dùng chung một engine qua nhiều lời gọi trong cùng test của họ:
khi đó `keys` là toàn bộ phím từ lúc tạo engine (hoặc từ lần `clear`/`reset` gần nhất) và `their_note` ghi rằng đáp án của họ chỉ phủ phần cuối.
Một số ca là trạng thái giữa từ (họ kiểm chữ đang gõ, chưa có ranh giới từ): `keys` khi đó không kết thúc bằng `␣`/`⏎`, và đáp án của Dấu cũng là chữ hiển thị giữa từ (trước D4).

## 4. Giấy phép

Chuỗi phím là dữ liệu ngắn, gần như không có tính sáng tạo; dù vậy mọi nguồn đều được ghi công ở mục 5 và chỉ giữ nguồn có giấy phép tương thích GPLv3.

| Nguồn | SPDX | Dùng cho Dấu (GPLv3) |
|---|---|---|
| bamboo-core | MIT | được, giữ thông báo bản quyền |
| ibus-bamboo | GPL-3.0 (file LICENSE, không ghi "or later") | được, cùng GPLv3 |
| fcitx5-unikey (thư mục test) | GPL-2.0-or-later (SPDX trong file test) | được, nhờ "or later" |
| goxkey | BSD-3-Clause | được, giữ thông báo bản quyền |
| vi-rs | MIT | được |
| ibus-teni | GPL-3.0-or-later (thư mục test-data có LICENSE riêng) | được |
| uvie-rs | MIT OR Apache-2.0 | được (chọn MIT) |
| ibus-telex | GPL-3.0-or-later, chỉ khai trong `Cargo.toml`, repo không có file LICENSE | được; người dùng chốt giữ kèm ghi chú (05/11/2026) |
| gonhanh.org | BSD-3-Clause | được, giữ thông báo bản quyền |
| XKey | MIT (file LICENSE); engine ghi là chuyển từ OpenKey (GPL-3.0) | được ở cả hai trường hợp: MIT hay GPL-3.0 đều tương thích GPLv3 |

## 5. Từng nguồn

Số "ca" là số hàng trong TSV.
"Bỏ" ghi đơn vị: ca (một chuỗi phím) hoặc test (một hàm test của họ).

### 5.1 bamboo-core (Go)

- https://github.com/BambooEngine/bamboo-core, commit `b2e49a2b48c7d3772a3673142a7747eccd9d5f79` (16/09/2024). MIT, © 2018 Luong Thanh Lam.
- File: `bamboo_test.go` (chép tay từng điểm kiểm; `rules_parser_test.go`, `utils_test.go` là test hàm nội bộ).
- 67 ca: Telex 66, VNI 1; 60 ca có đáp án chữ, 7 ca họ chỉ kiểm cờ hợp lệ.
- Cấu hình test của họ:
  - kiểu "Telex 2" (Telex có `[ ]` và w đứng riêng thành ư) → `telex`;
  - cờ `EstdFlags` = bỏ dấu tự do + `EstdToneStyle`;
  - đọc mã `findToneTarget`: `EstdToneStyle` đặt dấu "oa, oe, uy" không âm cuối ở nguyên âm đầu, tức kiểu cũ → `tone=classic`;
  - một test bỏ cờ đó → mặc định Dấu;
  - họ kiểm chữ của từ đang gõ (`GetProcessedString`), không có ranh giới từ.
- Ba ca bamboo đưa chữ dựng sẵn ("tôi", "tối", "chuyển") vào engine rồi gõ tiếp: ghi thành `⟦…⟧` (D20).
- Bỏ:
  - 7 ca D27 (Không có phím gõ nhanh ơ, ư) (`[ ] { }` thành ơ ư);
  - 4 ca gõ giữa từ bằng "EnglishMode" của họ (D2 (Chuyển Việt/Anh): Dấu không có chế độ Anh);
  - 2 test lệnh "khôi phục từ vừa gõ" (Dấu không có lệnh này);
  - 3 ca bố cục bàn phím "Microsoft layout" (TCVN, không có ở Dấu);
  - 1 ca trùng;
  - benchmark;
  - 6 test hàm nội bộ.

### 5.2 ibus-bamboo (Go)

- https://github.com/BambooEngine/ibus-bamboo, commit `49e03d7a36b8a8b796950c158b545af8cf9707d4` (19/05/2026). GPL-3.0, © 2018 Luong Thanh Lam.
- File: `engine_test.go`, `tests/xtest.data` (14 câu dùng cho script gõ thử X11 của họ, không có đáp án).
- 32 ca, tất cả `simple-telex`, `tone=classic`; 15 ca có đáp án.
- Quy đổi: mặc định của họ là kiểu "Telex" của bamboo, trong đó w chỉ biến đổi u, o, a (không có w đứng riêng thành ư, không có `[ ]`) — đúng định nghĩa Telex đơn giản của Dấu (D29). Cờ mặc định giống bamboo-core (kiểu cũ).
- Bỏ:
  - 12 test bật macro (D3);
  - 8 test lặp lại chuỗi phím đã có (hai chế độ preedit/backspace của họ chạy cùng chuỗi);
  - 6 test Ctrl+A hoặc sự kiện rỗng (không sinh chữ);
  - 3 test emoji và hàm phụ.

### 5.3 fcitx5-unikey (C++, engine ukengine của UniKey)

- https://github.com/fcitx/fcitx5-unikey, commit `ed9170c35c1a6275d105e03d7f9bc4f674c1469c` (05/09/2026). Thư mục test GPL-2.0-or-later, © 2021 CSSlayer.
- File: `test/testunikey.cpp`.
- 1.325 ca, tất cả `telex`; 1.324 có đáp án. Gồm:
  - 1.307 mục đang chạy của bảng `expectedTelexData` (mỗi chuỗi phím rồi Return);
  - 11 ca đầu `testBasic`;
  - 6 ca dùng chữ xung quanh con trỏ (ghi thành `⟦…⟧`);
  - 1 ca `testType` (không có đáp án).
- Cấu hình:
  - Telex của UniKey (có `[ ]`, w đứng đầu từ thành ư) → `telex`;
  - `ModernStyle` mặc định tắt → `tone=classic`;
  - bảng `expectedTelexData` chạy với `AutoNonVnRestore=False`, `SpellCheck=False` → `autoRestore=off;src:spellcheck=off`;
  - đáp án `testBasic` là hàng đợi chữ commit; ghép đáp án với nhóm phím theo thứ tự là cách đọc của người trích;
  - riêng nhóm thứ hai (`baao␣`, chạy khi Macro tắt và ModifySurroundingText tắt): theo `src/unikey-im.cpp` của họ, phụ âm gõ ở đầu từ được gửi thẳng vào app thay vì commit, nên hàng đợi chỉ có phần sau chữ b ("âo␣"); `their_note` ghi "committed part only" (cách đọc mã của người trích, chưa chạy).
- Bỏ: 414 mục của bảng đang bị comment trong mã của họ (họ không chạy). Không có ca nào cần `[ ]`.

### 5.4 goxkey (Rust, macOS)

- https://github.com/huytd/goxkey, commit `b197c57218ceb9096c341a9862acfabf7cb6932b` (23/09/2026). BSD-3-Clause, © 2023 Huy Tran. Engine của goxkey là vi-rs (5.5).
- File: `src/main.rs` (test trong mã).
- 4 ca: Telex 3, VNI 1, đều có đáp án.
- Bỏ:
  - 2 test gọi hàm quyết định khôi phục với một "chữ đã biến đổi" mà chuỗi phím không thể sinh ra;
  - 1 test danh sách từ được phép của người dùng (D4: không có danh sách);
  - 1 test kiểu gõ Telex+VNI gộp (không có ở Dấu);
  - 76 test hàm nội bộ (`input.rs`, `hotkey.rs`, `scripting/parser.rs`).

### 5.5 vi-rs (Rust)

- https://github.com/zerox-dg/vi-rs, commit `192e246d37e83094a1228e798b160f3cee14c879` (22/06/2026). MIT, © 2020 Hung Nguyen.
- File: `testdata/input/simple_telex.txt`, `non_vietnamese_telex.txt`, `simple_vni.txt`, `non_vietnamese_vni.txt` (đáp án của họ: các file `.snap` trong `testdata/output/`), `tests/incremental.rs`.
- 182 ca: Telex 139, VNI 43; 170 có đáp án.
  - Họ biến đổi **từng từ riêng** (không có ranh giới từ, không có khôi phục), nên mỗi từ trong file đầu vào là một ca, không có `␣`.
  - Kiểu đặt dấu mặc định của họ là kiểu mới → mặc định Dấu; 1 ca kiểu cũ.
- Bỏ:
  - `all_telex.txt` và `all_vni.txt` (mỗi file 24.226 dòng, sinh máy móc từ danh sách âm tiết) — kho lớn, không trích (mục 7);
  - 20 test hàm nội bộ;
  - 2 test không có chuỗi phím.

### 5.6 ibus-teni (Go)

- https://github.com/teni-ime/ibus-teni, commit `a3824854c0f5e85dcfea66d984b9bad0c16c2bf2` (10/04/2020). GPL-3.0-or-later, © 2018 Nguyen Cong Hoang.
- File: `test-data/*.tdata` (mỗi dòng: đáp án, dấu cách, chuỗi phím; chuỗi phím do `test-data/test-data-gen.go` của họ sinh từ từ điển trong `dict/`, theo ba thứ tự gõ telex1/2/3 và vni1/2/3), `src/teni/teni_coverage_test.go`.
- 3.050 ca: Telex 1.533, VNI 1.517; 3.049 có đáp án. Gồm:
  - các file `nodict`, `vietnamese.std.dict.*` (kiểu cũ → `tone=classic`), `vietnamese.new.dict.*` (kiểu mới → mặc định), `vietnamese.sp.dict.*` (từ đặc biệt: viết tắt, từ mượn có đ);
  - 4 ca của `teni_coverage_test.go`.
  - Mọi ca mang `src:dictionary`: engine của họ quyết định bằng từ điển. Họ kiểm chữ giữa từ, không có ranh giới từ.
- Quy đổi: kiểu gõ "Teni" (Telex của họ) → `telex`; file `.telexw` (kiểu Telex có `[ ]`) chỉ giữ ca không có ngoặc.
- Bỏ:
  - 11 ca D27;
  - 1 dòng khung test của họ cũng bỏ qua;
  - `vietnamese.cm.dict.*` (7 file, 47.767 dòng, sinh từ danh sách từ thông dụng) — kho lớn, không trích.

### 5.7 uvie-rs (Rust)

- https://github.com/uvie-project/uvie-rs, commit `555ef9dd31b6bf208343a70484e84db79f1bddfe` (21/10/2026). MIT OR Apache-2.0, © 2026 thuupx.
- File: `tests/*.rs`. Trích tự động các mẫu:
  - `type_seq`, `type_seq_vni`, `type_diff`;
  - hàm phụ hai tham số;
  - vòng lặp trên mảng cặp;
  - chuỗi gọi `type_chars`/`press_space`/`press_backspace` và hàm phụ xoá một chữ như `backspace(&mut e, &mut screen)` kèm kiểm `screen`;
  - vòng `for … in "…".chars()` và mảng chữ `Vec<char>`.
- 947 ca: Telex 925, VNI 22; 922 có đáp án.
- Cấu hình:
  - `set_modern_orthography` mặc định tắt → `tone=classic` khi test không bật;
  - "english override" (từ điển tiếng Anh) mặc định bật → `src:englishDictionary`;
  - `set_quick_start` → `advanced=consonantShortcuts`;
  - `set_relaxed_coda` → `src:relaxedCoda=on`.
- Bỏ:
  - 14 ca bật Quick Telex (cc → ch…, mục "Đã biết nhưng không làm" của DECISIONS.md);
  - 3 test đọc file dữ liệu (`tests/data/`: 22k từ Việt, 100k từ Anh, cặp Telex — kho lớn);
  - 9 test chỉ in kết quả, không kiểm gì (ví dụ `vcv_tests.rs:debug_phat_sequences`, `test_ua_diphthong_tone`; giá trị "mong đợi" trong đó chỉ là ghi chú, có cái tự ghi là đoán);
  - 68 test không trích được (bảng nội bộ, kích thước diff, lịch sử sửa từ trước, bất biến sinh ngẫu nhiên).

### 5.8 ibus-telex (Rust)

- https://github.com/manhavn/ibus-telex, commit `fb522b4804c2ef8496ec8746f7b1e4043b3716c2` (05/10/2026). GPL-3.0-or-later (khai trong `Cargo.toml`), tác giả commit Bùi Văn Mạnh.
- File: `tests/parity_corpus.tsv` (chuỗi phím và kết quả mà họ ghi là chụp từ ibus-unikey 0.7.0), `tests/typing.rs`.
- 323 ca: Telex 311, VNI 10, Telex đơn giản 2; tất cả có đáp án.
- Quy đổi:
  - tuỳ chọn mặc định của họ (giống UniKey: kiểu cũ) → `tone=classic`;
  - `standalone_w: false` → `simple-telex`;
  - `free_marking: false` → `freeMarking=off`;
  - `spell_check: false` → `src:spellcheck=off`;
  - khung `parity.rs` của họ gõ thêm một Space ở cuối rồi bỏ một dấu cách cuối khỏi kết quả: các ca corpus vì vậy kết thúc bằng `␣`, `their_note` ghi rõ.
- Bỏ:
  - 9 ca D27;
  - 2 test chỉ gọi API;
  - `keys.rs` (phân loại mã phím) và `protocol.rs` (thử giao thức D-Bus với engine đang chạy).

### 5.9 gonhanh.org — Gõ Nhanh (Rust, macOS)

- https://github.com/khaphanspace/gonhanh.org, commit `1fdac7aec67663f2c23df6addfb13c59bbc5f374` (05/11/2026). BSD-3-Clause, © 2025 Gõ Nhanh Contributors.
- File: `core/tests/*.rs`. Trích tự động:
  - mảng hằng cặp phím/đáp án và các hàm chạy `telex`, `vni`, `telex_auto_restore`, `telex_traditional`, `vni_traditional`;
  - hàm phụ trong từng file, vòng lặp trên mảng cặp, chuỗi `type_word` trên cùng engine;
  - `restore_and_type` → `⟦…⟧`;
  - chuỗi mã phím `on_key` (chỉ lấy phím, không lấy đáp án).
  - Ký hiệu của họ: `<` là Backspace → `⌫`.
- 4.110 ca: Telex 3.680, VNI 411, Telex đơn giản 19; 3.992 có đáp án.
- Cấu hình:
  - mặc định của họ là kiểu mới, "English auto-restore" tắt → `autoRestore=off`; bật → `src:englishDictionary` (họ dùng danh sách từ tiếng Anh);
  - `set_modern_tone(false)` → `tone=classic`;
  - `set_allow_foreign_consonants(true)` → `advanced=allowZFWJ`;
  - `set_skip_w_shortcut(true)` (w đầu từ giữ là w) → `simple-telex`;
  - `set_free_tone(true)` (bỏ kiểm tra) → `src:spellcheck=off`;
  - hàm tạo engine trong file test (`engine_on()`, `engine_off()`, `setup()`) được đọc như `Engine::new()` cộng các lệnh `set_…` bên trong: `engine_on()` của `english_auto_restore_toggle_test.rs` bật khôi phục tiếng Anh → `src:englishDictionary` (ở Dấu là mặc định, tự khôi phục bật).
- Bỏ:
  - 34 test viết hoa đầu câu và 62 test macro/gõ tắt văn bản (D3; kể cả 3 test của `issue_387_backspace_correction_test.rs`, có macro và tắt bộ gõ trong hàm `setup()`);
  - 4 ca D27 (họ bật phím ngoặc);
  - 124 ca `rstest` sinh từ tham số lúc chạy;
  - 13 test đọc file dữ liệu hoặc sinh đầu vào (kho 22k từ Việt, 100k từ Anh, hoán vị thứ tự gõ);
  - 43 test không trích được (hoán vị sinh lúc chạy, kiểm trường kết quả của engine).
  - Kho dữ liệu `core/tests/data/` không trích.

### 5.10 XKey (Swift, macOS)

- https://github.com/xmannv/xkey, commit `398e78e9c1a92f740d5cbf1673914a3b3c458eff` (11/10/2026). MIT, © 2025 XKey.
- File: `XKeyTests/VNEngineTests.swift`, `VNEngineBackspaceRestoreTests.swift`, `VNEngineBufferIntegrationTests.swift`, `TypingBufferTests.swift` (trích tự động chuỗi `processKey`/`typeWord`/`typeTelex`/`vni([...])` và các lần kiểm `getCurrentWord()`), danh sách `corpus` của `ScreenSimulationTests.swift` (chỉ phím, họ kiểm bất biến).
- 263 ca: Telex 240, VNI 23; 234 có đáp án (từ đang gõ, `getCurrentWord()`).
  - Hai nhánh của một `if … else` trên trạng thái engine của họ là hai ca riêng, mỗi nhánh tính phím từ chỗ `if`.
  - `their_note` ghi điều kiện của nhánh (ví dụ `VNEngineTests.swift:testTelex_BackspaceAndRetype_LY#2`, `#3`).
- Cấu hình:
  - engine mặc định của họ kiểu mới, kiểm tra chính tả và khôi phục bật, **Quick Telex bật**;
  - ca nào có cặp phụ âm đôi mà Quick Telex có thể đổi (cc, gg, kk, nn, qq, pp, tt) thì bỏ; các ca còn lại không chịu ảnh hưởng của Quick Telex nên chạy với mặc định Dấu;
  - `vUseModernOrthography = 0` → `tone=classic`;
  - `vCheckSpelling = 0` → `src:spellcheck=off`;
  - `vCustomConsonants` → `advanced=allowZFWJ` và/hoặc `src:customConsonants`.
- Bỏ:
  - `XKeyTests/Resources/telex_test_suite.csv` (8.046 ca) vì nguồn gốc không rõ (mục Hiện trạng);
  - 4 test macro, cả file viết hoa đầu câu (D3);
  - 14 ca D27;
  - 1 ca Quick Telex;
  - kiểu "adaptive" Telex+VNI (1 ca, cả file `VNEngineAdaptiveTests.swift`);
  - 166 test không có chuỗi phím kèm kiểm chữ (cờ, lịch sử, hoàn tác, cấu trúc bộ đệm);
  - các file test còn lại là phần ứng dụng (event tap, Trợ năng, cài đặt, đồng bộ).

## 6. Đếm sơ bộ trên đáp án của họ (không trích đáp án)

Người trích chạy một bộ kiểm âm tiết tạm (luật D31 rút gọn, viết riêng cho việc đếm này, không dùng trong engine): `scripts/research/external-tests/answer_stats.py`, đọc `build/external-answers/`, chỉ in số đếm.
Chỉ xét ca kết thúc bằng ranh giới từ (hoặc ca ibus-teni, vốn là từ trọn vẹn).
Đây là số đếm heuristic trước khi xem từng ca; kết quả xem từng ca ở mục 9.

| Nguồn | Ca kết thúc từ có đáp án | Đáp án còn một từ có dấu không phải âm tiết hợp lệ | Dấu thanh ở chữ mà cả hai kiểu đều không cho | Kiểu đặt dấu khác tuỳ chọn của chính test |
|---|---|---|---|---|
| fcitx5-unikey | 1.323 | 384 (họ tắt kiểm tra chính tả và khôi phục) | 0 | 0 |
| ibus-teni | 3.049 | 1.579 (từ điển riêng của họ có viết tắt, từ mượn) | 6 (cùng một từ trong từ điển đặc biệt, 6 thứ tự gõ) | 0 |
| gonhanh | 1.819 | 42 | 2 (gi + i, khó phân định) | 0 |
| ibus-telex | 250 | 20 | 0 | 0 |
| uvie-rs | 82 | 2 | 0 | 2 |
| goxkey | 2 | 1 | 0 | 0 |
| bamboo-core, ibus-bamboo, vi-rs, XKey | 0–5 | 0 | 0 | 0 |

Không có ca nào có huyền, hỏi hoặc ngã trên vần kết thúc bằng p, t, c, ch.
Cột thứ ba là nhóm đáng xem lại nhất ở bước 3:

- theo D4 và D31, Dấu khôi phục các từ đó khi kết thúc từ, nên đáp án của Dấu sẽ khác ở hầu hết các ca này;
- một phần là khác biệt có chủ ý (bộ gõ không khôi phục);
- một phần có thể là lỗi chính tả trong đáp án của họ (sai luật phân bố phụ âm đầu hoặc vần không có trong tiếng Việt).

## 7. Không trích và vì sao

- **Kho lớn sinh máy móc** (vi-rs `all_*.txt`, ibus-teni `vietnamese.cm.dict.*`, dữ liệu `tests/data/` của uvie-rs và `core/tests/data/` của gonhanh):
  - là bảng phủ toàn bộ âm tiết hoặc danh sách từ, không phải ca người viết chọn;
  - Dấu đã có phép thử trên kho âm tiết của riêng mình (bảng mốc M1 (Engine) trong `docs/PROGRESS.md`);
  - người dùng chốt chưa trích (05/11/2026); việc làm sau: thêm vào `extract.sh` khi cần (vài chục nghìn ca mỗi nguồn).
- **Test sinh lúc chạy** (`rstest`, hoán vị thứ tự gõ, bất biến ngẫu nhiên): đầu vào không nằm trong mã.
- **Test API** (số Backspace, cờ hợp lệ, cấu trúc bộ đệm, lịch sử sửa từ trước, hoàn tác): không phải chuỗi phím với chữ mong đợi.
- **Tính năng Dấu không có:**
  - macro, viết hoa đầu câu, bảng mã cũ (D3);
  - chế độ Anh riêng (D2);
  - `[ ]` thành ơ ư (D27);
  - Quick Telex (mục "Đã biết nhưng không làm");
  - kiểu gõ Telex+VNI gộp;
  - danh sách từ được phép (D4);
  - Esc khôi phục chuỗi phím (D4: Esc chỉ reset).

## 8. Nguồn đã thấy nhưng chưa xem

Tìm trên GitHub ngày 05/11/2026, chưa clone, chưa kiểm giấy phép hay bộ test:

- bogo-python (BoGoEngine, GPL-3.0);
- avim (1ec5, MIT);
- vietc (vndangkhoa, MIT);
- Funput (MIT);
- ibus-mangrs (fundokukiri, GPL-3.0, README nói có bảng 480 ca);
- bamboo-core bản Rust (bamboo-vi, MIT);
- TypeVN, gotivi, InputKey, unikey-rust;
- 1xkey-src (GPL-3.0);
- daukey (emizuki, GPL-3.0);
- PHTV.

Nhiều repo mới trong năm 2026 có bộ test lớn sinh tự động; nên ưu tiên repo có lịch sử và người dùng thật.

Nguồn tra: GitHub (`gh search repos "vietnamese input method"`), https://github.com/topics/telex, https://github.com/topics/vni, https://github.com/topics/vietnamese-ime, https://formulae.brew.sh/cask/gonhanh.

## 9. Kết quả so sánh (05/11/2026)

### 9.1 Cách so

- `scripts/research/external-tests/compare.sh` ghép ba file theo `id`, so ở dạng NFC, ghi `build/external-review/` và in hai bảng ở mục 9.2. Ba file là:
  - `docs/research/external-test-inputs/<nguồn>.tsv`;
  - `build/external-dau-output/<nguồn>.tsv` (đầu ra bước 2);
  - `build/external-answers/<nguồn>.tsv`.
- Chuẩn hoá theo `their_note`:
  - bỏ phím commit cuối (⏎, ß…) và phần chữ sau con trỏ khi họ chỉ kiểm phần chữ được commit;
  - bỏ một ␣ cuối (và ⏎/⇥ ngay trước nó) cho bộ corpus của ibus-telex (khung test của họ gõ thêm Space rồi bỏ dấu cách cuối);
  - với "current word only", "getCurrentWord()", "preedit" chỉ so từ cuối;
  - với "covers only the last N keys", "committed part only" chỉ so phần cuối.
  - Trên dữ liệu của lần xét đầu, script cho đúng từng ca khớp/khác như lần đó.
- Định nghĩa các lớp A–E, X ở mục Hiện trạng. Ví dụ cho quy tắc "ca vừa thuộc B vừa có quyết định cụ thể của Dấu xếp vào A": "pass" ở nguồn có từ điển tiếng Anh, Dấu ra "pas" theo D26.
- Xếp lớp là việc của người so, script không tự xếp:
  - ca khác giữ lớp của lần xét trước nếu phím, đầu ra của Dấu và đáp án của họ không đổi;
  - còn lại thành `unreviewed` (ghi lớp cũ trong `rule_notes`), người so xem từng ca rồi áp lớp bằng `--set`.
- Để xem ca, người so chạy engine của Dấu bằng chương trình tạm ngoài repo (gọi `VietEngine` qua API công khai, không sửa engine).
- Việc đọc chữ trước con trỏ của D20 nằm trong khung test `ExternalCasesTests` (mô hình theo `InPlaceComposer`, chưa chạy trên Dấu thật):
  - từ commit f39f066;
  - từ ngày 05/11/2026 khung test đọc cả ở chữ cái đầu tiên và chỉ nối khi từ ghép còn là tiền tố hợp lệ (D20), cùng ba ngoại lệ của D20 (mục 9.8).

### 9.2 Đếm theo nguồn

Đo 05/11/2026 trên engine sau commit 0a9bb4b, khung test mô phỏng D20 theo cách đọc ở chữ cái đầu tiên và ba ngoại lệ của D20. Chạy lại ngày 09/11/2026 trên engine sau faff8a3: mọi số trong hai bảng dưới không đổi.
"Khác" gồm cả lớp X.
Cột `src:`: ca có tuỳ chọn của nguồn mà Dấu không có (mục 2.2).

| Nguồn | Ca | Họ không kiểm chữ | Khớp, không `src:` | Khác, không `src:` | Khớp, có `src:` | Khác, có `src:` |
|---|---|---|---|---|---|---|
| gonhanh | 4.110 | 119 | 2.228 | 86 | 1.505 | 172 |
| ibus-teni | 3.050 | 1 | 0 | 0 | 1.627 | 1.422 |
| fcitx5-unikey | 1.325 | 1 | 7 | 0 | 1.225 | 92 |
| uvie-rs | 947 | 37 | 1 | 0 | 743 | 166 |
| ibus-telex | 323 | 11 | 271 | 40 | 0 | 1 |
| XKey | 263 | 30 | 214 | 6 | 10 | 3 |
| vi-rs | 182 | 12 | 165 | 5 | 0 | 0 |
| bamboo-core | 67 | 7 | 50 | 10 | 0 | 0 |
| ibus-bamboo | 32 | 17 | 14 | 1 | 0 | 0 |
| goxkey | 4 | 0 | 3 | 1 | 0 | 0 |
| **Tổng** | **10.303** | **235** | **2.953** | **149** | **5.110** | **1.856** |

Theo lớp (chỉ ca khác):

| Nguồn | A | B | C | D | E | X |
|---|---|---|---|---|---|---|
| gonhanh | 197 | 21 | 39 | 0 | 0 | 1 |
| ibus-teni | 0 | 1.416 | 6 | 0 | 0 | 0 |
| fcitx5-unikey | 84 | 8 | 0 | 0 | 0 | 0 |
| uvie-rs | 102 | 46 | 18 | 0 | 0 | 0 |
| ibus-telex | 31 | 1 | 9 | 0 | 0 | 0 |
| XKey | 6 | 1 | 1 | 0 | 0 | 1 |
| vi-rs | 5 | 0 | 0 | 0 | 0 | 0 |
| bamboo-core | 8 | 0 | 0 | 0 | 0 | 2 |
| ibus-bamboo | 1 | 0 | 0 | 0 | 0 | 0 |
| goxkey | 1 | 0 | 0 | 0 | 0 | 0 |
| **Tổng** | **435** | **1.493** | **73** | **0** | **0** | **4** |

**Lần xét đầu** (cùng ngày, trước khi sửa engine, khung test và `extract.sh`): 10.320 ca, 240 họ không kiểm chữ, 7.971 khớp, 2.109 khác (A 359, B 1.492, C 73, D 10, E 77, X 98).
Từ đó:

- 10 ca lớp D: 7 khớp, 3 sang A (D26, D35 ("uơ" và "ươ")).
- 77 ca lớp E: 16 khớp (câu hỏi về phím biến đổi khác loại, về dấu ngay sau "qu" và "qui", về vần "uêu"), 61 sang A theo quyết định đã chốt.
- 48 ca X thiếu mô phỏng D20: khớp cả.
- 7 ca X của XKey và bamboo-core mà họ không kiểm chữ trên màn hình: 5 khớp (vòng ⌫ nay ghi đủ), 2 còn X.
- 43 ca trích sai:
  - 6 bị bỏ (test chỉ in);
  - 23 khớp;
  - 11 sang A (D32 10, D31 1);
  - 1 sang B;
  - 1 thành câu hỏi về xoá hết từ dài bằng ⌫ rồi gõ từ mới (mục 9.8);
  - 1 thành X (nhánh `if` không xảy ra ở Dấu).
- 8 ca lần đầu khớp nay khác:
  - 3 X (`←` là `clear()`), 2 A (D20 + D26) và 1 ca chữ cái gõ sát chữ có sẵn (mục 9.8), do khung test nay mô phỏng D20;
  - 2 A do D35 mới ("uwo" → "uơ").

Sau đó, cùng ngày:

- Ca xoá hết từ dài bằng ⌫ khớp sau khi D33 chốt (commit 0a9bb4b).
- Ca chữ cái gõ sát chữ có sẵn và 3 ca A-D20 ("duow␣⌫c") khớp sau khi D20 đọc cả ở chữ cái đầu tiên.
- Với ba ngoại lệ của D20, 26 ca đổi đầu ra (mục 9.8):
  - 2 ca X của chuỗi gonhanh (`←` là `clear()`) nay khớp, ca X thứ ba vẫn X;
  - 2 ca B của uvie-rs ra chữ khác nhau nhưng vẫn B;
  - 22 ca còn lại vẫn khớp.

### 9.3 Lớp A — Dấu cố ý khác (435)

| Quyết định | Ca | Điểm khác |
|---|---|---|
| D26 | 217 | gõ đúp phím dấu/biến đổi bỏ biến đổi và khoá tới hết từ, kể cả sau ⌫; mốc khôi phục là chữ đang hiển thị (D4), nên từ tiếng Anh mất một chữ (đã chấp nhận ở D26). Trong đó 84 ca của fcitx5-unikey: UniKey dùng w thứ hai để thêm móc cho u ("uow" rồi w ra "ươ"), Dấu coi đó là gõ đúp, còn uơ/ươ do D35 tự quyết. 4 ca dấu thanh của vần oo nằm ở o thứ hai (ví dụ "xoòng" trong D26). 1 ca "ww" trên "ưa" bỏ móc ("chuawrwz" → "chủawz") |
| D30 (dấu thanh trên vần tắc) | 36 | huyền, hỏi, ngã trên vần có âm cuối p, t, c, ch được nhận giữa từ ("catr" hiện "cảt"); kết thúc từ D4 khôi phục; khi tắt tự khôi phục thì chữ đó ở lại |
| D31 (nới cho địa danh) | 33 | k đứng trước mọi nguyên âm nên "kò", "ká", "Kẩ", "kô" hợp lệ; âm cuối k chỉ sau ă và phải có sắc/nặng, nên "Busk" và "Ddawk" (không dấu) được khôi phục |
| D4 (tiếng Việt thắng) | 21 | từ vừa là tiếng Anh vừa là âm tiết hợp lệ ra chữ Việt (sims → sím, per → pẻ, wrong → ưởng) |
| D32 | 20 | ⌫ xoá chữ cuối đang hiển thị và đặt lại dấu ("tiế" ⌫ → "tí"; "thật" ⌫⌫ → "th"); nguồn khác xoá theo phím ("thật" ⌫⌫ → "thạ") |
| D30 | 19 | từ đã sai chính tả thì phím sau đi thẳng như chữ cái, không biến đổi và không bị nuốt |
| D4, D31 (khôi phục khi kết thúc từ) | 18 | chữ không phải âm tiết (đ, â, ă, ấ, đs, đm, Đ trước "$") được trả về đúng phím đã gõ |
| D30, D20 (không tự thêm dấu phụ) | 15 | Dấu không tự thêm mũ hay móc người gõ chưa gõ (thuocs → thuóc giữa từ, kết thúc từ khôi phục; uvie-rs tự thêm thành thuốc) |
| D26 (giới hạn đã biết) | 13 | từ tiếng Anh có chữ lặp trùng phím dấu/biến đổi mất cả dấu lẫn chữ ("worry" → "ưory", "express" → "êps", "versus" → "veus") |
| D4 (chỉ khôi phục khi kết thúc từ) | 10 | giữa từ Dấu còn hiện chữ đã biến đổi; uvie-rs bỏ biến đổi ngay khi vần sai; kết thúc từ hai bên ra cùng chữ |
| D35 | 10 | "uow", "uwo", "nuo7" ở cuối từ ra uơ, không phải ươ ("uwo␣" → "uơ␣", "nguwo" → "nguơ", "huwo" → "huơ") |
| D31 (b, m, p, v + âm đệm) | 5 | "more", "bore", "pore" ra "moẻ", "boẻ", "poẻ" (hợp lệ, tiếng Việt thắng theo D4) |
| D28 | 3 | bỏ dấu tự do tắt; d sau nguyên âm biến d đầu từ thành đ |
| D28 (phím biến đổi khác loại) | 3 | "aaw" → "ă", "ooww" → "ow" (đổi dấu, rồi "ww" bỏ móc theo D26) |
| D15 | 2 | kiểu cũ ra "hòa"; đáp án của uvie-rs là kiểu mới dù test chạy kiểu cũ |
| D20, D26 | 2 | sau ⌫ qua dấu cách, phím biến đổi đọc lại từ trước và gõ đúp bỏ mũ ("tuân" + a → "tuana", "tiêng" + e → "tienge"); gonhanh coi a, e là chữ |
| D31 ("qui" không hợp lệ) | 2 | "quis", "quir" (kiểu cũ) giữ nguyên; uvie-rs ra "quí", "quỉ" |
| D40 (phím z) | 2 | z khi từ chưa có dấu thanh là chữ z, không bỏ mũ ("kongoz" hiện "kôngz" khi tắt tự khôi phục); gonhanh bỏ mọi dấu phụ |
| D31 (iê không đứng đầu âm tiết) | 1 | "ieje" không biến đổi |
| D21, D23 (w → qu chỉ ở VNI), D36 (VNI: chữ số thành dấu) | 1 mỗi quyết định | gõ tắt phụ âm chỉ khi kết thúc từ; Telex không có w → qu; chữ số không đặt được dấu thì đi thẳng |

### 9.4 Lớp B — do tuỳ chọn của nguồn (1.493)

| Tuỳ chọn | Ca | Ghi chú |
|---|---|---|
| `src:dictionary` (ibus-teni) | 1.416 | gần hết là từ viết tắt có đ (đbp, hđqt, tnđh…), từ mượn nhiều âm tiết (amiđan, bôxit, café), từ tiếng Anh giữa từ; Dấu không dùng từ điển (D4, D31) |
| `src:englishDictionary` (gonhanh, uvie-rs) | 67 | giữa từ họ đã hiện chữ tiếng Anh ("good"), Dấu hiện "gôd" và khôi phục khi kết thúc từ; từ sai không có trong danh sách của họ thì họ giữ nguyên (chứcc, tàoo, đc). "good←book": "gôd" có sẵn không phải tiếng Việt nên "book" gõ sau reset đi thẳng ("gôdbook", D20 ngoại lệ (b)); họ ra "goodbook" |
| `src:spellcheck=off` (fcitx5-unikey, XKey, ibus-telex) | 10 | họ biến đổi cả chữ không phải âm tiết ("baao␣" ra "bâo␣"); Dấu kiểm tra chính tả luôn chạy (D30) |

### 9.5 Lớp C — đáp án của họ sai chính tả (73)

| Luật | Ca |
|---|---|
| vần không có trong tiếng Việt: âi, êi, ăi, ăo, âo, oâ, ôa, ơng, aum, âum, uôp, uên, ưn, ươ đứng một mình, "uo" không mũ trước âm cuối, oo không âm cuối | 25 |
| iê không đứng đầu âm tiết, phải viết yê (D31) | 20 |
| vần kết thúc p, t, c, ch chỉ mang sắc hoặc nặng (D31): âp, ăp, ăc, ôc, têp, ưc, ưt, ưp, ươc, ươt, ươp | 11 |
| dấu thanh của vần oo nằm ở o thứ hai (soóc, moóc), không ở o thứ nhất | 6 |
| ă, â không đứng cuối âm tiết (D31) | 6 |
| phân bố c/k, g/gh, ng/ngh, q+u (D31): cí, ghá, nghá, qá, qư | 5 |

### 9.6 Lớp X — không so được (4)

| Nguyên nhân | Ca | Ghi chú |
|---|---|---|
| `←` là `clear()` của engine họ, không phải phím mũi tên (mục 2.1) | 1 | gonhanh `integration_test.rs:complex_mau_sac_continuous_session#24`: sau `clear()` họ gõ tiếp sát chữ cũ như trong ô mới; khung test của Dấu coi `←` là phím mũi tên nên D20 đọc từ ngay trước con trỏ ("mà" + "sawsc" ra "măsc", họ ra "sắc"). Hai ca cùng chuỗi `#3`, `#17` ("sắc" + "ddepj", "sắc" + "ddor") nay khớp nhờ D20 ngoại lệ (c). Muốn so được thì khung test phải chạy `clear()` như đổi ô nhập (reset và biết trước con trỏ không có từ) |
| Họ không kiểm chữ trên màn hình | 2 | "raw-keys view" của bamboo-core |
| Nhánh `if` trên trạng thái engine của họ không xảy ra ở Dấu | 1 | XKey `VNEngineTests.swift:testTelex_BackspaceAndRetype_LY#3` chỉ chạy khi engine của họ còn "l" sau hai ⌫; ở Dấu "lý" ⌫⌫ còn rỗng (D32), và nhánh kia (`#2`) khớp |

Đã giải quyết (05/11/2026):

- 43 ca do `extract.sh` trích sai ở lần đầu (xem Hiện trạng và mục 9.2):
  - uvie-rs: hàm phụ `backspace(&mut e, &mut screen)` không được nhận, vòng ⌫ chỉ ghi một lần, test chỉ in kết quả, vòng lặp qua mảng từ;
  - gonhanh: `engine_on()` bị đọc thành `autoRestore=off`;
  - XKey: hai nhánh `if` bị gộp;
  - fcitx5-unikey: hàng đợi commit của `testBasic#2`.
- 48 ca khung test bước 2 chưa mô phỏng D20, nay khớp cả 48 sau commit f39f066.

### 9.7 Lớp D — lỗi của Dấu (0; bốn kiểu của lần xét đầu đã sửa)

Bốn kiểu tìm thấy ở lần xét đầu, đã sửa ở commit 4d908e3 (và 36da993 cho VNI "u7o"); quyết định ghi ở D26, D29, D31, D35.
Các kiểu đánh số 1–4 trong bảng (không phải số quyết định).

| Kiểu | Ví dụ (nguồn, id) | Phím | Dấu ra trước | Dấu ra bây giờ | Dựa vào |
|---|---|---|---|---|---|
| 1. w sau "gi" không thành ư (2 ca) | vi-rs `simple_telex.txt:56.1`, `57.1` | `giw`, `giwax` | giw, giwax | giư, giữa (khớp) | D29, D31 |
| 2. w thứ hai trên "ưa" không bỏ móc (3 ca) | ibus-teni `nodict.tdata:9`; vi-rs `simple_telex.txt:65.1` | `huaww`, `chuawrwz` | hưaw, chửawz | huaw (khớp); chủawz (lớp A, D26: vi-rs đặt dấu hỏi ở a) | D26 |
| 3. "uwo" không cho uơ/ươ (3 ca) | gonhanh `permutation_test.rs:horn_order_diphthong#4`; uvie-rs `bugfix_tests.rs:test_uw_then_o_open_syllable#1`; bamboo-core `bamboo_test.go:TestDoubleTyping#2` | `uwo␣`, `nguwo`, `buwoo` | ưo␣, ngưo, bươo | uơ␣, nguơ (lớp A, D35: hai bộ gõ kia ra ươ); buô (khớp) | D35, D28 |
| 4. bảng vần thiếu "oao" (2 ca) | vi-rs `simple_telex.txt:54.1`; gonhanh `english_auto_restore_test.rs:pattern2_aa_vowel_pair#8` | `ngoaos`, `ngoafo␣` | ngoaos, ngoafo␣ | ngoáo, ngoào␣ (khớp) | D31 |

### 9.8 Lớp E — cần người dùng quyết định (0; chín câu hỏi của lần xét đầu đã chốt)

Người dùng đã chốt chín câu hỏi ngày 05/11/2026; các ca còn khác nay thuộc lớp A (mục 9.3).
Vòng xét đầu đặt mã E1–E9 cho chín câu hỏi này.
Mã chỉ còn trong cột đầu của bảng dưới, để tra ngược: `docs/history/DECISIONS-LOG.md` (lưu trữ, không sửa) còn dẫn theo "E8" và "E9".

| Mã cũ | Câu hỏi | Ca lần đầu | Quyết định |
|---|---|---|---|
| E1 | Huyền/hỏi/ngã trên vần đã có âm cuối p, t, c, ch | 36 | D30: nhận giữa từ, kết thúc từ D4 khôi phục |
| E2 | Phím biến đổi khác loại trên nguyên âm đã có dấu phụ, kể cả cặp ươ | 10 | D28: đổi sang dấu mới ("ươ" + o → "uô") |
| E3 | Phím dấu ngay sau "qu"; "qui" có hợp lệ không | 10 | D31: nhận dấu ngay sau "qu" ("qusa" → "quá"), "qui" vẫn không hợp lệ; D32: "quá" ⌫ → "qu" |
| E4 | Mốc khôi phục sau gõ đúp làm từ tiếng Anh mất hơn một chữ | 13 | D26: ghi là giới hạn đã biết, giữ hành vi |
| E5 | b, m, p (và v) đi với âm đệm o/u | 5 | D31: hợp lệ ("more" → "moẻ") |
| E6 | z khi từ chưa có dấu thanh | 2 | D40: z là chữ, không bỏ mũ/móc |
| E7 | Vần "uêu" | 1 | D31: thêm "uêu" và "oao" vào bảng vần |
| E8 | Chữ cái thường gõ sát chữ có sẵn sau một lần reset: trước đây D20 chỉ đọc chữ trước con trỏ ở phím dấu/biến đổi, nên chữ cái bắt đầu từ mới ("q" có sẵn + "uer" → "qủe") | 1 | D20 ("Chữ cái gõ sát chữ có sẵn"): chữ cái đầu tiên cũng đọc từ trước con trỏ, chỉ nối khi từ ghép còn là tiền tố hợp lệ (D30) |
| E9 | Từ dài quá 7 chữ (D33) bị xoá hết bằng ⌫ rồi gõ từ mới ngay đó | 1 | D33: xoá hết từ bằng ⌫ thì hết trạng thái đi thẳng |

Hai câu hỏi của lần xét thứ hai (đáp án của họ trích nguyên văn chỉ để mô tả):

| Câu hỏi | Ví dụ (nguồn, id) | Phím | Dấu ra trước | Dấu ra bây giờ | Bộ gõ kia ra |
|---|---|---|---|---|---|
| Chữ cái sát chữ có sẵn (E8) | fcitx5-unikey `testunikey.cpp:testBasic.surrounding#1` (tắt tự khôi phục) | `⟦q⟧uer⏎` | qủe⏎ | quẻ⏎ (khớp) | fcitx5-unikey: commit "uẻ" sau chữ q có sẵn |
| Xoá hết từ dài bằng ⌫ (E9) | uvie-rs `feed_diff_tests.rs:diff_sticky_full_erase_restores_vietnamese#3` | `permission` + 10 ⌫ + `vieetj` | vieetj | việt (khớp) | uvie-rs: việt |

**Cách chọn cho chữ cái sát chữ có sẵn (câu hỏi E8; mô phỏng, 05/11/2026).**

- Ba phương án chạy bằng engine của Dấu trên 10.303 ca và các tình huống sửa chữ, qua bản sao khung test `ExternalCasesTests` (mô hình theo `InPlaceComposer`, chưa chạy trên Dấu thật):
  - chỉ đọc ở phím dấu/biến đổi, như trước (cách cũ);
  - đọc cả ở chữ cái đầu tiên và luôn nối vào từ đọc được (luôn nối);
  - như luôn nối nhưng chữ cái chỉ nối khi từ ghép còn là tiền tố hợp lệ (nối có điều kiện).
- So với cách cũ:
  - luôn nối ra khác ở 38 ca và làm hỏng 34 ca trong đó, vì dính từ mới vào từ trước con trỏ (sau ⌫ qua dấu cách hay sau reset, "ddi␣⌫hocj" ra "đihocj" thay vì "đihọc");
  - nối có điều kiện ra khác ở 4 ca: ca "q" + "uer" và 3 ca "duow␣⌫c" của gonhanh (`bug_reports_test.rs:bug_duow_restore_horn#1`, `bug_duow_double_break_backspace_horn#1`, `bug_dduow_break_backspace_final#1`), giữa từ ra "dươc", "đươc".
- Người dùng chọn nối có điều kiện (D20).
- Sau khi khung test trong repo mô phỏng cách này, `compare.sh` cho đúng 4 ca đó đổi đầu ra, cả 4 khớp với họ.
- Lớp IMK làm ở `InPlaceComposer` (test `InPlaceComposerLetterTests`).

**Ba ngoại lệ của D20 (mô phỏng rồi đo trong repo, 05/11/2026).**

- Người dùng chốt ba ngoại lệ sau mô phỏng cùng cách trên, cho các giới hạn còn lại của cách nối có điều kiện ("#Hà" + "Nooij" ra "#HàNooij", "foo" + "bar" ra "foobả", "anh" + "emx" ra "anhemx"):
  - (a) chữ hoa sau chữ thường bắt đầu từ mới;
  - (b) từ có sẵn không phải tiếng Việt nhận chữ gõ tiếp nguyên văn tới hết từ;
  - (c) phím dấu/biến đổi đầu tiên không áp dụng được lên từ tiếng Việt có sẵn thì bắt đầu từ mới (D20).
- Trên 10.303 ca, mô phỏng cho (a) đổi 0 ca, (b) đổi 2, (c) đổi 24, không bất biến nào hỏng.
- Khung test trong repo làm theo (`ExternalCasesTests.d20Seed`):
  - từ dài hơn 7 chữ đi vào trạng thái đi thẳng của D33 bằng `VietEngine.seedOverflow`;
  - áp (b) cho cả phím dấu lẫn chữ cái và cho (b) thắng (a);
  - (a) không áp cho phím dấu có đặt dấu lên từ (D20);
  - đúng 26 ca đổi đầu ra, như mô phỏng.
- Các ca đổi:
  - (b): uvie-rs `real_api_sim.rs:real_type_good_then_arrow_then_type#3`, `real_type_good_escape#3` ("good←book" ra "gôdbook", trước "gôdbôk"; vẫn lớp B);
  - (c): 24 ca của chuỗi gonhanh `integration_test.rs:complex_mau_sac_continuous_session` (`#3`–`#26`), "sắc" + "ddepj" nay "sắcđẹp", "sắc" + "ddor" nay "sắcđỏ"; `#3` và `#17` chuyển từ X sang khớp.
- `compare.sh`: khớp 8.061 → 8.063, X 6 → 4, A, B, C, D, E không đổi.
- Lớp IMK làm ở `InPlaceComposer` (test `InPlaceComposerExceptionTests`); chưa gõ thử trên Dấu thật.

Chữ tiếng Việt dựng sẵn đến như một phím (mục 2.1, 7 ca): cả 7 ca khớp với họ; D40 chốt Dấu coi đó là một chữ cái của từ.
