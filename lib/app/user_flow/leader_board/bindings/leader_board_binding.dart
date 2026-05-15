import 'package:get/get.dart';

import '../controllers/leader_board_controller.dart';

class LeaderBoardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LeaderBoardController>(LeaderBoardController.new);
  }
}
