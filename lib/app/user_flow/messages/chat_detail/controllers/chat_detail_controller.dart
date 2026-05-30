import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ChatMessageModel {
  final String text;
  final bool isMe;
  final String time;

  ChatMessageModel({
    required this.text,
    required this.isMe,
    required this.time,
  });
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
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
