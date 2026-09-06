import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';

import '../controllers/chat_detail_controller.dart';

/// Shared visual tokens for voice / video call log rows in the chat thread.
class ChatCallMessageTheme {
  const ChatCallMessageTheme({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.bubbleColor,
    required this.icon,
  });

  final String title;
  final String? subtitle;
  final Color accentColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color bubbleColor;
  final IconData icon;

  static ChatCallMessageTheme forVoice(ChatMessageModel message) {
    return _build(message, isVideo: false);
  }

  static ChatCallMessageTheme forVideo(ChatMessageModel message) {
    return _build(message, isVideo: true);
  }

  static ChatCallMessageTheme _build(
    ChatMessageModel message, {
    required bool isVideo,
  }) {
    final title = isVideo ? 'Video call' : 'Voice call';

    final String? subtitle;
    final Color accentColor;
    final Color titleColor;
    final Color subtitleColor;

    if (message.isMissedCall) {
      subtitle = 'Missed call';
      accentColor = kColorRed;
      titleColor = kColorWhite;
      subtitleColor = kColorRed;
    } else if (message.isUnansweredCall) {
      subtitle = 'No answer';
      accentColor = isVideo ? kColorPrimary : const Color(0xFFE65100);
      titleColor = kColorWhite;
      subtitleColor = kColorWhite.withValues(alpha: 0.58);
    } else {
      subtitle = ChatInboxPreviewType.callDurationLabel(
        message.callDurationSeconds,
      );
      accentColor = message.isMe ? kColorPrimary : kColorPrimary;
      titleColor = kColorWhite;
      subtitleColor = kColorWhite.withValues(alpha: 0.58);
    }

    final bubbleColor = message.isMe
        ? kColorPrimary.withValues(alpha: 0.72)
        : const Color(0xFF2B1946);

    return ChatCallMessageTheme(
      title: title,
      subtitle: subtitle,
      accentColor: accentColor,
      titleColor: titleColor,
      subtitleColor: subtitleColor,
      bubbleColor: bubbleColor,
      icon: _iconFor(message, isVideo: isVideo),
    );
  }

  static IconData _iconFor(ChatMessageModel message, {required bool isVideo}) {
    if (isVideo) {
      if (message.isMissedCall) return Icons.missed_video_call_rounded;
      if (message.isUnansweredCall) return Icons.videocam_rounded;
      return message.isMe ? Icons.videocam_rounded : Icons.videocam_rounded;
    }

    if (message.isMissedCall) return Icons.phone_missed_rounded;
    if (message.isUnansweredCall) return Icons.phone_callback_rounded;
    return message.isMe ? Icons.call_made_rounded : Icons.call_received_rounded;
  }
}
