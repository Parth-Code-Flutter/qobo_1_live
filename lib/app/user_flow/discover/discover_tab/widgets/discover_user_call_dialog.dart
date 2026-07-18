import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

import '../controllers/discover_tab_controller.dart';

/// Dating-style preview when tapping a Discover user — follow / message /
/// view full profile. Voice/Video call actions stay disabled for now.
Future<void> showDiscoverUserCallDialog(
  BuildContext context,
  DiscoverTabController controller,
  SocialUserCard user,
) async {
  var profile = user;
  final refreshed = await controller.fetchPublicProfile(user.id);
  if (refreshed != null) profile = refreshed;
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.58),
    builder: (sheetContext) {
      return Obx(() {
        final live = controller.userById(profile.id) ?? profile;
        final isProcessing = controller.processingFollowId.value == live.id;

        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.paddingOf(sheetContext).bottom + 12,
          ),
          child: DiscoverUserPreviewSheet(
            hostContext: context,
            user: live,
            controller: controller,
            isFollowProcessing: isProcessing,
          ),
        );
      });
    },
  );
}

class DiscoverUserPreviewSheet extends StatelessWidget {
  const DiscoverUserPreviewSheet({
    super.key,
    required this.hostContext,
    required this.user,
    required this.controller,
    required this.isFollowProcessing,
  });

  final BuildContext hostContext;
  final SocialUserCard user;
  final DiscoverTabController controller;
  final bool isFollowProcessing;

  @override
  Widget build(BuildContext context) {
    final photo = resolveUserAvatarUrl(user.displayPicture);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: const Color(0xFF160B2A),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 280,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (photo != null)
                      Image.network(
                        photo,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => _photoFallback(),
                      )
                    else
                      _photoFallback(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x33000000),
                            Color(0x00000000),
                            Color(0xF2160B2A),
                          ],
                          stops: [0, 0.4, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: kColorWhite.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: kColorWhite.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SemiBoldText(
                                  text: user.name,
                                  fontSize: TextStyles.k24FontSize,
                                  color: kColorWhite,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (user.gender.isNotEmpty)
                                Icon(
                                  _genderIcon(user.gender),
                                  color: kColorWhite.withValues(alpha: 0.9),
                                  size: 20,
                                ),
                            ],
                          ),
                          Spacing.v8,
                          _statusRow(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.bio.trim().isNotEmpty) ...[
                      _bioCard(),
                      Spacing.v12,
                    ],
                    _statsRow(),
                    Spacing.v16,
                    _primaryActions(context),
                    Spacing.v10,
                    _viewProfileButton(context),
                    Spacing.v10,
                    _connectionHint(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoFallback() {
    return ColoredBox(
      color: const Color(0xFF2A1248),
      child: Center(
        child: FramedUserAvatar(
          name: user.name,
          imageUrl: user.displayPicture,
          frameUrl: user.avatarFrameUrl,
          frameSeed: user.id,
          size: 96,
          fontSize: TextStyles.k24FontSize,
        ),
      ),
    );
  }

  Widget _statusRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (user.level > 0)
          _chip('Lv ${user.level}', Icons.military_tech_rounded),
        if (user.isVip) _chip('VIP', Icons.workspace_premium_rounded, accent: true),
        if (user.isMutual)
          _chip('Mutual', Icons.favorite_rounded, accent: true)
        else if (user.isFollowing)
          _chip('Following', Icons.person_add_alt_1_rounded)
        else if (user.isFollower)
          _chip('Follows you', Icons.arrow_downward_rounded),
        if (user.country.isNotEmpty)
          _chip(user.country, Icons.public_rounded),
      ],
    );
  }

  Widget _chip(String label, IconData icon, {bool accent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent
            ? kColorPrimary.withValues(alpha: 0.85)
            : kColorWhite.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: kColorWhite),
          Spacing.h4,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _bioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
      ),
      child: AppText(
        text: user.bio.trim(),
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite.withValues(alpha: 0.82),
        align: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(child: _statTile('Followers', '${user.followersCount}')),
        Container(
          width: 1,
          height: 34,
          color: kColorWhite.withValues(alpha: 0.12),
        ),
        Expanded(child: _statTile('Following', '${user.followingCount}')),
        if (user.coinsPerSecond > 0) ...[
          Container(
            width: 1,
            height: 34,
            color: kColorWhite.withValues(alpha: 0.12),
          ),
          Expanded(
            child: _statTile(
              'Coins/s',
              user.coinsPerSecond.toStringAsFixed(0),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statTile(String label, String value) {
    return Column(
      children: [
        SemiBoldText(
          text: value,
          fontSize: TextStyles.k16FontSize,
          color: kColorWhite,
        ),
        Spacing.v2,
        AppText(
          text: label,
          fontSize: TextStyles.k10FontSize,
          color: kColorWhite.withValues(alpha: 0.55),
        ),
      ],
    );
  }

  Widget _primaryActions(BuildContext sheetContext) {
    return Row(
      children: [
        Expanded(
          child: _DatingActionButton(
            label: user.isFollowing ? 'Following' : 'Follow',
            icon: user.isFollowing
                ? Icons.check_rounded
                : Icons.person_add_alt_1_rounded,
            style: user.isFollowing
                ? _DatingActionStyle.softFollow
                : _DatingActionStyle.follow,
            loading: isFollowProcessing,
            onTap: () => controller.toggleFollowUser(sheetContext, user),
          ),
        ),
        Spacing.h10,
        Expanded(
          child: _DatingActionButton(
            label: 'Message',
            icon: Icons.chat_bubble_rounded,
            style: user.canMessage
                ? _DatingActionStyle.message
                : _DatingActionStyle.messageLocked,
            onTap: () => _onMessagePressed(sheetContext),
          ),
        ),
      ],
    );
  }

  Widget _viewProfileButton(BuildContext sheetContext) {
    return _DatingActionButton(
      label: 'View Profile',
      icon: Icons.person_outline_rounded,
      style: _DatingActionStyle.viewProfile,
      onTap: () => _openFullProfile(sheetContext),
    );
  }

  Widget _connectionHint() {
    final String text;
    final IconData icon;
    if (user.canMessage) {
      text = 'You can start a conversation now';
      icon = Icons.check_circle_outline_rounded;
    } else if (user.isFollowing) {
      text = 'Waiting for them to follow you back';
      icon = Icons.hourglass_top_rounded;
    } else {
      text = 'Follow to connect — message when either follows';
      icon = Icons.info_outline_rounded;
    }

    return Row(
      children: [
        Icon(icon, size: 15, color: kColorWhite.withValues(alpha: 0.45)),
        Spacing.h8,
        Expanded(
          child: AppText(
            text: text,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }

  Future<void> _onMessagePressed(BuildContext sheetContext) async {
    if (!user.canMessage) {
      AppToast.showError(
        sheetContext,
        user.isFollowing
            ? 'Waiting for them to follow you back'
            : 'Follow to connect — message when either follows',
      );
      return;
    }

    Navigator.of(sheetContext).pop();
    await Future<void>.delayed(Duration.zero);
    final launchContext = hostContext.mounted ? hostContext : Get.context;
    if (launchContext == null || !launchContext.mounted) return;
    await controller.openChat(launchContext, user);
  }

  Future<void> _openFullProfile(BuildContext sheetContext) async {
    Navigator.of(sheetContext).pop();
    await Future<void>.delayed(Duration.zero);
    await Get.toNamed(
      Routes.DISCOVER_PUBLIC_PROFILE,
      arguments: <String, dynamic>{
        'userId': user.id,
        'user': user,
      },
    );
  }

  IconData _genderIcon(String gender) {
    final g = gender.toLowerCase();
    if (g.contains('female') || g == 'f') return Icons.female_rounded;
    if (g.contains('male') || g == 'm') return Icons.male_rounded;
    return Icons.person_outline_rounded;
  }
}

class _DatingActionStyle {
  const _DatingActionStyle._({
    required this.gradient,
    required this.glow,
    this.border,
    this.textAlpha = 1,
  });

  final Gradient gradient;
  final Color glow;
  final Border? border;
  final double textAlpha;

  /// Hot pink — primary CTA for Follow.
  static const follow = _DatingActionStyle._(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF4DC4), Color(0xFFFF2D7B), Color(0xFFFF6A3D)],
    ),
    glow: Color(0xFFFF2D7B),
  );

  /// Soft glass when already following.
  static final softFollow = _DatingActionStyle._(
    gradient: LinearGradient(
      colors: [
        kColorWhite.withValues(alpha: 0.16),
        kColorWhite.withValues(alpha: 0.08),
      ],
    ),
    glow: kColorProfileChipPinkStart,
    border: Border.all(color: kColorProfileChipPinkStart.withValues(alpha: 0.55)),
  );

  /// Electric violet/blue for Message when unlocked.
  static const message = _DatingActionStyle._(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF7B5CFF), Color(0xFF4F7CFF), Color(0xFF2ED3FF)],
    ),
    glow: Color(0xFF5B6CFF),
  );

  /// Still colorful when locked — dimmed cyan/violet so it doesn’t look dead.
  static final messageLocked = _DatingActionStyle._(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFF7B5CFF).withValues(alpha: 0.42),
        const Color(0xFF2ED3FF).withValues(alpha: 0.28),
      ],
    ),
    glow: const Color(0xFF5B6CFF),
    border: Border.all(color: const Color(0xFF8FA8FF).withValues(alpha: 0.45)),
    textAlpha: 0.78,
  );

  /// Sunset orange/gold for View Profile.
  static const viewProfile = _DatingActionStyle._(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF9A3D), Color(0xFFFF5E7A), Color(0xFFFF3DAA)],
    ),
    glow: Color(0xFFFF6A4E),
  );
}

class _DatingActionButton extends StatelessWidget {
  const _DatingActionButton({
    required this.label,
    required this.icon,
    required this.style,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final _DatingActionStyle style;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final textColor = kColorWhite.withValues(alpha: style.textAlpha);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: style.gradient,
            border: style.border,
            boxShadow: [
              BoxShadow(
                color: style.glow.withValues(alpha: 0.42),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: textColor),
                      Spacing.h8,
                      SemiBoldText(
                        text: label,
                        fontSize: TextStyles.k14FontSize,
                        color: textColor,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
