import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class AgencyRecruitLinkController extends GetxController {
  final agencyCode = 'QOBO-AG8X9'.obs;
  final recruitLink = 'https://qobo1.live/invite/QOBO-AG8X9'.obs;

  void copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: agencyCode.value));
    AppToast.showSuccess(context, 'Agency Code copied to clipboard!');
  }

  void copyLink(BuildContext context) {
    Clipboard.setData(ClipboardData(text: recruitLink.value));
    AppToast.showSuccess(context, 'Recruit Link copied to clipboard!');
  }
}
