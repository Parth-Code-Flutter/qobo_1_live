import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

enum AgencyAccessMode { host, owner }

class AgencyAccessController extends GetxController {
  final ownerFormKey = GlobalKey<FormState>();

  final mode = AgencyAccessMode.host.obs;
  final obscurePassword = true.obs;

  final agencyCodeController = TextEditingController();
  final ownerPhoneController = TextEditingController();
  final ownerPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['mode']?.toString() == 'owner') {
      mode.value = AgencyAccessMode.owner;
    }
  }

  @override
  void onClose() {
    agencyCodeController.dispose();
    ownerPhoneController.dispose();
    ownerPasswordController.dispose();
    super.onClose();
  }

  void selectMode(AgencyAccessMode value) {
    mode.value = value;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  String? validateRequired(String label, String? value) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  void openHostApplication() {
    Get.toNamed(Routes.AGENCY_HOST_ONBOARDING);
  }

  void openHostStatus() {
    Get.toNamed(Routes.AGENCY_HOST_STATUS);
  }

  void openOwnerRegister() {
    Get.toNamed(Routes.AGENCY_OWNER_REGISTER);
  }

  void continueOwnerLogin(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (!(ownerFormKey.currentState?.validate() ?? false)) return;

    AppToast.showSuccess(
      context,
      'Agency login UI ready. API binding pending.',
    );
    Get.toNamed(Routes.AGENCY_OWNER);
  }
}
