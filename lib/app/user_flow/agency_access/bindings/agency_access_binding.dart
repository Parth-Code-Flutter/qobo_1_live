import 'package:get/get.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

import '../controllers/agency_access_controller.dart';

class AgencyAccessBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AgencySessionController>()) {
      Get.put(AgencySessionController(), permanent: true);
    }
    Get.lazyPut<AgencyAccessController>(AgencyAccessController.new);
  }
}
