import 'package:flutter/material.dart';

import '../controllers/chat_detail_controller.dart';
import 'chat_call_message_shell.dart';
import 'chat_call_message_theme.dart';

/// Video call log row in the chat message list.
class ChatVideoCallMessageWidget extends StatelessWidget {
  const ChatVideoCallMessageWidget({super.key, required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    return ChatCallMessageShell(
      message: message,
      theme: ChatCallMessageTheme.forVideo(message),
      showDirectionBadge: true,
    );
  }
}
