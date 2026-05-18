import 'package:get/get.dart';
import '../controllers/visitors_controller.dart';

class VisitorsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VisitorsController>(
      () => VisitorsController(),
    );
  }
}
