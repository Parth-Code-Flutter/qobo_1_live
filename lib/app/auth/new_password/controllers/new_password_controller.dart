import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/auth/auth_route_arguments.dart';
import 'package:qobo_one_live/constants/status_code_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

/// Screen after forgot-password OTP: collects the new password and calls
/// `POST /api/auth/reset-password` with [phone], [otp], and the chosen password.
class NewPasswordController extends GetxController {
  NewPasswordController({AuthRepo? authRepo}) : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;

  final formKey = GlobalKey<FormState>();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final isNewPasswordHidden = true.obs;
  final isConfirmPasswordHidden = true.obs;
  final isSubmitLoading = false.obs;

  /// 10-digit phone (must match [AuthNewPasswordArgs.phone] from the verify screen).
  String _phone = '';

  /// OTP the user entered before this route (must match [AuthNewPasswordArgs.otp]).
  String _otp = '';

  static const int _minPasswordLength = 6;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      _phone = (args[AuthNewPasswordArgs.phone] as String?)?.trim() ?? '';
      _otp = (args[AuthNewPasswordArgs.otp] as String?)?.trim() ?? '';
    }
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordHidden.value = !isNewPasswordHidden.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordHidden.value = !isConfirmPasswordHidden.value;
  }

  String? validateNewPassword(BuildContext context, String? value) {
    final v = (value ?? '').trim();
    final base = Validate.passwordValidation(context, v);
    if (base != null) return base;
    if (v.length < _minPasswordLength) {
      return LocaleKeys.newPasswordMinLengthError.tr;
    }
    return null;
  }

  String? validateConfirmPassword(BuildContext context, String? value) {
    return Validate.confirmPasswordValidation(
      context,
      (value ?? '').trim(),
      newPasswordController.text.trim(),
    );
  }

  /// Validates form, then calls [AuthRepo.resetPassword]. On success, clears the stack to login.
  Future<void> onConfirmPressed(BuildContext context) async {
    if (isSubmitLoading.value) return;
    if (!(formKey.currentState?.validate() ?? false)) return;

    if (_phone.isEmpty || _otp.isEmpty) {
      AppToast.showError(
        context,
        LocaleKeys.resetPasswordMissingContext.tr,
      );
      return;
    }

    final password = newPasswordController.text.trim();

    try {
      isSubmitLoading.value = true;
      final res = await _authRepo.resetPassword(
        phone: _phone,
        otp: _otp,
        password: password,
        isShowLoader: false,
      );

      if (!context.mounted) return;

      if (res == null) {
        AppToast.showError(context, 'Request failed. Please try again.');
        return;
      }

      final message = res.message.trim().isNotEmpty
          ? res.message.trim()
          : 'Something went wrong.';

      // Backend may return `1` (auth helpers) or `201` (REST convention).
      if (res.statusCode == 1 ||
          res.statusCode == StatusCodeConstants.success) {
        AppToast.showSuccess(context, message);
        Get.offAllNamed(Routes.AUTH_LOGIN);
      } else {
        AppToast.showError(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      isSubmitLoading.value = false;
    }
  }

  void onSignInTap() {
    Get.offAllNamed(Routes.AUTH_LOGIN);
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
