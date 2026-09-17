import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_room/controllers/live_room_controller.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Self-service host dashboard; financial details use the existing wallet flow.
class HostDashboardView extends StatelessWidget {
  const HostDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLightUi.bg,
      appBar: const CommonAppBarWidget(
        title: 'Host Dashboard',
        subtitle: 'Your space to shine',
      ),
      body: AppShellBackground(
        child: GetBuilder<UserSessionController>(
          builder: (session) {
            if (!session.isHost) {
              return Center(
                child: AppText(
                  text: 'Host approval is required.',
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.subtitle,
                ),
              );
            }
            return RefreshIndicator(
              color: AppLightUi.pink,
              onRefresh: () async {
                await session.refreshProfileFromApi();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  _profileCard(session),
                  Spacing.v16,
                  _goLiveHero(),
                  Spacing.v24,
                  const SemiBoldText(
                    text: 'Your activity',
                    fontSize: TextStyles.k16FontSize,
                    color: AppLightUi.title,
                  ),
                  Spacing.v6,
                  const AppText(
                    text: 'Manage your wallet and explore your gifts.',
                    fontSize: TextStyles.k12FontSize,
                    color: AppLightUi.subtitle,
                  ),
                  Spacing.v12,
                  _activityTile(
                    title: 'Wallet & withdrawals',
                    subtitle: 'View your balance and manage withdrawals',
                    icon: Icons.account_balance_wallet_rounded,
                    accent: AppLightUi.violet,
                    onTap: () => Get.to(
                      () => const WalletView(),
                      binding: WalletBinding(),
                    ),
                  ),
                  Spacing.v12,
                  _activityTile(
                    title: 'Gift transactions',
                    subtitle: 'See your gift transaction history',
                    icon: Icons.card_giftcard_rounded,
                    accent: AppLightUi.pink,
                    onTap: () => Get.toNamed(Routes.GIFT_TRANSACTIONS),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _profileCard(UserSessionController session) {
    return GlossyDatingCard(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2.4),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppLightUi.glossRingGradient,
            ),
            child: AppUserAvatar(
              name: session.displayName,
              imageUrl: session.displayPicturePath,
              size: 58,
            ),
          ),
          Spacing.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: session.displayName,
                  fontSize: TextStyles.k18FontSize,
                  color: AppLightUi.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Spacing.v6,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        AppLightUi.gold.withValues(alpha: 0.22),
                        AppLightUi.pink.withValues(alpha: 0.12),
                      ],
                    ),
                    border: Border.all(
                      color: AppLightUi.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: AppLightUi.gold,
                      ),
                      SizedBox(width: 5),
                      SemiBoldText(
                        text: 'Approved Host',
                        fontSize: 11,
                        color: AppLightUi.gold,
                      ),
                    ],
                  ),
                ),
                if (session.agencyCode.isNotEmpty) ...[
                  Spacing.v10,
                  AppText(
                    text: 'Agency · ${session.agencyCode}',
                    fontSize: TextStyles.k12FontSize,
                    color: AppLightUi.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _goLiveHero() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: AppLightUi.familyCtaGradient,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kColorWhite.withValues(alpha: 0.18),
              border: Border.all(
                color: kColorWhite.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.live_tv_rounded,
              color: kColorWhite,
              size: 24,
            ),
          ),
          Spacing.v16,
          const BoldText(
            text: 'Ready for your next live?',
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
          Spacing.v8,
          AppText(
            text: 'Connect with your audience and share your moment.',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.9),
          ),
          Spacing.v20,
          appButton(
            onPressed: () {
              final live = Get.isRegistered<LiveRoomController>()
                  ? Get.find<LiveRoomController>()
                  : Get.put(LiveRoomController());
              live.openGoLive();
            },
            buttonText: 'Go live',
            textColor: const Color(0xFF2A1744),
            buttonIcon: const Icon(
              Icons.videocam_rounded,
              color: Color(0xFF2A1744),
              size: 20,
            ),
            borderRadius: 16,
            buttonHeight: 48,
            gradientColors: const [
              Color(0xFFFFD84E),
              Color(0xFFFF9C2A),
            ],
          ),
        ],
      ),
    );
  }

  Widget _activityTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GlossyDatingCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: AppLightUi.iconTileDecoration(accent, radius: 14),
            child: Icon(icon, color: accent, size: 22),
          ),
          Spacing.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SemiBoldText(
                  text: title,
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                ),
                Spacing.v4,
                AppText(
                  text: subtitle,
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.subtitle,
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppLightUi.muted,
          ),
        ],
      ),
    );
  }
}
