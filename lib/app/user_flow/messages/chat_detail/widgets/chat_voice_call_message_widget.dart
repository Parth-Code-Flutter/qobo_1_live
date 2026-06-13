import 'package:flutter/material.dart';

import '../controllers/chat_detail_controller.dart';
import 'chat_call_message_shell.dart';
import 'chat_call_message_theme.dart';

/// Voice call log row in the chat message list.
class ChatVoiceCallMessageWidget extends StatelessWidget {
  const ChatVoiceCallMessageWidget({super.key, required this.message});

  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    return ChatCallMessageShell(
      message: message,
      theme: ChatCallMessageTheme.forVoice(message),
    );
  }
}
