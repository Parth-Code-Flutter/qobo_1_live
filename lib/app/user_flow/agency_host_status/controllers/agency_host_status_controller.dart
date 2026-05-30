import 'package:get/get.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';

class AgencyHostStatusController extends GetxController {
  final AgencyRepo _agencyRepo = AgencyRepo();

  final status = 'Under Review'.obs;
  final applicationId = ''.obs;
  final phone = ''.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      applicationId.value = args['application_id']?.toString() ?? 'APP-0000';
      phone.value = args['phone']?.toString() ?? '';
    } else {
      applicationId.value = 'APP-0000';
    }

    if (applicationId.value.isNotEmpty || phone.value.isNotEmpty) {
      fetchStatus();
    }
  }

  Future<void> fetchStatus() async {
    if (applicationId.value.isEmpty && phone.value.isEmpty) return;
    try {
      isLoading.value = true;
      final response = await _agencyRepo.hostVerifyStatus(
        applicationId: applicationId.value,
        phone: phone.value,
        isShowLoader: false,
      );
      if (response != null &&
          response['statusCode'] == 1 &&
          response['data'] != null) {
        final data = response['data'];
        if (data is Map) {
          status.value = data['status']?.toString() ?? 'Under Review';
        }
      }
    } catch (_) {
      // ignore
    } finally {
      isLoading.value = false;
    }
  }

  void refreshStatus() {
    fetchStatus();
  }
}
