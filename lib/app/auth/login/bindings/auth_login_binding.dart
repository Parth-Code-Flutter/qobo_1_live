import 'package:get/get.dart';

import '../controllers/auth_login_controller.dart';

class AuthLoginBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<AuthLoginController>()) {
      final controller = Get.find<AuthLoginController>();
      if (controller.canReuseForLogin) {
        controller.prepareForLoginScreen();
        return;
      }
      Get.delete<AuthLoginController>(force: true);
    }
    Get.put<AuthLoginController>(AuthLoginController());
  }
}
