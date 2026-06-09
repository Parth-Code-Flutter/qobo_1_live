import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:qobo_one_live/firebase/firebase_options.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// One-time Firebase Core setup for the app.
abstract final class FirebaseBootstrap {
  FirebaseBootstrap._();

  static bool _attempted = false;
  static bool isAvailable = false;

  /// Safe to call multiple times; initializes at most once.
  static Future<bool> tryInitialize() async {
    if (_attempted) return isAvailable;
    _attempted = true;

    if (kIsWeb) {
      LoggerUtils.logInfo('FirebaseBootstrap: skipped on web');
      return false;
    }

    if (Firebase.apps.isNotEmpty) {
      isAvailable = true;
      return true;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      if (!DefaultFirebaseOptions.isIosConfigured) {
        LoggerUtils.logInfo(
          'FirebaseBootstrap: iOS skipped — register app com.qobo1live.live in '
          'Firebase project qobo1live-914ac, add GoogleService-Info.plist to '
          'ios/Runner/, then run flutterfire configure.',
        );
        return false;
      }
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
      );
      isAvailable = true;
      LoggerUtils.logInfo(
        'FirebaseBootstrap: initialized (${DefaultFirebaseOptions.android.projectId})',
      );
      return true;
    } catch (e) {
      LoggerUtils.logWarning('FirebaseBootstrap: initialize failed — $e');
      return false;
    }
  }
}
