import 'dart:async';

import 'package:alarm/alarm.dart';

import '../models/alarm_item.dart';
import '../theme/sounds.dart';

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

  /// How long we'll wait on a single native `alarm` plugin call before
  /// giving up. Without this, a stuck platform channel call (seen on some
  /// devices/OEM skins) left callers (and the Save button) hanging forever.
  static const _nativeCallTimeout = Duration(seconds: 8);

  /// Arms (or re-arms) the native alarm for [item]. No-ops if the item is
  /// disabled, after first cancelling any previously armed alarm with the
  /// same id.
  ///
  /// Never hangs: every native call is bounded by [_nativeCallTimeout]. A
  /// timeout or native error is logged and rethrown as a normal exception
  /// so callers can surface it to the user instead of spinning forever.
  static Future<void> schedule(AlarmItem item) async {
    try {
      await Alarm.stop(item.id).timeout(_nativeCallTimeout);
    } on TimeoutException {
      // Nothing was armed yet under this id, or the stop simply didn't
      // report back in time — either way it's safe to keep going.
    }

    if (!item.enabled) return;

    final dateTime = nextFireTime(item);
    final title = item.isPartOfChain ? 'K-Alarm · chuỗi' : 'K-Alarm';
    final body = item.label.isNotEmpty ? item.label : 'Báo thức ${item.timeLabel}';
    final sound = kSoundById(item.soundAsset);

    await Alarm.set(
      alarmSettings: AlarmSettings(
        id: item.id,
        dateTime: dateTime,
        loopAudio: true,
        vibrate: item.vibrate,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        allowAlarmOverlap: true,
        assetAudioPath: sound?.assetPath ?? _defaultAssetAudioPath,
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
    ).timeout(_nativeCallTimeout);
  }

  // The `alarm` plugin always needs an assetAudioPath; fall back to one of
  // our own bundled tones rather than depending on a device default sound
  // that may not exist on every OEM skin.
  static String get _defaultAssetAudioPath =>
      kSoundById(kDefaultSoundId)?.assetPath ?? 'assets/sounds/classic_beep.mp3';

  static Future<void> cancel(int id) async {
    try {
      await Alarm.stop(id).timeout(_nativeCallTimeout);
    } on TimeoutException {
      // Treat as already stopped.
    }
  }

  static Future<void> cancelAll(Iterable<int> ids) async {
    for (final id in ids) {
      await cancel(id);
    }
  }

  /// Stops the alarm currently ringing with [id] (call only once the user
  /// has completed the dismiss challenge).
  static Future<void> stopRinging(int id) => cancel(id);
}
