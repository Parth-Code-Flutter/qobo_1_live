import 'package:get/get.dart';
import '../controllers/backpack_controller.dart';

class BackpackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BackpackController>(
      () => BackpackController(),
    );
  }
}
