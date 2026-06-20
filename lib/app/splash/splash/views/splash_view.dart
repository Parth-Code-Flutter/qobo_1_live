import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            kGifSplashScreen,
            fit: BoxFit.cover,
          ),
          Obx(() {
            if (!controller.permissionBlocked.value) {
              return const SizedBox.shrink();
            }
            return _permissionBlockedOverlay();
          }),
        ],
      ),
    );
  }

  Widget _permissionBlockedOverlay() {
    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mic_external_on_rounded,
                size: 56,
                color: kColorWhite.withValues(alpha: 0.9),
              ),
              Spacing.v20,
              SemiBoldText(
                text: 'Microphone & camera required',
                fontSize: TextStyles.k20FontSize,
                color: kColorWhite,
                align: TextAlign.center,
              ),
              Spacing.v12,
              AppText(
                text:
                    'Qobo Live needs microphone and camera access for calls and live streaming. '
                    'Please allow both permissions to continue.',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite.withValues(alpha: 0.78),
                align: TextAlign.center,
                maxLines: 6,
              ),
              Spacing.v28,
              appButton(
                onPressed: controller.retryPermissions,
                buttonText: 'Allow access',
                isGradient: true,
              ),
              Obx(() {
                if (!controller.showOpenSettings.value) {
                  return const SizedBox.shrink();
                }
                return Column(
                  children: [
                    Spacing.v12,
                    appButton(
                      onPressed: controller.openDeviceSettings,
                      buttonText: 'Open Settings',
                      isGradient: false,
                      buttonColor: Colors.transparent,
                      buttonBorderColor: kColorWhite.withValues(alpha: 0.45),
                      textColor: kColorWhite,
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
