import 'package:get/get.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

import '../controllers/agency_owner_dashboard_controller.dart';

class AgencyOwnerDashboardBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AgencySessionController>()) {
      Get.put(AgencySessionController(), permanent: true);
    }
    Get.lazyPut<AgencyOwnerDashboardController>(
      AgencyOwnerDashboardController.new,
    );
  }
}
