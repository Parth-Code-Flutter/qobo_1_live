import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class AgencyRecruitLinkController extends GetxController {
  final AgencyRepo _agencyRepo = AgencyRepo();

  final agencyCode = ''.obs;
  final recruitLink = ''.obs;
  final isLoading = false.obs;

  AgencySessionController get _session => Get.find<AgencySessionController>();

  @override
  void onInit() {
    super.onInit();
    _hydrateFromSession();
    _fetchLink();
  }

  void _hydrateFromSession() {
    if (_session.agencyCode.value.isNotEmpty) {
      agencyCode.value = _session.agencyCode.value;
    }
    if (_session.recruitLink.value.isNotEmpty) {
      recruitLink.value = _session.recruitLink.value;
    }
  }

  Future<void> _fetchLink() async {
    final agencyId = _session.agencyId.value;
    if (agencyId.isEmpty) return;

    isLoading.value = true;
    try {
      final response = await _agencyRepo.generateInviteLink(
        agencyId: agencyId,
        isShowLoader: false,
      );
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        final code = data['code']?.toString() ?? '';
        final link = data['link']?.toString() ?? '';
        if (code.isNotEmpty) agencyCode.value = code;
        if (link.isNotEmpty) {
          recruitLink.value = link;
          _session.recruitLink.value = link;
        }
      }
    } catch (_) {
      // Session / dashboard link remains as fallback.
    } finally {
      isLoading.value = false;
    }
  }

  void copyCode(BuildContext context) {
    if (agencyCode.value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: agencyCode.value));
    AppToast.showSuccess(context, 'Agency code copied to clipboard!');
  }

  void copyLink(BuildContext context) {
    if (recruitLink.value.isEmpty) return;
    Clipboard.setData(ClipboardData(text: recruitLink.value));
    AppToast.showSuccess(context, 'Recruit link copied to clipboard!');
  }
}
