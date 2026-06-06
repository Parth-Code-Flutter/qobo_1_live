import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

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
    builder: (ctx) {
      return Obx(() {
        final live = controller.userById(profile.id) ?? profile;
        final isProcessing = controller.processingFollowId.value == live.id;

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1230),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Spacing.v16,
                AppUserAvatar(
                  name: live.name,
                  imageUrl: live.displayPicture,
                  size: 72,
                ),
                Spacing.v10,
                SemiBoldText(
                  text: live.name,
                  fontSize: TextStyles.k18FontSize,
                  color: kColorWhite,
                ),
                if (live.level > 0) ...[
                  Spacing.v4,
                  AppText(
                    text: 'Level ${live.level}',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.7),
                  ),
                ],
                if (live.bio.isNotEmpty) ...[
                  Spacing.v8,
                  AppText(
                    text: live.bio,
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.75),
                    align: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                Spacing.v16,
                Row(
                  children: [
                    Expanded(
                      child: appButton(
                        onPressed: isProcessing
                            ? () {}
                            : () => controller.toggleFollow(ctx, live),
                        buttonText: live.isFollowing ? 'Following' : 'Follow',
                        buttonColor: live.isFollowing
                            ? Colors.white.withValues(alpha: 0.12)
                            : kColorPrimary,
                        textColor: kColorWhite,
                        borderRadius: 14,
                      ),
                    ),
                    Spacing.h10,
                    Expanded(
                      child: appButton(
                        onPressed: live.canMessage
                            ? () {
                                Navigator.of(ctx).pop();
                                controller.openChat(context, live);
                              }
                            : () {},
                        buttonText: 'Message',
                        buttonColor: live.canMessage
                            ? kColorBottomNavHeart
                            : Colors.white.withValues(alpha: 0.08),
                        textColor: live.canMessage
                            ? kColorWhite
                            : kColorWhite.withValues(alpha: 0.4),
                        borderRadius: 14,
                      ),
                    ),
                  ],
                ),
                if (!live.canMessage) ...[
                  Spacing.v10,
                  AppText(
                    text: live.isFollowing
                        ? 'They need to follow you back to message'
                        : 'Follow to connect — message when either follows',
                    fontSize: TextStyles.k10FontSize,
                    color: kColorWhite.withValues(alpha: 0.55),
                    align: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      });
    },
  );
}
