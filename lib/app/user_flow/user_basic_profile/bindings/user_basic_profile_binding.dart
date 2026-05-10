import 'package:get/get.dart';

import '../controllers/user_basic_profile_controller.dart';

/// Registers dependencies for [UserBasicProfileView].
class UserBasicProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserBasicProfileController>(UserBasicProfileController.new);
  }
}
