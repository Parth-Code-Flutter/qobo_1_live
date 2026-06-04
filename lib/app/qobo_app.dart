import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/theme_controller.dart';
import 'package:qobo_one_live/theme/app_theme.dart';
import 'package:qobo_one_live/utils/alert_message_utils/alert_message_utils.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:toastification/toastification.dart';

class QoboApp extends StatelessWidget {
  const QoboApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return ScreenUtilInit(
          child: ToastificationWrapper(
            child: Obx(
              () => GetMaterialApp(
                debugShowCheckedModeBanner: false,
                title: LocaleKeys.appTitle.tr,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: themeController.themeMode.value,
                initialRoute: AppPages.INITIAL,
                initialBinding: BindingsBuilder(() {
                  Get.put(AlertMessageUtils(), permanent: true);
                }),
                getPages: AppPages.routes,
                translationsKeys: AppTranslation.translations,
                locale: const Locale('en', 'US'),
                fallbackLocale: const Locale('en', 'US'),
                supportedLocales: const [Locale('en', 'US')],
              ),
            ),
          ),
        );
      },
    );
  }
}
