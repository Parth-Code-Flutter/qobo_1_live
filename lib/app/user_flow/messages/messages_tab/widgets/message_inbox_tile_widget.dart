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
  const MessageInboxCallPreviewWidget({super.key, required this.theme});

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
  const MessageInboxTextPreviewWidget({super.key, required this.theme});

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
        borderRadius: BorderRadius.circular(24),
        splashColor: kColorWhite.withValues(alpha: 0.08),
        highlightColor: kColorWhite.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: hasUnread
                  ? const [Color(0xFF763D68), Color(0xFF442449)]
                  : const [Color(0xFF393254), Color(0xFF24203D)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: hasUnread
                  ? const Color(0xFFFF9AB5).withValues(alpha: 0.55)
                  : kColorWhite.withValues(alpha: 0.09),
            ),
            boxShadow: [
              BoxShadow(
                color: (hasUnread ? const Color(0xFFB63279) : Colors.black)
                    .withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _InboxAvatar(item: item, hasUnread: hasUnread),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: item.name,
                        color: kColorWhite,
                        fontSize: TextStyles.k14FontSize,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Spacing.v4,
                      previewTheme.isCallPreview
                          ? MessageInboxCallPreviewWidget(theme: previewTheme)
                          : MessageInboxTextPreviewWidget(theme: previewTheme),
                    ],
                  ),
                ),
                Spacing.h8,
                SizedBox(
                  width: 68,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppText(
                        text: item.time,
                        color: hasUnread
                            ? const Color(0xFFFFD4E4)
                            : kColorWhite.withValues(alpha: 0.55),
                        fontSize: TextStyles.k8FontSize,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),
                      if (hasUnread)
                        _UnreadBadge(count: item.unreadCount)
                      else
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFFB5A2CE),
                          size: 22,
                        ),
                    ],
                  ),
                ),
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
                  color: const Color(0xFFFF6FA8),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF1A1230),
                    width: 1.5,
                  ),
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
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6FA8),
        borderRadius: BorderRadius.circular(12),
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
