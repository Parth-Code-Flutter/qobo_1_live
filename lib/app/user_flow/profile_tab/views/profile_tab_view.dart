import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Profile tab view (temporary) with shared background art.
class ProfileTabView extends StatelessWidget {
  const ProfileTabView({super.key, required this.onLogoutPressed});

  final VoidCallback onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    final userSession = _resolveUserSession();
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            children: [
              _topHeaderLikeLiveRoom(userSession),
              const Spacer(),
              appButton(
                onPressed: onLogoutPressed,
                buttonText: LocaleKeys.logoutButtonText.tr,
                isGradient: false,
                buttonColor: kColorPrimary,
                borderRadius: 14,
                buttonIcon: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: const Icon(Icons.logout, color: kColorWhite, size: 18),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Reuses live-room-like top profile row style in profile tab.
  Widget _topHeaderLikeLiveRoom(UserSessionController userSession) {
    return GetBuilder<UserSessionController>(
      init: userSession,
      builder: (session) {
        final imageUrl = session.displayPictureUrl;
        return Row(
          children: [
            Container(
              width: 65,
              height: 65,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: kColorWhite,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xB3FFFFFF), width: 1),
              ),
              child: ClipOval(
                child: imageUrl == null
                    ? ColoredBox(
                        color: const Color(0xFF2A2A2A),
                        child: Center(
                          child: SemiBoldText(
                            text: session.initials,
                            fontSize: TextStyles.k14FontSize,
                            color: kColorWhite,
                          ),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: const Color(0xFF2A2A2A),
                          child: Center(
                            child: SemiBoldText(
                              text: session.initials,
                              fontSize: TextStyles.k14FontSize,
                              color: kColorWhite,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            Spacing.h10,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: LocaleKeys.liveRoomWelcome.tr,
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                  SemiBoldText(
                    text: session.displayName,
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                  ),
                ],
              ),
            ),
            const Center(
              child: Icon(
                Icons.chevron_right_rounded,
                color: kColorWhite,
              ),
            ),
          ],
        );
      },
    );
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }
}
