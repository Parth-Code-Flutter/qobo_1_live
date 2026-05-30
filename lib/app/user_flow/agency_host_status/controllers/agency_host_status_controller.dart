import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';

enum AgencyStatusLookupType { applicationId, hostId, agencyId, phone }

class AgencyHostStatusController extends GetxController {
  final AgencyRepo _agencyRepo = AgencyRepo();

  final lookupController = TextEditingController();

  final lookupType = AgencyStatusLookupType.applicationId.obs;
  final status = ''.obs;
  final applicationId = ''.obs;
  final hostId = ''.obs;
  final agencyId = ''.obs;
  final phone = ''.obs;
  final reason = ''.obs;
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
    hostId.value = args['host_id']?.toString().trim() ?? '';
    agencyId.value = args['agency_id']?.toString().trim() ?? '';
    phone.value = args['phone']?.toString().trim() ?? '';

    if (applicationId.value.isNotEmpty) {
      lookupType.value = AgencyStatusLookupType.applicationId;
      lookupController.text = applicationId.value;
    } else if (hostId.value.isNotEmpty) {
      lookupType.value = AgencyStatusLookupType.hostId;
      lookupController.text = hostId.value;
    } else if (agencyId.value.isNotEmpty) {
      lookupType.value = AgencyStatusLookupType.agencyId;
      lookupController.text = agencyId.value;
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
      case AgencyStatusLookupType.hostId:
        return 'Host ID';
      case AgencyStatusLookupType.agencyId:
        return 'Agency ID';
      case AgencyStatusLookupType.phone:
        return 'Phone number';
    }
  }

  String get lookupHint {
    switch (lookupType.value) {
      case AgencyStatusLookupType.applicationId:
        return 'Enter application ID';
      case AgencyStatusLookupType.hostId:
        return 'Enter host ID';
      case AgencyStatusLookupType.agencyId:
        return 'Enter agency ID';
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
        hostId: lookupType.value == AgencyStatusLookupType.hostId
            ? lookup
            : null,
        agencyId: lookupType.value == AgencyStatusLookupType.agencyId
            ? lookup
            : null,
        phone: lookupType.value == AgencyStatusLookupType.phone ? lookup : null,
        isShowLoader: false,
      );

      final data = response?['data'];
      if (response != null && response['statusCode'] == 1 && data is Map) {
        _applyStatusData(data);
      } else {
        status.value = 'Not Found';
        reason.value =
            response?['message']?.toString() ??
            'No host application was found for this lookup.';
      }
    } catch (_) {
      status.value = 'Unable to Check';
      reason.value = 'Please try again after some time.';
    } finally {
      isLoading.value = false;
    }
  }

  void _applyStatusData(Map data) {
    status.value = data['status']?.toString() ?? 'Under Review';
    applicationId.value =
        data['application_id']?.toString() ??
        data['applicationId']?.toString() ??
        data['id']?.toString() ??
        applicationId.value;
    hostId.value =
        data['host_id']?.toString() ??
        data['hostId']?.toString() ??
        data['host']?['id']?.toString() ??
        hostId.value;
    agencyId.value =
        data['agency_id']?.toString() ??
        data['agencyId']?.toString() ??
        agencyId.value;
    phone.value = data['phone']?.toString() ?? phone.value;
    reason.value =
        data['reason']?.toString() ?? data['message']?.toString() ?? '';
  }

  void refreshStatus() {
    fetchStatus();
  }
}
