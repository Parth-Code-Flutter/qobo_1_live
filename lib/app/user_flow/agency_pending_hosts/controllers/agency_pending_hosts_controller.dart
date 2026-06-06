import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_host_list/controllers/agency_host_list_controller.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';

class AgencyPendingHostsController extends GetxController {
  final AgencyRepo _agencyRepo = AgencyRepo();

  final isLoading = true.obs;
  final loadError = ''.obs;
  final applications = <AgencyHostModel>[].obs;
  final processingId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPendingApplications();
  }

  Future<void> fetchPendingApplications({bool showLoader = true}) async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final response = await _agencyRepo.getHostApplications(
        status: 'pending',
        isShowLoader: showLoader,
      );
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        final raw = data['applications'];
        if (raw is List) {
          applications.assignAll(
            raw
                .whereType<Map>()
                .map(
                  (e) => AgencyHostModel.fromApplicationJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList(),
          );
          isLoading.value = false;
          return;
        }
      }
      loadError.value =
          agencyApiMessage(response) ?? 'Could not load pending applications.';
      applications.clear();
    } catch (_) {
      loadError.value = 'Network error.';
      applications.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveHost(AgencyHostModel host) async {
    final id = host.reviewApplicationId;
    if (id.isEmpty) return;

    processingId.value = id;
    try {
      final response = await _agencyRepo.approveHostApplication(
        applicationId: id,
        coinsPerSecond: host.coinsPerSecond > 0 ? host.coinsPerSecond : 5,
      );
      if (isAgencyApiSuccess(response)) {
        Get.snackbar(
          'Approved',
          agencyApiMessage(response) ?? '${host.name} is now an active host.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.withValues(alpha: 0.85),
          colorText: Colors.white,
        );
        applications.removeWhere((h) => h.reviewApplicationId == id);
        return;
      }
      Get.snackbar(
        'Failed',
        agencyApiMessage(response) ?? 'Could not approve application.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Network error while approving.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      processingId.value = '';
    }
  }

  Future<void> rejectHost(AgencyHostModel host, String reason) async {
    final id = host.reviewApplicationId;
    if (id.isEmpty) return;

    processingId.value = id;
    try {
      final response = await _agencyRepo.rejectHostApplication(
        applicationId: id,
        reason: reason,
      );
      if (isAgencyApiSuccess(response)) {
        Get.snackbar(
          'Rejected',
          agencyApiMessage(response) ?? '${host.name} was rejected.',
          snackPosition: SnackPosition.BOTTOM,
        );
        applications.removeWhere((h) => h.reviewApplicationId == id);
        return;
      }
      Get.snackbar(
        'Failed',
        agencyApiMessage(response) ?? 'Could not reject application.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (_) {
      Get.snackbar(
        'Error',
        'Network error while rejecting.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      processingId.value = '';
    }
  }

  void onBackPressed() => Get.back<void>();
}
