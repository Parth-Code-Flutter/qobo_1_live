import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_glass_card.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Settings tab — profile summary + logout (same logout path as user bottom nav).
class SuperAdminSettingsTabView extends StatelessWidget {
  const SuperAdminSettingsTabView({super.key, required this.onLogoutPressed});

  final Future<void> Function() onLogoutPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 110),
          children: [
            const SuperAdminTabHeader(
              icon: Icons.settings_rounded,
              title: 'Settings',
              subtitle: 'Account and session controls',
            ),
            Spacing.v10,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GetBuilder<UserSessionController>(
                builder: (session) {
                  return SuperAdminGlassCard(
                    child: Row(
                      children: [
                        FramedUserAvatar(
                          name: session.displayName,
                          imageUrl: session.displayPictureUrl,
                          frameUrl: session.profileFrameUrl,
                          frameSeed: session.userId,
                          size: 56,
                          fontSize: TextStyles.k16FontSize,
                        ),
                        Spacing.h12,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SemiBoldText(
                                text: session.displayName,
                                fontSize: TextStyles.k16FontSize,
                                color: kColorWhite,
                              ),
                              Spacing.v4,
                              AppText(
                                text: session.email.isNotEmpty
                                    ? session.email
                                    : session.phone,
                                fontSize: TextStyles.k12FontSize,
                                color: Colors.white70,
                              ),
                              Spacing.v6,
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kColorPrimary.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: SemiBoldText(
                                  text: session.role.isEmpty
                                      ? 'super_admin'
                                      : session.role,
                                  fontSize: TextStyles.k10FontSize,
                                  color: kColorWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Spacing.v24,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: appButton(
                onPressed: () => onLogoutPressed(),
                buttonText: 'Log out',
                isGradient: true,
                buttonHeight: 50,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
