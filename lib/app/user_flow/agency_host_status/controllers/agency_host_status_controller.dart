import 'package:get/get.dart';

class AgencyHostStatusController extends GetxController {
  final status = 'Under Review'.obs;
  final applicationId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      applicationId.value = args['application_id']?.toString() ?? 'APP-0000';
    } else {
      applicationId.value = 'APP-0000';
    }
  }

  void refreshStatus() {
    status.value = 'Under Review';
  }
}
