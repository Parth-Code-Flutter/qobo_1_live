import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/auth/login/bindings/auth_login_binding.dart';
import 'package:qobo_one_live/app/auth/login/controllers/auth_login_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  test('binding replaces a registered controller after it has closed', () {
    final closedController = AuthLoginController();
    Get.put<AuthLoginController>(closedController);
    closedController.onClose();

    AuthLoginBinding().dependencies();

    final activeController = Get.find<AuthLoginController>();
    expect(activeController, isNot(same(closedController)));
    expect(activeController.canReuseForLogin, isTrue);
  });

  test('binding safely resets a live registered controller', () {
    final controller = AuthLoginController();
    Get.put<AuthLoginController>(controller);
    controller.emailController.text = 'user@example.com';
    controller.passwordController.text = 'password';
    controller.isLoginLoading.value = true;

    AuthLoginBinding().dependencies();

    expect(Get.find<AuthLoginController>(), same(controller));
    expect(controller.emailController.text, isEmpty);
    expect(controller.passwordController.text, isEmpty);
    expect(controller.isLoginLoading.value, isFalse);
  });
}
