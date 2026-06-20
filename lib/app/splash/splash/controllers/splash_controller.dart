import 'dart:async';

import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_media_permissions.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

class SplashController extends GetxController {
  final permissionBlocked = false.obs;
  final showOpenSettings = false.obs;

  bool _navigated = false;

  @override
  void onReady() {
    super.onReady();
    unawaited(_runStartup());
  }

  Future<void> _runStartup() async {
    await Future.wait([
      Future<void>.delayed(const Duration(seconds: 3)),
      _ensurePermissions(),
    ]);

    if (permissionBlocked.value) return;
    unawaited(_navigateNext());
  }

  Future<void> _ensurePermissions() async {
    if (await AppMediaPermissions.areGranted()) {
      permissionBlocked.value = false;
      showOpenSettings.value = false;
      return;
    }

    final granted = await AppMediaPermissions.requestRequired();
    if (granted) {
      permissionBlocked.value = false;
      showOpenSettings.value = false;
      return;
    }

    permissionBlocked.value = true;
    showOpenSettings.value = await AppMediaPermissions.isPermanentlyDenied();
  }

  Future<void> retryPermissions() async {
    if (await AppMediaPermissions.areGranted()) {
      permissionBlocked.value = false;
      showOpenSettings.value = false;
      unawaited(_navigateNext());
      return;
    }

    final granted = await AppMediaPermissions.requestRequired();
    if (granted) {
      permissionBlocked.value = false;
      showOpenSettings.value = false;
      unawaited(_navigateNext());
      return;
    }

    permissionBlocked.value = true;
    showOpenSettings.value = await AppMediaPermissions.isPermanentlyDenied();
  }

  Future<void> openDeviceSettings() async {
    await AppMediaPermissions.openSettings();
  }

  Future<void> _navigateNext() async {
    if (_navigated || permissionBlocked.value) return;
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
