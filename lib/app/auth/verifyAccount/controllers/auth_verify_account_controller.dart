import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

class AuthVerifyAccountController extends GetxController {
  AuthVerifyAccountController({AuthRepo? authRepo})
      : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;

  final formKey = GlobalKey<FormState>();
  final phoneNumberController = TextEditingController();
  final selectedDialCode = '+91'.obs;
  final isOtpView = false.obs;
  final isContinueLoading = false.obs;
  final otpError = RxnString();
  final otpControllers = List.generate(4, (_) => TextEditingController());
  final otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool isFromLoginWithOtp = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['isFromLoginWithOtp'] == true) {
      isFromLoginWithOtp = true;
    }
  }

  void onCountryCodeChanged(String dialCode) {
    selectedDialCode.value = dialCode;
  }

  void showOtpView() {
    isOtpView.value = true;
    otpError.value = null;
  }

  void showPhoneNumberView() {
    isOtpView.value = false;
  }

  bool handleBackAction() {
    if (isOtpView.value) {
      showPhoneNumberView();
      return false;
    }
    return true;
  }

  void onOtpChanged({
    required int index,
    required String value,
  }) {
    otpError.value = null;
    if (value.isNotEmpty && index < otpFocusNodes.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
    }
  }

  bool validatePhoneForm() {
    return formKey.currentState?.validate() ?? false;
  }

  bool validateOtp(BuildContext context) {
    final otpValue = otpControllers.map((controller) => controller.text).join();
    final validationMessage = Validate.otpValidation(
      context,
      otpValue,
      otpLength: 4,
    );
    otpError.value = validationMessage;
    return validationMessage == null;
  }

  void setContinueLoading(bool value) {
    isContinueLoading.value = value;
  }

  /// Continue CTA: requests OTP on phone step, verifies OTP on OTP step.
  Future<void> onContinuePressed(BuildContext context) async {
    if (isContinueLoading.value) return;

    if (isOtpView.value) {
      await _submitVerifyOtp(context);
      return;
    }

    await _submitLoginPhoneOtp(context);
  }

  Future<void> _submitLoginPhoneOtp(BuildContext context) async {
    if (!validatePhoneForm()) return;

    try {
      setContinueLoading(true);
      final res = await _authRepo.loginWithOtp(
        phone: phoneNumberController.text.trim(),
        countryCode: selectedDialCode.value,
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

      if (res.statusCode == 1) {
        AppToast.showSuccess(context, message);
        showOtpView();
      } else {
        AppToast.showError(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      setContinueLoading(false);
    }
  }

  Future<void> _submitVerifyOtp(BuildContext context) async {
    if (!validateOtp(context)) return;

    try {
      setContinueLoading(true);
      final otpDigits = otpControllers.map((c) => c.text).join();
      final res = await _authRepo.verifyOtp(
        phone: phoneNumberController.text.trim(),
        otp: otpDigits,
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

      if (res.statusCode == 1) {
        AppToast.showSuccess(context, message);
      } else {
        AppToast.showError(context, message);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.showError(context, e.toString());
      }
    } finally {
      setContinueLoading(false);
    }
  }

  @override
  void onClose() {
    phoneNumberController.dispose();
    for (final otpController in otpControllers) {
      otpController.dispose();
    }
    for (final otpFocusNode in otpFocusNodes) {
      otpFocusNode.dispose();
    }
    super.onClose();
  }
}
