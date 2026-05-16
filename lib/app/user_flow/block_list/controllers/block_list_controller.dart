import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

class BlockListController extends GetxController {
  
  final blockedUsers = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    _mockData();
  }

  void _mockData() {
    blockedUsers.addAll([
      {'name': 'ToxicUser99', 'image': kImgTemp4, 'id': '4928172'},
      {'name': 'Spambot', 'image': kImgTemp3, 'id': '9948271'},
    ]);
  }

  void unblockUser(int index) {
    blockedUsers.removeAt(index);
    Get.snackbar('Unblocked', 'User has been unblocked.');
  }
}
