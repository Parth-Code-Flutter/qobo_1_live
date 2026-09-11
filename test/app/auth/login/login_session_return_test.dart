import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/app/auth/login/bindings/auth_login_binding.dart';
import 'package:qobo_one_live/app/auth/login/views/auth_login_view.dart';

void main() {
  tearDown(Get.reset);
  for (final replaceLogin in [false, true]) {
    testWidgets(
      'login stays usable after expiry (replace original: $replaceLogin)',
      (tester) async {
        tester.view.physicalSize = const Size(360, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Get.testMode = true;
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, child) => GetMaterialApp(
              initialRoute: '/login',
              translationsKeys: AppTranslation.translations,
              locale: const Locale('en', 'US'),
              getPages: [
                GetPage(
                  name: '/login',
                  page: () => const AuthLoginView(),
                  binding: AuthLoginBinding(),
                ),
                GetPage(
                  name: '/home',
                  page: () => const Scaffold(body: Text('Home')),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var attempt = 0; attempt < 3; attempt++) {
          await tester.enterText(
            find.byType(TextFormField).first,
            '1234567890',
          );
          await tester.enterText(
            find.byType(TextFormField).last,
            'test-password',
          );
          if (replaceLogin) {
            Get.offAllNamed('/home');
          } else {
            Get.toNamed('/home');
          }
          await tester.pumpAndSettle();
          Get.offAllNamed('/login');
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byType(TextFormField), findsNWidgets(2));
          expect(find.byType(ErrorWidget), findsNothing);
          await tester.enterText(
            find.byType(TextFormField).first,
            '1234567890',
          );
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
