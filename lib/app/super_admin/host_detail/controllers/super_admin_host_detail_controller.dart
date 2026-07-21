import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/super_admin/super_admin_repo.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Host detail — `GET /api/super-admin/hosts/:hostId` + status updates.
class SuperAdminHostDetailController extends GetxController {
  SuperAdminHostDetailController({SuperAdminRepo? repo})
    : _repo = repo ?? SuperAdminRepo();

  final SuperAdminRepo _repo;

  late final String hostId;

  final isLoading = false.obs;
  final isProcessing = false.obs;
  final error = ''.obs;
  final detail = Rxn<SuperAdminHostDetail>();

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    hostId = args is Map
        ? (args['hostId']?.toString().trim() ?? '')
        : (args?.toString().trim() ?? '');
    loadDetail();
  }

  Future<void> loadDetail({bool showLoader = true}) async {
    if (hostId.isEmpty) {
      error.value = 'Missing host id.';
      return;
    }
    isLoading.value = true;
    error.value = '';
    try {
      final response = await _repo.getHostDetail(
        hostId: hostId,
        isShowLoader: showLoader,
      );
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        detail.value = SuperAdminHostDetail.fromJson(
          Map<String, dynamic>.from(data),
        );
        return;
      }
      error.value =
          agencyApiMessage(response) ?? 'Unable to load host details.';
      detail.value = null;
    } catch (_) {
      error.value = 'Unable to load host details.';
      detail.value = null;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> setStatus(String status, {String? reason}) async {
    final context = Get.context;
    if (hostId.isEmpty) return;
    isProcessing.value = true;
    try {
      final response = await _repo.updateHostStatus(
        hostId: hostId,
        status: status,
        reason: reason,
      );
      if (isAgencyApiSuccess(response)) {
        if (context != null) {
          AppToast.showSuccess(
            context,
            agencyApiMessage(response) ?? 'Host $status.',
          );
        }
        await loadDetail(showLoader: false);
        if (Get.isRegistered<SuperAdminHomeController>()) {
          Get.find<SuperAdminHomeController>().loadTrackedHosts(
            showLoader: false,
          );
        }
        return;
      }
      if (context != null) {
        AppToast.showError(
          context,
          agencyApiMessage(response) ?? 'Could not update host.',
        );
      }
    } finally {
      isProcessing.value = false;
    }
  }
}
