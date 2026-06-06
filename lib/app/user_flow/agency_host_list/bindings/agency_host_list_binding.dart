import 'package:get/get.dart';
import '../controllers/agency_host_list_controller.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

class AgencyHostListBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AgencySessionController>()) {
      Get.put(AgencySessionController(), permanent: true);
    }
    Get.lazyPut<AgencyHostListController>(
      () => AgencyHostListController(),
    );
  }
}
