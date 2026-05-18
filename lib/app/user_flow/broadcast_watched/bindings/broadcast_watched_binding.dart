import 'package:get/get.dart';
import '../controllers/broadcast_watched_controller.dart';

class BroadcastWatchedBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BroadcastWatchedController>(
      () => BroadcastWatchedController(),
    );
  }
}
