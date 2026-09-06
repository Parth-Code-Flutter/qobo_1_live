import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/chat_detail_controller.dart';
import 'chat_call_message_theme.dart';

/// Shared WhatsApp-style shell for voice and video call log bubbles.
class ChatCallMessageShell extends StatelessWidget {
  const ChatCallMessageShell({
    super.key,
    required this.message,
    required this.theme,
    this.showDirectionBadge = false,
  });

  final ChatMessageModel message;
  final ChatCallMessageTheme theme;
  final bool showDirectionBadge;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 240, minWidth: 168),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.bubbleColor,
              border: Border.all(color: kColorWhite.withValues(alpha: 0.11)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(message.isMe ? 16 : 4),
                bottomRight: Radius.circular(message.isMe ? 4 : 16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CallIconBadge(
                  icon: theme.icon,
                  accentColor: theme.accentColor,
                  showOutgoingBadge:
                      showDirectionBadge &&
                      message.isMe &&
                      !message.isMissedCall &&
                      !message.isUnansweredCall,
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: theme.title,
                        fontSize: TextStyles.k12FontSize,
                        color: theme.titleColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (theme.subtitle != null &&
                          theme.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AppText(
                          text: theme.subtitle!,
                          fontSize: TextStyles.k10FontSize,
                          color: theme.subtitleColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Spacing.v4,
          AppText(
            text: message.time,
            fontSize: 10,
            color: kColorWhite.withValues(alpha: 0.48),
          ),
        ],
      ),
    );
  }
}

class _CallIconBadge extends StatelessWidget {
  const _CallIconBadge({
    required this.icon,
    required this.accentColor,
    required this.showOutgoingBadge,
  });

  final IconData icon;
  final Color accentColor;
  final bool showOutgoingBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: accentColor),
          ),
          if (showOutgoingBadge)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF2B1946),
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.north_east_rounded,
                  size: 9,
                  color: accentColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
