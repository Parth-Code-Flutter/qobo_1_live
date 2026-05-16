import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ChatMessageModel {
  final String text;
  final bool isMe;
  final String time;

  ChatMessageModel({required this.text, required this.isMe, required this.time});
}

class ChatDetailController extends GetxController {
  
  final chatName = 'John Borino'.obs;
  final chatImage = ''.obs;

  final messages = <ChatMessageModel>[].obs;
  final messageController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args.containsKey('name')) chatName.value = args['name'];
      if (args.containsKey('image')) chatImage.value = args['image'];
    }

    _loadMockMessages();
  }

  void _loadMockMessages() {
    messages.addAll([
      ChatMessageModel(text: 'Hey there! How are you doing today?', isMe: false, time: '10:00 AM'),
      ChatMessageModel(text: 'I am doing great, just working on this new app update. You?', isMe: true, time: '10:05 AM'),
      ChatMessageModel(text: 'Make yourself proud 😍', isMe: false, time: '10:15 AM'),
    ]);
  }

  void sendMessage() {
    if (messageController.text.trim().isNotEmpty) {
      messages.add(
        ChatMessageModel(
          text: messageController.text.trim(),
          isMe: true,
          time: 'Now',
        ),
      );
      messageController.clear();
      // Simulate reply
      Future.delayed(const Duration(seconds: 1), () {
        messages.add(
          ChatMessageModel(
            text: 'That sounds amazing! Keep going 🔥',
            isMe: false,
            time: 'Now',
          ),
        );
      });
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
