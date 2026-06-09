// Generated manually from `android/app/google-services.json` (project qobo1live-914ac).
// Re-run `flutterfire configure` when iOS app is registered in Firebase Console.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Firebase configuration for [Firebase.initializeApp].
abstract final class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase is not configured for web.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase is not configured for $defaultTargetPlatform.',
        );
    }
  }

  /// Android app: `com.qobo1live.live` (from google-services.json).
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA3N-vCSTjw4Qa3ilpbsiAD3LGt24eV3ZM',
    appId: '1:152049582917:android:dfcd5c94cbd8bde9d3342c',
    messagingSenderId: '152049582917',
    projectId: 'qobo1live-914ac',
    storageBucket: 'qobo1live-914ac.firebasestorage.app',
  );

  /// iOS — register `com.qobo1live.live` in Firebase Console, add
  /// `ios/Runner/GoogleService-Info.plist`, then replace [iosAppId] via
  /// `flutterfire configure` or paste values from the plist.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA3N-vCSTjw4Qa3ilpbsiAD3LGt24eV3ZM',
    appId: 'IOS_APP_ID_PENDING',
    messagingSenderId: '152049582917',
    projectId: 'qobo1live-914ac',
    storageBucket: 'qobo1live-914ac.firebasestorage.app',
    iosBundleId: 'com.qobo1live.live',
  );

  static bool get isIosConfigured =>
      ios.appId.isNotEmpty && !ios.appId.contains('PENDING');
}
