import 'package:get/get.dart';
import '../controllers/user_level_controller.dart';

class UserLevelBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserLevelController>(
      () => UserLevelController(),
    );
  }
}
