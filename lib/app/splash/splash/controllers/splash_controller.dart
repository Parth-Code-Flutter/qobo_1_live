import 'dart:async';

import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
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
      Get.offNamed(Routes.BOTTOM_NAV);
    } else {
      Get.offNamed(Routes.AUTH_LOGIN);
    }
  }
}
