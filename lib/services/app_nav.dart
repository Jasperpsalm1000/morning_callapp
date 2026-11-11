import 'package:flutter/material.dart';
import '../screens/call_screen.dart';

/// Lets us open the call screen from anywhere, for example when a
/// notification is tapped.
class AppNav {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static Future<void> openCall({bool autoStart = true}) async {
    await key.currentState?.push(
      MaterialPageRoute(builder: (_) => CallScreen(autoStart: autoStart)),
    );
  }
}
