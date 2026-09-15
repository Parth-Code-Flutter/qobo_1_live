import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/glossy_dating_card.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import 'message_inbox_preview_theme.dart';
import 'messages_common_widgets.dart';

/// Call preview line for an inbox row (icon + title + subtitle).
class MessageInboxCallPreviewWidget extends StatelessWidget {
  const MessageInboxCallPreviewWidget({
    super.key,
    required this.theme,
    this.hasUnread = false,
  });

  final MessageInboxPreviewTheme theme;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final color = hasUnread
        ? theme.primaryColor
        : theme.primaryColor.withValues(alpha: 0.78);
    return Row(
      children: [
        Icon(theme.icon, size: 14, color: color),
        Spacing.h6,
        Expanded(
          child: AppText(
            text: theme.secondaryText?.isNotEmpty == true
                ? '${theme.primaryText} · ${theme.secondaryText}'
                : theme.primaryText,
            color: color,
            fontSize: TextStyles.k12FontSize,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    this.hasUnread = false,
  });

  final MessageInboxPreviewTheme theme;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    return AppText(
      text: theme.primaryText,
      color: hasUnread ? AppLightUi.body : AppLightUi.muted,
      fontSize: TextStyles.k12FontSize,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Inbox conversation row — dense, scannable dating list UX (~64–72dp).
///
/// Hierarchy:
/// `[Avatar]  Name (bold if unread) .............. time`
/// `          Preview ......................... badge`
///
/// Unread uses ONE clear cue: bold name + compact trailing badge.
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

    return GlossyDatingCard(
      onTap: onTap,
      radius: 16,
      borderWidth: hasUnread ? 1.3 : 1.0,
      emphasized: hasUnread,
      // Compact padding keeps rows scannable (Material list ~64–72dp).
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      fill: hasUnread ? AppLightUi.cardSoft : AppLightUi.card,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _InboxAvatar(item: item),
          Spacing.h10,
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppLightUi.title,
                          fontSize: TextStyles.k14FontSize,
                          fontWeight:
                              hasUnread ? FontWeight.w700 : FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                    ),
                    Spacing.h8,
                    Text(
                      item.time,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: hasUnread ? AppLightUi.pink : AppLightUi.muted,
                        fontSize: 11,
                        fontWeight:
                            hasUnread ? FontWeight.w600 : FontWeight.w400,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: previewTheme.isCallPreview
                          ? MessageInboxCallPreviewWidget(
                              theme: previewTheme,
                              hasUnread: hasUnread,
                            )
                          : MessageInboxTextPreviewWidget(
                              theme: previewTheme,
                              hasUnread: hasUnread,
                            ),
                    ),
                    if (hasUnread) ...[
                      Spacing.h8,
                      _UnreadBadge(count: item.unreadCount),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InboxAvatar extends StatelessWidget {
  const _InboxAvatar({required this.item});

  final MessageListItemModel item;

  @override
  Widget build(BuildContext context) {
    // Framed avatar sized so the full row lands near ~64–72dp with padding.
    const avatarSize = 42.0;
    final frameExtent = avatarSize * 1.28;

    return SizedBox(
      width: frameExtent,
      height: frameExtent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: frameExtent,
            height: frameExtent,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppLightUi.glossRingGradient,
              boxShadow: [
                BoxShadow(
                  color: AppLightUi.title.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          Container(
            width: frameExtent - 3.5,
            height: frameExtent - 3.5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kColorWhite,
            ),
          ),
          FramedUserAvatar(
            name: item.name,
            imageUrl: item.imageUrl,
            frameUrl: item.avatarFrameUrl,
            frameSeed: item.targetId,
            size: avatarSize,
            fontSize: TextStyles.k12FontSize,
          ),
        ],
      ),
    );
  }
}

/// Compact unread count — capped, high-contrast pink badge.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: EdgeInsets.symmetric(horizontal: label.length > 1 ? 5 : 0),
      decoration: const BoxDecoration(
        gradient: AppLightUi.familyCtaGradient,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: kColorWhite,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.05,
        ),
      ),
    );
  }
}
