import 'package:qobo_one_live/app/user_flow/role_application/role_application_view.dart';
import 'package:qobo_one_live/repo/agency/role_application_repo.dart';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/generated/locales.g.dart';
import 'package:qobo_one_live/app/bottom_nav/controllers/bottom_nav_controller.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/app_widgets/svip_badge_chip.dart';
import 'package:qobo_one_live/app/user_flow/host_dashboard/host_dashboard_view.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Profile tab view (temporary) with shared background art.
class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key, required this.onLogoutPressed});

  final VoidCallback onLogoutPressed;

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  @override
  void initState() {
    super.initState();
    // Cold start: getProfile may omit cover URL while backpack has isEquipped.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = _resolveUserSession();
      if (session.profileBackgroundUrl.trim().isEmpty) {
        session.syncEquippedProfileBackgroundFromBackpack();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userSession = _resolveUserSession();
    return GetBuilder<UserSessionController>(
      init: userSession,
      builder: (session) {
        final backgroundUrl =
            ApiImageUtils.normalize(session.profileBackgroundUrl)?.trim() ?? '';
        final backgroundPreviewUrl =
            ApiImageUtils.normalize(
              session.profileBackgroundPreviewUrl,
            )?.trim() ??
            '';
        final hasEquippedCover = backgroundUrl.isNotEmpty;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Equipped Edit Cover fills the whole Profile tab; else app art.
            if (hasEquippedCover)
              Positioned.fill(
                child: ProfileBackgroundMedia(
                  key: ValueKey('profile_tab_bg_$backgroundUrl'),
                  url: backgroundUrl,
                  fit: BoxFit.cover,
                  showLoadingIndicator: false,
                  previewImageUrl: backgroundPreviewUrl,
                ),
              )
            else
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: kColorLavenderBg,
                  ),
                ),
              ),
            // Soft wash so feature tiles / logout stay readable on SVGA covers.
            if (hasEquippedCover)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        kColorBlack.withValues(alpha: 0.28),
                        kColorBlack.withValues(alpha: 0.55),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _profileHero(session, onCover: hasEquippedCover),
                      Spacing.v16,
                      _profileFeatureGrid(onCover: hasEquippedCover),
                      Spacing.v16,
                      appButton(
                        onPressed: widget.onLogoutPressed,
                        buttonText: LocaleKeys.logoutButtonText.tr,
                        isGradient: true,
                        gradientColors: AppLightUi.familyCtaColors,
                        borderRadius: 16,
                        buttonHeight: 52,
                        buttonIcon: const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(
                            Icons.logout_rounded,
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
          ],
        );
      },
    );
  }

  Widget _profileHero(UserSessionController session, {required bool onCover}) {
    final imageUrl = session.displayPictureUrl;
    // Family CTA gradient hero → always white type (same as Open Family Chat).
    const titleColor = kColorWhite;
    final bodyColor = kColorWhite.withValues(alpha: 0.90);
    return LayoutBuilder(
      builder: (_, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final avatarSize = isCompact ? 74.0 : 88.0;
        final avatarFrameSize = avatarSize * 1.34;
        // Cover media is full-tab now — hero is only identity content.
        return _ProfileHeroCard(
          onCover: onCover,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: avatarFrameSize,
                        height: avatarFrameSize,
                        child: Center(
                          child: FramedUserAvatar(
                            key: ValueKey(
                              'profile_frame_${session.profileFrameUrl}',
                            ),
                            name: session.displayName,
                            imageUrl: imageUrl,
                            size: avatarSize,
                            frameUrl: session.profileFrameUrl,
                            frameSeed: session.userId.isNotEmpty
                                ? session.userId
                                : session.displayName,
                            fontSize: isCompact
                                ? TextStyles.k14FontSize
                                : TextStyles.k18FontSize,
                          ),
                        ),
                      ),
                      Spacing.v6,
                      _smallChip(
                        text: session.levelBadge,
                        start: kColorProfileChipPinkStart,
                        end: kColorProfileChipPinkEnd,
                      ),
                    ],
                  ),
                  Spacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: BoldText(
                                text: session.displayName,
                                fontSize: isCompact
                                    ? TextStyles.k18FontSize
                                    : TextStyles.k20FontSize,
                                color: titleColor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (session.isSvipMember) ...[
                              Spacing.h6,
                              const SvipBadgeChip(),
                            ],
                          ],
                        ),
                        Spacing.v2,
                        AppText(
                          text:
                              'Id : ${session.userId.isNotEmpty ? session.userId : '25656363'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontSize: TextStyles.k14FontSize,
                          color: bodyColor,
                          style: TextStyles.kRegularPoppins(
                            fontSize: TextStyles.k14FontSize,
                            colors: bodyColor,
                          ),
                        ),
                        Spacing.v6,
                        _loginRoleMark(session.effectiveRole),
                        Spacing.v10,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _smallChip(
                              text: _pattiChipLabel(session.pattiStyle),
                              start: kColorProfileChipOrangeStart,
                              end: kColorProfileChipOrangeEnd,
                              fontSize: TextStyles.k10FontSize,
                            ),
                            _smallChip(
                              text: '00',
                              start: kColorProfileChipPurpleStart,
                              end: kColorProfileChipPurpleEnd,
                              fontSize: TextStyles.k10FontSize,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _openBasicProfileAndRefresh(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: titleColor,
                        size: 34,
                      ),
                    ),
                  ),
                ],
              ),
              Spacing.v16,
              // Counts come from GET /api/user/profile (formatted* / *Count).
              Row(
                children: [
                  _statBlock(
                    session.formattedVisitors,
                    'Visitors',
                    onTap: () => Get.toNamed(Routes.VISITORS),
                  ),
                  _statDivider(),
                  _statBlock(
                    session.formattedFriends,
                    'Friends',
                    onTap: () => Get.toNamed(
                      Routes.FOLLOW_LIST,
                      arguments: const {'initialTab': 0},
                    ),
                  ),
                  _statDivider(),
                  _statBlock(
                    session.formattedFollowing,
                    'Following',
                    onTap: () => Get.toNamed(
                      Routes.FOLLOW_LIST,
                      arguments: const {'initialTab': 1},
                    ),
                  ),
                  _statDivider(),
                  _statBlock(
                    session.formattedFollowers,
                    'Followers',
                    onTap: () => Get.toNamed(
                      Routes.FOLLOW_LIST,
                      arguments: const {'initialTab': 2},
                    ),
                  ),
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
    IconData? icon,
    double fontSize = TextStyles.k12FontSize,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [start, end],
        ),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.62)),
        boxShadow: [
          BoxShadow(
            color: end.withValues(alpha: 0.42),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 13,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(icon == null ? 11 : 7, 4, 11, 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 13, color: kColorWhite),
                    const SizedBox(width: 4),
                  ],
                  SemiBoldText(
                    text: text,
                    fontSize: fontSize,
                    color: kColorWhite,
                    style: TextStyles.kSemiBoldPoppins(
                      fontSize: fontSize,
                      colors: kColorWhite,
                    ).copyWith(
                      letterSpacing: 0.2,
                      shadows: const [
                        Shadow(
                          color: Color(0x40000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Small lowercase role under the profile id. Uses the signed-in role only.
  Widget _loginRoleMark(String role) {
    final label = switch (role) {
      'super_admin' => 'super admin',
      'coins_seller' => 'coin seller',
      'agency' => 'agency',
      'host' => 'host',
      _ => 'user',
    };
    final icon = switch (role) {
      'super_admin' => Icons.workspace_premium_rounded,
      'coins_seller' => Icons.paid_rounded,
      'agency' => Icons.apartment_rounded,
      'host' => Icons.mic_rounded,
      _ => Icons.person_rounded,
    };
    final colors = switch (role) {
      'super_admin' => (const Color(0xFFFFC94A), const Color(0xFFE85D04)),
      'coins_seller' => (const Color(0xFFFFD56A), const Color(0xFFD97706)),
      'agency' => (const Color(0xFF67E8F9), const Color(0xFF2563EB)),
      'host' => (const Color(0xFFFF7AD9), const Color(0xFFDB2777)),
      _ => (const Color(0xFFC4B5FD), const Color(0xFF7C3AED)),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: _smallChip(
        text: label,
        start: colors.$1,
        end: colors.$2,
        icon: icon,
        fontSize: TextStyles.k10FontSize,
      ),
    );
  }

  String _pattiChipLabel(String style) {
    final raw = style.trim();
    if (raw.isEmpty) return 'Classic Patti';
    final parts = raw
        .split(RegExp(r'[_\s-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
    return '$parts Patti';
  }

  Widget _statBlock(
    String value,
    String label, {
    VoidCallback? onTap,
  }) {
    const valueColor = kColorWhite;
    final labelColor = kColorWhite.withValues(alpha: 0.86);
    final content = Column(
      children: [
        BoldText(
          text: value,
          fontSize: TextStyles.k20FontSize,
          color: valueColor,
        ),
        Spacing.v6,
        AppText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: labelColor,
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
      color: kColorWhite.withValues(alpha: 0.55),
    );
  }

  Widget _profileFeatureGrid({required bool onCover}) {
    final session = _resolveUserSession();
    final showSuperAdmin = session.showSuperAdminIcon;
    final showAgency = session.showAgencyIcon;
    final showCoinSeller = session.showCoinsSellerIcon;

    final features = <_ProfileFeatureItem>[
      _ProfileFeatureItem('Top Up', kIconRechargeCoins, const [
        Color(0xFFFF8A1D),
        Color(0xFFFF6B57),
      ], onTap: _openWallet),
      if (showSuperAdmin)
        _ProfileFeatureItem('Super\nAdmin', kIconBadge, const [
          Color(0xFFFF4D8D),
          Color(0xFF8F37F2),
        ], onTap: _openSuperAdminFlow),
      if (showAgency)
        _ProfileFeatureItem('Agency', kIconMall, const [
          Color(0xFF6E4BFF),
          Color(0xFF00BCD4),
        ], onTap: _openAgencyFlow),
      if (session.showHostIcon)
        _ProfileFeatureItem('Host', kIconBadge, const [
          Color(0xFF00897B),
          Color(0xFF26C6DA),
        ], onTap: _openHostFlow),
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
      _ProfileFeatureItem('Invite', kIconAward, const [
        Color(0xFFFF3F7F),
        Color(0xFF8E1B85),
      ], onTapRoute: Routes.REFERRAL),
      _ProfileFeatureItem('SVIP', kIconSVIP, const [
        Color(0xFF15BDE6),
        Color(0xFF17D7C4),
      ], onTapRoute: Routes.SVIP),
      _ProfileFeatureItem('Entry\nFrames', kIconSVIP, const [
        Color(0xFFFFB020),
        Color(0xFFFFD700),
      ], onTapRoute: Routes.VIP_STORE),
      _ProfileFeatureItem('Activity', kIconActivity, const [
        Color(0xFF43D40A),
        Color(0xFF80F20A),
      ], onTapRoute: Routes.ACTIVITY),
      _ProfileFeatureItem('Mall', kIconMall, const [
        Color(0xFFE5009E),
        Color(0xFFFF54C8),
      ], onTapRoute: Routes.MALL),
      _ProfileFeatureItem('Tasks', kIconPointerCenter, const [
        Color(0xFF00A8B8),
        Color(0xFF08D6C7),
      ], onTapRoute: Routes.POINT_CENTER),
      _ProfileFeatureItem('Award', kIconAward, const [
        Color(0xFFFF145C),
        Color(0xFFFFD83D),
      ], onTapRoute: Routes.AWARD),
      _ProfileFeatureItem('Call', kIconAward, const [
        Color(0xFFE5009E),
        Color(0xFFFF54C8),
      ], onTapRoute: Routes.CALL),
      if (showCoinSeller)
        _ProfileFeatureItem('Coin Seller', kIconCoin2, const [
          Color(0xFFFFB020),
          Color(0xFFFF6B00),
        ], onTapRoute: Routes.COIN_SELLER),
      _ProfileFeatureItem(
        'Support',
        kIconCustomerService,
        const [Color(0xFFFFC51D), Color(0xFFFFFF35)],
        onTapRoute: Routes.CUSTOMER_SERVICE,
      ),
      _ProfileFeatureItem('Transactions', kIconCoin3, const [
        Color(0xFFFFB020),
        Color(0xFFFF6B57),
      ], onTapRoute: Routes.GIFT_TRANSACTIONS),
      _ProfileFeatureItem(
        'Settings',
        '',
        const [Color(0xFF7B5CFF), Color(0xFFFF2E83)],
        materialIcon: Icons.settings_rounded,
        onTapRoute: Routes.SETTINGS,
      ),
    ];

    return GlossyDatingCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
      radius: 22,
      fill: onCover
          ? kColorWhite.withValues(alpha: 0.94)
          : AppLightUi.card,
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
      onTap: () async {
        if (item.onTap != null) {
          await item.onTap!.call();
        } else if (item.onTapRoute != null) {
          await Get.toNamed(item.onTapRoute!);
          // After Backpack equip/unequip, reload session so the hero frame updates.
          if (item.onTapRoute == Routes.BACKPACK) {
            await _resolveUserSession().refreshProfileFromApi(
              isShowLoader: false,
            );
          }
          if (item.onTapRoute == Routes.COIN_SELLER ||
              item.onTapRoute == Routes.AGENCY_OWNER ||
              item.onTapRoute == Routes.SUPER_ADMIN_BOTTOM_NAV) {
            await _resolveUserSession().refreshProfileFromApi(
              isShowLoader: false,
            );
          }
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
                  color: AppLightUi.title.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: item.materialIcon != null
                ? Icon(item.materialIcon, color: kColorWhite, size: 28)
                : SvgPicture.asset(
                    item.iconPath,
                    width: 29,
                    height: 29,
                    fit: BoxFit.contain,
                    colorFilter: const ColorFilter.mode(
                      kColorWhite,
                      BlendMode.srcIn,
                    ),
                  ),
          ),
          Spacing.v8,
          Center(
            child: AppText(
              text: item.label,
              fontSize: TextStyles.k12FontSize,
              color: AppLightUi.body,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Edit Profile → always refresh session on return (updated or just back).
  Future<void> _openBasicProfileAndRefresh() async {
    await Get.toNamed(Routes.USER_BASIC_PROFILE);
    final session = _resolveUserSession();
    await session.refreshProfileFromApi(isShowLoader: false);
    // Cover / VIP fields may only exist on backpack seats — fill if profile omits them.
    if (session.profileBackgroundUrl.trim().isEmpty) {
      await session.syncEquippedProfileBackgroundFromBackpack();
    }
  }

  Future<void> _openWallet() async {
    await Get.to(() => const WalletView(), binding: WalletBinding());
  }

  Future<void> _openSuperAdminFlow() async {
    final session = _resolveUserSession();
    if (session.isSuperAdmin) {
      // Keep host bottom nav underneath so back returns to Profile.
      if (Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().onNavBarTabSelected(
          BottomNavController.profileTabIndex,
        );
      }
      await Get.toNamed(Routes.SUPER_ADMIN_BOTTOM_NAV);
      return;
    }
    await Get.to(
      () => const RoleApplicationView(role: ApplicationRole.superAdmin),
    );
    await session.refreshProfileFromApi();
  }

  Future<void> _openAgencyFlow() async {
    final session = _resolveUserSession();
    // Keep Profile selected under the pushed route so Back returns here.
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().onNavBarTabSelected(
        BottomNavController.profileTabIndex,
      );
    }

    if (session.isAgency) {
      await Get.toNamed(Routes.AGENCY_OWNER);
      return;
    }

    await Get.toNamed(Routes.AGENCY_OWNER_REGISTER);
  }

  Future<void> _openHostFlow() async {
    final session = _resolveUserSession();
    if (session.isHost) {
      await Get.to(() => const HostDashboardView());
    } else {
      await Get.toNamed(Routes.AGENCY_HOST_ONBOARDING);
    }
    await session.refreshProfileFromApi();
  }

  UserSessionController _resolveUserSession() {
    if (Get.isRegistered<UserSessionController>()) {
      return Get.find<UserSessionController>();
    }
    return Get.put(UserSessionController(), permanent: true);
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.child, required this.onCover});

  final Widget child;
  final bool onCover;

  @override
  Widget build(BuildContext context) {
    return _ProfileGradientPanel(
      onCover: onCover,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: child,
    );
  }
}

/// Gradient panel + glossy ring (Profile hero).
class _ProfileGradientPanel extends StatelessWidget {
  const _ProfileGradientPanel({
    required this.child,
    required this.onCover,
    this.radius = 22,
    this.padding = const EdgeInsets.fromLTRB(12, 14, 12, 18),
  });

  final Widget child;
  final bool onCover;
  final double radius;
  final EdgeInsetsGeometry padding;

  static const _borderWidth = 1.8;

  @override
  Widget build(BuildContext context) {
    final innerRadius = radius - _borderWidth;
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: GlossyDatingCard.defaultBorderGradient,
          boxShadow: [
            BoxShadow(
              color: AppLightUi.title.withValues(alpha: onCover ? 0.12 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(_borderWidth),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(innerRadius),
          child: Stack(
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: AppLightUi.familyCtaGradient,
                ),
                child: Padding(padding: padding, child: child),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 32,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          kColorWhite.withValues(alpha: 0.38),
                          kColorWhite.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    this.onTap,
    this.materialIcon,
  });

  final String label;
  final String iconPath;
  final List<Color> gradientColors;
  final String? onTapRoute;
  final Future<void> Function()? onTap;
  final IconData? materialIcon;
}
