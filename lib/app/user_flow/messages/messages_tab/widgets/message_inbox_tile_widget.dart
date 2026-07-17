import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import 'message_inbox_preview_theme.dart';
import 'messages_common_widgets.dart';

/// Call preview line for an inbox row (icon + title + subtitle).
class MessageInboxCallPreviewWidget extends StatelessWidget {
  const MessageInboxCallPreviewWidget({
    super.key,
    required this.theme,
  });

  final MessageInboxPreviewTheme theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: theme.iconBackground,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(theme.icon, size: 13, color: theme.primaryColor),
        ),
        Spacing.h6,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: theme.primaryText,
                color: theme.primaryColor,
                fontSize: TextStyles.k12FontSize,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (theme.secondaryText != null &&
                  theme.secondaryText!.isNotEmpty) ...[
                const SizedBox(height: 1),
                AppText(
                  text: theme.secondaryText!,
                  color: theme.secondaryColor,
                  fontSize: TextStyles.k10FontSize,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Text preview line for an inbox row.
class MessageInboxTextPreviewWidget extends StatelessWidget {
  const MessageInboxTextPreviewWidget({
    super.key,
    required this.theme,
  });

  final MessageInboxPreviewTheme theme;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text: theme.primaryText,
      color: theme.primaryColor,
      fontSize: TextStyles.k12FontSize,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Inbox conversation row on the Messages tab.
class MessageInboxTileWidget extends StatelessWidget {
  const MessageInboxTileWidget({
    super.key,
    required this.item,
    required this.onTap,
  });

  final MessageListItemModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final previewTheme = MessageInboxPreviewTheme.fromItem(item);
    final hasUnread = item.unreadCount > 0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: kColorWhite.withValues(alpha: 0.08),
        highlightColor: kColorWhite.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: hasUnread ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: kColorWhite.withValues(alpha: hasUnread ? 0.18 : 0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InboxAvatar(item: item, hasUnread: hasUnread),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SemiBoldText(
                              text: item.name,
                              color: kColorWhite,
                              fontSize: TextStyles.k14FontSize,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Spacing.h8,
                          AppText(
                            text: item.time,
                            color: hasUnread
                                ? kColorWhite
                                : kColorWhite.withValues(alpha: 0.62),
                            fontSize: TextStyles.k10FontSize,
                          ),
                        ],
                      ),
                      Spacing.v4,
                      previewTheme.isCallPreview
                          ? MessageInboxCallPreviewWidget(theme: previewTheme)
                          : MessageInboxTextPreviewWidget(theme: previewTheme),
                    ],
                  ),
                ),
                if (hasUnread) ...[
                  Spacing.h8,
                  _UnreadBadge(count: item.unreadCount),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InboxAvatar extends StatelessWidget {
  const _InboxAvatar({required this.item, required this.hasUnread});

  final MessageListItemModel item;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    // Same framed avatar used by New Match / discover (API frame or seed fallback).
    const avatarSize = 48.0;
    final frameExtent = avatarSize * 1.34;

    return SizedBox(
      width: frameExtent,
      height: frameExtent,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          FramedUserAvatar(
            name: item.name,
            imageUrl: item.imageUrl,
            frameUrl: item.avatarFrameUrl,
            frameSeed: item.targetId,
            size: avatarSize,
            fontSize: TextStyles.k12FontSize,
          ),
          if (hasUnread)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: kColorBottomNavHeart,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF1A1230), width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: kColorBottomNavHeart,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: AppText(
        text: label,
        color: kColorWhite,
        fontSize: TextStyles.k8FontSize,
      ),
    );
  }
}
