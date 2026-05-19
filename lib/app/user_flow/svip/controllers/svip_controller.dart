import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SvipController extends GetxController {
  final isSvipActive = false.obs;
  final coinsBalance = 12450.obs;

  final List<Map<String, dynamic>> privileges = [
    {
      'title': 'SVIP Badge', 
      'desc': 'Gold crown emblem on your profile name.',
      'icon': Icons.workspace_premium_rounded,
      'color': Color(0xFFFFD700),
    },
    {
      'title': 'Special Entrance', 
      'desc': 'A luxurious sports car animation when joining a stream.',
      'icon': Icons.sports_kabaddi_rounded,
      'color': Color(0xFFFF4500),
    },
    {
      'title': 'Kick & Mute Immunity', 
      'desc': 'Never get kicked or muted by room moderators.',
      'icon': Icons.security_rounded,
      'color': Color(0xFF1E90FF),
    },
    {
      'title': 'VVIP Chat Style', 
      'desc': 'Golden text messages and high-contrast bubble layout.',
      'icon': Icons.chat_bubble_rounded,
      'color': Color(0xFFBA55D3),
    },
    {
      'title': 'Custom Backgrounds', 
      'desc': 'Upload custom profile poster backgrounds.',
      'icon': Icons.wallpaper_rounded,
      'color': Color(0xFF3CB371),
    },
    {
      'title': 'VIP Support Line', 
      'desc': 'Direct, prioritized customer support channel.',
      'icon': Icons.support_agent_rounded,
      'color': Color(0xFFFF8C00),
    },
  ];

  final List<Map<String, dynamic>> plans = [
    {'id': 1, 'duration': '1 Month', 'price': 5000, 'saving': 'Standard'},
    {'id': 2, 'duration': '3 Months', 'price': 14000, 'saving': 'Save 7%'},
    {'id': 3, 'duration': '12 Months', 'price': 50000, 'saving': 'Save 17%'},
  ];

  final selectedPlan = 1.obs;

  void selectPlan(int planId) {
    selectedPlan.value = planId;
  }

  void subscribe() {
    final activePlan = plans.firstWhere((p) => p['id'] == selectedPlan.value);
    final price = activePlan['price'] as int;

    if (coinsBalance.value >= price) {
      coinsBalance.value -= price;
      isSvipActive.value = true;
      Get.dialog(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFFFFD700)),
              SizedBox(width: 8),
              Text('SVIP Activated!'),
            ],
          ),
          content: Text('Congratulations! You are now a Supreme VIP member.\nYour privileges are active immediately.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Enter Hub'),
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
          content: Text('You need ${price - coinsBalance.value} more Coins to open SVIP. Would you like to recharge now?'),
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
