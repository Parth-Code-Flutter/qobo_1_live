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
import 'discover_user_call_dialog.dart';

/// Discover tab — same users as Messages "New Match" (`GET /api/user/discover`).
class DiscoverUsersFeed extends StatelessWidget {
  const DiscoverUsersFeed({super.key, required this.controller});

  final DiscoverTabController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isDiscoverUsersLoading.value) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
          ),
        );
      }

      final users = controller.discoverUsers;
      if (users.isEmpty) {
        return Center(
          child: AppText(
            text: 'New matches will appear here',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite.withValues(alpha: 0.65),
            align: TextAlign.center,
          ),
        );
      }

      return RefreshIndicator(
        color: kColorPrimary,
        backgroundColor: kColorWhite,
        onRefresh: controller.fetchDiscoverUsers,
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 16, top: 2),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: users.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(left: 2, right: 2, bottom: 8),
                child: Row(
                  children: [
                    SemiBoldText(
                      text: 'New Matches',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                    Spacing.h8,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: kColorDiscoverChip.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SemiBoldText(
                        text: '${users.length}',
                        fontSize: TextStyles.k10FontSize,
                        color: kColorWhite,
                      ),
                    ),
                  ],
                ),
              );
            }
            final user = users[index - 1];
            return _DiscoverUserRow(
              user: user,
              onProfileTap: () =>
                  showDiscoverUserCallDialog(context, controller, user),
              onVoiceCall: () =>
                  controller.startDirectCall(context, user, ChatCallType.voice),
              onVideoCall: () =>
                  controller.startDirectCall(context, user, ChatCallType.video),
            );
          },
        ),
      );
    });
  }
}

class _DiscoverUserRow extends StatelessWidget {
  const _DiscoverUserRow({
    required this.user,
    required this.onProfileTap,
    required this.onVoiceCall,
    required this.onVideoCall,
  });

  final SocialUserCard user;
  final VoidCallback onProfileTap;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: kColorVideoListTileBg.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            width: 0.5,
            color: user.isMutual
                ? kColorBottomNavHeart.withValues(alpha: 0.4)
                : kColorWhite.withValues(alpha: 0.08),
          ),
        ),
        child: SizedBox(
          height: 54,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: Row(
              children: [
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onProfileTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: [
                            _CompactAvatar(user: user),
                            Spacing.h10,
                            Expanded(child: _CompactInfo(user: user)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _CompactCallActions(
                  onVoiceCall: onVoiceCall,
                  onVideoCall: onVideoCall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactAvatar extends StatelessWidget {
  const _CompactAvatar({required this.user});

  final SocialUserCard user;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AppUserAvatar(
          name: user.name,
          imageUrl: user.displayPicture,
          size: 38,
          border: Border.all(
            color: user.isMutual
                ? kColorBottomNavHeart
                : kColorWhite.withValues(alpha: 0.2),
            width: user.isMutual ? 1.5 : 1,
          ),
        ),
        if (user.isFollowing)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: kColorAudioSpeakingGreen,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1A1230), width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _CompactInfo extends StatelessWidget {
  const _CompactInfo({required this.user});

  final SocialUserCard user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: SemiBoldText(
            text: user.name,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (user.level > 0) ...[
          AppText(
            text: ' · ',
            fontSize: TextStyles.k12FontSize,
            color: kColorWhite.withValues(alpha: 0.35),
          ),
          AppText(
            text: 'Lv ${user.level}',
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite.withValues(alpha: 0.55),
          ),
        ],
      ],
    );
  }
}

class _CompactCallActions extends StatelessWidget {
  const _CompactCallActions({
    required this.onVoiceCall,
    required this.onVideoCall,
  });

  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CallIconButton(
          icon: Icons.call_rounded,
          onTap: onVoiceCall,
          gradient: const LinearGradient(
            colors: [kColorProfileChipPurpleStart, kColorProfileChipPurpleEnd],
          ),
        ),
        const SizedBox(width: 12),
        _CallIconButton(
          icon: Icons.videocam_rounded,
          onTap: onVideoCall,
          gradient: const LinearGradient(
            colors: [kColorProfileActionPinkStart, kColorProfileActionPinkEnd],
          ),
        ),
      ],
    );
  }
}

class _CallIconButton extends StatelessWidget {
  const _CallIconButton({
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 24,
          height: 24,
          decoration: BoxDecoration(shape: BoxShape.circle, gradient: gradient),
          child: Icon(icon, size: 14, color: kColorWhite),
        ),
      ),
    );
  }
}
