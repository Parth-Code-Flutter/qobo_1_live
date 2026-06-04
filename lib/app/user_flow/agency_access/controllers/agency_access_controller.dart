import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

enum AgencyAccessMode { host, owner }

class AgencyAccessController extends GetxController {
  final mode = AgencyAccessMode.host.obs;

  AgencySessionController get _agencySession =>
      Get.find<AgencySessionController>();

  bool get ownerHasAgency => _agencySession.hasAgency.value;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['mode']?.toString() == 'owner') {
      mode.value = AgencyAccessMode.owner;
    }
  }

  void selectMode(AgencyAccessMode value) {
    mode.value = value;
  }

  void openHostApplication() {
    Get.toNamed(Routes.AGENCY_HOST_ONBOARDING);
  }

  void openHostStatus() {
    Get.toNamed(Routes.AGENCY_HOST_STATUS);
  }

  void openOwnerRegister() {
    Get.toNamed(Routes.AGENCY_OWNER_REGISTER);
  }

  void openOwnerDashboard() {
    Get.toNamed(Routes.AGENCY_OWNER);
  }
}
