import 'package:get/get.dart';

class AristocracyCenterController extends GetxController {
  final selectedRankIndex = 0.obs;
  
  final ranks = <Map<String, dynamic>>[
    {
      'name': 'Knight',
      'icon': 'assets/icons/badge_icon.svg',
      'price': '1,000 Coins / Month',
      'privileges': [
        'Exclusive Knight entry effect',
        'Special Knight badge next to username',
        'Knight exclusive text color in live chat',
        '1.2x EXP booster on sending gifts',
      ],
      'gradient': [0xFF616161, 0xFF9BC5C3], // Silver themed
    },
    {
      'name': 'Viscount',
      'icon': 'assets/icons/badge_icon.svg',
      'price': '5,000 Coins / Month',
      'privileges': [
        'Premium entry car animation',
        'Special Viscount badge next to username',
        'Viscount chat bubble theme',
        '1.5x EXP booster on sending gifts',
        'Mute immunity in public rooms',
      ],
      'gradient': [0xFFB37A30, 0xFFE6C875], // Bronze/Gold themed
    },
    {
      'name': 'Duke',
      'icon': 'assets/icons/medal_icon.svg',
      'price': '20,000 Coins / Month',
      'privileges': [
        'Royal Dragon entry animation',
        'Duke VIP badge and dynamic profile frame',
        'Access to Duke-only premium virtual rooms',
        '2.0x EXP booster on sending gifts',
        'Kick immunity in public rooms',
        'Custom microphone design inside rooms',
      ],
      'gradient': [0xFF5C2D84, 0xFF7E4EA8], // Royal Purple themed
    },
    {
      'name': 'King',
      'icon': 'assets/icons/medal_icon.svg',
      'price': '100,000 Coins / Month',
      'privileges': [
        'Golden Phoenix full screen entry animation',
        'Emperor Profile badge & Dynamic profile card',
        'Exclusive King Badge & dynamic profile frame',
        'King-only premium 3D virtual room background',
        '3.0x EXP booster on sending gifts',
        'Ultimate protection (immune to Kick, Ban, and Mute)',
        'Personal customer relationship manager',
      ],
      'gradient': [0xFFE65C00, 0xFFF9D423], // Fiery King Gold themed
    },
  ].obs;

  void selectRank(int index) {
    selectedRankIndex.value = index;
  }

  void purchaseNobleRank(String rankName) {
    Get.snackbar(
      'Purchase Initiated',
      'Processing subscription for the $rankName tier...',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
