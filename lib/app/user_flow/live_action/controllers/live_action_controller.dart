import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';

class LiveActionController extends GetxController {
  
  void navToCreateVideoRoom() {
    // Navigate to Create Room view with argument
    Get.toNamed(Routes.LIVE_ROOM_CREATE, arguments: {'type': 'VIDEO'});
  }

  void navToCreateAudioRoom() {
    // Navigate to Create Room view with argument
    Get.toNamed(Routes.LIVE_ROOM_CREATE, arguments: {'type': 'AUDIO'});
  }
}
