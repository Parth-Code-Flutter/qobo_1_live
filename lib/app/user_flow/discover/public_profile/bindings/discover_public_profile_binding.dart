import 'package:get/get.dart';

import '../controllers/discover_public_profile_controller.dart';

class DiscoverPublicProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiscoverPublicProfileController>(
      DiscoverPublicProfileController.new,
    );
  }
}
