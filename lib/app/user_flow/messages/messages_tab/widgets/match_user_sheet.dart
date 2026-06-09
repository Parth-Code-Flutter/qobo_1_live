import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

import '../controllers/messages_tab_controller.dart';
import '../models/social_user_card.dart';

/// Bottom sheet when tapping a New Match avatar.
Future<void> showMatchUserSheet(
  BuildContext context,
  MessagesTabController controller,
  SocialUserCard user,
) async {
  SocialUserCard profile = user;
  final refreshed = await controller.fetchPublicProfile(user.id);
  if (refreshed != null) profile = refreshed;

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (ctx) {
      return Obx(() {
        final live = controller.userById(profile.id) ?? profile;
        final isProcessing = controller.processingFollowId.value == live.id;

        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: MediaQuery.paddingOf(ctx).bottom + 12,
          ),
          child: _MatchUserSheetBody(
            user: live,
            isProcessing: isProcessing,
            onFollowTap: () => controller.toggleFollow(ctx, live),
            onMessageTap: () => _onMessagePressed(
              sheetContext: ctx,
              hostContext: context,
              controller: controller,
              user: live,
            ),
          ),
        );
      });
    },
  );
}

Future<void> _onMessagePressed({
  required BuildContext sheetContext,
  required BuildContext hostContext,
  required MessagesTabController controller,
  required SocialUserCard user,
}) async {
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
  if (!hostContext.mounted) return;
  await controller.openChat(hostContext, user);
}

class _MatchUserSheetBody extends StatelessWidget {
  const _MatchUserSheetBody({
    required this.user,
    required this.isProcessing,
    required this.onFollowTap,
    required this.onMessageTap,
  });

  final SocialUserCard user;
  final bool isProcessing;
  final VoidCallback onFollowTap;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: kColorPrimary.withValues(alpha: 0.35),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2A1248),
                      const Color(0xFF1A0E32),
                      const Color(0xFF120822),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              right: -20,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kColorProfileChipPinkStart.withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dragHandle(),
                  Spacing.v16,
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
                  _actionRow(),
                  Spacing.v12,
                  _connectionHint(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dragHandle() {
    return Container(
      width: 44,
      height: 4,
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }

  Widget _avatarSection() {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
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
              boxShadow: [
                BoxShadow(
                  color: kColorProfileChipPinkStart.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Container(
            width: 88,
            height: 88,
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
                size: 88,
                fontSize: TextStyles.k20FontSize,
              ),
            ),
          ),
          if (user.isVip)
            Positioned(
              bottom: 0,
              right: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
        if (user.level > 0) _chip('LV.${user.level}', Icons.military_tech_rounded),
        if (user.isMutual)
          _chip('Mutual', Icons.favorite_rounded, accent: true)
        else if (user.isFollowing)
          _chip('Following', Icons.person_add_alt_1_rounded)
        else if (user.isFollower)
          _chip('Follows you', Icons.arrow_downward_rounded),
        if (user.canMessage)
          _chip('Can message', Icons.chat_bubble_rounded, accent: true),
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
            color: accent ? kColorProfileChipPinkStart : kColorWhite.withValues(alpha: 0.75),
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

  Widget _actionRow() {
    return Row(
      children: [
        Expanded(
          child: _FollowButton(
            isFollowing: user.isFollowing,
            isProcessing: isProcessing,
            onTap: onFollowTap,
          ),
        ),
        Spacing.h12,
        Expanded(
          child: _MessageButton(
            enabled: user.canMessage,
            onTap: onMessageTap,
          ),
        ),
      ],
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: kColorWhite.withValues(alpha: 0.5)),
          Spacing.h8,
          Expanded(
            child: AppText(
              text: text,
              fontSize: TextStyles.k10FontSize,
              color: kColorWhite.withValues(alpha: 0.58),
            ),
          ),
        ],
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.isFollowing,
    required this.isProcessing,
    required this.onTap,
  });

  final bool isFollowing;
  final bool isProcessing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isFollowing
                ? null
                : const LinearGradient(
                    colors: [
                      kColorProfileActionPinkStart,
                      kColorProfileActionPinkEnd,
                    ],
                  ),
            color: isFollowing
                ? kColorWhite.withValues(alpha: 0.08)
                : null,
            border: isFollowing
                ? Border.all(color: kColorWhite.withValues(alpha: 0.22))
                : null,
            boxShadow: isFollowing
                ? null
                : [
                    BoxShadow(
                      color: kColorProfileActionPinkStart.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: isProcessing
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: isFollowing
                          ? kColorWhite.withValues(alpha: 0.7)
                          : kColorWhite,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isFollowing
                            ? Icons.check_rounded
                            : Icons.person_add_alt_1_rounded,
                        size: 18,
                        color: kColorWhite,
                      ),
                      Spacing.h6,
                      SemiBoldText(
                        text: isFollowing ? 'Following' : 'Follow',
                        fontSize: TextStyles.k14FontSize,
                        color: kColorWhite,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  const _MessageButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: enabled
                ? LinearGradient(
                    colors: [
                      kColorBottomNavHeart,
                      kColorBottomNavHeart.withValues(alpha: 0.82),
                    ],
                  )
                : null,
            color: enabled ? null : kColorWhite.withValues(alpha: 0.06),
            border: enabled
                ? null
                : Border.all(color: kColorWhite.withValues(alpha: 0.1)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 17,
                  color: enabled
                      ? kColorWhite
                      : kColorWhite.withValues(alpha: 0.35),
                ),
                Spacing.h6,
                SemiBoldText(
                  text: 'Message',
                  fontSize: TextStyles.k14FontSize,
                  color: enabled
                      ? kColorWhite
                      : kColorWhite.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
