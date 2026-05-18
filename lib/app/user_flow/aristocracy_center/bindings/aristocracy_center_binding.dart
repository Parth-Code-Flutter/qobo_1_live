import 'package:get/get.dart';
import '../controllers/aristocracy_center_controller.dart';

class AristocracyCenterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AristocracyCenterController>(
      () => AristocracyCenterController(),
    );
  }
}
