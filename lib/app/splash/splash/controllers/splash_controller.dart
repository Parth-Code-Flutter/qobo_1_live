import 'dart:async';

import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/utils/auth/role_home_route.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

class SplashController extends GetxController {
  bool _navigated = false;

  @override
  void onReady() {
    super.onReady();
    unawaited(_runStartup());
  }

  Future<void> _runStartup() async {
    await Future<void>.delayed(const Duration(seconds: 3));
    unawaited(_navigateNext());
  }

  Future<void> _navigateNext() async {
    if (_navigated) return;
    _navigated = true;

    final storage = LocalStorage.shared;
    final isLoggedIn = await storage.isLoggedIn();
    if (isLoggedIn) {
      // Re-register FCM + socket so cold starts still receive follower alerts.
      unawaited(FcmTokenSyncService.ensureSynced());
      unawaited(UserRealtimeSocketService.ensureConnected());
      // Route by stored role (e.g. super_admin → Super Admin bottom nav).
      final homeRoute = await RoleHomeRoute.resolve();
      Get.offNamed(homeRoute);
    } else {
      Get.offNamed(Routes.AUTH_LOGIN);
    }
  }
}
