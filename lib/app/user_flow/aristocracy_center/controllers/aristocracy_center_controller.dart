import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AristocracyCenterController extends GetxController {
  final selectedRankIndex = 0.obs;
  final coinsBalance = 12450.obs;
  
  // Track currently active rank
  final activeRankName = RxnString();

  final ranks = <Map<String, dynamic>>[
    {
      'name': 'Knight',
      'icon': 'assets/icons/badge_icon.svg',
      'priceVal': 1000,
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
      'priceVal': 5000,
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
      'priceVal': 20000,
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
      'priceVal': 100000,
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
    final rank = ranks.firstWhere((r) => r['name'] == rankName);
    final price = rank['priceVal'] as int;

    if (coinsBalance.value >= price) {
      coinsBalance.value -= price;
      activeRankName.value = rankName;
      Get.dialog(
        AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.shield_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Text('$rankName Unlocked!'),
            ],
          ),
          content: Text('Welcome to the nobility! You have successfully subscribed to the "$rankName" rank.\nEnjoy your premium privileges immediately.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );
    } else {
      Get.dialog(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Insufficient Coins'),
            ],
          ),
          content: Text('You need ${price - coinsBalance.value} more Coins to purchase the "$rankName" subscription. Would you like to recharge?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF761B65)),
              onPressed: () {
                Get.back();
                Get.snackbar('Redirecting', 'Opening recharge panel...');
              },
              child: const Text('Recharge Now', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }
}
