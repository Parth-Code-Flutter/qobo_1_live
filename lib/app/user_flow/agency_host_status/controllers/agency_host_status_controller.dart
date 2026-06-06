import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';

enum AgencyStatusLookupType { applicationId, phone }

class AgencyHostStatusController extends GetxController {
  final AgencyRepo _agencyRepo = AgencyRepo();

  final lookupController = TextEditingController();

  final lookupType = AgencyStatusLookupType.applicationId.obs;
  final status = ''.obs;
  final applicationId = ''.obs;
  final hostId = ''.obs;
  final hostName = ''.obs;
  final agencyId = ''.obs;
  final agencyCode = ''.obs;
  final phone = ''.obs;
  final reason = ''.obs;
  final hostType = ''.obs;
  final hostInterest = ''.obs;
  final createdAt = ''.obs;
  final isLoading = false.obs;
  final hasSearched = false.obs;

  bool get hasLookupValue => lookupController.text.trim().isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    _hydrateFromArguments();
  }

  @override
  void onClose() {
    lookupController.dispose();
    super.onClose();
  }

  void _hydrateFromArguments() {
    final args = Get.arguments;
    if (args is! Map) return;

    applicationId.value = args['application_id']?.toString().trim() ?? '';
    phone.value = args['phone']?.toString().trim() ?? '';

    if (applicationId.value.isNotEmpty) {
      lookupType.value = AgencyStatusLookupType.applicationId;
      lookupController.text = applicationId.value;
    } else if (phone.value.isNotEmpty) {
      lookupType.value = AgencyStatusLookupType.phone;
      lookupController.text = phone.value;
    }

    if (lookupController.text.trim().isNotEmpty) {
      fetchStatus();
    }
  }

  void selectLookupType(AgencyStatusLookupType type) {
    lookupType.value = type;
    lookupController.clear();
    status.value = '';
    reason.value = '';
    hasSearched.value = false;
  }

  String get lookupLabel {
    switch (lookupType.value) {
      case AgencyStatusLookupType.applicationId:
        return 'Application ID';
      case AgencyStatusLookupType.phone:
        return 'Phone number';
    }
  }

  String get lookupHint {
    switch (lookupType.value) {
      case AgencyStatusLookupType.applicationId:
        return 'Enter application ID';
      case AgencyStatusLookupType.phone:
        return 'Enter WhatsApp number';
    }
  }

  TextInputType get keyboardType {
    return lookupType.value == AgencyStatusLookupType.phone
        ? TextInputType.phone
        : TextInputType.text;
  }

  Future<void> fetchStatus() async {
    final lookup = lookupController.text.trim();
    if (lookup.isEmpty) return;

    try {
      isLoading.value = true;
      hasSearched.value = true;

      final response = await _agencyRepo.hostVerifyStatus(
        applicationId: lookupType.value == AgencyStatusLookupType.applicationId
            ? lookup
            : null,
        phone: lookupType.value == AgencyStatusLookupType.phone ? lookup : null,
        isShowLoader: false,
      );

      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        _applyStatusData(Map<String, dynamic>.from(data));
      } else {
        status.value = 'Not Found';
        reason.value =
            agencyApiMessage(response) ??
            'No host application was found for this lookup.';
        hostName.value = '';
        agencyCode.value = '';
        createdAt.value = '';
      }
    } catch (_) {
      status.value = 'Unable to Check';
      reason.value = 'Please try again after some time.';
    } finally {
      isLoading.value = false;
    }
  }

  void _applyStatusData(Map<String, dynamic> data) {
    status.value = data['status']?.toString() ?? 'pending';
    applicationId.value =
        data['applicationId']?.toString() ??
        data['application_id']?.toString() ??
        data['id']?.toString() ??
        applicationId.value;
    hostId.value = data['hostId']?.toString() ?? '';
    hostName.value = data['hostName']?.toString() ?? '';
    agencyId.value = data['agencyId']?.toString() ?? '';
    agencyCode.value = data['agencyCode']?.toString() ?? '';
    phone.value = data['phone']?.toString() ?? phone.value;
    hostType.value =
        data['type']?.toString() ?? data['hostType']?.toString() ?? '';
    hostInterest.value =
        data['category']?.toString() ??
        data['interests']?.toString() ??
        data['interest']?.toString() ??
        '';
    createdAt.value = data['createdAt']?.toString() ?? '';
    reason.value = data['reason']?.toString() ?? '';
  }

  void refreshStatus() {
    fetchStatus();
  }
}
