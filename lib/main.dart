import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:toastification/toastification.dart';

void main() {
  runApp(
    ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return ScreenUtilInit(
          child: ToastificationWrapper(
            child: GetMaterialApp(
              debugShowCheckedModeBanner: false,
              title: LocaleKeys.appTitle.tr,
              initialRoute: AppPages.INITIAL,
              getPages: AppPages.routes,
              // Localization setup aligned with reference project style.
              translationsKeys: AppTranslation.translations,
              locale: const Locale('en', 'US'),
              fallbackLocale: const Locale('en', 'US'),
              supportedLocales: const [
                Locale('en', 'US'),
              ],
            ),
          ),
        );
      },
    ),
  );
}
