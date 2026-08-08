import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/phone_mask_utils.dart';
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
              color: message.isMe ? kColorPrimary : kColorBackground,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(message.isMe ? 16 : 0),
                bottomRight: Radius.circular(message.isMe ? 0 : 16),
              ),
            ),
            child: AppText(
              text: PhoneMaskUtils.mask(message.text),
              fontSize: TextStyles.k14FontSize,
              color: message.isMe ? kColorWhite : kColorText,
            ),
          ),
          Spacing.v4,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(text: message.time, fontSize: 10, color: kColorHint),
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
        color = kColorHint;
        icon = Icons.done_all_rounded;
      case ChatDeliveryStatus.sent:
        color = kColorHint;
        icon = Icons.done_rounded;
    }
    return Icon(icon, size: 14, color: color);
  }
}
