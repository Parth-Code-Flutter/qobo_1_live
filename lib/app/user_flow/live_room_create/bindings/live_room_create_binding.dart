import 'package:get/get.dart';
import '../controllers/live_room_create_controller.dart';

class LiveRoomCreateBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiveRoomCreateController>(
      () => LiveRoomCreateController(),
    );
  }
}
