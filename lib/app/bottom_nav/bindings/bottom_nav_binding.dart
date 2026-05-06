import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_room/controllers/live_room_controller.dart';

import '../controllers/bottom_nav_controller.dart';

class BottomNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BottomNavController>(BottomNavController.new);
    Get.lazyPut<LiveRoomController>(LiveRoomController.new);
  }
}
