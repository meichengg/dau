# Bảng thuật ngữ Anh–Việt

Thuật ngữ dùng trong chuỗi giao diện của Dấu (String Catalog, D41 (Ngôn ngữ giao diện)), để câu tiếng Anh và tiếng Việt gọi một thứ bằng cùng một từ ở mọi màn. Câu tiếng Anh theo thuật ngữ Apple tiếng Anh, câu tiếng Việt theo thuật ngữ Apple tiếng Việt (D38 (Chữ trên giao diện)). Thêm từ mới vào đây trước khi viết câu dùng nó. Kiểm mọi khoá có đủ bản `en` và `vi`: `scripts/check-l10n/check.sh`.

## Không dịch

- **Dấu**: giữ nguyên ở mọi ngôn ngữ (D24 (Tên và định danh)).
- **Tên giao diện của macOS** (System Settings, Keyboard, Input Sources, Edit…, Add, Done, Allow, Don’t Allow, Log Out, Applications, Trash, Language & Region ("Ngôn ngữ & Vùng") và mục Applications của nó, tên ngôn ngữ Vietnamese, tuỳ chọn "Automatically switch to a document’s input source"): không viết trong câu, luôn là `%@` lấy từ chuỗi của hệ thống (`SystemUINames`, `LayoutNames`; D38).
- **Nhãn trong app của người khác** (OpenKey "Bảng điều khiển…", "Khởi động cùng macOS", "Thoát"; XKey "Thoát XKey"; Gõ Nhanh "Launch at login"; tên app khác như "Gõ Nhanh"): chép đúng chữ app đó hiện, cả trong câu tiếng Anh.
- **Gõ Nhanh**: tên app khác, giữ nguyên chữ có dấu tiếng Việt trong câu tiếng Anh.
- **Ví dụ gõ** (`hoaf binhf`, `hoà`, `thúy`…): dữ liệu, không dịch.

## Thuật ngữ

| Tiếng Anh | Tiếng Việt | Ghi chú |
|---|---|---|
| input source | nguồn đầu vào | khái niệm của macOS; không dùng "nguồn nhập liệu" trong giao diện (D38) |
| Input menu | menu nguồn đầu vào | menu nguồn đầu vào trên thanh menu |
| input method | bộ gõ | phần mềm gõ (Dấu, OpenKey…); "bộ gõ Dấu" là tiến trình bộ gõ, khác app Dấu |
| Dấu – Vietnamese | Dấu – Tiếng Việt | tên nguồn đầu vào; macOS chọn theo ngôn ngữ hệ thống (D41), nên trong câu luôn là `%@` (`SystemUINames.dauInputSource`), không viết cứng |
| typing method | kiểu gõ | Telex, VNI, Simple Telex |
| Simple Telex | Telex đơn giản | D29 (Telex đơn giản) |
| tone mark placement | vị trí dấu thanh | Modern / Classic = kiểu mới / kiểu cũ |
| mark key | phím dấu | |
| free mark placement | bỏ dấu tự do | |
| restore non-Vietnamese words | tự khôi phục từ không phải tiếng Việt | D4 (Từ nước ngoài) |
| add marks to typed words | thêm dấu cho từ đã gõ | D20 (Thêm dấu cho từ đã gõ) |
| consonant shortcuts | gõ tắt phụ âm | D21 (Gõ tắt phụ âm) |
| Smart Typing | Thông minh | mục trong sidebar |
| underline | gạch chân | quy tắc theo app: Underline / No Underline = Có gạch chân / Không gạch chân (D5 (Quy tắc theo ứng dụng), D13 (Gạch chân là đường lui cuối cùng)) |
| app rules | quy tắc riêng | |
| Suggested | Đề xuất | nhãn và mục của danh sách tương thích |
| Dấu Settings | Cài đặt Dấu | tên cửa sổ Cài đặt; menu bộ gõ: "Dấu Settings…" / "Cài đặt Dấu…" |
| Set Up Dấu, Setup Guide… | Thiết lập Dấu, Hướng dẫn thiết lập… | cửa sổ onboarding và mục menu Help |
| turn on / turn off | bật / tắt | |
| Try Again | Thử lại | |
| Reinstall | Cài lại | |
| Uninstall… | Gỡ cài đặt… | bỏ khỏi nguồn đầu vào = remove from input sources |
| Release channel, Stable | Kênh phát hành, Ổn định | |

## Cách viết câu tiếng Anh

- Hoa đầu mỗi từ (title case) cho nút, mục menu, tiêu đề cửa sổ, sheet, mục sidebar và lựa chọn của menu chọn; hoa chữ đầu câu (sentence case) cho tên hàng, tiêu đề nhóm, mô tả, câu gợi ý.
- Tiêu đề ngắn dạng cụm từ (alert, banner) viết Title Case; tiêu đề là câu đầy đủ viết sentence case.
- Dấu nháy cong “ ” và ’, dấu ba chấm là một ký tự (…), như chuỗi của macOS.
- Phím Enter của bàn phím Mac gọi là Return.
