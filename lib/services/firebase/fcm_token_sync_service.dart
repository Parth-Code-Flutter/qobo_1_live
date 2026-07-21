import 'dart:io';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_service.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Registers the device FCM token with `POST /api/user/fcm-token`.
///
/// Called after login, on cold start when already logged in, and whenever FCM
/// rotates the token so follower live-stream pushes can reach this device.
class FcmTokenSyncService extends GetxController {
  FcmTokenSyncService({
    ChatRepo? chatRepo,
    FcmTokenService? fcmTokenService,
  }) : _chatRepo = chatRepo ?? ChatRepo(),
       _fcmTokenService = fcmTokenService ?? FcmTokenService();

  final ChatRepo _chatRepo;
  final FcmTokenService _fcmTokenService;

  String? _lastSyncedToken;

  /// Ensures a singleton is registered and syncs the current token when logged in.
  static Future<void> ensureSynced() async {
    final service = Get.isRegistered<FcmTokenSyncService>()
        ? Get.find<FcmTokenSyncService>()
        : Get.put(FcmTokenSyncService(), permanent: true);
    await service.syncCurrentToken();
  }

  /// Syncs [token] (or the current device token) to the backend.
  Future<void> syncCurrentToken({String? token}) async {
    if (kIsWeb) return;

    final isLoggedIn = await LocalStorage.shared.isLoggedIn();
    if (!isLoggedIn) return;

    final resolved = (token ?? await _fcmTokenService.getToken())?.trim();
    if (resolved == null || resolved.isEmpty) {
      LoggerUtils.logInfo('FcmTokenSync: skipped — no FCM token');
      return;
    }
    if (_lastSyncedToken == resolved) return;

    try {
      final response = await _chatRepo.registerFcmToken(
        token: resolved,
        platform: _platformLabel(),
        isShowLoader: false,
      );
      final code = response?['statusCode'];
      final ok =
          code == 1 ||
          code == 200 ||
          code == 201 ||
          response?['data']?['success'] == true;
      if (ok) {
        _lastSyncedToken = resolved;
        LoggerUtils.logInfo(
          'FcmTokenSync: registered (${resolved.length} chars, ${_platformLabel()})',
        );
      } else {
        LoggerUtils.logWarning(
          'FcmTokenSync: register failed — ${response?['message']}',
        );
      }
    } catch (e) {
      LoggerUtils.logWarning('FcmTokenSync: register error — $e');
    }
  }

  void clearCachedToken() {
    _lastSyncedToken = null;
  }

  String _platformLabel() {
    if (defaultTargetPlatform == TargetPlatform.iOS) return 'ios';
    if (defaultTargetPlatform == TargetPlatform.android) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}
