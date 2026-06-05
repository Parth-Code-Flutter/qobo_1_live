import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_status/models/agency_owner_application_state.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_dashboard_data.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

enum AgencyAccessMode { host, owner }

class AgencyAccessController extends GetxController {
  final mode = AgencyAccessMode.host.obs;
  final isRefreshingOwnerState = false.obs;

  final AgencyRepo _agencyRepo = AgencyRepo();

  AgencySessionController get _agencySession =>
      Get.find<AgencySessionController>();

  bool get ownerHasApprovedAgency => _agencySession.hasApprovedAgency;

  bool get ownerApplicationPending => _agencySession.isApplicationPending;

  bool get ownerApplicationRejected => _agencySession.isApplicationRejected;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args['mode']?.toString() == 'owner') {
      mode.value = AgencyAccessMode.owner;
      refreshOwnerApplicationState();
    }
  }

  void selectMode(AgencyAccessMode value) {
    mode.value = value;
    if (value == AgencyAccessMode.owner) {
      refreshOwnerApplicationState();
    }
  }

  Future<void> refreshOwnerApplicationState() async {
    if (_agencySession.hasApprovedAgency) return;

    isRefreshingOwnerState.value = true;
    try {
      final response = await _agencyRepo.getAgencyDashboard(
        isShowLoader: false,
      );
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        final parsed = AgencyDashboardData.fromJson(
          Map<String, dynamic>.from(data),
        );
        await _agencySession.applyDashboardResponse(parsed);
      }
    } catch (_) {
      // Keep locally stored pending/rejected state.
    } finally {
      isRefreshingOwnerState.value = false;
    }
  }

  void openHostApplication() {
    Get.toNamed(Routes.AGENCY_HOST_ONBOARDING);
  }

  void openHostStatus() {
    Get.toNamed(Routes.AGENCY_HOST_STATUS);
  }

  void openOwnerApply() {
    if (_agencySession.isApplicationPending) {
      openOwnerStatus();
      return;
    }
    Get.toNamed(Routes.AGENCY_OWNER_REGISTER);
  }

  void openOwnerStatus() {
    Get.toNamed(
      Routes.AGENCY_OWNER_STATUS,
      arguments: {
        if (_agencySession.applicationId.value.isNotEmpty)
          'application_id': _agencySession.applicationId.value,
        if (_agencySession.appliedPhone.value.isNotEmpty)
          'phone': _agencySession.appliedPhone.value,
        'autoFetch': _agencySession.applicationId.value.isNotEmpty ||
            _agencySession.appliedPhone.value.isNotEmpty,
      },
    );
  }

  void openOwnerDashboard() {
    if (_agencySession.hasApprovedAgency) {
      Get.toNamed(Routes.AGENCY_OWNER);
      return;
    }
    if (_agencySession.applicationState.value ==
        AgencyOwnerApplicationState.pending) {
      openOwnerStatus();
      return;
    }
    openOwnerApply();
  }
}
