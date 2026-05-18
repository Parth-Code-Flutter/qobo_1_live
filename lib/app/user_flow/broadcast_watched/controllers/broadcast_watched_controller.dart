import 'package:get/get.dart';

class BroadcastWatchedController extends GetxController {
  final isLoading = false.obs;

  // Streamers watched list
  final broadcasts = <Map<String, dynamic>>[
    {
      'name': 'Alina Khan',
      'avatar': 'assets/temp_img/temp2.png', // Fallback to kImgTemp2
      'isLive': true,
      'viewers': '12.4K',
      'watchDuration': '1.5 hours watched',
      'lastWatched': 'Today, 2:30 PM',
      'category': 'Music & Singing',
    },
    {
      'name': 'Zainab Malik',
      'avatar': 'assets/temp_img/temp2.png',
      'isLive': false,
      'viewers': '0',
      'watchDuration': '45 minutes watched',
      'lastWatched': 'Yesterday, 8:15 PM',
      'category': 'Gaming & Chat',
    },
    {
      'name': 'Hamza Shah',
      'avatar': 'assets/temp_img/temp2.png',
      'isLive': true,
      'viewers': '8.5K',
      'watchDuration': '2.0 hours watched',
      'lastWatched': 'May 16, 11:00 AM',
      'category': 'Daily Life ChitChat',
    },
    {
      'name': 'Sana Chaudhry',
      'avatar': 'assets/temp_img/temp2.png',
      'isLive': false,
      'viewers': '0',
      'watchDuration': '3.2 hours watched',
      'lastWatched': 'May 14, 4:20 PM',
      'category': 'Dance & Dance',
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchWatchedHistory();
  }

  void fetchWatchedHistory() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isLoading.value = false;
  }

  void joinLiveRoom(String name) {
    Get.snackbar(
      'Connecting to Live...',
      'Joining ${name}\'s live broadcast room now!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void visitProfile(String name) {
    Get.snackbar(
      'Profile Visit',
      'Opening ${name}\'s profile page...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
