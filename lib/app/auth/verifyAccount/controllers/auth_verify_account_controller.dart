import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthVerifyAccountController extends GetxController {
  final phoneNumberController = TextEditingController();
  final selectedDialCode = '+91'.obs;

  void onCountryCodeChanged(String dialCode) {
    selectedDialCode.value = dialCode;
  }

  @override
  void onClose() {
    phoneNumberController.dispose();
    super.onClose();
  }
}
