import 'dart:async';

import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_dashboard_data.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_status/models/agency_owner_application_state.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Agency owner session: application review state + approved agency context.
class AgencySessionController extends GetxController {
  final hasAgency = false.obs;
  final agencyId = ''.obs;
  final agencyName = ''.obs;
  final agencyCode = ''.obs;
  final commissionRate = 0.0.obs;
  final status = ''.obs;
  final recruitLink = ''.obs;

  final applicationState = AgencyOwnerApplicationState.none.obs;
  final applicationId = ''.obs;
  final appliedAgencyName = ''.obs;
  final appliedOwnerName = ''.obs;
  final appliedPhone = ''.obs;
  final applicationReason = ''.obs;
  final applicationSubmittedAt = ''.obs;

  /// Hosts from last successful dashboard API (for heart-tab map).
  final cachedHosts = <AgencyHostRevenueDemo>[].obs;

  Future<void>? _hydrateInFlight;

  bool get hasApprovedAgency =>
      hasAgency.value &&
      applicationState.value == AgencyOwnerApplicationState.approved;

  bool get isApplicationPending =>
      applicationState.value == AgencyOwnerApplicationState.pending;

  bool get isApplicationRejected =>
      applicationState.value == AgencyOwnerApplicationState.rejected;

  bool get canOpenOwnerDashboard => hasApprovedAgency;

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
  }

  LocalStorage get _storage => LocalStorage.shared;

  Future<void> loadFromStorage() async {
    final json = await _storage.getJsonFromStorage(kStorageAgencyOwnerApplication);
    if (json != null && json.isNotEmpty) {
      _applyApplicationJson(json, persist: false);
    }
    final agencyJson = await _storage.getJsonFromStorage(kStorageApprovedAgency);
    if (agencyJson != null && agencyJson.isNotEmpty) {
      _applyApprovedAgencyJson(agencyJson);
    }
  }

  /// Agency code for host onboarding when the logged-in user owns an approved agency.
  Future<String?> resolveApprovedAgencyCode() async {
    if (hasApprovedAgency && agencyCode.value.trim().isNotEmpty) {
      return agencyCode.value.trim();
    }

    await ensureHydratedFromDashboard();

    if (hasApprovedAgency && agencyCode.value.trim().isNotEmpty) {
      return agencyCode.value.trim();
    }
    return null;
  }

  /// Loads agency id/name/hosts from dashboard when memory session is empty (cold start).
  Future<void> ensureHydratedFromDashboard({bool forceRefresh = false}) async {
    await loadFromStorage();

    if (!forceRefresh &&
        agencyId.value.trim().isNotEmpty &&
        hasApprovedAgency) {
      return;
    }

    if (_hydrateInFlight != null) {
      await _hydrateInFlight;
      return;
    }

    _hydrateInFlight = _fetchDashboardIntoSession();
    try {
      await _hydrateInFlight;
    } finally {
      _hydrateInFlight = null;
    }
  }

  Future<void> _fetchDashboardIntoSession() async {
    try {
      final response = await AgencyRepo().getAgencyDashboard(
        isShowLoader: false,
      );
      final data = response?['data'];
      if (!isAgencyApiSuccess(response) || data is! Map) return;

      final parsed = AgencyDashboardData.fromJson(
        Map<String, dynamic>.from(data),
      );
      await applyDashboardResponse(parsed);
    } catch (_) {
      // Non-agency users or offline — host-list may still work via auth token.
    }
  }

  Future<void> setPendingApplication({
    required String id,
    required String agencyNameValue,
    required String ownerName,
    required String phone,
  }) async {
    applicationState.value = AgencyOwnerApplicationState.pending;
    applicationId.value = id;
    appliedAgencyName.value = agencyNameValue;
    appliedOwnerName.value = ownerName;
    appliedPhone.value = phone;
    applicationReason.value = '';
    applicationSubmittedAt.value = DateTime.now().toIso8601String();
    hasAgency.value = false;
    await _persistApplication();
    update();
  }

  /// `POST /api/agency/register` — active agency or pending application.
  Future<void> applyRegisterResponse(Map<String, dynamic> data) async {
    final agencyStatus = data['status']?.toString() ?? 'active';
    if (isAgencyStatusPending(agencyStatus)) {
      await applyPendingAgency(
        agencyName: data['name']?.toString() ?? appliedAgencyName.value,
        ownerName: appliedOwnerName.value,
        phone: appliedPhone.value,
        applicationId: data['id']?.toString() ?? data['application_id']?.toString(),
        reason: data['reason']?.toString(),
      );
      return;
    }
    setAgency(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? appliedAgencyName.value,
      code: data['code']?.toString() ?? '',
      commission: _parseCommission(data['commissionRate']),
      agencyStatus: agencyStatus,
    );
    await _clearApplicationStorage();
    update();
  }

  /// `GET /api/agency/dashboard` — full dashboard only when agency is approved.
  Future<void> applyDashboardResponse(AgencyDashboardData data) async {
    if (data.isPending) {
      await applyPendingAgency(
        agencyName: data.agencyName,
        ownerName: data.ownerName,
        phone: appliedPhone.value,
        reason: 'Waiting for super admin approval.',
      );
      status.value = data.agencyStatus;
      return;
    }
    if (!data.isApproved) {
      await applyPendingAgency(
        agencyName: data.agencyName,
        ownerName: data.ownerName,
        phone: appliedPhone.value,
      );
      status.value = data.agencyStatus;
      return;
    }
    setAgency(
      id: data.agencyId,
      name: data.agencyName,
      code: data.agencyCode,
      commission: data.commissionRate,
      agencyStatus: data.agencyStatus,
      link: data.recruitLink.isNotEmpty ? data.recruitLink : null,
    );
    cachedHosts.assignAll(data.hosts);
    await _clearApplicationStorage();
    update();
  }

  Future<void> applyPendingAgency({
    required String agencyName,
    String? ownerName,
    String? phone,
    String? applicationId,
    String? reason,
  }) async {
    applicationState.value = AgencyOwnerApplicationState.pending;
    appliedAgencyName.value = agencyName;
    if (ownerName != null && ownerName.isNotEmpty) {
      appliedOwnerName.value = ownerName;
    }
    if (phone != null && phone.isNotEmpty) {
      appliedPhone.value = phone;
    }
    if (applicationId != null && applicationId.isNotEmpty) {
      this.applicationId.value = applicationId;
    }
    applicationReason.value = reason ?? '';
    hasAgency.value = false;
    agencyId.value = '';
    agencyCode.value = '';
    recruitLink.value = '';
    cachedHosts.clear();
    await _clearApprovedAgencyStorage();
    await _persistApplication();
    update();
  }

  /// `GET /api/agency/revenue` success — logged-in user has an active agency.
  Future<void> applyRevenueActiveAgency(Map<String, dynamic> data) async {
    final code = data['agencyCode']?.toString() ?? agencyCode.value;
    if (agencyId.value.isEmpty && code.isNotEmpty) {
      setAgency(
        id: data['agency_id']?.toString() ?? data['agencyId']?.toString() ?? '',
        name: appliedAgencyName.value.isNotEmpty
            ? appliedAgencyName.value
            : (data['agency_name']?.toString() ?? 'My Agency'),
        code: code,
        commission: _parseCommission(data['commissionRate']),
        agencyStatus: 'active',
      );
    } else {
      applicationState.value = AgencyOwnerApplicationState.approved;
      hasAgency.value = true;
      if (code.isNotEmpty) agencyCode.value = code;
      commissionRate.value = _parseCommission(data['commissionRate']);
    }
    await _clearApplicationStorage();
    update();
  }

  /// Reserved for a future agency-application-status API (not in current doc).
  Future<void> applyStatusFromApi(Map<String, dynamic> data) async {
    final state = AgencyOwnerApplicationState.fromApi(
      data['status']?.toString(),
    );
    applicationState.value = state;
    applicationId.value =
        data['application_id']?.toString() ??
        data['applicationId']?.toString() ??
        data['id']?.toString() ??
        applicationId.value;
    appliedAgencyName.value =
        data['agency_name']?.toString() ??
        data['agencyName']?.toString() ??
        appliedAgencyName.value;
    appliedOwnerName.value =
        data['owner_name']?.toString() ??
        data['ownerName']?.toString() ??
        appliedOwnerName.value;
    appliedPhone.value =
        data['phone']?.toString() ??
        data['whatsapp']?.toString() ??
        appliedPhone.value;
    applicationReason.value = data['reason']?.toString() ?? '';
    applicationSubmittedAt.value =
        data['createdAt']?.toString() ??
        data['submitted_at']?.toString() ??
        applicationSubmittedAt.value;

    if (state == AgencyOwnerApplicationState.approved) {
      final agency = data['agency'];
      if (agency is Map) {
        setAgency(
          id: agency['id']?.toString() ?? '',
          name: agency['name']?.toString() ?? appliedAgencyName.value,
          code: agency['code']?.toString() ?? '',
          commission: _parseCommission(agency['commissionRate']),
          agencyStatus: agency['status']?.toString() ?? 'active',
          link: agency['recruitLink']?.toString(),
        );
      } else {
        setAgency(
          id: data['agency_id']?.toString() ?? data['agencyId']?.toString() ?? '',
          name: appliedAgencyName.value,
          code: data['agency_code']?.toString() ?? data['agencyCode']?.toString() ?? '',
          commission: _parseCommission(data['commissionRate']),
        );
      }
      await _clearApplicationStorage();
    } else if (state == AgencyOwnerApplicationState.rejected) {
      hasAgency.value = false;
      await _persistApplication();
    } else if (state == AgencyOwnerApplicationState.pending) {
      hasAgency.value = false;
      await _persistApplication();
    }
    update();
  }

  void setAgency({
    required String id,
    required String name,
    required String code,
    double commission = 0.10,
    String agencyStatus = 'active',
    String? link,
  }) {
    agencyId.value = id;
    agencyName.value = name;
    agencyCode.value = code;
    commissionRate.value = commission;
    status.value = agencyStatus;
    recruitLink.value =
        link ?? 'https://qobo1.live/invite/${code.trim().toUpperCase()}';
    hasAgency.value = id.isNotEmpty;
    applicationState.value = AgencyOwnerApplicationState.approved;
    unawaited(_persistApprovedAgency());
  }

  Future<void> clearAgency() async {
    hasAgency.value = false;
    agencyId.value = '';
    agencyName.value = '';
    agencyCode.value = '';
    commissionRate.value = 0;
    status.value = '';
    recruitLink.value = '';
    cachedHosts.clear();
    applicationState.value = AgencyOwnerApplicationState.none;
    applicationId.value = '';
    appliedAgencyName.value = '';
    appliedOwnerName.value = '';
    appliedPhone.value = '';
    applicationReason.value = '';
    applicationSubmittedAt.value = '';
    await _clearApprovedAgencyStorage();
    await _clearApplicationStorage();
    update();
  }

  Future<void> _clearApplicationStorage() async {
    await _storage.writeStringStorage(kStorageAgencyOwnerApplication, '');
  }

  Future<void> _persistApplication() async {
    await _storage.writeJsonStorage(kStorageAgencyOwnerApplication, {
      'status': applicationState.value.apiLabel,
      'applicationId': applicationId.value,
      'agencyName': appliedAgencyName.value,
      'ownerName': appliedOwnerName.value,
      'phone': appliedPhone.value,
      'reason': applicationReason.value,
      'submittedAt': applicationSubmittedAt.value,
    });
  }

  void _applyApplicationJson(Map<String, dynamic> json, {required bool persist}) {
    applicationState.value = AgencyOwnerApplicationState.fromApi(
      json['status']?.toString(),
    );
    applicationId.value = json['applicationId']?.toString() ?? '';
    appliedAgencyName.value = json['agencyName']?.toString() ?? '';
    appliedOwnerName.value = json['ownerName']?.toString() ?? '';
    appliedPhone.value = json['phone']?.toString() ?? '';
    applicationReason.value = json['reason']?.toString() ?? '';
    applicationSubmittedAt.value = json['submittedAt']?.toString() ?? '';
    if (applicationState.value != AgencyOwnerApplicationState.approved) {
      hasAgency.value = false;
    }
  }

  void _applyApprovedAgencyJson(Map<String, dynamic> json) {
    final id = json['agencyId']?.toString().trim() ?? '';
    final code = json['agencyCode']?.toString().trim() ?? '';
    if (id.isEmpty || code.isEmpty) return;

    agencyId.value = id;
    agencyName.value = json['agencyName']?.toString() ?? '';
    agencyCode.value = code;
    commissionRate.value = _parseCommission(json['commissionRate']);
    status.value = json['status']?.toString() ?? 'active';
    final link = json['recruitLink']?.toString() ?? '';
    recruitLink.value = link.isNotEmpty
        ? link
        : 'https://qobo1.live/invite/${code.toUpperCase()}';
    hasAgency.value = true;
    applicationState.value = AgencyOwnerApplicationState.approved;
  }

  Future<void> _persistApprovedAgency() async {
    if (!hasAgency.value || agencyId.value.trim().isEmpty) return;
    await _storage.writeJsonStorage(kStorageApprovedAgency, {
      'agencyId': agencyId.value,
      'agencyName': agencyName.value,
      'agencyCode': agencyCode.value,
      'commissionRate': commissionRate.value,
      'status': status.value,
      'recruitLink': recruitLink.value,
    });
  }

  Future<void> _clearApprovedAgencyStorage() async {
    await _storage.writeStringStorage(kStorageApprovedAgency, '');
  }

  double _parseCommission(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0.10;
  }

  String get commissionPercentLabel {
    final pct = (commissionRate.value * 100).round();
    return '$pct%';
  }
}
