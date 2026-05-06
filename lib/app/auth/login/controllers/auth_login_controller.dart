import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class AuthLoginController extends GetxController {
  AuthLoginController({AuthRepo? authRepo})
      : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordHidden = true.obs;
  final isLoginLoading = false.obs;
  final selectedDialCode = '+91'.obs;
  final isPhoneInput = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }

  bool validateForm() {
    return formKey.currentState?.validate() ?? false;
  }

  void onCountryCodeChanged(String dialCode) {
    selectedDialCode.value = dialCode;
  }

  /// Decides whether country-code picker should be visible based on first chars.
  void onUsernameChanged(String value) {
    final trimmed = value.trimLeft();
    if (trimmed.isEmpty) {
      isPhoneInput.value = false;
      return;
    }
    final first = trimmed[0];
    isPhoneInput.value = RegExp(r'^\d$').hasMatch(first);
  }

  String? validateUsername(BuildContext context, String? value) {
    final username = (value ?? '').trim();
    if (username.isEmpty) {
      return LocaleKeys.loginUsernameRequired.tr;
    }
    if (isPhoneInput.value) {
      if (!RegExp(r'^\d{10}$').hasMatch(username)) {
        return LocaleKeys.loginEmailOrPhoneInvalid.tr;
      }
      return null;
    }
    if (!username.isEmail) {
      return LocaleKeys.loginEmailOrPhoneInvalid.tr;
    }
    return null;
  }

  /// API-friendly login username.
  /// Backend expects raw phone digits for phone login (no dial-code prefix).
  String get resolvedLoginUsername {
    final username = emailController.text.trim();
    return username;
  }

  Future<void> onLoginPressed(BuildContext context) async {
    if (isLoginLoading.value) return;
    if (!validateForm()) return;

    try {
      isLoginLoading.value = true;
      final response = await _authRepo.login(
        username: resolvedLoginUsername,
        password: passwordController.text.trim(),
        isShowLoader: false,
      );
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

        // Save auth token if backend returns one in known key names.
        if (data is Map<String, dynamic>) {
          final token = _extractToken(data);
          if (token.isNotEmpty) {
            await storage.writeStringStorage(kStorageToken, token);
          }
          await storage.writeJsonStorage(kStorageUserData, data);
        }
        await storage.writeBoolStorage(kStorageIsLoggedIn, true);

        if (!context.mounted) return;
        AppToast.showSuccess(context, message?.isNotEmpty == true ? message! : 'Login successful');
        Get.offAllNamed(Routes.BOTTOM_NAV);
      } else {
        AppToast.showError(context, message?.isNotEmpty == true ? message! : 'Login failed');
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      isLoginLoading.value = false;
    }
  }

  String _extractToken(Map<String, dynamic> data) {
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
}
