# K-Alarm

Ứng dụng báo thức Flutter (Android + iOS) cho phép:

- **Báo thức đơn**: một giờ cố định, lặp lại theo các ngày trong tuần hoặc chỉ một lần.
- **Chuỗi báo thức**: nhiều mốc giờ reo độc lập trong cùng một nhóm, ví dụ `01:05`, `02:03`, `05:00`. Mỗi mốc có thể chọn một nhiệm vụ tắt báo thức khác nhau.
- **Nhiệm vụ để tắt báo thức** (không có nút "Tắt" nhanh trên thông báo — phải mở app và hoàn thành nhiệm vụ):
  - Giải toán (3 mức độ khó)
  - Quét mã QR (có thể đặt trước nội dung mã QR cụ thể, ví dụ dán ở xa giường/ngoài phòng tắm)
  - Lắc điện thoại đủ số lần yêu cầu
  - Gõ lại chính xác một câu (tùy chỉnh hoặc ngẫu nhiên)

Báo thức dùng gói [`alarm`](https://pub.dev/packages/alarm) — kêu đúng giờ, vượt qua khóa màn hình, kể cả khi app bị tắt hẳn hoặc điện thoại ở chế độ im lặng/Không làm phiền.

## Nhận diện thương hiệu

Theo đúng bộ brand guidelines K-Alarm: màu chủ đạo Electric Indigo `#6366F1`, Alert Coral
`#FF4A3D`, Wake Amber `#F59E0B`, Mission Emerald `#10B981`, trên nền tối Obsidian Night
`#0B0F19`; font chữ **Plus Jakarta Sans** (nội dung) và **JetBrains Mono** (mọi con số giờ/đếm
ngược, dùng tabular figures để số không bị xê dịch). Toàn bộ nằm ở:

- `lib/theme/brand.dart` — màu, font, `ThemeData` dùng chung (`buildKAlarmTheme`), `kMonoTime()`
- `lib/widgets/k_alarm_logo.dart` — logo (K + mắt xích + chuông) và wordmark "K-ALARM."
- `assets/brand/` — logo.svg (hiển thị trong app) + icon_source/icon_foreground (app icon, đã
  generate sẵn cho Android/iOS qua `flutter_launcher_icons`)
- `assets/fonts/` — font .ttf đóng gói sẵn, không cần mạng khi chạy

Màn hình chuỗi báo thức (K-Chain) hiển thị timeline các mắt xích nối nhau đúng theo mock trong
guidelines, mỗi mắt xích một màu brand xoay vòng Indigo → Coral → Amber → Emerald.

## Chạy thử

```bash
flutter pub get
flutter run
```

### Android
Đã cấu hình sẵn permissions (exact alarm, full-screen intent, camera cho QR...) trong
`android/app/src/main/AndroidManifest.xml`, và `minSdk 23`, Kotlin `2.4.0` trong
`android/settings.gradle.kts` theo đúng hướng dẫn cài đặt của gói `alarm`.

Lần build đầu tiên trên máy bạn sẽ tải khá nhiều dependency Gradle/Kotlin — cần mạng ổn định.

### iOS
Mở `ios/Runner.xcworkspace` bằng Xcode, vào **Signing & Capabilities** và bật:
- Background Modes → Audio, AirPlay and Picture in Picture
- Background Modes → Background fetch

(Các key tương ứng đã được thêm sẵn vào `Info.plist`, và `AppDelegate.swift` đã đăng ký
background task + notification delegate cho plugin `alarm`.)

Chạy `pod install --repo-update` trong thư mục `ios/` nếu Xcode tạo Podfile, và đặt
iOS Deployment Target ít nhất **13.0**.

Nhớ cấp quyền **Notifications** và **Camera** khi app hỏi lần đầu mở (dùng cho QR challenge).

## Cấu trúc code

```
lib/
  models/
    alarm_item.dart       # AlarmItem (1 mốc giờ) + AlarmChain (nhóm nhiều mốc)
    challenge.dart        # ChallengeType + ChallengeConfig (cấu hình nhiệm vụ tắt)
  services/
    storage_service.dart  # Lưu alarms/chains vào SharedPreferences
    alarm_scheduler.dart  # Gọi gói `alarm` để đặt/hủy báo thức native
    alarm_repository.dart # Nguồn dữ liệu chính (CRUD alarms & chains), ChangeNotifier
    permission_service.dart
  screens/
    home_screen.dart      # Danh sách báo thức đơn + chuỗi
    alarm_edit_screen.dart # Tạo/sửa báo thức đơn
    chain_edit_screen.dart # Tạo/sửa chuỗi báo thức (nhiều mốc giờ)
    ring_screen.dart       # Màn hình báo thức đang reo + nhiệm vụ tắt
  widgets/
    challenge_config_editor.dart     # UI chọn & cấu hình loại nhiệm vụ
    sound_picker.dart                # Bottom sheet chọn âm báo thức (có nghe trước)
    challenges/
      math_challenge.dart
      qr_challenge.dart
      shake_challenge.dart
      retype_challenge.dart
  theme/
    brand.dart   # Màu, font, ThemeData
    sounds.dart  # Danh mục 27 âm báo thức có sẵn
```

## Ghi chú về hành vi báo thức

- Báo thức **một lần** (không chọn ngày lặp lại): sau khi hoàn thành nhiệm vụ tắt, báo thức tự
  động chuyển sang "tắt" (`enabled = false`). Phù hợp cho chuỗi báo thức như ví dụ trong yêu cầu.
- Báo thức **lặp lại** (có chọn ngày): sau khi hoàn thành nhiệm vụ, hệ thống tự đặt lại cho lần
  kế tiếp đúng ngày đã chọn.
- Thông báo của báo thức **không có nút "Tắt"** và **không tắt khi vuốt bỏ thông báo**
  (`androidStopAlarmOnDismiss: false`) — mục đích là buộc người dùng mở app và hoàn thành nhiệm
  vụ ở màn hình `RingScreen` thì báo thức mới thực sự dừng.
- **Âm báo thức**: app có sẵn **27 âm báo thức** tự tổng hợp (không vi phạm bản quyền), nằm trong
  `assets/sounds/`. Mỗi báo thức đơn, và mỗi mốc giờ trong một chuỗi, có thể chọn âm riêng qua mục
  "Âm báo thức" trong màn hình sửa (xem trước bằng nút play trước khi chọn). Danh mục âm nằm ở
  `lib/theme/sounds.dart`, UI chọn ở `lib/widgets/sound_picker.dart`. Muốn thêm âm mới: chạy
  `python3 tools/gen_sounds.py` sau khi thêm định nghĩa mới trong file đó, rồi khai báo trong
  `lib/theme/sounds.dart`.
