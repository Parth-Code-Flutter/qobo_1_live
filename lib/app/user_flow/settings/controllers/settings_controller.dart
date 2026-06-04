import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/theme_controller.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

class SettingsController extends GetxController {
  UserSessionController get _userSession => Get.find<UserSessionController>();
  ThemeController get _theme => Get.find<ThemeController>();

  ThemeMode get currentThemeMode => _theme.themeMode.value;

  Future<void> setThemeMode(ThemeMode mode) async {
    await _theme.setThemeMode(mode);
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
    final colors = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: colors.error),
        ),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Get.back();
              Get.snackbar('Account', 'Account deletion requested.');
            },
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );
  }

  void onLogoutTap() async {
    await _userSession.clearSession();
    Get.offAllNamed(Routes.AUTH_LOGIN);
  }
}
