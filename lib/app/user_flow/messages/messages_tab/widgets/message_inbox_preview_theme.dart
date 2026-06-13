import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

import 'messages_common_widgets.dart';

/// Preview labels and colors for inbox rows on the Messages tab.
class MessageInboxPreviewTheme {
  const MessageInboxPreviewTheme({
    required this.primaryText,
    required this.secondaryText,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
    required this.iconBackground,
    this.isCallPreview = false,
  });

  final String primaryText;
  final String? secondaryText;
  final Color primaryColor;
  final Color secondaryColor;
  final IconData? icon;
  final Color iconBackground;
  final bool isCallPreview;

  factory MessageInboxPreviewTheme.fromItem(MessageListItemModel item) {
    if (!item.isCallPreview) {
      return MessageInboxPreviewTheme(
        primaryText: item.message.isNotEmpty
            ? item.message
            : 'Start a conversation',
        secondaryText: null,
        primaryColor: kColorWhite.withValues(alpha: 0.88),
        secondaryColor: kColorWhite.withValues(alpha: 0.55),
        icon: null,
        iconBackground: Colors.transparent,
      );
    }

    final title = item.isVideoCall ? 'Video call' : 'Voice call';
    final String? subtitle;
    final Color primaryColor;
    final Color secondaryColor;
    final Color accent;
    final IconData icon;

    if (item.isMissedCall) {
      subtitle = 'Missed call';
      accent = kColorRed;
      primaryColor = kColorWhite.withValues(alpha: 0.92);
      secondaryColor = const Color(0xFFFF8A80);
      icon = item.isVideoCall
          ? Icons.missed_video_call_rounded
          : Icons.phone_missed_rounded;
    } else if (item.isUnansweredCall) {
      subtitle = 'No answer';
      accent = kColorPrimary;
      primaryColor = kColorWhite.withValues(alpha: 0.92);
      secondaryColor = kColorWhite.withValues(alpha: 0.58);
      icon = item.isVideoCall
          ? Icons.videocam_rounded
          : Icons.phone_callback_rounded;
    } else {
      subtitle = _completedSubtitle(item.message);
      accent = kColorPrimary;
      primaryColor = kColorWhite.withValues(alpha: 0.92);
      secondaryColor = kColorWhite.withValues(alpha: 0.58);
      if (item.isVideoCall) {
        icon = Icons.videocam_rounded;
      } else {
        icon = item.isIncomingCall
            ? Icons.call_received_rounded
            : Icons.call_made_rounded;
      }
    }

    return MessageInboxPreviewTheme(
      primaryText: title,
      secondaryText: subtitle,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      icon: icon,
      iconBackground: accent.withValues(alpha: 0.22),
      isCallPreview: true,
    );
  }

  static String? _completedSubtitle(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split('·').map((p) => p.trim()).toList();
    if (parts.length >= 2 && parts.last.isNotEmpty) return parts.last;
    if (trimmed == 'Voice call' || trimmed == 'Video call') return null;
    return trimmed;
  }
}
