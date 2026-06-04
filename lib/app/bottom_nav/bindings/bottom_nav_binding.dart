import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_action/controllers/live_action_controller.dart';
import 'package:qobo_one_live/app/user_flow/live_room/controllers/live_room_controller.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

import '../controllers/bottom_nav_controller.dart';

class BottomNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserSessionController>(
      () => UserSessionController(),
      fenix: true,
    );
    Get.lazyPut<BottomNavController>(BottomNavController.new);
    Get.lazyPut<LiveActionController>(LiveActionController.new, fenix: true);
    Get.lazyPut<LiveRoomController>(LiveRoomController.new);
  }
}
