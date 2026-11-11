
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Alarm-style daily reminder service for Morning Call.
///
/// This schedules an audible, vibrating notification at the chosen time.
/// Tapping the notification opens the app's existing check-in screen.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyId = 1;
  static const int _testId = 2;

  static bool _initialized = false;

  static const AndroidNotificationDetails _alarmDetails =
      AndroidNotificationDetails(
    'morning_call_alarm_channel_v2',
    'Morning Call Alarm',
    channelDescription:
        'Daily alarm-style reminders for your morning check-in.',
    importance: Importance.max,
    priority: Priority.max,
    category: AndroidNotificationCategory.alarm,
    visibility: NotificationVisibility.public,
    playSound: true,
    enableVibration: true,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    ticker: 'Morning Call alarm',
    autoCancel: true,
  );

  static const NotificationDetails _notificationDetails =
      NotificationDetails(android: _alarmDetails);

  /// Initialise notifications and the phone's local timezone.
  ///
  /// Returns true if the app was launched by tapping a notification.
  static Future<bool> init({
    required void Function() onTap,
  }) async {
    if (!_initialized) {
      tzdata.initializeTimeZones();

      try {
        final timezoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(
          tz.getLocation(timezoneInfo.identifier),
        );
      } catch (_) {
        // Fallback for devices where timezone lookup fails.
        // Nigeria uses Africa/Lagos.
        tz.setLocalLocation(tz.getLocation('Africa/Lagos'));
      }

      const androidSettings =
          AndroidInitializationSettings('@drawable/ic_notification');

      await _plugin.initialize(
        settings: const InitializationSettings(
          android: androidSettings,
        ),
        onDidReceiveNotificationResponse: (_) => onTap(),
      );

      _initialized = true;
    }

    final launchDetails =
        await _plugin.getNotificationAppLaunchDetails();

    return launchDetails?.didNotificationLaunchApp ?? false;
  }

  /// Request permission to display notifications.
  static Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted = await android?.requestNotificationsPermission();

    // On Android versions that do not need this permission, the result
    // may be null.
    return granted ?? true;
  }

  /// Request Android's special exact-alarm access.
  ///
  /// On Android 12+, the user may need to approve this in system settings.
  static Future<bool> requestExactAlarmPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted = await android?.requestExactAlarmsPermission();

    // Older Android versions may not return a value for this permission.
    return granted ?? true;
  }

  /// Schedule or replace the daily alarm.
  ///
  /// Uses the phone's local timezone and an exact alarm when permitted.
  /// If exact-alarm access is unavailable, falls back to an inexact alarm.
  static Future<void> scheduleDaily(int hour, int minute) async {
    if (!_initialized) {
      throw StateError(
        'NotificationService.init() must run before scheduling.',
      );
    }

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Enter a valid alarm time.');
    }

    await _plugin.cancel(id: _dailyId);

    final now = tz.TZDateTime.now(tz.local);

    var next = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If today's alarm time has passed, schedule for tomorrow.
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1));
    }

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    var exactAlarmAllowed = false;

    try {
      exactAlarmAllowed =
          await android?.requestExactAlarmsPermission() ?? false;
    } catch (_) {
      exactAlarmAllowed = false;
    }

    await _plugin.zonedSchedule(
      id: _dailyId,
      title: 'Good morning! Your Morning Call is ready.',
      body: 'How did yesterday go? Let’s plan your goals for today.',
      scheduledDate: next,
      notificationDetails: _notificationDetails,
      androidScheduleMode: exactAlarmAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel the daily alarm.
  static Future<void> cancelDaily() async {
    await _plugin.cancel(id: _dailyId);
  }

  /// Display an immediate test notification.
  static Future<void> showTest() async {
    await _plugin.show(
      id: _testId,
      title: 'Morning Call alarm test',
      body: 'Your notification sound and vibration are ready to test.',
      notificationDetails: _notificationDetails,
    );
  }

  /// Check whether an alarm is currently scheduled.
  static Future<bool> isDailyScheduled() async {
    final pending = await _plugin.pendingNotificationRequests();

    return pending.any((notification) => notification.id == _dailyId);
  }
}