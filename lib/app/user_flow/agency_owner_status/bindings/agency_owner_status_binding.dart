import 'package:get/get.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

import '../controllers/agency_owner_status_controller.dart';

class AgencyOwnerStatusBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AgencySessionController>()) {
      Get.put(AgencySessionController(), permanent: true);
    }
    Get.lazyPut<AgencyOwnerStatusController>(AgencyOwnerStatusController.new);
  }
}
