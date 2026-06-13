import 'package:get/get.dart';

import '../controllers/chat_voice_call_controller.dart';

class ChatVoiceCallBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatVoiceCallController>(() => ChatVoiceCallController());
  }
}
