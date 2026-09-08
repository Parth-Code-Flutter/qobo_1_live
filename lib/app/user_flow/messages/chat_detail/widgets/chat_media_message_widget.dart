import 'package:flutter/material.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/widgets/gift_icon_widget.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/emoji_celebration_overlay.dart';

import '../controllers/chat_detail_controller.dart';
import 'chat_detail_theme.dart';
import 'chat_text_message_widget.dart';

/// Inline emoji and gift message using the app's shared media renderers.
class ChatMediaMessageWidget extends StatelessWidget {
  const ChatMediaMessageWidget({super.key, required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final media = message.animationUrl ?? message.mediaUrl ?? '';
    return Align(
      alignment: message.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: message.isGift ? 180 : 116,
            padding: const EdgeInsets.all(12),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: message.isGift ? 132 : 78,
                  child: Center(
                    child: message.isGift
                        ? GiftIconWidget(
                            icon: media.isNotEmpty ? media : message.mediaUrl,
                            size: 124,
                            emojiSize: 62,
                          )
                        : EmojiMediaView(
                            image: media.isNotEmpty ? media : '😊',
                            emojiFontSize: 58,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
                if (message.text.isNotEmpty) ...[
                  Spacing.v6,
                  AppText(
                    text: message.text,
                    fontSize: TextStyles.k12FontSize,
                    color: message.isMe ? kColorWhite : kColorText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    align: TextAlign.center,
                  ),
                ],
              ],
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
