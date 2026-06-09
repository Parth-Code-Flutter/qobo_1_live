import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    Future.delayed(const Duration(seconds: 3), () async {
      final storage = LocalStorage.shared;
      final isLoggedIn = await storage.isLoggedIn();
      if (isLoggedIn) {
        Get.offNamed(Routes.BOTTOM_NAV);
      } else {
        Get.offNamed(Routes.AUTH_LOGIN);
      }
    });
  }
}
