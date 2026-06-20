import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/discover_tab_controller.dart';

/// Center dialog when tapping a user on Discover — profile + call actions.
Future<void> showDiscoverUserCallDialog(
  BuildContext context,
  DiscoverTabController controller,
  SocialUserCard user,
) async {
  var profile = user;
  final refreshed = await controller.fetchPublicProfile(user.id);
  if (refreshed != null) profile = refreshed;
  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (ctx) => DiscoverUserCallDialog(
      hostContext: context,
      user: profile,
      controller: controller,
    ),
  );
}

class DiscoverUserCallDialog extends StatelessWidget {
  const DiscoverUserCallDialog({
    super.key,
    required this.hostContext,
    required this.user,
    required this.controller,
  });

  /// Feed/root context — stays mounted after the dialog is popped.
  final BuildContext hostContext;
  final SocialUserCard user;
  final DiscoverTabController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2A1248),
              Color(0xFF1A0E32),
              Color(0xFF120822),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: kColorPrimary.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _avatarSection(),
                  Spacing.v12,
                  SemiBoldText(
                    text: user.name,
                    fontSize: TextStyles.k20FontSize,
                    color: kColorWhite,
                    align: TextAlign.center,
                  ),
                  Spacing.v8,
                  _statusRow(),
                  if (user.bio.isNotEmpty) ...[
                    Spacing.v12,
                    _bioCard(),
                  ],
                  if (user.followersCount > 0 || user.followingCount > 0) ...[
                    Spacing.v12,
                    _statsRow(),
                  ],
                  Spacing.v20,
                  _callButtons(context),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(
                  Icons.close_rounded,
                  color: kColorWhite.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarSection() {
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  kColorProfileChipPinkStart.withValues(alpha: 0.85),
                  kColorProfileChipPurpleEnd.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: kColorWhite.withValues(alpha: 0.18),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: AppUserAvatar(
                name: user.name,
                imageUrl: user.displayPicture,
                size: 80,
                fontSize: TextStyles.k18FontSize,
              ),
            ),
          ),
          if (user.isVip)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: kColorWhite, width: 1),
                ),
                child: const SemiBoldText(
                  text: 'VIP',
                  fontSize: TextStyles.k8FontSize,
                  color: kColorBlack,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 6,
      children: [
        if (user.level > 0)
          _chip('Level ${user.level}', Icons.military_tech_rounded),
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
            ? kColorPrimary.withValues(alpha: 0.35)
            : kColorWhite.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent
              ? kColorProfileChipPinkStart.withValues(alpha: 0.45)
              : kColorWhite.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: accent
                ? kColorProfileChipPinkStart
                : kColorWhite.withValues(alpha: 0.75),
          ),
          Spacing.h4,
          SemiBoldText(
            text: label,
            fontSize: TextStyles.k10FontSize,
            color: accent ? kColorWhite : kColorWhite.withValues(alpha: 0.82),
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
        text: user.bio,
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite.withValues(alpha: 0.78),
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

  Widget _callButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CallActionButton(
            label: 'Voice',
            icon: Icons.call_rounded,
            gradient: const LinearGradient(
              colors: [
                kColorProfileChipPurpleStart,
                kColorProfileChipPurpleEnd,
              ],
            ),
            onTap: () => _startCall(
              context,
              ChatCallType.voice,
            ),
          ),
        ),
        Spacing.h12,
        Expanded(
          child: _CallActionButton(
            label: 'Video',
            icon: Icons.videocam_rounded,
            gradient: const LinearGradient(
              colors: [
                kColorProfileActionPinkStart,
                kColorProfileActionPinkEnd,
              ],
            ),
            onTap: () => _startCall(
              context,
              ChatCallType.video,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _startCall(BuildContext dialogContext, ChatCallType callType) async {
    Navigator.of(dialogContext).pop();
    await Future<void>.delayed(Duration.zero);
    final launchContext = hostContext.mounted ? hostContext : Get.context;
    if (launchContext == null || !launchContext.mounted) return;
    await controller.startDirectCall(launchContext, user, callType);
  }
}

class _CallActionButton extends StatelessWidget {
  const _CallActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: kColorProfileActionPinkStart.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: kColorWhite),
              Spacing.h8,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
