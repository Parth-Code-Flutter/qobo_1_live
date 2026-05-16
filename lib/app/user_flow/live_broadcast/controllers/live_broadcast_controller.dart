import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class LiveBroadcastController extends GetxController {
  final isHost = false.obs;
  final roomType = 'VIDEO'.obs;
  
  final chatMessages = <String>[].obs;
  final chatTextController = TextEditingController();

  final isMicMuted = false.obs;
  final isCameraOff = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args.containsKey('isHost')) isHost.value = args['isHost'];
      if (args.containsKey('roomType')) roomType.value = args['roomType'];
    }
    
    // Simulate initial chat load
    chatMessages.addAll([
      'System: Welcome to the live room! Please be respectful.',
      'User123: Hello!',
      'Guest007: 👋',
    ]);
  }

  void sendMessage() {
    if (chatTextController.text.trim().isNotEmpty) {
      chatMessages.add('You: ${chatTextController.text.trim()}');
      chatTextController.clear();
    }
  }

  void toggleMic() {
    isMicMuted.value = !isMicMuted.value;
  }

  void toggleCamera() {
    isCameraOff.value = !isCameraOff.value;
  }

  void leaveRoom() {
    Get.back();
  }

  @override
  void onClose() {
    chatTextController.dispose();
    super.onClose();
  }
}
