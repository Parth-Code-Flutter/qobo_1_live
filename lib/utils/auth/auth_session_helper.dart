import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/profile/stored_profile_map.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Persists token/user after `/api/auth/login` or `/api/auth/social` and navigates home.
abstract final class AuthSessionHelper {
  AuthSessionHelper._();

  static String extractToken(Map<String, dynamic> data) {
    final candidates = <String?>[
      data['token'] as String?,
      data['accessToken'] as String?,
      data['access_token'] as String?,
      data['jwt'] as String?,
    ];
    for (final value in candidates) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  /// Handles API envelope `statusCode` / `message` / `data` used across auth flows.
  static Future<void> handleAuthApiResponse(
    BuildContext context,
    Map<String, dynamic>? response, {
    String successFallbackMessage = 'Login successful',
    String failureFallbackMessage = 'Login failed',
  }) async {
    if (!context.mounted) return;
    if (response == null) {
      AppToast.showError(context, 'Request failed. Please try again.');
      return;
    }

    final statusCode = (response['statusCode'] as num?)?.toInt() ?? 0;
    final message = (response['message'] as String?)?.trim();
    final data = response['data'];

    if (statusCode == 1) {
      final storage = Get.isRegistered<LocalStorage>()
          ? Get.find<LocalStorage>()
          : Get.put(LocalStorage(), permanent: true);

      if (data is Map<String, dynamic>) {
        // Flatten `{ "user": {...}, "token": "..." }` so [UserSessionController] reads top-level keys.
        final merged = coalesceStoredProfileMap(data);
        final token = extractToken(merged);
        if (token.isNotEmpty) {
          await storage.writeStringStorage(kStorageToken, token);
        }
        await storage.writeJsonStorage(kStorageUserData, merged);
      }
      await storage.writeBoolStorage(kStorageIsLoggedIn, true);

      if (!context.mounted) return;
      AppToast.showSuccess(
        context,
        message?.isNotEmpty == true ? message! : successFallbackMessage,
      );
      Get.offAllNamed(Routes.BOTTOM_NAV);
    } else {
      AppToast.showError(
        context,
        message?.isNotEmpty == true ? message! : failureFallbackMessage,
      );
    }
  }
}
