import 'package:get/get.dart';
import '../controllers/entrance_patti_controller.dart';

class EntrancePattiBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EntrancePattiController>(
      () => EntrancePattiController(),
    );
  }
}
