# Kế hoạch của các mốc đã đóng

Chép nguyên từ `docs/PROGRESS.md` khi sắp xếp lại tài liệu (03/11/2026). Kết quả từng việc nằm ở nhật ký `PROGRESS.md`.

## M0 + M1
| Việc | Agent | Song song |
|---|---|---|
| M0: git init, .gitignore, LICENSE, README, project.yml, khung 2 app + 2 package, build Debug universal | release-eng | với M1-nghiên cứu |
| M1a: clone OpenKey ra /tmp, viết `docs/OPENKEY-NOTES.md` | researcher | với M0 |
| M1b: engine Telex + test (sau M1a, đối chiếu mâu thuẫn trước) | engine-dev | sau M1a |
| M1c: VNI, Telex đơn giản, gõ tắt phụ âm, test hiệu năng | engine-dev | sau M1b |
| Kiểm toán M0, M1 | auditor | cuối mỗi mốc |

## M3 (30/10/2026)
| # | Việc | Agent | Song song |
|---|---|---|---|
| T1 | Chế độ gạch chân D13 (`setMarkedText`, chốt chữ khi kết thúc từ/reset), bật theo quy tắc người dùng; đo thử ở Chrome, VS Code, Terminal với phím dồn (0/5/10 ms) | imk-dev | cùng T5 |
| T5 | Khung `docs/COMPATIBILITY.md`: danh sách app cần thử (app phổ biến ở VN, app đã cài trên máy), cột kết quả, cách thử | researcher | cùng T1 |
| T2 | D20 "Thêm dấu cho từ đã gõ" ở bộ gõ (đọc chữ trước con trỏ bằng `attributedSubstring` khi bộ đệm rỗng, `seed`); reset khi đổi nguồn không qua `activateServer`; rà D18 | imk-dev | sau T1 (cùng file controller) |
| T3 | Danh sách tương thích có sẵn trong bản build (D7, D13): model ở DauShared, bộ gõ đọc, app hiện "Đề xuất"; nội dung theo kết quả T1 | imk-dev + app-ui-dev | sau T1 |
| T4 | Mở lại giao diện đã làm xong (lựa chọn gạch chân, công tắc D20), bỏ ô trống M3 tương ứng | app-ui-dev | sau T2, T3 |
| T6 | Chạy ma trận tương thích trên máy, ghi tự sửa chính tả (D4) | phiên chính + agent GUI | sau T4 |
| T7 | VoiceOver đọc tên nguồn (D17), biểu tượng V | người dùng | bất kỳ lúc nào |
| T8 | Kiểm toán M3 | auditor | cuối |

## M5 (30/10/2026)
| # | Việc | Agent | Song song |
|---|---|---|---|
| T1 | Trả lời câu hỏi mở: `TISRegisterInputSource`/`TISEnableInputSource` từ app chủ có cần người dùng xác nhận, có phải đăng xuất lần đầu không; app chủ có sandbox chép được bộ gõ vào `~/Library/Input Methods` không (temporary-exception); cách các bộ gõ mở cài/gỡ; danh sách bundle ID bộ gõ tiếng Việt cũ | researcher | cùng T2 |
| T2 | Giao diện onboarding 3 bước theo artboard (OnboardingConflict, OnboardingEnable, Onboarding), dịch vụ cài/bật/phát hiện để giao diện gọi qua protocol, hiện đúng phím tắt hệ thống | app-ui-dev | cùng T1 |
| T3 | Dịch vụ cài đặt thật: chép bộ gõ nhúng sẵn, đăng ký, bật (người dùng bấm, N4) có Hoàn tác, nâng cấp bản mới (dừng tiến trình cũ), gỡ cài đặt (D16, sheet xác nhận) | imk-dev (+ app-ui-dev nối giao diện) | sau T1 |
| T4 | ~~Thử trên máy: gỡ bản Debug hiện tại rồi chạy onboarding từ đầu~~ — bỏ (người dùng chốt 04/11/2026). Phần gỡ qua app rồi chạy onboarding từ đầu đã làm 04/11 với bản Release (nhật ký 04/11); không thử trên tài khoản macOS mới | — | — |
| T5 | Kiểm toán M5 | auditor | cuối |
