import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/super_admin/super_admin_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Agency detail — `GET /api/super-admin/agencies/:agencyId` + hosts / process / commission.
class SuperAdminAgencyDetailController extends GetxController {
  SuperAdminAgencyDetailController({SuperAdminRepo? repo})
    : _repo = repo ?? SuperAdminRepo();

  final SuperAdminRepo _repo;

  late final String agencyId;

  final isLoading = false.obs;
  final isLoadingHosts = false.obs;
  final isProcessing = false.obs;
  final error = ''.obs;
  final detail = Rxn<SuperAdminAgencyDetail>();
  final hosts = <SuperAdminTrackedHost>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    agencyId = args is Map
        ? (args['agencyId']?.toString().trim() ?? '')
        : (args?.toString().trim() ?? '');
    loadAll();
  }

  Future<void> loadAll({bool showLoader = true}) async {
    await Future.wait([
      loadDetail(showLoader: showLoader),
      loadHosts(showLoader: false),
    ]);
  }

  Future<void> loadDetail({bool showLoader = true}) async {
    if (agencyId.isEmpty) {
      error.value = 'Missing agency id.';
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final response = await _repo.getAgencyDetail(
        agencyId: agencyId,
        isShowLoader: showLoader,
      );
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        detail.value = SuperAdminAgencyDetail.fromJson(
          Map<String, dynamic>.from(data),
        );
        return;
      }
      error.value =
          agencyApiMessage(response) ?? 'Unable to load agency details.';
      detail.value = null;
    } catch (_) {
      error.value = 'Unable to load agency details.';
      detail.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadHosts({bool showLoader = true}) async {
    if (agencyId.isEmpty) return;
    isLoadingHosts.value = true;
    try {
      final response = await _repo.getAgencyHosts(
        agencyId: agencyId,
        isShowLoader: showLoader,
      );
      if (isAgencyApiSuccess(response)) {
        final maps = extractSuperAdminListMaps(
          response?['data'],
          nestedKey: 'hosts',
        );
        final code = detail.value?.code ?? '';
        hosts.assignAll(
          maps.map((m) {
            final withCode = Map<String, dynamic>.from(m);
            if ((withCode['agencyCode']?.toString() ?? '').isEmpty &&
                code.isNotEmpty) {
              withCode['agencyCode'] = code;
            }
            return SuperAdminTrackedHost.fromJson(withCode);
          }).toList(),
        );
        return;
      }
      hosts.clear();
    } catch (_) {
      hosts.clear();
    } finally {
      isLoadingHosts.value = false;
    }
  }

  void openHostDetail(SuperAdminTrackedHost host) {
    if (host.id.isEmpty) return;
    Get.toNamed(Routes.SUPER_ADMIN_HOST_DETAIL, arguments: {'hostId': host.id});
  }

  Future<void> approve() => _processStatus('approved');

  Future<void> reject(String feedback) =>
      _processStatus('rejected', feedback: feedback);

  Future<void> suspend(String feedback) =>
      _processStatus('suspended', feedback: feedback);

  Future<void> reactivate() => _processStatus('active');

  Future<void> updateCommission(double rate) async {
    final context = Get.context;
    if (agencyId.isEmpty) return;
    isProcessing.value = true;
    try {
      final response = await _repo.updateAgencyCommission(
        agencyId: agencyId,
        commissionRate: rate,
      );
      if (isAgencyApiSuccess(response)) {
        if (context != null) {
          AppToast.showSuccess(
            context,
            agencyApiMessage(response) ?? 'Commission updated.',
          );
        }
        await loadDetail(showLoader: false);
        _refreshHomeLists();
        return;
      }
      if (context != null) {
        AppToast.showError(
          context,
          agencyApiMessage(response) ?? 'Could not update commission.',
        );
      }
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> _processStatus(String status, {String? feedback}) async {
    final context = Get.context;
    if (agencyId.isEmpty) return;
    isProcessing.value = true;
    try {
      final response = await _repo.processAgency(
        agencyId: agencyId,
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
        await loadAll(showLoader: false);
        _refreshHomeLists();
        return;
      }
      if (context != null) {
        AppToast.showError(
          context,
          agencyApiMessage(response) ?? 'Could not update agency.',
        );
      }
    } finally {
      isProcessing.value = false;
    }
  }

  void _refreshHomeLists() {
    if (!Get.isRegistered<SuperAdminHomeController>()) return;
    final home = Get.find<SuperAdminHomeController>();
    home.loadAgencies(showLoader: false);
    home.loadDashboardStats(showLoader: false);
  }

  /// Owner metrics dashboard — requires `agency_id` for Super Admin tokens.
  void openOwnerDashboard() {
    if (agencyId.isEmpty) return;
    final name = detail.value?.name ?? '';
    Get.toNamed(
      Routes.AGENCY_OWNER,
      arguments: {
        'agencyId': agencyId,
        'agency_id': agencyId,
        if (name.isNotEmpty) 'agencyName': name,
      },
    );
  }
}
