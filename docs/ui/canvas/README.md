# Bản chụp canvas thiết kế

Ảnh chụp các artboard trên trang "Thiết kế" của canvas mockup, để xem thiết kế đã duyệt mà không cần mở canvas trên claude.ai. Canvas vẫn là nơi sửa thiết kế (CLAUDE.md, mục Điều phối); thư mục này chỉ là bản chụp, sinh bằng `scripts/design/render-canvas.sh`, không sửa tay.

- `*.png`: ảnh chụp từng artboard.
- `src/*.dc.html`: nguồn của artboard (nội dung, câu chữ chính xác); agent đọc file này thay cho canvas.
- `canvas.json`: vị trí, kích thước và tiêu đề các artboard.

## Chào mừng

- [Chào mừng – bước 1: tắt bộ gõ cũ](OnboardingConflict.png) · [nguồn](src/OnboardingConflict.dc.html)
- [Chào mừng – bước 1: đã tắt bộ gõ cũ (sau khi bấm Quay lại ở bước 2)](OnboardingConflictDone.png) · [nguồn](src/OnboardingConflictDone.dc.html)
- [Chào mừng – bước 2: bật Dấu](OnboardingEnable.png) · [nguồn](src/OnboardingEnable.dc.html)
- [Chào mừng – bước 2: không đọc được phím tắt, có nguồn tiếng Việt khác](OnboardingEnableNotes.png) · [nguồn](src/OnboardingEnableNotes.dc.html)
- [Chào mừng – bước 2: chưa cài được](OnboardingEnableError.png) · [nguồn](src/OnboardingEnableError.dc.html)
- [Chào mừng – bước 2: chờ bấm Allow](OnboardingEnableWaiting.png) · [nguồn](src/OnboardingEnableWaiting.dc.html)
- [Chào mừng – bước 2: chưa bật được](OnboardingEnableFailed.png) · [nguồn](src/OnboardingEnableFailed.dc.html)
- [Chào mừng – bước 2: đã bật](OnboardingEnableDone.png) · [nguồn](src/OnboardingEnableDone.dc.html)
- [Chào mừng – bước 2: đã bật, chưa có phím tắt](OnboardingEnableDoneNoShortcut.png) · [nguồn](src/OnboardingEnableDoneNoShortcut.dc.html)
- [Chào mừng – bước 3: chọn kiểu gõ](Onboarding.png) · [nguồn](src/Onboarding.dc.html)
- [Chào mừng – bước 3: Dấu chưa là nguồn đang dùng](OnboardingNotSelected.png) · [nguồn](src/OnboardingNotSelected.dc.html)

## Cài đặt

- [Cài đặt – Gõ phím](SettingsTyping.png) · [nguồn](src/SettingsTyping.dc.html)
- [Cài đặt – Thông minh](SettingsSmart.png) · [nguồn](src/SettingsSmart.dc.html)
- [Cài đặt – tìm không có kết quả](SettingsSearchEmpty.png) · [nguồn](src/SettingsSearchEmpty.dc.html)
- [Cài đặt – Ứng dụng](SettingsApps.png) · [nguồn](src/SettingsApps.dc.html)
- [Cài đặt – Cập nhật & hỗ trợ](SettingsAbout.png) · [nguồn](src/SettingsAbout.dc.html)
- [Cài đặt – Cập nhật & hỗ trợ (bản phát triển)](SettingsAboutDev.png) · [nguồn](src/SettingsAboutDev.dc.html)
- [Cài đặt – hàng Ngôn ngữ (theo macOS)](SettingsLanguage.png) · [nguồn](src/SettingsLanguage.dc.html)
- [Cài đặt – hàng Ngôn ngữ (Dấu đặt riêng English, macOS tiếng Việt)](SettingsLanguageEn.png) · [nguồn](src/SettingsLanguageEn.dc.html)
- [Cài đặt – hàng Ngôn ngữ (đã đổi sang English, chưa mở lại Dấu)](SettingsLanguagePending.png) · [nguồn](src/SettingsLanguagePending.dc.html)

## Trạng thái

- [Trạng thái – Dấu chưa được bật](SettingsNotEnabled.png) · [nguồn](src/SettingsNotEnabled.dc.html)
- [Trạng thái – bộ gõ trên máy đã bị thay](SettingsTampered.png) · [nguồn](src/SettingsTampered.dc.html)
- [Trạng thái – chế độ tối](SettingsDark.png) · [nguồn](src/SettingsDark.dc.html)

## Banner “Dấu chưa được bật”

- [Banner “Dấu chưa được bật” – sau khi bấm Bật lại](SettingsBannerStates.png) · [nguồn](src/SettingsBannerStates.dc.html)

## Thông minh

- [Thông minh – mở “Nâng cao”](SettingsSmartAdvanced.png) · [nguồn](src/SettingsSmartAdvanced.dc.html)

## Ứng dụng

- [Ứng dụng – chưa có quy tắc riêng](SettingsAppsEmpty.png) · [nguồn](src/SettingsAppsEmpty.dc.html)
- [Ứng dụng – thêm quy tắc](SettingsAppsAdd.png) · [nguồn](src/SettingsAppsAdd.dc.html)
- [Ứng dụng – thêm quy tắc, chưa chọn](SettingsAppsAddEmpty.png) · [nguồn](src/SettingsAppsAddEmpty.dc.html)

## Khác

- [Trạng thái thẻ cập nhật](UpdateStates.png) · [nguồn](src/UpdateStates.dc.html)
- [Thông báo cập nhật](Update.png) · [nguồn](src/Update.dc.html)
- [Xác nhận quay về / gỡ cài đặt](ConfirmDialogs.png) · [nguồn](src/ConfirmDialogs.dc.html)
- [Báo ứng dụng gõ lỗi](Report.png) · [nguồn](src/Report.dc.html)
- [Menu nguồn đầu vào (hệ thống vẽ)](Main.png) · [nguồn](src/Main.dc.html)
- [Khi gõ trong ứng dụng](TypingStates.png) · [nguồn](src/TypingStates.dc.html)
- [Ảnh chia sẻ Open Graph 1200×630](OgImage.png) · [nguồn](src/OgImage.dc.html)
- [Ảnh xem trước GitHub 1280×640](GithubPreview.png) · [nguồn](src/GithubPreview.dc.html)

## Gỡ cài đặt

- [Gỡ cài đặt – bỏ Dấu khỏi nguồn đầu vào](UninstallRemoveSource.png) · [nguồn](src/UninstallRemoveSource.dc.html)

## Nhận diện

- [Nhận diện – hướng biểu tượng](BrandConcepts.png) · [nguồn](src/BrandConcepts.dc.html)
- [Nhận diện – hướng dẫn thương hiệu](BrandGuide.png) · [nguồn](src/BrandGuide.dc.html)
- [Nhận diện – biểu tượng ứng dụng](AppIcon.png) · [nguồn](src/AppIcon.dc.html)
- [Nhận diện – nơi hình đại diện xuất hiện](BrandInUse.png) · [nguồn](src/BrandInUse.dc.html)
- [Nhận diện – biểu tượng trong hệ thống](MenuBarIcons.png) · [nguồn](src/MenuBarIcons.dc.html)
- [Nhận diện – biểu tượng bản phát triển](AppIconDev.png) · [nguồn](src/AppIconDev.dc.html)

## Trang tải về

- [Trang tải về – máy tính](Landing.png) · [nguồn](src/Landing.dc.html)
- [Trang tải về – điện thoại](LandingMobile.png) · [nguồn](src/LandingMobile.dc.html)

