import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                _profileHero(userSession),
                Spacing.v16,
                _profileActionCards(),
                Spacing.v12,
                _profileFeatureGrid(),
                Spacing.v20,
                _settingsRow(),
                Spacing.v12,
                appButton(
                  onPressed: onLogoutPressed,
                  buttonText: LocaleKeys.logoutButtonText.tr,
                  isGradient: false,
                  buttonColor: kColorPrimary,
                  borderRadius: 14,
                  buttonIcon: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: const Icon(
                      Icons.logout,
                      color: kColorWhite,
                      size: 18,
                    ),
                  ),
                ),
                Spacing.v20,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _profileHero(UserSessionController userSession) {
    return GetBuilder<UserSessionController>(
      init: userSession,
      builder: (session) {
        final imageUrl = session.displayPictureUrl;
        return LayoutBuilder(
          builder: (_, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final avatarSize = isCompact ? 74.0 : 88.0;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: avatarSize,
                        height: avatarSize,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: kColorWhite,
                          shape: BoxShape.circle,
                          border: Border.all(color: kColorWhite, width: 1.2),
                        ),
                        child: ClipOval(
                          child: imageUrl == null
                              ? _initialsAvatar(session.initials)
                              : Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _initialsAvatar(session.initials),
                                ),
                        ),
                      ),
                      Spacing.h12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BoldText(
                              text: session.displayName,
                              fontSize: isCompact
                                  ? TextStyles.k18FontSize
                                  : TextStyles.k20FontSize,
                              color: kColorWhite,
                            ),
                            Spacing.v2,
                            AppText(
                              text:
                                  'Id : ${session.userId.isNotEmpty ? session.userId : '25656363'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: TextStyles.k14FontSize,
                              color: kColorWhite,
                              style: TextStyles.kRegularPoppins(
                                fontSize: TextStyles.k14FontSize,
                                colors: kColorWhite,
                              ),
                            ),
                            Spacing.v10,
                            // Wrap prevents chip row overflow on narrow devices.
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _smallChip(
                                  text: 'LV.0',
                                  start: kColorProfileChipPinkStart,
                                  end: kColorProfileChipPinkEnd,
                                ),
                                _smallChip(
                                  text: '00',
                                  start: kColorProfileChipPurpleStart,
                                  end: kColorProfileChipPurpleEnd,
                                ),
                                _smallChip(
                                  text: 'Lorium Ip',
                                  start: kColorProfileChipOrangeStart,
                                  end: kColorProfileChipOrangeEnd,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Get.toNamed(Routes.USER_BASIC_PROFILE),
                        child: const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            color: kColorWhite,
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Spacing.v16,
                  Row(
                    children: [
                      _statBlock(
                        '2K',
                        'Visitors',
                        onTap: () => Get.toNamed(Routes.VISITORS),
                      ),
                      _statDivider(),
                      _statBlock('1K', 'Friends'),
                      _statDivider(),
                      _statBlock(
                        '1K',
                        'Following',
                        onTap: () => Get.toNamed(
                          '/follow-list',
                          arguments: const {'initialTab': 0},
                        ),
                      ),
                      _statDivider(),
                      _statBlock(
                        '10K',
                        'Followers',
                        onTap: () => Get.toNamed(
                          '/follow-list',
                          arguments: const {'initialTab': 1},
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _smallChip({
    required String text,
    required Color start,
    required Color end,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [start, end]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: SemiBoldText(
        text: text,
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite,
      ),
    );
  }

  Widget _statBlock(String value, String label, {VoidCallback? onTap}) {
    final content = Column(
      children: [
        BoldText(
          text: value,
          fontSize: TextStyles.k20FontSize,
          color: kColorWhite,
        ),
        Spacing.v6,
        AppText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite,
        ),
      ],
    );

    return Expanded(
      child: onTap == null
          ? content
          : GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: content,
            ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1.2,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: kColorWhite.withValues(alpha: 0.85),
    );
  }

  Widget _initialsAvatar(String initials) {
    return ColoredBox(
      color: kColorAvatarFallbackBg,
      child: Center(
        child: SemiBoldText(
          text: initials,
          fontSize: TextStyles.k24FontSize,
          color: kColorWhite,
        ),
      ),
    );
  }

  /// Quick action cards right below stats, matching Figma layout.
  Widget _profileActionCards() {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            title: 'Recharge\nCoins',
            icon: kIconRechargeCoins,
            start: kColorProfileActionOrangeStart,
            end: kColorProfileActionOrangeEnd,
            onTap: () {
              Get.to(() => const WalletView(), binding: WalletBinding());
            },
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _actionCard(
            title: 'Live Streamer\nCenter',
            icon: kIconMike,
            start: kColorProfileActionPinkStart,
            end: kColorProfileActionPinkEnd,
            onTap: () {
              Get.bottomSheet(
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  decoration: const BoxDecoration(
                    color: Color(0xFF161622),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Spacing.v20,
                      const SemiBoldText(
                        text: 'Streamer & Agency Center',
                        fontSize: 16,
                        color: kColorWhite,
                      ),
                      Spacing.v20,
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kColorPrimary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.video_call_rounded,
                            color: kColorPrimary,
                          ),
                        ),
                        title: const SemiBoldText(
                          text: 'Join an Agency (Host)',
                          fontSize: 13,
                          color: kColorWhite,
                        ),
                        subtitle: const AppText(
                          text: 'Register as a streamer to start broadcasting.',
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                        onTap: () {
                          Get.back();
                          Get.toNamed(
                            Routes.AGENCY_ACCESS,
                            arguments: {'mode': 'host'},
                          );
                        },
                      ),
                      const Divider(color: Colors.white10),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.business_rounded,
                            color: Colors.purpleAccent,
                          ),
                        ),
                        title: const SemiBoldText(
                          text: 'Agency Owner Dashboard',
                          fontSize: 13,
                          color: kColorWhite,
                        ),
                        subtitle: const AppText(
                          text:
                              'Manage your agency, invite codes, & host earnings.',
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                        onTap: () {
                          Get.back();
                          Get.toNamed(
                            Routes.AGENCY_ACCESS,
                            arguments: {'mode': 'owner'},
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard({
    required String title,
    required String icon,
    required Color start,
    required Color end,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 74,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: [start, end]),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SemiBoldText(
                text: title,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ),
            Spacing.h8,
            SvgPicture.asset(icon, width: 20, height: 20, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

  Widget _profileFeatureGrid() {
    final features = <_ProfileFeatureItem>[
      _ProfileFeatureItem('Visitors', kIconVisitor, const [
        Color(0xFF1F74F2),
        Color(0xFF22B8F2),
      ], onTapRoute: Routes.VISITORS),
      _ProfileFeatureItem('User Level', kIconUserLevel, const [
        Color(0xFF8F37F2),
        Color(0xFFD23CF6),
      ], onTapRoute: Routes.USER_LEVEL),
      _ProfileFeatureItem('Backpack', kIconBackpack, const [
        Color(0xFFFF36B6),
        Color(0xFFFF5C9B),
      ], onTapRoute: Routes.BACKPACK),
      _ProfileFeatureItem('Family', kIconFamily, const [
        Color(0xFFFF8A1D),
        Color(0xFFFFD21E),
      ], onTapRoute: Routes.FAMILY),
      _ProfileFeatureItem('SVIP', kIconSVIP, const [
        Color(0xFF15BDE6),
        Color(0xFF17D7C4),
      ], onTapRoute: Routes.SVIP),
      _ProfileFeatureItem('Activity', kIconActivity, const [
        Color(0xFF43D40A),
        Color(0xFF80F20A),
      ], onTapRoute: Routes.ACTIVITY),
      _ProfileFeatureItem(
        'Aristocracy\nCenter',
        kIconAristocracyCenter,
        const [Color(0xFFFF2525), Color(0xFFFF8C2D)],
        onTapRoute: Routes.ARISTOCRACY_CENTER,
      ),
      _ProfileFeatureItem('Mall', kIconMall, const [
        Color(0xFFE5009E),
        Color(0xFFFF54C8),
      ], onTapRoute: Routes.MALL),
      _ProfileFeatureItem('Point Center', kIconPointerCenter, const [
        Color(0xFF00A8B8),
        Color(0xFF08D6C7),
      ], onTapRoute: Routes.POINT_CENTER),
      _ProfileFeatureItem('Award', kIconAward, const [
        Color(0xFFFF145C),
        Color(0xFFFFD83D),
      ], onTapRoute: Routes.AWARD),
      _ProfileFeatureItem(
        'Broadcast\nWatched',
        kIconBroadcastWatched,
        const [Color(0xFF20E06B), Color(0xFF50F0A8)],
        onTapRoute: Routes.BROADCAST_WATCHED,
      ),
      _ProfileFeatureItem('Call', kIconAward, const [
        Color(0xFFE5009E),
        Color(0xFFFF54C8),
      ], onTapRoute: Routes.CALL),
      _ProfileFeatureItem(
        'Customer\nservice',
        kIconCustomerService,
        const [Color(0xFFFFC51D), Color(0xFFFFFF35)],
        onTapRoute: Routes.CUSTOMER_SERVICE,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: kColorProfileFeatureBorder.withValues(alpha: 0.75),
          width: 1,
        ),
      ),
      child: GridView.builder(
        itemCount: features.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 18,
          crossAxisSpacing: 8,
          mainAxisExtent: 104,
        ),
        itemBuilder: (_, index) => _featureItem(features[index]),
      ),
    );
  }

  Widget _featureItem(_ProfileFeatureItem item) {
    return GestureDetector(
      onTap: () {
        if (item.onTapRoute != null) {
          Get.toNamed(item.onTapRoute!);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: item.gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: item.gradientColors.first.withValues(alpha: 0.24),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: SvgPicture.asset(
              item.iconPath,
              width: 29,
              height: 29,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(kColorWhite, BlendMode.srcIn),
            ),
          ),
          Spacing.v8,
          Center(
            child: AppText(
              text: item.label,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }

  Widget _settingsRow() {
    return GestureDetector(
      onTap: () => Get.toNamed(Routes.SETTINGS),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: kColorWhite.withValues(alpha: 0.12),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.settings_rounded, color: kColorWhite, size: 22),
            Spacing.h12,
            const Expanded(
              child: SemiBoldText(
                text: 'Settings',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: kColorWhite,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileFeatureItem {
  const _ProfileFeatureItem(
    this.label,
    this.iconPath,
    this.gradientColors, {
    this.onTapRoute,
  });

  final String label;
  final String iconPath;
  final List<Color> gradientColors;
  final String? onTapRoute;
}
