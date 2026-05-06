import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Profile tab view (temporary) with shared background art.
class ProfileTabView extends StatelessWidget {
  const ProfileTabView({
    super.key,
    required this.onLogoutPressed,
  });

  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BoldText(
                  text: 'Profile Screen',
                  fontSize: TextStyles.k22FontSize,
                  color: kColorWhite,
                ),
                const SizedBox(height: 16),
                appButton(
                  onPressed: onLogoutPressed,
                  buttonText: LocaleKeys.logoutButtonText.tr,
                  isGradient: false,
                  buttonColor: kColorPrimary,
                  borderRadius: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
