import 'package:get/get.dart';

import '../controllers/live_room_controller.dart';

class LiveRoomBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LiveRoomController>(
      LiveRoomController.new,
    );
  }
}
