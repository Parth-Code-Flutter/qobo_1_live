import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AuthLoginController extends GetxController {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isPasswordHidden = true.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordHidden.value = !isPasswordHidden.value;
  }
}
