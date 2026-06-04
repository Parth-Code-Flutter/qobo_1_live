import 'package:get/get.dart';
import 'package:qobo_one_live/app/bottom_nav/controllers/bottom_nav_controller.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

class AgencyOwnerDashboardController extends GetxController {
  AgencySessionController get _session => Get.find<AgencySessionController>();

  bool get hasAgency => _session.hasAgency.value;

  bool get isDemoPreview => !hasAgency;

  String get displayAgencyName =>
      hasAgency && _session.agencyName.value.isNotEmpty
          ? _session.agencyName.value
          : AgencyRevenueDemo.agencyName;

  String get displayAgencyCode =>
      hasAgency && _session.agencyCode.value.isNotEmpty
          ? _session.agencyCode.value
          : AgencyRevenueDemo.agencyCode;

  String get displayOwnerName => AgencyRevenueDemo.ownerName;

  int get ownerCoinsPerSecond => AgencyRevenueDemo.ownerCoinsPerSecond;

  AgencyCallSample get sampleCall => AgencyRevenueDemo.sampleCall;

  List<AgencyHostRevenueDemo> get hosts => AgencyRevenueDemo.hosts;

  int get totalAgencyEarnings => AgencyRevenueDemo.totalAgencyEarnings;

  int get companyShare => AgencyRevenueDemo.companyShare;

  int get hostCallShare => AgencyRevenueDemo.hostCallShare;

  int get ownerCommission => AgencyRevenueDemo.ownerCommissionCoins;

  int get totalGifts => AgencyRevenueDemo.totalGiftsVolume;

  int get availableForPayout => AgencyRevenueDemo.availableForPayout;

  void openRecruitLink() {
    Get.toNamed(Routes.AGENCY_RECRUIT_LINK);
  }

  /// Heart tab host map (constellation UI) — agency hosts from demo/API later.
  void openHostList() {
    if (Get.isRegistered<BottomNavController>()) {
      Get.find<BottomNavController>().openHeartTabForAgencyHosts();
      return;
    }
    Get.offAllNamed(Routes.BOTTOM_NAV);
    Future.microtask(() {
      if (Get.isRegistered<BottomNavController>()) {
        Get.find<BottomNavController>().openHeartTabForAgencyHosts();
      }
    });
  }

  void openRevenue() {
    Get.toNamed(Routes.AGENCY_REVENUE);
  }

  void openRegisterAgency() {
    Get.toNamed(Routes.AGENCY_OWNER_REGISTER);
  }

  void openHostDetail(AgencyHostRevenueDemo host) {
    openHostList();
  }
}
