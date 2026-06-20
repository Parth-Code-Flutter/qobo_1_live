import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline_rounded,
                color: kColorWhite.withValues(alpha: 0.5),
                size: 48,
              ),
              Spacing.v12,
              AppText(
                text: 'New matches will appear here',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite.withValues(alpha: 0.7),
                align: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: kColorPrimary,
        backgroundColor: kColorWhite,
        onRefresh: controller.fetchDiscoverUsers,
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 24, top: 4),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: users.length,
          separatorBuilder: (_, __) => Divider(
            color: kColorWhite.withValues(alpha: 0.1),
            height: 1,
          ),
          itemBuilder: (context, index) {
            final user = users[index];
            return _DiscoverUserListTile(
              user: user,
              onTap: () => showDiscoverUserCallDialog(
                context,
                controller,
                user,
              ),
            );
          },
        ),
      );
    });
  }
}

class _DiscoverUserListTile extends StatelessWidget {
  const _DiscoverUserListTile({
    required this.user,
    required this.onTap,
  });

  final SocialUserCard user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AppUserAvatar(
                    name: user.name,
                    imageUrl: user.displayPicture,
                    size: 48,
                    border: Border.all(
                      color: user.isMutual
                          ? kColorBottomNavHeart
                          : kColorWhite.withValues(alpha: 0.85),
                      width: user.isMutual ? 2 : 1.2,
                    ),
                  ),
                  if (user.isFollowing)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.shade400,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1A1230)),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                ],
              ),
              Spacing.h12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: user.name,
                      fontSize: TextStyles.k16FontSize,
                      color: kColorWhite,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.level > 0) ...[
                      Spacing.v2,
                      AppText(
                        text: 'Level ${user.level}',
                        fontSize: TextStyles.k12FontSize,
                        color: kColorWhite.withValues(alpha: 0.6),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: kColorWhite.withValues(alpha: 0.45),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
