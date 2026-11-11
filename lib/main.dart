import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'services/app_nav.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool launchedByNotification = false;
  try {
    launchedByNotification = await NotificationService.init(
      onTap: () => AppNav.openCall(),
    );

    // Re-schedule on every start. This keeps the reminder correct even if
    // the phone's clock or time zone changed.
    final s = await SettingsService.load();
    if (s.enabled) {
      await NotificationService.scheduleDaily(s.hour, s.minute);
    }
  } catch (e) {
    debugPrint('Notification setup failed: $e');
  }

  runApp(MorningCallApp(openCallOnStart: launchedByNotification));
}

class MorningCallApp extends StatelessWidget {
  final bool openCallOnStart;

  const MorningCallApp({super.key, this.openCallOnStart = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morning Call',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNav.key,
      theme: _buildTheme(),
      home: HomeShell(openCallOnStart: openCallOnStart),
    );
  }

  ThemeData _buildTheme() {
    final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF4F46E5));
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface.withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
