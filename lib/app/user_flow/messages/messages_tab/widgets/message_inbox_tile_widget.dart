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
    this.hasUnread = false,
  });

  final MessageInboxPreviewTheme theme;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final color = hasUnread
        ? theme.primaryColor
        : theme.primaryColor.withValues(alpha: 0.72);
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
      color: hasUnread
          ? kColorWhite.withValues(alpha: 0.92)
          : kColorWhite.withValues(alpha: 0.58),
      fontSize: TextStyles.k12FontSize,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Inbox conversation row — Bumble/WhatsApp-style dating list UX.
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFFFF5C9A).withValues(alpha: 0.10),
        highlightColor: kColorWhite.withValues(alpha: 0.04),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: hasUnread
                ? const Color(0xFFFF5C9A).withValues(alpha: 0.08)
                : kColorWhite.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasUnread
                  ? const Color(0xFFFF5C9A).withValues(alpha: 0.18)
                  : kColorWhite.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _InboxAvatar(item: item),
              Spacing.h12,
              Expanded(
                child: Column(
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
                              color: kColorWhite,
                              fontSize: TextStyles.k14FontSize,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),
                        Spacing.h10,
                        // Trailing meta column — time + badge share one scan path.
                        SizedBox(
                          width: 56,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                item.time,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: hasUnread
                                      ? const Color(0xFFFF8AB8)
                                      : kColorWhite.withValues(alpha: 0.45),
                                  fontSize: 11,
                                  fontWeight: hasUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (hasUnread)
                                _UnreadBadge(count: item.unreadCount)
                              else
                                const SizedBox(height: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(right: 66),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxAvatar extends StatelessWidget {
  const _InboxAvatar({required this.item});

  final MessageListItemModel item;

  @override
  Widget build(BuildContext context) {
    // Slightly smaller frames keep chat rows dense like Bumble/Hinge.
    const avatarSize = 44.0;
    final frameExtent = avatarSize * 1.34;

    return SizedBox(
      width: frameExtent,
      height: frameExtent,
      child: FramedUserAvatar(
        name: item.name,
        imageUrl: item.imageUrl,
        frameUrl: item.avatarFrameUrl,
        frameSeed: item.targetId,
        size: avatarSize,
        fontSize: TextStyles.k12FontSize,
      ),
    );
  }
}

/// Compact unread count — capped, high-contrast, no oversized glow.
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
        color: Color(0xFFFF4D8D),
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
