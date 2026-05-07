import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
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
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 88,
                    height: 88,
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
                  Spacing.h16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BoldText(
                          text: session.displayName,
                          fontSize: TextStyles.k20FontSize,
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
                        Row(
                          children: [
                            _smallChip(
                              text: 'LV.0',
                              start: kColorProfileChipPinkStart,
                              end: kColorProfileChipPinkEnd,
                            ),
                            Spacing.h10,
                            _smallChip(
                              text: '00',
                              start: kColorProfileChipPurpleStart,
                              end: kColorProfileChipPurpleEnd,
                            ),
                            Spacing.h10,
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
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: kColorWhite,
                      size: 34,
                    ),
                  ),
                ],
              ),
              Spacing.v16,
              Row(
                children: [
                  _statBlock('2K', 'Visitors'),
                  _statDivider(),
                  _statBlock('1K', 'Following'),
                  _statDivider(),
                  _statBlock('10K', 'Followers'),
                ],
              ),
            ],
          ),
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

  Widget _statBlock(String value, String label) {
    return Expanded(
      child: Column(
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
              Get.to(
                () => const WalletView(),
                binding: WalletBinding(),
              );
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
            onTap: () {},
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: [start, end]),
        ),
        child: Row(
          children: [
            Expanded(
              child: SemiBoldText(
                text: title,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ),
            Spacing.h8,
            SvgPicture.asset(icon, width: 22, height: 22, fit: BoxFit.contain),
          ],
        ),
      ),
    );
  }

  /// Profile feature section (4x3) with circular icon chips.
  Widget _profileFeatureGrid() {
    final features = <_ProfileFeatureItem>[
      _ProfileFeatureItem('Visitors', kIconVisitor, kColorProfileFeatureGreen),
      _ProfileFeatureItem('User Level', kIconUserLevel, kColorProfileFeaturePurple),
      _ProfileFeatureItem('Backpack', kIconBackpack, kColorProfileFeatureOrange),
      _ProfileFeatureItem('Family', kIconFamily, kColorProfileFeaturePeach),
      _ProfileFeatureItem('SVIP', kIconSVIP, kColorProfileFeatureBlue),
      _ProfileFeatureItem('Activity', kIconActivity, kColorProfileFeatureYellow),
      _ProfileFeatureItem('Aristocracy\nCenter', kIconAristocracyCenter, kColorProfileFeaturePink),
      _ProfileFeatureItem('Mall', kIconMall, kColorProfileFeatureCyan),
      _ProfileFeatureItem('Point Center', kIconPointerCenter, kColorProfileFeaturePink),
      _ProfileFeatureItem('Award', kIconAward, kColorProfileFeaturePeach),
      _ProfileFeatureItem('Broadcast\nWatched', kIconBroadcastWatched, kColorProfileFeatureGreen),
      _ProfileFeatureItem('Customer\nservice', kIconCustomerService, kColorProfileFeatureYellow),
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
          mainAxisSpacing: 10,
          crossAxisSpacing: 6,
          mainAxisExtent: 138,
        ),
        itemBuilder: (_, index) => _featureItem(features[index]),
      ),
    );
  }

  Widget _featureItem(_ProfileFeatureItem item) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: item.bgColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: SvgPicture.asset(
            item.iconPath,
            width: 35,
            height: 35,
            fit: BoxFit.contain,
          ),
        ),
        Spacing.v6,
        Center(
          child: AppText(
            text: item.label,
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
        ),
      ],
    );
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }
}

class _ProfileFeatureItem {
  const _ProfileFeatureItem(this.label, this.iconPath, this.bgColor);

  final String label;
  final String iconPath;
  final Color bgColor;
}
