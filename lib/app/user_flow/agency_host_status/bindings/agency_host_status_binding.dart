import 'package:get/get.dart';
import '../controllers/agency_host_status_controller.dart';

class AgencyHostStatusBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgencyHostStatusController>(
      () => AgencyHostStatusController(),
    );
  }
}
