import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/super_admin/super_admin_repo.dart';
import 'package:qobo_one_live/utils/files_utils/file_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Shared data + API actions for Super Admin Dashboard / Agency / Host tabs.
///
/// Wired to guide endpoints:
/// - `GET /api/super-admin/dashboard`
/// - `GET /api/super-admin/agencies`
/// - `POST /api/super-admin/agency/process`
/// - `GET /api/super-admin/hosts/track`
/// - `GET /api/super-admin/agency/generate-link`
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
  final agencyStatusFilter = 'pending'.obs;
  final generatedAgencyLink = ''.obs;

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
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is List) {
        agencies.assignAll(
          data
              .whereType<Map>()
              .map(
                (e) =>
                    SuperAdminAgencyItem.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(),
        );
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
      final response = await _repo.getTrackedHosts(isShowLoader: showLoader);
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is List) {
        trackedHosts.assignAll(
          data
              .whereType<Map>()
              .map(
                (e) => SuperAdminTrackedHost.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList(),
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

  Future<void> approveAgency(SuperAdminAgencyItem agency) async {
    await _processAgency(agency, 'approved');
  }

  Future<void> rejectAgency(
    SuperAdminAgencyItem agency,
    String feedback,
  ) async {
    await _processAgency(agency, 'rejected', feedback: feedback);
  }

  Future<void> generateAgencyLink() async {
    final context = Get.context;
    final response = await _repo.generateAgencyLink();
    final data = response?['data'];
    if (!isAgencyApiSuccess(response) || data is! Map) {
      if (context != null) {
        AppToast.showError(
          context,
          agencyApiMessage(response) ?? 'Could not generate link.',
        );
      }
      return;
    }

    final link = data['link']?.toString().trim() ?? '';
    final text = (data['whatsappText']?.toString().trim().isNotEmpty == true)
        ? data['whatsappText'].toString().trim()
        : link;
    generatedAgencyLink.value = link;
    await Clipboard.setData(ClipboardData(text: text));
    if (link.isNotEmpty) {
      await FileUtils.openFileOrLink(
        'https://wa.me/?text=${Uri.encodeComponent(text)}',
      );
    }
    if (context != null) {
      AppToast.showSuccess(context, 'Agency invite copied.');
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
