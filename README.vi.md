# HermesEnabler 2

[English](README.md) · [Tiếng Việt](README.vi.md) · [한국어](README.ko.md) · [简体中文](README.zh-CN.md) · [繁體中文](README.zh-TW.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [Português](README.pt.md)

![](image.png)

> Chỉ hỗ trợ watchOS 27.0 đến 27.3 beta 1.

## Cài đặt

### macOS

Trên macOS, bạn có thể cài đặt file IPA dựng sẵn bằng WatchBridge hoặc Sideloadly, hoặc tự build ứng dụng trực tiếp bằng Xcode. Hãy đảm bảo iPhone đã ghép đôi với Apple Watch cần cài đặt và đồng hồ đang chạy phiên bản watchOS được hỗ trợ.

#### Cài đặt IPA

> **Sự cố đã biết với Sideloadly 0.72:** [Issue #43](https://github.com/pookjw/HermesEnabler/issues/43) cho biết phiên bản này có thể xóa ứng dụng Watch được nhúng trong quá trình ký. Nếu ứng dụng iPhone đã được cài đặt nhưng HermesEnabler2 không xuất hiện trên Apple Watch, hãy dùng Xcode. Báo cáo này chỉ áp dụng cho phiên bản 0.72; khả năng tương thích với các phiên bản khác chưa được xác nhận.

1. Tải IPA từ trang [Releases](https://github.com/pookjw/HermesEnabler/releases).
2. Cài đặt [Sideloadly](https://sideloadly.io) trên máy Mac, kết nối iPhone bằng cáp rồi chọn thiết bị trong Sideloadly.
3. Kéo IPA vào Sideloadly và nhập Apple ID của bạn. Tắt **Use automatic bundle ID**, đặt một Bundle Identifier cố định rồi bắt đầu ký.
4. Trên iPhone, mở **Cài đặt → Cài đặt chung → VPN & Quản lý thiết bị** rồi tin cậy chứng nhận nhà phát triển của bạn.
5. Trên iPhone, mở **Cài đặt → Quyền riêng tư & Bảo mật → Chế độ nhà phát triển**, bật chế độ này, khởi động lại rồi xác nhận.
6. Trên iPhone, mở ứng dụng **Watch**, vào **Đồng hồ của tôi → Ứng dụng** rồi cài đặt **HermesEnabler2** trên Apple Watch.
7. Trên Apple Watch, mở **Cài đặt → Quyền riêng tư & Bảo mật → Chế độ nhà phát triển**, bật chế độ này, khởi động lại rồi xác nhận. Nếu tùy chọn không xuất hiện, hãy cài đặt ứng dụng Watch trước rồi kiểm tra lại.
8. Mở **HermesEnabler2** trên Apple Watch và làm theo các bước trong ứng dụng.

#### Build bằng Xcode

1. Mở [HermesEnabler2.xcodeproj](HermesEnabler2.xcodeproj) trong Xcode.
2. Chọn Apple Watch của bạn làm đích chạy rồi nhấn **Run**.
3. Mở **HermesEnabler2** trên Apple Watch và làm theo các bước trong ứng dụng.

#### Cài đặt bằng WatchBridge

Trên macOS 11 trở lên, bạn có thể dùng bản DMG dựng sẵn của WatchBridge mà không cần cài đặt Xcode.

1. Tải DMG phù hợp từ [WatchBridge Releases](https://github.com/AdminZachary/WatchBridge/releases/latest). Chọn `arm64` cho Apple Silicon hoặc `x86_64` cho Intel. Mở DMG rồi kéo **WatchBridge.app** vào thư mục **Ứng dụng**.
2. Tải IPA gốc từ [HermesEnabler Releases](https://github.com/pookjw/HermesEnabler/releases). Kết nối iPhone đã ghép đôi qua USB và chọn thiết bị trong WatchBridge.
3. Làm theo hướng dẫn để hiển thị công tắc Chế độ nhà phát triển. Bật chế độ này trên đồng hồ, khởi động lại và xác nhận. Sau đó ký và cài đặt IPA trong WatchBridge.

Nếu macOS chặn lần mở đầu tiên, hãy làm theo hướng dẫn trong ghi chú phát hành của WatchBridge.

### Windows

Trên Windows, dự án sử dụng [WatchBridge](https://github.com/AdminZachary/WatchBridge), một công cụ cộng đồng dùng để chuẩn bị Chế độ nhà phát triển và cài đặt IPA chứa cả ứng dụng chủ trên iPhone lẫn ứng dụng Watch. Công cụ này không liên kết với Apple hoặc dự án này.

1. Cài đặt **Apple Mobile Device Service** bằng cách cài [iTunes](https://www.apple.com/itunes/) hoặc ứng dụng **Apple Devices** từ Microsoft Store. WatchBridge cần dịch vụ này để giao tiếp qua USB và Wi-Fi. WebView2 được tích hợp sẵn trong Windows 11.
2. Đảm bảo iPhone của bạn đã được ghép đôi với Apple Watch cần cài đặt. WatchBridge chỉ hỗ trợ một Apple Watch đã ghép đôi tại một thời điểm; nếu có nhiều hơn một Apple Watch được ghép đôi, bước chuẩn bị sẽ dừng thay vì tự chọn thiết bị.
3. Tải `watchbridge-windows.zip` từ trang [WatchBridge Releases](https://github.com/AdminZachary/WatchBridge/releases/latest), giải nén rồi chạy `WatchBridge.exe`. File thực thi này chưa được ký nên Windows SmartScreen có thể hiển thị cảnh báo trong lần khởi chạy đầu tiên.
4. Tải IPA từ trang [Releases](https://github.com/pookjw/HermesEnabler/releases). Hãy dùng IPA gốc chứa cả ứng dụng chủ trên iPhone và `Watch/*.app`; các gói chỉ chứa ứng dụng Watch không được hỗ trợ.
5. Kết nối iPhone đã ghép đôi qua USB rồi chọn thiết bị trong WatchBridge.
6. Ghép đôi Apple Watch và xác nhận lời nhắc tin cậy trên Apple Watch. Yêu cầu hiển thị công tắc **Chế độ nhà phát triển**, sau đó trên Apple Watch, mở **Cài đặt → Quyền riêng tư & Bảo mật → Chế độ nhà phát triển**, bật chế độ này, khởi động lại rồi xác nhận. Quay lại WatchBridge và nhấn **Check again**. WatchBridge không tự bật Chế độ nhà phát triển hoặc khởi động lại Apple Watch cho bạn.
7. Đăng nhập bằng Apple ID của bạn, chọn IPA HermesEnabler2 rồi bắt đầu ký và cài đặt. WatchBridge sẽ cài đặt ứng dụng chủ trên iPhone trước, sau đó cài đặt ứng dụng Watch.
8. Mở **HermesEnabler2** trên Apple Watch và làm theo các bước trong ứng dụng.

> Quá trình chuẩn bị Chế độ nhà phát triển yêu cầu kết nối USB. Sau lần ghép đôi đầu tiên qua USB, việc cài đặt và gia hạn có thể sử dụng Wi-Fi.

## Lưu ý

- Trong Sideloadly, hãy tắt **Use automatic bundle ID** và sử dụng một Bundle Identifier cố định. Giữ nguyên Bundle Identifier và Apple ID cho mỗi lần cập nhật để ứng dụng có thể giữ lại dữ liệu và bản sao lưu hiện có.
- Provisioning profile của Apple Personal Team miễn phí sẽ hết hạn sau bảy ngày. Khi điều đó xảy ra, hãy build và cài đặt lại ứng dụng bằng cùng Apple ID và Bundle Identifier.
- Dự án này sử dụng entitlement **App Groups**, nhưng Personal Team miễn phí không thể cấp entitlement này. Bạn có thể cần một nhóm nhà phát triển trả phí; việc thay đổi Bundle Identifier không loại bỏ giới hạn này. Đừng cho rằng xóa entitlement là giải pháp hoàn chỉnh vì chức năng chính của ứng dụng khi không có entitlement này chưa được xác nhận.
- Nếu ứng dụng iPhone đã được cài đặt nhưng ứng dụng Watch không xuất hiện, hãy kiểm tra nhật ký Sideloadly để tìm dòng `Watch apps will be stripped from the IPA`. Điều này có nghĩa là ứng dụng Watch được nhúng đã bị xóa; chỉ cài đặt ứng dụng iPhone sẽ không cài đặt được ứng dụng Watch. Hãy dùng Xcode để cài đặt ứng dụng Watch.
- Trước khi xóa ứng dụng, hãy luôn khôi phục bản sao lưu MobileGestalt thông qua ứng dụng HermesEnabler2.

## Ghi công

Dự án này sử dụng mã nguồn từ [Gester](https://github.com/sasobhabha/Gester).

Bạn tự chịu rủi ro khi sử dụng.
