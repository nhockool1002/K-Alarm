import 'package:alarm/alarm.dart';
import 'package:permission_handler/permission_handler.dart';

/// Requests the runtime permissions K-Alarm needs: notifications, exact
/// alarms (Android 12+) and camera (for the QR-scan dismiss challenge).
class PermissionService {
  static Future<void> requestAll() async {
    await _requestNotification();
    await _requestExactAlarm();
  }

  static Future<void> _requestNotification() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  static Future<void> _requestExactAlarm() async {
    if (!Alarm.android) return;
    final status = await Permission.scheduleExactAlarm.status;
    if (status.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }
  }

  static Future<bool> requestCamera() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    final result = await Permission.camera.request();
    return result.isGranted;
  }
}
