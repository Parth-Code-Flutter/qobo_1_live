import 'package:get/get.dart';
import '../controllers/live_moderation_controller.dart';

class LiveModerationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiveModerationController>(
      () => LiveModerationController(),
    );
  }
}
