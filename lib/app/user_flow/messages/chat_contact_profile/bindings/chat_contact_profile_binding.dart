import 'package:get/get.dart';

import '../controllers/chat_contact_profile_controller.dart';

class ChatContactProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatContactProfileController>(
      () => ChatContactProfileController(),
    );
  }
}
