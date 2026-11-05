import 'package:alarm/alarm.dart';

import '../models/alarm_item.dart';

/// Wraps the native `alarm` plugin: turns an [AlarmItem] into a scheduled,
/// full-screen, lock-screen-breaking native alarm, and knows how to work out
/// the next time a (possibly repeating) item should fire.
class AlarmScheduler {
  static Future<void> init() async {
    await Alarm.init();
  }

  /// Next DateTime this item should ring, relative to [from] (defaults to now).
  static DateTime nextFireTime(AlarmItem item, {DateTime? from}) {
    final now = from ?? DateTime.now();

    if (item.repeatDays.isEmpty) {
      var dt = DateTime(now.year, now.month, now.day, item.hour, item.minute);
      if (!dt.isAfter(now)) {
        dt = dt.add(const Duration(days: 1));
      }
      return dt;
    }

    for (var i = 0; i < 8; i++) {
      final day = now.add(Duration(days: i));
      if (item.repeatDays.contains(day.weekday)) {
        final dt = DateTime(day.year, day.month, day.day, item.hour, item.minute);
        if (dt.isAfter(now)) return dt;
      }
    }
    // Should never be reached (a week always contains every weekday), but
    // keeps the function total.
    return DateTime(now.year, now.month, now.day, item.hour, item.minute)
        .add(const Duration(days: 7));
  }

  /// Arms (or re-arms) the native alarm for [item]. No-ops if the item is
  /// disabled, after first cancelling any previously armed alarm with the
  /// same id.
  static Future<void> schedule(AlarmItem item) async {
    await Alarm.stop(item.id);
    if (!item.enabled) return;

    final dateTime = nextFireTime(item);
    final title = item.isPartOfChain ? 'K-Alarm · chuỗi' : 'K-Alarm';
    final body = item.label.isNotEmpty ? item.label : 'Báo thức ${item.timeLabel}';

    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: item.id,
        dateTime: dateTime,
        loopAudio: true,
        vibrate: item.vibrate,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        allowAlarmOverlap: true,
        volumeSettings: VolumeSettings.fixed(volume: item.volume),
        notificationSettings: NotificationSettings(
          title: title,
          body: body,
          // No stop/snooze action on the notification itself: dismissing the
          // alarm must go through the in-app challenge, never a tap or a
          // swipe from the notification shade.
          androidStopAlarmOnDismiss: false,
          icon: 'notification_icon',
          keepNotificationAfterAlarmEnds: false,
        ),
      ),
    );
  }

  static Future<void> cancel(int id) => Alarm.stop(id);

  static Future<void> cancelAll(Iterable<int> ids) async {
    for (final id in ids) {
      await Alarm.stop(id);
    }
  }

  /// Stops the alarm currently ringing with [id] (call only once the user
  /// has completed the dismiss challenge).
  static Future<void> stopRinging(int id) => Alarm.stop(id);
}
