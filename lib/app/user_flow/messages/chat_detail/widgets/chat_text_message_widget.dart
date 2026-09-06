import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/phone_mask_utils.dart';
import 'package:qobo_one_live/utils/text_utils/profanity_mask_utils.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/chat_detail_controller.dart';

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
              color: message.isMe ? null : const Color(0xFF2B1946),
              gradient: message.isMe
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [kColorProfileChipPinkStart, kColorPrimary],
                    )
                  : null,
              border: Border.all(
                color: message.isMe
                    ? kColorProfileChipPinkStart.withValues(alpha: 0.32)
                    : kColorWhite.withValues(alpha: 0.11),
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(message.isMe ? 18 : 5),
                bottomRight: Radius.circular(message.isMe ? 5 : 18),
              ),
            ),
            child: AppText(
              text: ProfanityMaskUtils.mask(PhoneMaskUtils.mask(message.text)),
              fontSize: TextStyles.k14FontSize,
              color: kColorWhite,
            ),
          ),
          Spacing.v4,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                text: message.time,
                fontSize: 10,
                color: kColorWhite.withValues(alpha: 0.48),
              ),
              if (message.isMe) ...[
                const SizedBox(width: 4),
                _DeliveryStatusIcon(status: message.deliveryStatus),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryStatusIcon extends StatelessWidget {
  const _DeliveryStatusIcon({required this.status});

  final ChatDeliveryStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (status) {
      case ChatDeliveryStatus.read:
        color = Colors.lightBlueAccent;
        icon = Icons.done_all_rounded;
      case ChatDeliveryStatus.delivered:
        color = kColorWhite.withValues(alpha: 0.55);
        icon = Icons.done_all_rounded;
      case ChatDeliveryStatus.sent:
        color = kColorWhite.withValues(alpha: 0.55);
        icon = Icons.done_rounded;
    }
    return Icon(icon, size: 14, color: color);
  }
}
