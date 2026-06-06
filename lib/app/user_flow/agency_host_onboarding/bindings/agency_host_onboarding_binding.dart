import 'package:get/get.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

import '../controllers/agency_host_onboarding_controller.dart';

class AgencyHostOnboardingBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AgencySessionController>()) {
      Get.put(AgencySessionController(), permanent: true);
    }
    Get.lazyPut<AgencyHostOnboardingController>(
      AgencyHostOnboardingController.new,
    );
  }
}
