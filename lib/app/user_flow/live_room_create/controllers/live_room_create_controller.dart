import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class LiveRoomCreateController extends GetxController {
  
  final roomNameController = TextEditingController();
  final roomType = 'AUDIO'.obs; // AUDIO or VIDEO
  final seatCount = '8'.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args.containsKey('type')) {
        roomType.value = args['type'];
      }
    }
  }

  void selectRoomType(String type) {
    roomType.value = type;
  }

  void selectSeats(String count) {
    seatCount.value = count;
  }

  void createRoom(BuildContext context) {
    if (roomNameController.text.trim().isEmpty) {
      AppToast.showError(context, 'Please enter a room name');
      return;
    }

    AppToast.showSuccess(context, 'Room created successfully!');
    Get.offNamed('/live-broadcast', arguments: {
      'isHost': true, 
      'roomType': roomType.value
    });
  }

  @override
  void onClose() {
    roomNameController.dispose();
    super.onClose();
  }
}
