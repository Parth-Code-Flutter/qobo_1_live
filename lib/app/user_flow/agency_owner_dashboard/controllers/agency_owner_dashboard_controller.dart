import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

class AgencyOwnerDashboardController extends GetxController {
  AgencySessionController get _session => Get.find<AgencySessionController>();

  bool get hasAgency => _session.hasAgency.value;

  String get agencyName =>
      _session.agencyName.value.isNotEmpty
          ? _session.agencyName.value
          : 'Your Agency';

  String get agencyCode => _session.agencyCode.value;

  String get commissionLabel => _session.commissionPercentLabel;

  String get agencyStatus => _session.status.value;

  void openRecruitLink() {
    Get.toNamed(Routes.AGENCY_RECRUIT_LINK);
  }

  void openHostList() {
    Get.toNamed(Routes.AGENCY_HOST_LIST);
  }

  void openRevenue() {
    Get.toNamed(Routes.AGENCY_REVENUE);
  }

  void openRegisterAgency() {
    Get.toNamed(Routes.AGENCY_OWNER_REGISTER);
  }
}
