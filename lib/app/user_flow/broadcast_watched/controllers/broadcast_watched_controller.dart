import 'package:get/get.dart';

class BroadcastWatchedController extends GetxController {
  final isLoading = false.obs;

  // Streamers watched list
  final broadcasts = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchWatchedHistory();
  }

  void fetchWatchedHistory() async {
    isLoading.value = true;
    broadcasts.clear();
    isLoading.value = false;
  }

  void joinLiveRoom(String name) {
    Get.snackbar(
      'Connecting to Live...',
      'Joining $name\'s live broadcast room now!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void visitProfile(String name) {
    Get.snackbar(
      'Profile Visit',
      'Opening $name\'s profile page...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
