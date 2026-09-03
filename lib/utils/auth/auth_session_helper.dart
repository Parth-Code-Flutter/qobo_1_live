import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/pk/pk_v1_coordinator.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/auth/role_home_route.dart';
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

  static bool requiresLoginTakeover(Map<String, dynamic>? response) {
    if (response == null) return false;
    final data = response['data'];
    final bodyStatusCode = (response['statusCode'] as num?)?.toInt();
    return bodyStatusCode == 2 ||
        response['isAlreadyLoggedIn'] == true ||
        response['requireConfirmation'] == true ||
        (data is Map &&
            (data['isAlreadyLoggedIn'] == true ||
                data['requireConfirmation'] == true));
  }

  static Future<Map<String, dynamic>?> confirmAndForceLogin(
    BuildContext context,
    Map<String, dynamic>? response, {
    required Future<Map<String, dynamic>?> Function() onForceLogin,
  }) async {
    if (!context.mounted || !requiresLoginTakeover(response)) return response;

    final message = (response?['message'] as String?)?.trim();
    final confirmed = await CommonAppDialog.confirm(
      context: context,
      title: 'Already Logged In',
      message: message?.isNotEmpty == true
          ? message!
          : 'You are already logged in on another device. Do you want to log out from the other device and log in on this device?',
      icon: Icons.phonelink_lock_rounded,
      iconAccent: const Color(0xFFFFA53D),
      cancelLabel: 'Cancel',
      confirmLabel: 'Log In Here',
      barrierDismissible: false,
    );

    if (confirmed != true || !context.mounted) {
      return response;
    }
    return onForceLogin();
  }

  /// Handles API envelope `statusCode` / `message` / `data` used across auth flows.
  static Future<void> handleAuthApiResponse(
    BuildContext context,
    Map<String, dynamic>? response, {
    String successFallbackMessage = 'Login successful',
    String failureFallbackMessage = 'Login failed',
    Future<Map<String, dynamic>?> Function()? onForceLogin,
  }) async {
    if (!context.mounted) return;
    if (response == null) {
      AppToast.showError(context, 'Request failed. Please try again.');
      return;
    }

    final statusCode = (response['statusCode'] as num?)?.toInt() ?? 0;
    final message = (response['message'] as String?)?.trim();
    final data = response['data'];

    if (requiresLoginTakeover(response)) {
      if (onForceLogin == null) {
        AppToast.showError(
          context,
          message?.isNotEmpty == true ? message! : failureFallbackMessage,
        );
        return;
      }
      final forcedResponse = await confirmAndForceLogin(
        context,
        response,
        onForceLogin: onForceLogin,
      );
      if (!context.mounted ||
          forcedResponse == null ||
          identical(forcedResponse, response)) {
        return;
      }
      await handleAuthApiResponse(
        context,
        forcedResponse,
        successFallbackMessage: successFallbackMessage,
        failureFallbackMessage: failureFallbackMessage,
      );
      return;
    }

    if (statusCode == 1) {
      final storage = LocalStorage.shared;
      var homeRoute = Routes.BOTTOM_NAV;

      if (data is Map) {
        // Flatten `{ "user": {...}, "token": "..." }` so [UserSessionController] reads top-level keys.
        final merged = coalesceStoredProfileMap(
          Map<String, dynamic>.from(data),
        );
        final token = extractToken(merged);
        if (token.isNotEmpty) {
          await storage.writeStringStorage(kStorageToken, token);
        }
        await storage.writeJsonStorage(kStorageUserData, merged);
        // Role from login (`super_admin` | `agency` | `host` | `user`) picks the shell.
        homeRoute = await RoleHomeRoute.resolveAfterLogin(merged);
      } else {
        homeRoute = await RoleHomeRoute.resolve();
      }
      await storage.writeBoolStorage(kStorageIsLoggedIn, true);

      if (!Get.isRegistered<ChatSessionService>()) {
        Get.put(ChatSessionService(), permanent: true);
      }
      // Firestore call ringing requires Firebase Auth immediately after REST
      // login, otherwise the first outgoing/incoming ring can hit
      // `permission-denied` before chat screens get a chance to retry.
      await Get.find<ChatSessionService>().ensureSignedIn();
      // Follower live alerts: register device token + open realtime socket.
      unawaited(FcmTokenSyncService.ensureSynced());
      unawaited(UserRealtimeSocketService.ensureConnected());
      unawaited(PkV1Coordinator.ensureStarted());

      if (!context.mounted) return;
      AppToast.showSuccess(
        context,
        message?.isNotEmpty == true ? message! : successFallbackMessage,
      );
      Get.offAllNamed(homeRoute);
    } else {
      AppToast.showError(
        context,
        message?.isNotEmpty == true ? message! : failureFallbackMessage,
      );
    }
  }
}
