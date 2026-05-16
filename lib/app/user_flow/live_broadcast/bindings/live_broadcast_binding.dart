import 'package:get/get.dart';
import '../controllers/live_broadcast_controller.dart';

class LiveBroadcastBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiveBroadcastController>(
      () => LiveBroadcastController(),
    );
  }
}
