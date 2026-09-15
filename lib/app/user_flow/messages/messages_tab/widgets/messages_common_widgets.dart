import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import 'message_inbox_tile_widget.dart';
import '../models/social_user_card.dart';

/// Reusable model for message listing rows (chat inbox).
class MessageListItemModel {
  const MessageListItemModel({
    required this.targetId,
    required this.name,
    required this.message,
    required this.time,
    this.imageUrl,
    this.avatarFrameUrl,
    this.unreadCount = 0,
    this.roomId = '',
    this.lastMessageType = ChatInboxPreviewType.text,
    this.lastCallDirection,
    this.lastActivityAt,
  });

  final String targetId;
  final String name;
  final String message;
  final String time;
  final String? imageUrl;

  /// Equipped avatar frame from `recipient.avatarFrame.image` on `/api/chat/list`.
  final String? avatarFrameUrl;
  final int unreadCount;
  final String roomId;
  final String lastMessageType;
  final String? lastCallDirection;
  final DateTime? lastActivityAt;

  bool get isCallPreview => ChatInboxPreviewType.isCallType(lastMessageType);

  bool get isMissedCall => ChatInboxPreviewType.isMissedCall(lastMessageType);

  bool get isUnansweredCall =>
      ChatInboxPreviewType.isUnansweredCall(lastMessageType);

  bool get isVideoCall =>
      lastMessageType == ChatInboxPreviewType.videoCall ||
      lastMessageType == ChatInboxPreviewType.missedVideoCall ||
      lastMessageType == ChatInboxPreviewType.unansweredVideoCall;

  bool get isIncomingCall => lastCallDirection == 'incoming';
}

/// Horizontal New Match avatar — tap opens profile sheet.
class MessageMatchAvatarItem extends StatelessWidget {
  const MessageMatchAvatarItem({super.key, required this.user, this.onTap});

  final SocialUserCard user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const cardWidth = 128.0;
    const avatarSize = 54.0;
    const frameExtent = avatarSize * 1.34;

    return Align(
      alignment: Alignment.topCenter,
      child: GlossyDatingCard(
        onTap: onTap,
        radius: 26,
        borderWidth: 1.5,
        padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
        child: SizedBox(
          width: cardWidth - 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            SizedBox(
              width: frameExtent,
              height: frameExtent,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: frameExtent + 6,
                    height: frameExtent + 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppLightUi.glossRingGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppLightUi.title.withValues(alpha: 0.08),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                  FramedUserAvatar(
                    name: user.name,
                    imageUrl: user.displayPicture,
                    frameUrl: user.avatarFrameUrl,
                    frameSeed: user.id,
                    size: avatarSize,
                    fontSize: TextStyles.k12FontSize,
                  ),
                  if (user.isFollowing)
                    Positioned(
                      right: 0,
                      bottom: 2,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          gradient: AppLightUi.ctaGradient,
                          shape: BoxShape.circle,
                          border: Border.all(color: kColorWhite, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          size: 10,
                          color: kColorWhite,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Spacing.v6,
            SemiBoldText(
              text: user.name,
              color: AppLightUi.title,
              fontSize: TextStyles.k12FontSize,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                gradient: AppLightUi.familyCtaGradient,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: kColorWhite.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppLightUi.title.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text(
                'Say hello',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: kColorWhite,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  height: 1.1,
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

/// Search result row with Follow button (Messages tab search mode).
class MessageSearchUserTile extends StatelessWidget {
  const MessageSearchUserTile({
    super.key,
    required this.user,
    required this.isProcessing,
    required this.onFollowTap,
    required this.onAvatarTap,
  });

  final SocialUserCard user;
  final bool isProcessing;
  final VoidCallback onFollowTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return GlossyDatingCard(
      radius: 18,
      borderWidth: 1.3,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: AppUserAvatar(
              name: user.name,
              imageUrl: user.displayPicture,
              frameUrl: user.avatarFrameUrl,
              frameSeed: user.id,
              size: 44,
            ),
          ),
          Spacing.h12,
          Expanded(
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: user.name,
                    fontSize: TextStyles.k14FontSize,
                    color: AppLightUi.title,
                  ),
                  if (user.level > 0) ...[
                    Spacing.v2,
                    AppText(
                      text: 'Level ${user.level}',
                      fontSize: TextStyles.k10FontSize,
                      color: AppLightUi.muted,
                    ),
                  ],
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: isProcessing ? null : onFollowTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                gradient: user.isFollowing
                    ? null
                    : AppLightUi.familyCtaGradient,
                color: user.isFollowing ? Colors.transparent : null,
                borderRadius: BorderRadius.circular(20),
                border: user.isFollowing
                    ? Border.all(color: AppLightUi.borderStrong)
                    : Border.all(color: kColorWhite.withValues(alpha: 0.35)),
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppLightUi.pink,
                      ),
                    )
                  : SemiBoldText(
                      text: user.isFollowing ? 'Following' : 'Follow',
                      fontSize: TextStyles.k12FontSize,
                      color: user.isFollowing
                          ? AppLightUi.body
                          : kColorWhite,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inbox message row tile.
class MessageListTileItem extends StatelessWidget {
  const MessageListTileItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  final MessageListItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MessageInboxTileWidget(item: item, onTap: onTap);
  }
}
