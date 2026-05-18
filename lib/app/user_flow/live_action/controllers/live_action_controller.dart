import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/bottom_nav/controllers/bottom_nav_controller.dart';

/// In-room live action UI state (UI-only; room SDK / APIs later).
class LiveActionController extends GetxController {
  final messageController = TextEditingController();

  void onBackPressed() {
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().onNavBarTabSelected(0);
      return;
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
