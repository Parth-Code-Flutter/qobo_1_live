import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class AgencyRecruitLinkController extends GetxController {
  final agencyCode = 'QOBO-AG8X9'.obs;
  final recruitLink = 'https://qobo1.live/invite/QOBO-AG8X9'.obs;

  @override
  void onInit() {
    super.onInit();
    _hydrateFromSession();
  }

  void _hydrateFromSession() {
    if (!Get.isRegistered<AgencySessionController>()) return;
    final session = Get.find<AgencySessionController>();
    if (!session.hasAgency.value) return;

    if (session.agencyCode.value.isNotEmpty) {
      agencyCode.value = session.agencyCode.value;
    }
    if (session.recruitLink.value.isNotEmpty) {
      recruitLink.value = session.recruitLink.value;
    }
  }

  void copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: agencyCode.value));
    AppToast.showSuccess(context, 'Agency code copied to clipboard!');
  }

  void copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: recruitLink.value));
    AppToast.showSuccess(context, 'Recruit link copied to clipboard!');
  }
}
