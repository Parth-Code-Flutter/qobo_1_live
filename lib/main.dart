import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/services/firebase/push_notification_bootstrap.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/alert_message_utils/alert_message_utils.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:toastification/toastification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Background isolate entry must be registered before FCM is used.
  PushNotificationBootstrap.registerBackgroundHandler();

  await FirebaseBootstrap.tryInitialize();
  await PushNotificationBootstrap.tryInitialize();

  runApp(
    ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return ScreenUtilInit(
          child: ToastificationWrapper(
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: LocaleKeys.appTitle.tr,
              initialRoute: AppPages.INITIAL,
              initialBinding: BindingsBuilder(() {
                Get.put(AlertMessageUtils(), permanent: true);
                LocalStorage.ensureRegistered();
                if (!Get.isRegistered<UserSessionController>()) {
                  Get.put(UserSessionController(), permanent: true);
                }
              }),
              getPages: AppPages.routes,
              // Localization setup aligned with reference project style.
              translationsKeys: AppTranslation.translations,
              locale: const Locale('en', 'US'),
              fallbackLocale: const Locale('en', 'US'),
              supportedLocales: const [Locale('en', 'US')],
            ),
          ),
        );
      },
    ),
  );

  // Deliver Join/Reject from a terminated-state notification after UI exists.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PushNotificationBootstrap.flushPendingLaunch();
  });
}
