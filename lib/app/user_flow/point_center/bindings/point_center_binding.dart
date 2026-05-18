import 'package:get/get.dart';
import '../controllers/point_center_controller.dart';

class PointCenterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PointCenterController>(
      () => PointCenterController(),
    );
  }
}
