import 'package:get/get.dart';

import '../controllers/auth_login_controller.dart';

class AuthLoginBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<AuthLoginController>()) {
      Get.delete<AuthLoginController>(force: true);
    }
    Get.put<AuthLoginController>(AuthLoginController());
  }
}
