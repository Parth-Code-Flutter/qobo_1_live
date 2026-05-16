import 'package:get/get.dart';
import '../controllers/follow_list_controller.dart';

class FollowListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FollowListController>(
      () => FollowListController(),
    );
  }
}
