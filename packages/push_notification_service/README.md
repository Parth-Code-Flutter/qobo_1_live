# push_notification_service

Reusable Flutter package for **receiving** Firebase Cloud Messaging (FCM) pushes.

Copy this folder into another repo (or depend via `path` / git) after the host app initializes Firebase.

## Features (current)

- Notification permission request
- Foreground message receive
- Background / terminated message receive (top-level handler)
- Optional foreground system tray via `flutter_local_notifications`
- Actionable room invite trays (`JOIN_ROOM` / `REJECT_ROOM` / `DISMISS_ROOM`)
- FCM token + token refresh callbacks
- `onNotificationTap` + `onNotificationAction` hooks
- `flushPendingLaunch()` for cold-start navigation after `runApp`

## Host setup

### 1. pubspec

```yaml
dependencies:
  push_notification_service:
    path: packages/push_notification_service
```

### 2. main.dart

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:push_notification_service/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(...);

  // Must be a top-level function — required by firebase_messaging.
  FirebaseMessaging.onBackgroundMessage(pushNotificationBackgroundHandler);

  await PushNotificationService.instance.initialize(
    config: const PushNotificationConfig(
      showForegroundNotifications: true,
      enableVerboseLogging: true,
    ),
    handlers: PushNotificationHandlers(
      onForegroundMessage: (msg) { /* optional */ },
      onToken: (token) { /* send to backend if needed */ },
      onTokenRefresh: (token) { /* update backend if needed */ },
      onNotificationTap: (msg) {},
      onNotificationAction: (actionId, msg) {},
    ),
  );

  runApp(const MyApp());
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationService.instance.flushPendingLaunch();
  });
}
```

### 3. Android

Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

### 4. iOS

Add to `Info.plist`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>remote-notification</string>
</array>
```

Enable Push Notifications capability in Xcode.

## Notes

- Call `initialize` only after `Firebase.initializeApp`.
- Do not put heavy work in the background handler.
- Tap / deep-link routing is intentionally incomplete — use `onNotificationTap`.
