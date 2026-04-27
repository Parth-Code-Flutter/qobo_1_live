import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/validations/text_field_validations.dart';

class AuthVerifyAccountController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final phoneNumberController = TextEditingController();
  final selectedDialCode = '+91'.obs;
  final isOtpView = false.obs;
  final otpError = RxnString();
  final otpControllers = List.generate(4, (_) => TextEditingController());
  final otpFocusNodes = List.generate(4, (_) => FocusNode());

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
