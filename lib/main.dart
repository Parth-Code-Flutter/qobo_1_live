import 'package:audio_session/audio_session.dart';
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

  // Allow gift SVGA / short SFX to play on iOS even with the Silent switch on,
  // while mixing with Zego live-room / call audio (do not take exclusive focus).
  await _configureGiftAudioSession();

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

/// Configures a playback-capable session that mixes with RTC (Zego).
///
/// Note: `svgaplayer_flutter` is archived and has no `enableSound` API.
/// Gift SVGA audio comes from `flutter_svga` (embedded tracks) and/or the
/// gift-list `soundUrl` via [GiftSoundPlayer].
Future<void> _configureGiftAudioSession() async {
  try {
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.sonification,
          usage: AndroidAudioUsage.assistanceSonification,
        ),
        androidAudioFocusGainType:
            AndroidAudioFocusGainType.gainTransientMayDuck,
      ),
    );
  } catch (_) {
    // Audio session setup must never block app launch.
  }
}
