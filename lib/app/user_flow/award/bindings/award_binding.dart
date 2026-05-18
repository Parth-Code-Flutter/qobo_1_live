import 'package:get/get.dart';
import '../controllers/award_controller.dart';

class AwardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AwardController>(
      () => AwardController(),
    );
  }
}
