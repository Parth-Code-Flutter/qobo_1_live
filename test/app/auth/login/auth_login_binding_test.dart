import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/auth/login/controllers/auth_login_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    Get.reset();
  });

  tearDown(Get.reset);

  test('controller safely resets login fields', () {
    final controller = AuthLoginController();
    Get.put<AuthLoginController>(controller);
    controller.emailController.text = 'user@example.com';
    controller.passwordController.text = 'password';
    controller.isLoginLoading.value = true;

    controller.prepareForLoginScreen();

    expect(Get.find<AuthLoginController>(), same(controller));
    expect(controller.emailController.text, isEmpty);
    expect(controller.passwordController.text, isEmpty);
    expect(controller.isLoginLoading.value, isFalse);
  });
  testWidgets('binding defers resetting mounted fields until after build', (
    tester,
  ) async {
    final controller = Get.put(AuthLoginController());
    controller.emailController.text = 'user@example.com';
    controller.passwordController.text = 'password';
    final resetDuringBuild = ValueNotifier(false);
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            AnimatedBuilder(
              animation: controller.emailController,
              builder: (_, child) => Text(controller.emailController.text),
            ),
            ValueListenableBuilder<bool>(
              valueListenable: resetDuringBuild,
              builder: (_, reset, child) {
                if (reset) controller.prepareForLoginScreen();
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
    resetDuringBuild.value = true;
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(controller.emailController.text, isEmpty);
    expect(controller.passwordController.text, isEmpty);
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    resetDuringBuild.dispose();
  });
}
