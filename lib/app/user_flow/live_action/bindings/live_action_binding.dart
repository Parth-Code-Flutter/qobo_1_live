import 'package:get/get.dart';
import '../controllers/live_action_controller.dart';

class LiveActionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiveActionController>(
      () => LiveActionController(),
    );
  }
}
