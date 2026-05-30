import 'package:get/get.dart';

class BlockListController extends GetxController {
  final blockedUsers = <Map<String, dynamic>>[].obs;

  void unblockUser(int index) {
    blockedUsers.removeAt(index);
    Get.snackbar('Unblocked', 'User has been unblocked.');
  }
}
