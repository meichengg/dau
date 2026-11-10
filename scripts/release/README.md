# Bản phát hành (fork `meichengg/dau`)

Gói `.pkg` do CI dựng từ chính nhánh `main` của fork. Fork tự đồng bộ với upstream
`codefastlabs/dau` mỗi giờ; có commit mới thì CI tự dựng gói mới và **không** cần ai bấm gì.

## Đồng bộ upstream

`.github/workflows/sync-upstream.yml`:

- `git merge upstream/main` vào `main`. Không xung đột thì đẩy lên, rồi tự gọi `release.yml`.
- Xung đột ở file của fork (`docs/history/LOG-FORK-CI.md`,
  `.github/workflows/sync-upstream.yml`) thì lấy bản của fork.
- Xung đột ở chỗ khác: **không đẩy gì**, mở một issue "Sync upstream blocked", các lần sau
  chạy lại. Gộp tay xong thì đóng issue; lần chạy kế tiếp đi tiếp.

`docs/PROGRESS.md` không cần luật riêng: upstream viết lại file đó liên tục, nên nhật ký của
fork nằm ở `docs/history/LOG-FORK-CI.md` và không bao giờ đụng `PROGRESS.md`.

## Hai chế độ ký

| Có secret | Chữ ký | App Group (cài đặt dùng chung) |
|---|---|---|
| `MACOS_CERT_P12`, `MACOS_CERT_PASSWORD` | Apple Development, team lấy từ chứng chỉ | chạy |
| không có | chứng chỉ tự ký dùng một lần, chữ ký không có team | **bị từ chối** — vẫn cài và chạy, nhưng app và bộ gõ không dùng chung cài đặt |

Tên App Group là `<team>.com.codefastlabs.dau.shared`, team là thuộc tính của chứng chỉ chứ
không phải của repo, nên CI đọc team từ chứng chỉ (`scripts/release/team-id.sh`) thay vì
viết cứng. Chữ ký tự ký báo `TeamIdentifier=not set`; `sign-app.sh` bỏ
`com.apple.developer.team-identifier` trong trường hợp đó vì gắn nó vào thì kernel giết app
lúc exec.

Bật chế độ có team: xuất chứng chỉ một lần.

```sh
security export -t identities -f pkcs12 -o cert.p12 "Apple Development: <tên> (<ID>)"
base64 -i cert.p12 | gh secret set MACOS_CERT_P12 --repo meichengg/dau
gh secret set MACOS_CERT_PASSWORD --repo meichengg/dau   # mật khẩu của file .p12
```

Xuất bằng dòng lệnh cần máy đang **mở khoá** (hộp thoại ACL của Keychain). Máy khoá thì
`SecKeychainItemExport: The contents of this item cannot be retrieved.`

## Cài bản tải về

Tải `Dau-<version>.pkg` ở tab Actions (artifact của lần chạy) hoặc ở Releases (khi đẩy thẻ
`v*`), rồi:

```sh
scripts/release/install-pkg.sh --dist ~/Downloads/Dau-<version>.pkg
```

Script in SHA-256, bỏ cờ cách ly của gói (bản chưa công chứng nên Gatekeeper chặn ở bước
cài, trước khi postinstall kịp chạy), cài, rồi kiểm chữ ký, Team, App Group và trạng thái
bật.

**Không cần đăng xuất.** postinstall bỏ cờ cách ly, dừng bản cũ và mở app cho người dùng
đang đăng nhập; app tự chép bộ gõ vào `~/Library/Input Methods`, đăng ký, xoá bộ đệm danh
sách nguồn nhập liệu rồi xin macOS bật — mày bấm Allow trong hộp thoại macOS hiện ra (D37).
Chỉ đăng xuất khi sau đó mục Dấu vẫn không có trong System Settings › Keyboard › Input
Sources; đó là đường lui cuối, không phải bước bình thường.

Cài đè bản cũ cũng vậy: không cần gỡ trước, không cần đăng xuất.

## Script

- `install-pkg.sh [--dist] <pkg>` — cài và kiểm (ở trên).
- `build-pkg.sh <version>` — đóng gói bản đã build trong `build/DerivedData.noindex`; ký
  gói nếu identity ký được gói, không thì giữ gói chưa ký kèm cảnh báo.
- `sign-app.sh <app> <identity>` — ký bộ gõ rồi tới app, từ trong ra, với entitlements đã
  render; đọc team từ chứng chỉ.
- `team-id.sh <identity>` — in team (trường `OU`) của chứng chỉ, rỗng với chứng chỉ tự ký.
- `pkg/postinstall` — bỏ cờ cách ly, dừng bản cũ, mở app cho người dùng console.
