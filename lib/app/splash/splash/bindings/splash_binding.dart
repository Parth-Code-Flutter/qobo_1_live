import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    // Create controller immediately so onReady runs for timed navigation.
    Get.put<SplashController>(SplashController());
  }
}
