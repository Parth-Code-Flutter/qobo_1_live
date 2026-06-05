import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_dashboard_data.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_status/models/agency_owner_application_state.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';

enum AgencyOwnerStatusLookupType { applicationId, phone }

class AgencyOwnerStatusController extends GetxController {
  final AgencyRepo _agencyRepo = AgencyRepo();

  final lookupController = TextEditingController();
  final lookupType = AgencyOwnerStatusLookupType.applicationId.obs;

  final status = ''.obs;
  final applicationId = ''.obs;
  final agencyName = ''.obs;
  final ownerName = ''.obs;
  final phone = ''.obs;
  final reason = ''.obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;
  final apiNote = ''.obs;

  AgencySessionController get _session => Get.find<AgencySessionController>();

  @override
  void onInit() {
    super.onInit();
    _hydrateFromArguments();
    _hydrateFromSession();
  }

  @override
  void onClose() {
    lookupController.dispose();
    super.onClose();
  }

  void _hydrateFromSession() {
    if (_session.applicationId.value.isNotEmpty &&
        lookupController.text.trim().isEmpty) {
      lookupController.text = _session.applicationId.value;
      lookupType.value = AgencyOwnerStatusLookupType.applicationId;
    }
  }

  void _hydrateFromArguments() {
    final args = Get.arguments;
    if (args is! Map) return;

    final id = args['application_id']?.toString().trim() ?? '';
    final phoneArg = args['phone']?.toString().trim() ?? '';

    if (id.isNotEmpty) {
      lookupType.value = AgencyOwnerStatusLookupType.applicationId;
      lookupController.text = id;
    } else if (phoneArg.isNotEmpty) {
      lookupType.value = AgencyOwnerStatusLookupType.phone;
      lookupController.text = phoneArg;
    }

    if (args['autoFetch'] == true) {
      fetchMyAgencyStatus();
    }
  }

  void selectLookupType(AgencyOwnerStatusLookupType type) {
    lookupType.value = type;
    lookupController.clear();
    status.value = '';
    reason.value = '';
    apiNote.value = '';
    hasSearched.value = false;
  }

  String get lookupLabel {
    switch (lookupType.value) {
      case AgencyOwnerStatusLookupType.applicationId:
        return 'Reference ID';
      case AgencyOwnerStatusLookupType.phone:
        return 'WhatsApp number';
    }
  }

  String get lookupHint {
    switch (lookupType.value) {
      case AgencyOwnerStatusLookupType.applicationId:
        return 'Local reference (optional)';
      case AgencyOwnerStatusLookupType.phone:
        return 'WhatsApp from your application';
    }
  }

  TextInputType get keyboardType {
    return lookupType.value == AgencyOwnerStatusLookupType.phone
        ? TextInputType.phone
        : TextInputType.text;
  }

  /// Uses `GET /api/agency/dashboard` for the logged-in user.
  Future<void> fetchMyAgencyStatus() async {
    try {
      isLoading.value = true;
      hasSearched.value = true;
      apiNote.value = 'Checked via GET /api/agency/dashboard';

      final response = await _agencyRepo.getAgencyDashboard(
        isShowLoader: false,
      );

      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        final parsed = AgencyDashboardData.fromJson(
          Map<String, dynamic>.from(data),
        );
        await _session.applyDashboardResponse(parsed);
        if (parsed.isApproved) {
          _applyApprovedFromSession(parsed);
          return;
        }
        if (parsed.isPending) {
          status.value = 'pending';
          agencyName.value = parsed.agencyName;
          ownerName.value = parsed.ownerName;
          reason.value =
              agencyApiMessage(response) ??
              'Your agency application is pending super admin approval.';
          return;
        }
      }

      _applyPendingOrNotFound(
        agencyApiMessage(response) ??
            'No active agency found for your account yet.',
      );
    } catch (_) {
      _applyPendingOrNotFound(
        'Unable to reach the server. Showing your last saved application state.',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchStatus() async {
    await fetchMyAgencyStatus();
  }

  void _applyApprovedFromSession(AgencyDashboardData parsed) {
    status.value = 'approved';
    applicationId.value = _session.applicationId.value;
    agencyName.value = parsed.agencyName;
    ownerName.value = parsed.ownerName;
    phone.value = _session.appliedPhone.value;
    reason.value =
        'Agency code: ${parsed.agencyCode}. Status: ${parsed.agencyStatus}. You can open the owner dashboard.';
  }

  void _applyPendingOrNotFound(String message) {
    if (_session.applicationState.value == AgencyOwnerApplicationState.pending) {
      status.value = 'pending';
      applicationId.value = _session.applicationId.value;
      agencyName.value = _session.appliedAgencyName.value;
      ownerName.value = _session.appliedOwnerName.value;
      phone.value = _session.appliedPhone.value;
      reason.value = message;
      return;
    }

    if (_session.applicationState.value ==
        AgencyOwnerApplicationState.rejected) {
      status.value = 'rejected';
      reason.value = _session.applicationReason.value.isNotEmpty
          ? _session.applicationReason.value
          : message;
      return;
    }

    status.value = 'not_found';
    reason.value = message;
  }

  void openDashboard() {
    if (_session.hasApprovedAgency) {
      Get.offNamed(Routes.AGENCY_OWNER);
    }
  }
}
