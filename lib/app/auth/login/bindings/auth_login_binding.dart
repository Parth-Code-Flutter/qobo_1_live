import 'package:get/get.dart';

import '../controllers/auth_login_controller.dart';

class AuthLoginBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<AuthLoginController>()) {
      Get.find<AuthLoginController>().prepareForLoginScreen();
      return;
    }
    Get.put<AuthLoginController>(AuthLoginController());
  }
}
