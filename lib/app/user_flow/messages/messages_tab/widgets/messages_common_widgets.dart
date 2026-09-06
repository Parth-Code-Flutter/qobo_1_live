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
    const avatarSize = 48.0;
    const frameExtent = avatarSize * 1.34;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          width: 86,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kColorWhite.withValues(alpha: 0.10)),
          ),
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
                        right: 1,
                        bottom: 1,
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
              ),
              Spacing.v4,
              SemiBoldText(
                text: user.name,
                color: kColorWhite,
                fontSize: TextStyles.k10FontSize,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                align: TextAlign.center,
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
