import 'package:get/get.dart';

class EntrancePattiController extends GetxController {
  final isLoading = false.obs;

  // Currently equipped Patti ID
  final equippedPattiId = 'gold_patti'.obs;

  // Mock list of Entrance Pattis (Premium announcement banners)
  final pattiItems = <Map<String, dynamic>>[
    {
      'id': 'gold_patti',
      'title': 'Royal Golden Patti',
      'desc': 'Elegant gold borders with shining rays. Unlocked at Level 20.',
      'type': 'Level Reward',
      'badge': 'Active',
      'isUnlocked': true,
      'colors': [0xFFFFDF00, 0xFFD4AF37],
    },
    {
      'id': 'emerald_patti',
      'title': 'Emerald Knight Patti',
      'desc': 'Deep royal green wing guards. Unlocked via Knight noble rank.',
      'type': 'Aristocracy',
      'badge': 'Equip',
      'isUnlocked': true,
      'colors': [0xFF00FF87, 0xFF60EFFF],
    },
    {
      'id': 'cyber_patti',
      'title': 'Cyber Neon Patti',
      'desc': 'Pulsating futuristic neon bubble. Purchase in VIP Store.',
      'type': 'VIP Store',
      'badge': 'Locked',
      'isUnlocked': false,
      'colors': [0xFFF50057, 0xFF9C27B0],
    },
    {
      'id': 'matrix_patti',
      'title': 'Glitch Matrix Patti',
      'desc': 'Digital falling cybercode pattern. Exclusive SVIP privilege.',
      'type': 'SVIP Special',
      'badge': 'Locked',
      'isUnlocked': false,
      'colors': [0xFF1F4037, 0xFF99F2C8],
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchPattis();
  }

  void fetchPattis() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isLoading.value = false;
  }

  void equipPatti(String id) {
    equippedPattiId.value = id;
    Get.snackbar(
      'Patti Equipped!',
      'Your entrance nameplate has been successfully updated!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
