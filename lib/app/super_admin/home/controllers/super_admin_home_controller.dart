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
  final superAdminCode = ''.obs;
  final isSharingSuperAdminCode = false.obs;

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
    Get.toNamed(Routes.SUPER_ADMIN_AGENCY_DETAIL, arguments: {'agencyId': id});
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
    if (agency.id.isEmpty || processingAgencyId.value.isNotEmpty) return;
    final context = Get.context;
    processingAgencyId.value = agency.id;
    try {
      final response = await _repo.updateAgencyCommission(
        agencyId: agency.id,
        commissionRate: rate,
      );
      if (isAgencyApiSuccess(response)) {
        if (context != null && context.mounted) {
          AppToast.showSuccess(
            context,
            agencyApiMessage(response) ?? 'Commission updated.',
          );
        }
        await loadAgencies(showLoader: false);
        return;
      }
      if (context != null && context.mounted) {
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
        if (context != null && context.mounted) {
          AppToast.showSuccess(
            context,
            agencyApiMessage(response) ?? 'Host marked $status.',
          );
        }
        await loadTrackedHosts(showLoader: false);
        await loadDashboardStats(showLoader: false);
        return;
      }
      if (context != null && context.mounted) {
        AppToast.showError(
          context,
          agencyApiMessage(response) ?? 'Could not update host.',
        );
      }
    } finally {
      processingHostId.value = '';
    }
  }

  /// Manual creation uses the authenticated super admin endpoint.
  Future<void> openCreateAgency() async {
    await Get.toNamed(
      Routes.AGENCY_OWNER_REGISTER,
      arguments: {'fromSuperAdmin': true},
    );
    await loadAgencies(showLoader: false);
    await loadDashboardStats(showLoader: false);
  }

  /// FAB → host onboarding (`POST /api/agency/host-onboarding`).
  ///
  /// Disabled for super admin: they may only create agencies. Hosts are
  /// onboarded by agencies. Kept commented for easy restore.
  // Future<void> openCreateHost() async {
  //   await Get.toNamed(
  //     Routes.AGENCY_HOST_ONBOARDING,
  //     arguments: {'fromSuperAdmin': true},
  //   );
  //   await loadTrackedHosts(showLoader: false);
  //   await loadDashboardStats(showLoader: false);
  // }

  Future<void> shareSuperAdminCode() async {
    if (isSharingSuperAdminCode.value) return;
    isSharingSuperAdminCode.value = true;
    try {
      var response = await _repo.getMyCode();
      final codeData = response?['data'];
      if (response?['codeNotFound'] == true ||
          (isAgencyApiSuccess(response) &&
              (codeData is! Map ||
                  (codeData['code']?.toString().trim() ?? '').isEmpty))) {
        response = await _repo.generateCode();
      }
      final data = response?['data'];
      if (!isAgencyApiSuccess(response) || data is! Map) {
        final ctx = Get.context;
        if (ctx != null && ctx.mounted) {
          AppToast.showError(
            ctx,
            agencyApiMessage(response) ??
                'Could not retrieve Super Admin code.',
          );
        }
        return;
      }

      final code = data['code']?.toString().trim() ?? '';
      if (code.isEmpty) {
        final ctx = Get.context;
        if (ctx != null && ctx.mounted) {
          AppToast.showError(ctx, 'Super Admin code is empty. Try again.');
        }
        return;
      }
      final text =
          'Apply for an agency in Qobo1live using my Super Admin code: $code';
      superAdminCode.value = code;
      await Clipboard.setData(ClipboardData(text: text));
      // Native share sheet (WhatsApp, Messages, Mail, etc.).
      await SharePlus.instance.share(
        ShareParams(text: text, subject: 'Super Admin code'),
      );
      final ctx = Get.context;
      if (ctx != null && ctx.mounted) {
        AppToast.showSuccess(ctx, 'Code ready to share.');
      }
    } catch (_) {
      final ctx = Get.context;
      if (ctx != null && ctx.mounted) {
        AppToast.showError(ctx, 'Could not share code. Please try again.');
      }
    } finally {
      isSharingSuperAdminCode.value = false;
    }
  }

  Future<void> _processAgency(
    SuperAdminAgencyItem agency,
    String status, {
    String? feedback,
  }) async {
    if (agency.id.isEmpty || processingAgencyId.value.isNotEmpty) return;
    final context = Get.context;
    processingAgencyId.value = agency.id;
    try {
      final response = await _repo.processAgency(
        agencyId: agency.id,
        status: status,
        feedback: feedback,
      );
      if (isAgencyApiSuccess(response)) {
        if (context != null && context.mounted) {
          AppToast.showSuccess(
            context,
            agencyApiMessage(response) ?? 'Agency $status.',
          );
        }
        await loadAgencies(showLoader: false);
        await loadDashboardStats(showLoader: false);
        if (Get.isRegistered<UserSessionController>()) {
          await Get.find<UserSessionController>().refreshProfileFromApi();
        }
        return;
      }
      if (context != null && context.mounted) {
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
