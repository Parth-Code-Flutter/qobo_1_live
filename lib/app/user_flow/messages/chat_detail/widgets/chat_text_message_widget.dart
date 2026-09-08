import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/phone_mask_utils.dart';
import 'package:qobo_one_live/utils/text_utils/profanity_mask_utils.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/chat_detail_controller.dart';
import 'chat_detail_theme.dart';

/// Plain text bubble in the chat message list.
class ChatTextMessageWidget extends StatelessWidget {
  const ChatTextMessageWidget({super.key, required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: message.isMe ? null : ChatDetailTheme.incomingBubble,
              gradient: message.isMe ? ChatDetailTheme.outgoingGradient : null,
              border: Border.all(
                color: message.isMe
                    ? kColorWhite.withValues(alpha: 0.1)
                    : ChatDetailTheme.paleBorder,
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isMe ? 18 : 5),
                bottomRight: Radius.circular(message.isMe ? 5 : 18),
              ),
              boxShadow: [
                BoxShadow(
                  color: (message.isMe ? ChatDetailTheme.rose : kColorBlack)
                      .withValues(alpha: message.isMe ? 0.16 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: AppText(
              text: ProfanityMaskUtils.mask(PhoneMaskUtils.mask(message.text)),
              fontSize: TextStyles.k14FontSize,
              color: message.isMe ? kColorWhite : kColorText,
            ),
          ),
          Spacing.v4,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: message.time,
                fontSize: 10,
                color: ChatDetailTheme.textMuted,
              ),
              if (message.isMe) ...[
                const SizedBox(width: 4),
                ChatDeliveryStatusIcon(status: message.deliveryStatus),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class ChatDeliveryStatusIcon extends StatelessWidget {
  const ChatDeliveryStatusIcon({super.key, required this.status});

  final ChatDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (status) {
      case ChatDeliveryStatus.read:
        color = ChatDetailTheme.plum;
        icon = Icons.done_all_rounded;
      case ChatDeliveryStatus.delivered:
        color = ChatDetailTheme.textMuted;
        icon = Icons.done_all_rounded;
      case ChatDeliveryStatus.sent:
        color = ChatDetailTheme.textMuted;
        icon = Icons.done_rounded;
    }
    return Icon(icon, size: 14, color: color);
  }
}
