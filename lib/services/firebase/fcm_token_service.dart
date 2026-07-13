import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Safely resolves the current device FCM token for auth/API payloads.
class FcmTokenService {
  FcmTokenService({FirebaseMessaging? messaging}) : _messaging = messaging;

  final FirebaseMessaging? _messaging;

  Future<String?> getToken() async {
    if (kIsWeb) return null;

    final initialized = await FirebaseBootstrap.tryInitialize();
    if (!initialized) return null;

    try {
      final messaging = _messaging ?? FirebaseMessaging.instance;
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      final token = await messaging.getToken();
      final normalized = token?.trim();
      return normalized == null || normalized.isEmpty ? null : normalized;
    } catch (e) {
      LoggerUtils.logWarning('FcmTokenService: token unavailable — $e');
      return null;
    }
  }
}
