import 'package:get/get.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

import '../controllers/agency_owner_register_controller.dart';

class AgencyOwnerRegisterBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AgencySessionController>()) {
      Get.put(AgencySessionController(), permanent: true);
    }
    Get.lazyPut<AgencyOwnerRegisterController>(
      AgencyOwnerRegisterController.new,
    );
  }
}
