# Luồng chính của trang web bận bao lâu khi người dùng gõ

## Hiện trạng (09/11/2026)

Câu hỏi: trên các trang web người ta hay gõ, luồng chính của trang bận đủ lâu (từ khoảng 100 ms, bằng khoảng cách hai phím khi gõ bình thường) trong lúc gõ thường xuyên đến đâu? Lý do hỏi: đo ngày 09/11/2026 (`docs/PROGRESS.md`, nhật ký, đo lại riêng Chrome) cho thấy khi luồng chính của trang bận lâu hơn khoảng cách giữa hai phím, Chrome trả `selectedRange` cũ và thay tại chỗ sai; gạch chân (D13 (Gạch chân là đường lui cuối cùng)) không bị.

- **Dữ liệu dùng được:** số đo thật từ người dùng Chrome (CrUX), tháng 09/2026, bản desktop, theo origin, lấy qua trang công khai của Treo. Không có tài khoản, không đo trên máy ai.
- **Dữ liệu CrUX không có mốc 100 ms.** Chỉ có ba nhóm: tốt (≤ 200 ms), cần cải thiện (200–500 ms), kém (> 500 ms), và p75. Tỉ lệ ở mốc 100 ms không lấy được từ nguồn công khai không cần tài khoản.
- **Trên 17 origin có dữ liệu** (bảng ở mục 3): p75 INP từ 25 ms (vnexpress.net) đến 350 ms (chatgpt.com). Tỉ lệ lượt truy cập có INP trên 200 ms từ 2,7% (vnexpress.net) đến 45,6% (app.slack.com).
- **Trang đọc và tìm kiếm: ít lượt chậm** (vnexpress.net, github.com, www.google.com: 2,7–7,1% lượt trên 200 ms). **Ứng dụng chat, mạng xã hội, mua sắm: nhiều lượt chậm** (Slack, ChatGPT, Shopee, X, Telegram, Discord, LinkedIn, YouTube, Facebook: 27–46% lượt trên 200 ms).
- **Toàn web (Web Almanac 2025, tháng 7/2025):** desktop 97% origin có INP tốt, 2% cần cải thiện, dưới 1% kém. Điện thoại 77% / 21% / 3%. Số này tính theo origin (p75), nên không cho thấy các lượt chậm trong một origin có p75 tốt.
- **Không suy ra được tỉ lệ lỗi của Dấu từ các số này** (mục 4). Chúng cho biết rủi ro có thật ở một nhóm trang, tập trung ở ứng dụng web nặng; chúng không cho biết bao nhiêu chữ sẽ sai.
- **Chưa kiểm chứng:** Chrome có tính phím đi qua bộ gõ vào INP không (mục 4). Các số trong tài liệu này chỉ nói về độ bận của trang, không phải của riêng việc gõ qua bộ gõ.
- **chat.zalo.me không có dữ liệu CrUX** (origin chưa đủ lượt truy cập hoặc chưa được liệt kê). Không có số cho Zalo web.

## 1. INP đo gì (nguồn: web.dev, đọc 09/11/2026)

Nguồn: https://web.dev/articles/inp và https://web.dev/articles/optimize-input-delay.

- INP (Interaction to Next Paint) đo độ trễ của các tương tác trong cả vòng đời một lượt xem trang. Tương tác gồm nhấp chuột, chạm, và **nhấn phím** (một lần nhấn gồm `keydown`, `keypress`, `keyup`). Cuộn, rê chuột, thu phóng không tính.
- Mỗi tương tác có ba phần: **độ trễ đầu vào** (từ lúc người dùng thao tác đến lúc hàm xử lý đầu tiên chạy; dài ra khi luồng chính đang bận), **thời gian xử lý** (mọi hàm xử lý chạy xong), **độ trễ hiển thị** (từ lúc xử lý xong đến khi khung hình lên màn hình). INP của một tương tác là tổng ba phần.
- **Một lượt xem trang cho một số:** tương tác dài nhất, bỏ ngoại lệ (với trang có nhiều tương tác, bỏ một tương tác cao nhất cho mỗi 50 tương tác).
- **Số báo cáo cho một origin hay trang:** phân vị thứ 75 (p75) của các lượt xem. Ngưỡng: tốt ≤ 200 ms, cần cải thiện 200–500 ms, kém > 500 ms. Cột "tốt / cần cải thiện / kém" trong bảng là tỉ lệ **lượt xem trang** rơi vào mỗi nhóm, không phải tỉ lệ tương tác hay tỉ lệ phím.
- Web.dev nêu rõ: nhiều lần gõ phím có thể dồn trong thời gian rất ngắn ở ô nhập; hàm xử lý phím tốn thời gian (gợi ý tự động, gọi mạng) làm các phím chồng lên nhau; tương tác sau đến trước khi tương tác trước vẽ xong thì bị trễ thêm.

CrUX (nguồn dữ liệu): https://developer.chrome.com/docs/crux/methodology. Chỉ gồm người dùng Chrome bật báo cáo thống kê sử dụng và đồng bộ lịch sử; Chrome trên iOS, WebView, trình duyệt Chromium khác không có. Origin phải đủ phổ biến (ngưỡng không công bố). Tài liệu đó không nêu cửa sổ 28 ngày hay cách tính p75; hai điều ấy không dẫn từ nguồn Chrome.

## 2. Phương pháp và nguồn

- **PageSpeed Insights API v5 (không khoá):** thử 09/11/2026, cả 18 origin trả HTTP 429, hạn mức mỗi ngày của dự án dùng chung bằng 0 (`quota_limit_value: 0`). Không dùng được khi không có khoá.
- **CrUX API (`chromeuxreport.googleapis.com`):** trả HTTP 403 khi không có khoá. Cần tài khoản Google Cloud; không dùng.
- **Treo, báo cáo tốc độ trang công khai** (https://treo.sh/sitespeed/<origin>?formFactor=desktop), đọc 09/11/2026: trang này hiển thị dữ liệu CrUX theo origin, kỳ mới nhất là **09/2026**, bộ lọc "desktop". `robots.txt` của Treo cho phép đọc (chỉ chặn `/a/` và `/demo/`). Mỗi origin một lần tải, cách nhau 3 giây. HTML thô lưu ở `build/web-input-delay/treo-<origin>.html` (không commit). Lấy ba số: p75 INP, và tỉ lệ tốt / cần cải thiện / kém.
- Kiểm chéo: github.com trên bộ lọc tất cả thiết bị cho 91,9% tốt, p75 75 ms; bộ lọc desktop cho 95,6% tốt, p75 50 ms. Hai số khác nhau như mong đợi, nên bộ lọc desktop có tác dụng.
- **Web Almanac 2025, chương Hiệu năng** (https://almanac.httparchive.org/en/2025/performance), dữ liệu tháng 7/2025: phân bố INP toàn web theo origin. Không có phần phụ của INP (độ trễ đầu vào, xử lý, hiển thị).
- Không tìm thấy nguồn công khai không cần tài khoản cho: phân phối độ trễ đầu vào riêng (phần phụ INP theo origin), phân phối theo tương tác, mốc 100 ms.

## 3. Bảng theo origin (CrUX 09/2026, desktop, qua Treo)

"Trên 200 ms" = 100% trừ tỉ lệ tốt (tính từ bảng); các tỉ lệ làm tròn đến 0,1 nên có thể lệch 0,1.

| Origin | p75 INP (ms) | Tốt (≤ 200) | Cần cải thiện (200–500) | Kém (> 500) | Trên 200 ms |
|---|---|---|---|---|---|
| vnexpress.net | 25 | 97,3% | 1,8% | 0,9% | 2,7% |
| github.com | 50 | 95,6% | 3,2% | 1,2% | 4,4% |
| www.google.com | 75 | 92,9% | 5,3% | 1,8% | 7,1% |
| www.notion.so | 125 | 84,2% | 10,5% | 5,3% | 15,8% |
| claude.ai | 125 | 84,0% | 11,9% | 4,1% | 16,0% |
| mail.google.com | 125 | 83,3% | 11,1% | 5,6% | 16,7% |
| docs.google.com | 175 | 78,5% | 15,0% | 6,5% | 21,5% |
| www.messenger.com | 175 | 77,4% | 14,4% | 8,2% | 22,6% |
| www.facebook.com | 200 | 72,5% | 17,4% | 10,1% | 27,5% |
| www.linkedin.com | 225 | 68,9% | 20,9% | 10,2% | 31,1% |
| www.youtube.com | 225 | 70,2% | 18,7% | 11,1% | 29,8% |
| discord.com | 250 | 69,4% | 18,1% | 12,5% | 30,6% |
| web.telegram.org | 250 | 68,0% | 21,6% | 10,4% | 32,0% |
| x.com | 250 | 63,1% | 30,1% | 6,8% | 36,9% |
| shopee.vn | 300 | 60,9% | 26,7% | 12,4% | 39,1% |
| app.slack.com | 325 | 54,4% | 33,5% | 12,1% | 45,6% |
| chatgpt.com | 350 | 56,8% | 25,7% | 17,5% | 43,2% |
| chat.zalo.me | không có dữ liệu | | | | |

Ghi chú đọc bảng:
- Mọi p75 đều là bội của 25 ms; nhiều khả năng Treo làm tròn. Số chính xác của CrUX không lấy được.
- Một origin là cả các trang của nó, không riêng ô soạn thảo hay ô chat. Ví dụ www.google.com gồm cả trang kết quả; docs.google.com gồm cả bảng tính và trình chiếu.
- Số "kém" của chatgpt.com (17,5%) cao hơn Slack (12,1%) dù p75 của Slack cao hơn; hai số này không mâu thuẫn, vì p75 và tỉ lệ nhóm đo hai chỗ khác nhau của phân phối.
- Bộ lọc "desktop" của CrUX gồm Windows, macOS, ChromeOS, Linux; không tách riêng macOS.

## 4. Giới hạn: số này nói được gì và không nói được gì về Dấu (N5 (Chỉ hứa điều đã kiểm chứng))

**Cận trên hay cận dưới của rủi ro?** Không phải cận chặt nào, vì lệch theo cả hai hướng.

Lệch làm INP **cao hơn** rủi ro của Dấu (INP là cận trên với một số phép so):
- INP gồm cả độ trễ hiển thị (khung hình lên màn hình) và thời gian xử lý của hàm xử lý. Lỗi của Dấu chỉ liên quan đến việc luồng chính chưa kịp áp phím trước, tức gần với độ trễ đầu vào cộng một phần xử lý.
- INP tính mọi loại tương tác, nhiều nhất là nhấp chuột, không riêng gõ phím trong ô nhập.
- INP lấy tương tác dài nhất của cả lượt xem (bỏ 1 trên 50). Một lượt có "INP > 200 ms" chỉ nói ít nhất một tương tác chậm, không nói người gõ gặp nó giữa lúc gõ chữ.

Lệch làm INP **thấp hơn** rủi ro của Dấu:
- Rủi ro của Dấu bắt đầu từ khoảng 100 ms (khoảng cách hai phím), thấp hơn ngưỡng 200 ms của CrUX. Tỉ lệ ở mốc 100 ms hiển nhiên cao hơn tỉ lệ "cần cải thiện hoặc kém", nhưng không có số.
- INP chỉ thấy luồng chính bận khi có một tương tác rơi trúng lúc bận. Luồng chính bận mà không có tương tác thì không được ghi.
- Người dùng gõ tiếng Việt có thể có thói quen và trang khác người dùng trung bình của CrUX (gõ nhiều, trong ô soạn thảo, trang nặng hơn). Không có số.

Những điều chưa biết hoặc chưa kiểm chứng:
- **Suy luận, cần kiểm chứng:** phím đi qua bộ gõ (IMK) rồi mới vào trang dưới dạng sự kiện soạn thảo (`keydown` mã 229, `compositionupdate`, `input`). Chưa rõ Chrome có tính các phím này là "tương tác" cho INP hay không; nếu không, nhiều lần gõ qua bộ gõ không vào số INP, và INP của người gõ tiếng Việt khác số trong bảng. Chưa tìm được nguồn chính thức cho điểm này.
- Không có tỉ lệ cặp phím nào ở mức độ trễ ≥ 100 ms; không có phân phối theo tương tác; không có phần phụ của INP theo origin.
- Chỉ Chrome (CrUX). Không có số cho Safari, Firefox, các app Electron (Slack/Discord desktop, VS Code) hay WebView; app Electron dựa trên Chromium nhưng không vào CrUX.
- Bản đo ở M6 dùng trang thử chặn 300 ms mỗi 1000 ms và phím cách đều 100 ms, một máy; số đó là điều kiện nặng có chủ ý, không phải tần suất thật.
- Không biết lỗi của Dấu xảy ra bao nhiêu khi gõ thật trên các trang trong bảng.

**Kết luận được phép:** rủi ro "luồng chính bận lâu hơn khoảng cách hai phím trong lúc gõ" tồn tại trên web thật: ở 9 trong 17 origin có dữ liệu, ít nhất 27% lượt truy cập có một tương tác chậm hơn 200 ms, và ngay ở origin có p75 tốt (claude.ai, notion.so, mail.google.com) vẫn có 16–17% lượt như vậy. Nó tập trung ở ứng dụng web nặng, ít ở trang đọc và tìm kiếm. **Chưa được phép nói:** "x% chữ sẽ sai", hay "web nào cũng/không sao".

## 5. Nguồn

- INP: https://web.dev/articles/inp (đọc 09/11/2026)
- Độ trễ đầu vào: https://web.dev/articles/optimize-input-delay (đọc 09/11/2026)
- CrUX: https://developer.chrome.com/docs/crux/methodology (đọc 09/11/2026)
- Web Almanac 2025, Hiệu năng: https://almanac.httparchive.org/en/2025/performance (đọc 09/11/2026)
- Treo, báo cáo theo origin: https://treo.sh/sitespeed/<origin>?formFactor=desktop (đọc 09/11/2026, kỳ 09/2026)
