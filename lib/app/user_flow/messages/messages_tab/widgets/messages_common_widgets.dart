import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
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
  const MessageMatchAvatarItem({
    super.key,
    required this.user,
    this.onTap,
  });

  final SocialUserCard user;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppUserAvatar(
                  name: user.name,
                  imageUrl: user.displayPicture,
                  size: 50,
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
            Spacing.v6,
            AppText(
              text: user.name,
              color: kColorWhite,
              fontSize: TextStyles.k12FontSize,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              align: TextAlign.center,
            ),
          ],
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onAvatarTap,
            child: AppUserAvatar(
              name: user.name,
              imageUrl: user.displayPicture,
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
                    color: kColorWhite,
                  ),
                  if (user.level > 0) ...[
                    Spacing.v2,
                    AppText(
                      text: 'Level ${user.level}',
                      fontSize: TextStyles.k10FontSize,
                      color: kColorWhite.withValues(alpha: 0.6),
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: user.isFollowing
                    ? null
                    : const LinearGradient(
                        colors: [
                          kColorProfileActionPinkStart,
                          kColorProfileActionOrangeEnd,
                        ],
                      ),
                color: user.isFollowing ? Colors.transparent : null,
                borderRadius: BorderRadius.circular(20),
                border: user.isFollowing
                    ? Border.all(color: kColorWhite.withValues(alpha: 0.45))
                    : null,
              ),
              child: isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kColorWhite,
                      ),
                    )
                  : SemiBoldText(
                      text: user.isFollowing ? 'Following' : 'Follow',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
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
