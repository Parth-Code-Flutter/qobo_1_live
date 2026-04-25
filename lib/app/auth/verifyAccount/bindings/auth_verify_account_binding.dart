import 'package:get/get.dart';

import '../controllers/auth_verify_account_controller.dart';

class AuthVerifyAccountBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthVerifyAccountController>(
      AuthVerifyAccountController.new,
    );
  }
}
