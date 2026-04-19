import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

// =============================================================================
// MBOA HEALTH — Notification Service
// Wraps flutter_local_notifications for scheduled medication reminders.
//
// On web (kIsWeb) all methods are no-ops — browsers do not support local
// notifications via this plugin.
// =============================================================================

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'mboa_reminders';
  static const _channelName = 'Medication Reminders';
  static const _channelDesc =
      'Daily reminders to take your medications on time.';

  // ── Initialise ─────────────────────────────────────────────────────────────

  /// Call once in [main] before [runApp].
  Future<void> init() async {
    if (kIsWeb) return;

    // Initialise timezone database and set Cameroon local timezone (UTC+1).
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Africa/Douala'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios     = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Request POST_NOTIFICATIONS permission on Android 13+.
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Schedule ───────────────────────────────────────────────────────────────

  /// Schedule (or re-schedule) a notification for a medication reminder.
  ///
  /// [frequency] follows the DB enum:
  ///   daily | twice_daily | thrice_daily | weekly | as_needed
  ///
  /// • `as_needed` → fires once at the next occurrence of [hour]:[minute].
  /// • Everything else → repeats daily at the same time.
  Future<void> scheduleReminder({
    required int    id,
    required String medicationName,
    required int    hour,
    required int    minute,
    required String frequency,
  }) async {
    if (kIsWeb) return;

    try {
      await _plugin.cancel(id); // cancel before re-scheduling

      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: Importance.high,
        priority:   Priority.high,
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS:     DarwinNotificationDetails(),
      );

      // Build the next fire time in local timezone.
      final now       = tz.TZDateTime.now(tz.local);
      var   scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute,
      );
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      final repeat = frequency != 'as_needed';

      await _plugin.zonedSchedule(
        id,
        '💊 Time for your medication',
        medicationName,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            repeat ? DateTimeComponents.time : null,
      );
    } catch (_) {
      // Notification scheduling is non-critical — swallow all errors.
    }
  }

  // ── Cancel ─────────────────────────────────────────────────────────────────

  Future<void> cancelReminder(int id) async {
    if (kIsWeb) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    if (kIsWeb) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
