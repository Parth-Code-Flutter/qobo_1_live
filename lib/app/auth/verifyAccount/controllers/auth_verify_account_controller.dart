import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthVerifyAccountController extends GetxController {
  final phoneNumberController = TextEditingController();
  final selectedDialCode = '+91'.obs;
  final isOtpView = false.obs;
  final otpControllers = List.generate(4, (_) => TextEditingController());
  final otpFocusNodes = List.generate(4, (_) => FocusNode());

  void onCountryCodeChanged(String dialCode) {
    selectedDialCode.value = dialCode;
  }

  void showOtpView() {
    isOtpView.value = true;
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
    if (value.isNotEmpty && index < otpFocusNodes.length - 1) {
      otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      otpFocusNodes[index - 1].requestFocus();
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
