import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/super_admin/super_admin_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:share_plus/share_plus.dart';

/// Shared data + API actions for Super Admin Dashboard / Agency / Host tabs.
///
/// Spec: `super_admin_mobile_api_handover_v1.md`
class SuperAdminHomeController extends GetxController {
  SuperAdminHomeController({SuperAdminRepo? repo})
    : _repo = repo ?? SuperAdminRepo();

  final SuperAdminRepo _repo;

  final isLoadingStats = false.obs;
  final isLoadingAgencies = false.obs;
  final isLoadingHosts = false.obs;
  final error = ''.obs;

  final stats = Rxn<SuperAdminStats>();
  final agencies = <SuperAdminAgencyItem>[].obs;
  final trackedHosts = <SuperAdminTrackedHost>[].obs;
  final processingAgencyId = ''.obs;
  final processingHostId = ''.obs;
  final agencyStatusFilter = 'pending'.obs;
  final hostStatusFilter = ''.obs;
  final generatedAgencyLink = ''.obs;
  final isGeneratingAgencyLink = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Dashboard is the default tab — load stats on shell open.
    loadDashboardStats();
  }

  Future<void> loadDashboardStats({bool showLoader = true}) async {
    isLoadingStats.value = true;
    error.value = '';
    try {
      final response = await _repo.getDashboard(isShowLoader: showLoader);
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        stats.value = SuperAdminStats.fromJson(Map<String, dynamic>.from(data));
        return;
      }
      error.value = agencyApiMessage(response) ?? 'Unable to load dashboard.';
    } catch (_) {
      error.value = 'Unable to load dashboard.';
    } finally {
      isLoadingStats.value = false;
    }
  }

  Future<void> loadAgencies({bool showLoader = true}) async {
    isLoadingAgencies.value = true;
    try {
      final response = await _repo.getAgencies(
        status: agencyStatusFilter.value,
        isShowLoader: showLoader,
      );
      if (isAgencyApiSuccess(response)) {
        final maps = extractSuperAdminListMaps(
          response?['data'],
          nestedKey: 'agencies',
        );
        agencies.assignAll(maps.map(SuperAdminAgencyItem.fromJson).toList());
        return;
      }
      agencies.clear();
    } catch (_) {
      agencies.clear();
    } finally {
      isLoadingAgencies.value = false;
    }
  }

  Future<void> changeAgencyFilter(String status) async {
    agencyStatusFilter.value = status;
    await loadAgencies(showLoader: false);
  }

  Future<void> loadTrackedHosts({bool showLoader = true}) async {
    isLoadingHosts.value = true;
    try {
      final response = await _repo.getTrackedHosts(
        status: hostStatusFilter.value,
        isShowLoader: showLoader,
      );
      if (isAgencyApiSuccess(response)) {
        final maps = extractSuperAdminListMaps(
          response?['data'],
          nestedKey: 'hosts',
        );
        trackedHosts.assignAll(
          maps.map(SuperAdminTrackedHost.fromJson).toList(),
        );
        return;
      }
      trackedHosts.clear();
    } catch (_) {
      trackedHosts.clear();
    } finally {
      isLoadingHosts.value = false;
    }
  }

  Future<void> changeHostFilter(String status) async {
    hostStatusFilter.value = status;
    await loadTrackedHosts(showLoader: false);
  }

  /// Opens agency detail screen (`GET /agencies/:id`).
  void openAgencyDetail(SuperAdminAgencyItem agency) {
    openAgencyById(agency.id);
  }

  /// Opens agency detail by id (dashboard top-agency rows, deep links).
  void openAgencyById(String id) {
    if (id.isEmpty) return;
    Get.toNamed(
      Routes.SUPER_ADMIN_AGENCY_DETAIL,
      arguments: {'agencyId': id},
    );
  }

  /// Opens host detail screen (`GET /hosts/:id`).
  void openHostDetail(SuperAdminTrackedHost host) {
    if (host.id.isEmpty) return;
    Get.toNamed(Routes.SUPER_ADMIN_HOST_DETAIL, arguments: {'hostId': host.id});
  }

  Future<void> approveAgency(SuperAdminAgencyItem agency) async {
    await _processAgency(agency, 'approved');
  }

  Future<void> rejectAgency(
    SuperAdminAgencyItem agency,
    String feedback,
  ) async {
    await _processAgency(agency, 'rejected', feedback: feedback);
  }

  Future<void> suspendAgency(
    SuperAdminAgencyItem agency,
    String feedback,
  ) async {
    await _processAgency(agency, 'suspended', feedback: feedback);
  }

  Future<void> activateAgency(SuperAdminAgencyItem agency) async {
    await _processAgency(agency, 'active');
  }

  /// The backend has no hard-delete endpoint; rejecting removes the agency
  /// from the operational lists (`POST /agency/process` with `rejected`).
  Future<void> deleteAgency(SuperAdminAgencyItem agency, String reason) async {
    await _processAgency(
      agency,
      'rejected',
      feedback: reason.isEmpty ? 'Removed by super admin' : reason,
    );
  }

  /// `PATCH /agencies/:id/commission` — [rate] is a fraction (0.12 = 12%).
  Future<void> updateAgencyCommission(
    SuperAdminAgencyItem agency,
    double rate,
  ) async {
    if (agency.id.isEmpty) return;
    final context = Get.context;
    processingAgencyId.value = agency.id;
    try {
      final response = await _repo.updateAgencyCommission(
        agencyId: agency.id,
        commissionRate: rate,
      );
      if (isAgencyApiSuccess(response)) {
        if (context != null) {
          AppToast.showSuccess(
            context,
            agencyApiMessage(response) ?? 'Commission updated.',
          );
        }
        await loadAgencies(showLoader: false);
        return;
      }
      if (context != null) {
        AppToast.showError(
          context,
          agencyApiMessage(response) ?? 'Could not update commission.',
        );
      }
    } finally {
      processingAgencyId.value = '';
    }
  }

  /// `POST /hosts/:hostId/status` — status: active | suspended | inactive.
  /// `inactive` is the closest the backend offers to deleting a host.
  Future<void> setHostStatus(
    SuperAdminTrackedHost host,
    String status, {
    String? reason,
  }) async {
    if (host.id.isEmpty) return;
    final context = Get.context;
    processingHostId.value = host.id;
    try {
      final response = await _repo.updateHostStatus(
        hostId: host.id,
        status: status,
        reason: reason,
      );
      if (isAgencyApiSuccess(response)) {
        if (context != null) {
          AppToast.showSuccess(
            context,
            agencyApiMessage(response) ?? 'Host marked $status.',
          );
        }
        await loadTrackedHosts(showLoader: false);
        await loadDashboardStats(showLoader: false);
        return;
      }
      if (context != null) {
        AppToast.showError(
          context,
          agencyApiMessage(response) ?? 'Could not update host.',
        );
      }
    } finally {
      processingHostId.value = '';
    }
  }

  /// FAB → agency creation form (`POST /api/agency/register-public`), with
  /// invitedBy prefilled from the super admin account. Refreshes on return.
  Future<void> openCreateAgency() async {
    var invitedBy = '';
    if (Get.isRegistered<UserSessionController>()) {
      final session = Get.find<UserSessionController>();
      await session.loadFromStorage();
      invitedBy = session.email.trim().isNotEmpty
          ? session.email.trim()
          : session.userId.trim();
    }
    await Get.toNamed(
      Routes.AGENCY_OWNER_REGISTER,
      arguments: {
        'invitedBy': invitedBy.isEmpty ? 'super_admin' : invitedBy,
        'fromSuperAdmin': true,
      },
    );
    await loadAgencies(showLoader: false);
    await loadDashboardStats(showLoader: false);
  }

  /// FAB → host onboarding form (`POST /api/agency/host-onboarding`). The
  /// super admin types the target agency code. Refreshes on return.
  Future<void> openCreateHost() async {
    await Get.toNamed(
      Routes.AGENCY_HOST_ONBOARDING,
      arguments: {'fromSuperAdmin': true},
    );
    await loadTrackedHosts(showLoader: false);
    await loadDashboardStats(showLoader: false);
  }

  Future<void> generateAgencyLink() async {
    if (isGeneratingAgencyLink.value) return;
    isGeneratingAgencyLink.value = true;
    try {
      final response = await _repo.generateAgencyLink();
      final data = response?['data'];
      if (!isAgencyApiSuccess(response) || data is! Map) {
        final ctx = Get.context;
        if (ctx != null) {
          AppToast.showError(
            ctx,
            agencyApiMessage(response) ?? 'Could not generate link.',
          );
        }
        return;
      }

      final link = data['link']?.toString().trim() ?? '';
      final text = (data['whatsappText']?.toString().trim().isNotEmpty == true)
          ? data['whatsappText'].toString().trim()
          : (link.isNotEmpty
                ? 'Join as an agency on Qobo One Live: $link'
                : '');
      if (text.isEmpty) {
        final ctx = Get.context;
        if (ctx != null) {
          AppToast.showError(ctx, 'Invite link is empty.');
        }
        return;
      }

      generatedAgencyLink.value = link;
      await Clipboard.setData(ClipboardData(text: text));
      // Native share sheet (WhatsApp, Messages, Mail, etc.).
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'Agency invite'),
      );
      final ctx = Get.context;
      if (ctx != null) {
        AppToast.showSuccess(ctx, 'Invite ready to share.');
      }
    } finally {
      isGeneratingAgencyLink.value = false;
    }
  }

  Future<void> _processAgency(
    SuperAdminAgencyItem agency,
    String status, {
    String? feedback,
  }) async {
    if (agency.id.isEmpty) return;
    final context = Get.context;
    processingAgencyId.value = agency.id;
    try {
      final response = await _repo.processAgency(
        agencyId: agency.id,
        status: status,
        feedback: feedback,
      );
      if (isAgencyApiSuccess(response)) {
        if (context != null) {
          AppToast.showSuccess(
            context,
            agencyApiMessage(response) ?? 'Agency $status.',
          );
        }
        await loadAgencies(showLoader: false);
        await loadDashboardStats(showLoader: false);
        return;
      }
      if (context != null) {
        AppToast.showError(
          context,
          agencyApiMessage(response) ?? 'Could not update agency.',
        );
      }
    } finally {
      processingAgencyId.value = '';
    }
  }
}
