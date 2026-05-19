import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/app/user_flow/backpack/controllers/backpack_controller.dart';

class MallController extends GetxController {
  // Current user balance
  final coinsBalance = 12450.obs;

  final List<Map<String, dynamic>> tabs = [
    {'id': 1, 'name': 'Avatar Frames'},
    {'id': 2, 'name': 'Entrance Effects'},
    {'id': 3, 'name': 'Chat Bubbles'},
  ];

  final selectedTab = 1.obs;
  final selectedPreviewItem = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    // Default preview item
    selectedPreviewItem.value = storeItems[1]?[0];
  }

  final Map<int, List<Map<String, dynamic>>> storeItems = {
    1: [
      {'id': 'frame_gold', 'name': 'Golden Crown', 'icon': kIconUserLevel, 'price': 500, 'duration': '7 days', 'description': 'Look like royalty with this gleaming golden crown frame.'},
      {'id': 'frame_neon', 'name': 'Neon Border', 'icon': kIconVisitor, 'price': 1200, 'duration': '30 days', 'description': 'A vibrant neon purple-pink border that pulses with energy.'},
      {'id': 'frame_vip', 'name': 'VVIP Frame', 'icon': kIconSVIP, 'price': 3000, 'duration': '30 days', 'description': 'Strictly for VIP high-rollers. Showcases prestige.'},
    ],
    2: [
      {'id': 'effect_dragon', 'name': 'Dragon Arrival', 'icon': kIconActivity, 'price': 2000, 'duration': '30 days', 'description': 'A massive fire-breathing dragon flies across the screen when you join.'},
      {'id': 'effect_star', 'name': 'Star Shower', 'icon': kIconAward, 'price': 800, 'duration': '7 days', 'description': 'A shower of falling stars bursts around you upon entry.'},
    ],
    3: [
      {'id': 'bubble_ocean', 'name': 'Ocean Bubble', 'icon': kIconPointerCenter, 'price': 300, 'duration': '7 days', 'description': 'A cooling light-blue bubble theme for all room text chats.'},
      {'id': 'bubble_love', 'name': 'Love Heart', 'icon': kIconHeart, 'price': 600, 'duration': '7 days', 'description': 'Express yourself with a beautiful pink heart-adorned bubble.'},
    ],
  };

  void selectTab(int tabId) {
    selectedTab.value = tabId;
    if (storeItems[tabId] != null && storeItems[tabId]!.isNotEmpty) {
      selectedPreviewItem.value = storeItems[tabId]![0];
    } else {
      selectedPreviewItem.value = null;
    }
  }

  void buyItem(Map<String, dynamic> item) {
    final price = item['price'] as int;
    final name = item['name'] as String;

    if (coinsBalance.value >= price) {
      // Deduct balance
      coinsBalance.value -= price;

      // Dynamically add to backpack if BackpackController is loaded
      try {
        if (Get.isRegistered<BackpackController>()) {
          final backpack = Get.find<BackpackController>();
          final catId = selectedTab.value;
          final currentList = backpack.mockItems[catId] ?? [];
          
          // Check if item already exists in backpack
          final existingIndex = currentList.indexWhere((x) => x['name'] == name);
          if (existingIndex != -1) {
            final existing = currentList[existingIndex];
            currentList[existingIndex] = {
              'name': name,
              'icon': item['icon'],
              'quantity': (existing['quantity'] as int) + 1,
            };
          } else {
            currentList.add({
              'name': name,
              'icon': item['icon'],
              'quantity': 1,
            });
          }
          backpack.mockItems[catId] = List.from(currentList);
        }
      } catch (e) {
        // BackpackController not loaded, ignore
      }

      Get.dialog(
        AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Purchase Successful'),
            ],
          ),
          content: Text('You have successfully purchased "$name" for $price Coins!\nThe item has been added to your Backpack.'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Great!'),
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
          content: Text('You need ${price - coinsBalance.value} more Coins to purchase "$name". Would you like to recharge?'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF761B65)),
              onPressed: () {
                Get.back();
                // Route to recharge
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
