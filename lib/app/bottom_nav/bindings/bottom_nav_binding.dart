import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_host_list/controllers/agency_host_list_controller.dart';
import 'package:qobo_one_live/app/user_flow/live_room/controllers/live_room_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/controllers/messages_tab_controller.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

import '../controllers/bottom_nav_controller.dart';

class BottomNavBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserSessionController>(
      () => UserSessionController(),
      fenix: true,
    );
    if (!Get.isRegistered<AgencySessionController>()) {
      Get.put(AgencySessionController(), permanent: true);
    }
    Get.lazyPut<BottomNavController>(BottomNavController.new);
    Get.lazyPut<AgencyHostListController>(
      () => AgencyHostListController(embeddedInBottomNav: true),
      tag: BottomNavController.heartHostListTag,
      fenix: true,
    );
    Get.lazyPut<LiveRoomController>(LiveRoomController.new);
    Get.lazyPut<MessagesTabController>(
      MessagesTabController.new,
      fenix: true,
    );
  }
}
