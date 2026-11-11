# Morning Call — Professional Flutter Source

This refreshed source is based on your supplied project. It keeps the existing
check-in, local history, dashboard, settings, voice prompts, and reminder logic,
and applies a consistent professional blue/sunrise theme and custom call/sun
launcher icon.

## Run in VS Code (Windows)

1. Extract the ZIP.
2. In VS Code, select **File → Open Folder** and choose `morning_call`.
3. Open **Terminal → New Terminal** and run:

```powershell
flutter pub get
flutter run
```

To create an Android APK:

```powershell
flutter build apk --release
```

APK output: `build\app\outputs\flutter-apk\app-release.apk`

## Important notes

- Check-ins are stored locally on each phone and do not sync between friends.
- The daily reminder is a notification; it does not place a normal cellular
  phone call automatically.
- Enable the reminder in Settings and allow notifications on the device.
- Voice check-in requires microphone permission and speech services.
- This source applies a professional theme and launcher icon to the existing
  functional screens. The UI is inspired by the mockup, but is not a pixel-perfect
  recreation of every screen in the concept image.
