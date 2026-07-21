import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

class SettingsController extends GetxController {
  SettingsController({UserRepo? userRepo}) : _userRepo = userRepo ?? UserRepo();

  final UserRepo _userRepo;
  final settings = <String, dynamic>{}.obs;
  final isLoading = false.obs;

  UserSessionController get _userSession => Get.find<UserSessionController>();

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    isLoading.value = true;
    try {
      final response = await _userRepo.getSettings(isShowLoader: false);
      final data = response?['data'];
      if (data is Map) {
        settings.assignAll(Map<String, dynamic>.from(data));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateSettings(Map<String, dynamic> nextSettings) async {
    final previous = Map<String, dynamic>.from(settings);
    settings.assignAll(nextSettings);
    final response = await _userRepo.updateSettings(
      settings: nextSettings,
      isShowLoader: false,
    );
    if (response == null || response['statusCode'] == 0) {
      settings.assignAll(previous);
      Get.snackbar('Settings', 'Could not update settings.');
    }
  }

  void onLanguageTap() {
    Get.snackbar('Language', 'Language selection coming soon');
  }

  void onPrivacyTermsTap() {
    Get.snackbar('Privacy & Terms', 'Opening privacy policy');
  }

  void onBlockListTap() {
    Get.toNamed(Routes.BLOCK_LIST);
  }

  void onDeleteAccountTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Account',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Get.back();
              final response = await _userRepo.deleteAccount(
                isShowLoader: true,
              );
              if (response == null || response['statusCode'] == 0) {
                Get.snackbar('Account', 'Could not delete account.');
                return;
              }
              await _userSession.clearSession();
              Get.offAllNamed(Routes.AUTH_LOGIN);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void onLogoutTap() async {
    await UserRealtimeSocketService.ensureDisconnected();
    if (Get.isRegistered<FcmTokenSyncService>()) {
      Get.find<FcmTokenSyncService>().clearCachedToken();
    }
    await _userSession.clearSession();
    Get.offAllNamed(Routes.AUTH_LOGIN);
  }
}
