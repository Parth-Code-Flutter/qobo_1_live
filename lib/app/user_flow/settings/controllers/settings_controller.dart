import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';

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
    CommonAppDialog.show(
      context,
      title: 'Delete Account',
      message:
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
      icon: Icons.delete_forever_rounded,
      iconAccent: AdminAgencyUi.rose,
      actions: [
        const CommonAppDialogAction(label: 'Cancel'),
        CommonAppDialogAction(
          label: 'Delete',
          isPrimary: true,
          isDestructive: true,
          onPressed: () async {
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
        ),
      ],
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
