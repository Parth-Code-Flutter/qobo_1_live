import 'package:flutter/material.dart';

import '../controllers/chat_detail_controller.dart';
import 'chat_date_header_widget.dart';
import 'chat_text_message_widget.dart';
import 'chat_video_call_message_widget.dart';
import 'chat_voice_call_message_widget.dart';

/// Routes a timeline entry to the correct message-type widget.
class ChatTimelineMessageWidget extends StatelessWidget {
  const ChatTimelineMessageWidget({super.key, required this.entry});

  final ChatTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    if (entry.isDateHeader) {
      return ChatDateHeaderWidget(label: entry.dateLabel!);
    }

    final message = entry.message!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: _messageWidgetFor(message),
    );
  }

  Widget _messageWidgetFor(ChatMessageModel message) {
    if (message.isCallEntry) {
      if (message.isVideoCall) {
        return ChatVideoCallMessageWidget(message: message);
      }
      return ChatVoiceCallMessageWidget(message: message);
    }
    return ChatTextMessageWidget(message: message);
  }
}
