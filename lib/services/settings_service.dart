import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  final bool enabled;
  final int hour;
  final int minute;

  const ReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });
}

class SettingsService {
  static const _kEnabled = 'reminder_enabled';
  static const _kHour = 'reminder_hour';
  static const _kMinute = 'reminder_minute';

  static Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return ReminderSettings(
      enabled: prefs.getBool(_kEnabled) ?? false,
      hour: prefs.getInt(_kHour) ?? 7,
      minute: prefs.getInt(_kMinute) ?? 0,
    );
  }

  static Future<void> save(ReminderSettings s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabled, s.enabled);
    await prefs.setInt(_kHour, s.hour);
    await prefs.setInt(_kMinute, s.minute);
  }
}
