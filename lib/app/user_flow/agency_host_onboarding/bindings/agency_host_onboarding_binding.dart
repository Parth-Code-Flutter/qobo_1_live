import 'package:get/get.dart';

import '../controllers/agency_host_onboarding_controller.dart';

class AgencyHostOnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AgencyHostOnboardingController>(
      AgencyHostOnboardingController.new,
    );
  }
}
