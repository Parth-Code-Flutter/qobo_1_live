import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';

import '../controllers/chat_detail_controller.dart';
import 'chat_detail_theme.dart';

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
    final mine = message.isMe;

    final String? subtitle;
    final Color accentColor;
    final Color titleColor;
    final Color subtitleColor;

    if (message.isMissedCall) {
      subtitle = 'Missed call';
      // Keep missed red; on outgoing gradient use soft white badge + red icon.
      accentColor = mine ? const Color(0xFFFF8A9B) : kColorRed;
      titleColor = mine ? kColorWhite : kColorText;
      subtitleColor = mine ? const Color(0xFFFFB4C0) : kColorRed;
    } else if (message.isUnansweredCall) {
      subtitle = 'No answer';
      accentColor = mine ? kColorWhite : (isVideo ? AppLightUi.cyan : const Color(0xFFE65100));
      titleColor = mine ? kColorWhite : kColorText;
      subtitleColor = mine
          ? kColorWhite.withValues(alpha: 0.82)
          : ChatDetailTheme.textMuted;
    } else {
      subtitle = ChatInboxPreviewType.callDurationLabel(
        message.callDurationSeconds,
      );
      accentColor = mine ? kColorWhite : kColorPrimary;
      titleColor = mine ? kColorWhite : kColorText;
      subtitleColor = mine
          ? kColorWhite.withValues(alpha: 0.82)
          : ChatDetailTheme.textMuted;
    }

    final bubbleColor = mine
        ? ChatDetailTheme.rose
        : ChatDetailTheme.incomingBubble;

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
