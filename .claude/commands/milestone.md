---
description: Điều phối trọn một mốc trong docs/ROADMAP.md bằng các subagent, có kiểm toán trước khi đóng mốc
argument-hint: <M0..M10>
disable-model-invocation: true
---
Điều phối mốc **$ARGUMENTS** theo mục "Điều phối" trong `CLAUDE.md`:

1. Đọc `docs/PROGRESS.md`, `docs/DECISIONS.md`, mục $ARGUMENTS trong `docs/ROADMAP.md`. Nếu mốc trước chưa ĐẠT thì dừng và báo.
2. Chia mốc thành việc nhỏ, ghi kế hoạch vào `docs/PROGRESS.md` (việc, agent phụ trách, việc nào chạy song song được).
3. Việc nhỏ và vừa phiên chính tự làm; việc lớn giao subagent phù hợp, việc độc lập thì giao song song. Trước khi giao từ 3 agent trở lên trong một lượt: báo người dùng số agent và mức nặng, chờ đồng ý. Mỗi lần giao: nêu rõ phạm vi, file được sửa, tiêu chí xong.
4. Sau mỗi kết quả: đọc 5 mục báo cáo, chạy lại lệnh kiểm chứng, `scripts/check-docs/check.sh` và `scripts/check-l10n/check.sh`, commit nếu xanh. Mâu thuẫn hoặc câu hỏi mở thì ghi vào `docs/PROGRESS.md`.
5. Gọi `auditor` một lần khi mốc xong, rà cả **nội dung** `docs/` và `scripts/` (mâu thuẫn giữa các file, giả thiết ghi như sự thật, nhật ký có kết luận đã bị bác mà chưa đánh dấu), không chỉ `check.sh`. CHƯA ĐẠT thì giao sửa các mục "chặn", rồi kiểm toán lại chỉ trên danh sách đó; mục "ghi chú" vào `docs/PROGRESS.md`.
6. Đóng mốc: cập nhật `docs/PROGRESS.md` (đã làm, số đo, câu hỏi mở), chuyển nhật ký và ghi nhớ của mốc sang `docs/history/` (thêm vào mục lục `docs/README.md`), tóm tắt cho người dùng, liệt kê việc người dùng cần làm. Chỉ chuyển mốc tiếp khi không còn việc chờ người dùng chặn đường.
