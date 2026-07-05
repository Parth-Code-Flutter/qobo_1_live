import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/app/user_flow/backpack/controllers/backpack_controller.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';

class MallController extends GetxController {
  MallController({EconomyRepo? economyRepo})
    : _economyRepo = economyRepo ?? EconomyRepo();

  final EconomyRepo _economyRepo;
  final isLoading = false.obs;

  // Current user balance
  final coinsBalance = 12450.obs;

  final tabs = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Avatar Frames'},
    {'id': 2, 'name': 'Entrance Effects'},
    {'id': 3, 'name': 'Chat Bubbles'},
  ].obs;

  final selectedTab = 1.obs;
  final selectedPreviewItem = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    selectedPreviewItem.value = storeItems[1]?[0];
    fetchMall();
  }

  final RxMap<int, List<Map<String, dynamic>>>
  storeItems = <int, List<Map<String, dynamic>>>{
    1: [
      {
        'id': 'frame_gold',
        'name': 'Golden Crown',
        'icon': kIconUserLevel,
        'price': 500,
        'duration': '7 days',
        'description':
            'Look like royalty with this gleaming golden crown frame.',
      },
      {
        'id': 'frame_neon',
        'name': 'Neon Border',
        'icon': kIconVisitor,
        'price': 1200,
        'duration': '30 days',
        'description':
            'A vibrant neon purple-pink border that pulses with energy.',
      },
      {
        'id': 'frame_vip',
        'name': 'VVIP Frame',
        'icon': kIconSVIP,
        'price': 3000,
        'duration': '30 days',
        'description': 'Strictly for VIP high-rollers. Showcases prestige.',
      },
    ],
    2: [
      {
        'id': 'effect_dragon',
        'name': 'Dragon Arrival',
        'icon': kIconActivity,
        'price': 2000,
        'duration': '30 days',
        'description':
            'A massive fire-breathing dragon flies across the screen when you join.',
      },
      {
        'id': 'effect_star',
        'name': 'Star Shower',
        'icon': kIconAward,
        'price': 800,
        'duration': '7 days',
        'description':
            'A shower of falling stars bursts around you upon entry.',
      },
    ],
    3: [
      {
        'id': 'bubble_ocean',
        'name': 'Ocean Bubble',
        'icon': kIconPointerCenter,
        'price': 300,
        'duration': '7 days',
        'description':
            'A cooling light-blue bubble theme for all room text chats.',
      },
      {
        'id': 'bubble_love',
        'name': 'Love Heart',
        'icon': kIconHeart,
        'price': 600,
        'duration': '7 days',
        'description':
            'Express yourself with a beautiful pink heart-adorned bubble.',
      },
    ],
  }.obs;

  void selectTab(int tabId) {
    selectedTab.value = tabId;
    if (storeItems[tabId] != null && storeItems[tabId]!.isNotEmpty) {
      selectedPreviewItem.value = storeItems[tabId]![0];
    } else {
      selectedPreviewItem.value = null;
    }
  }

  Future<void> fetchMall() async {
    isLoading.value = true;
    try {
      final wallet = await _economyRepo.getWalletBalances(isShowLoader: false);
      final walletData = wallet?['data'];
      if (walletData is Map) {
        coinsBalance.value = _toInt(walletData['coins']);
      }

      final response = await _economyRepo.getMallItems(isShowLoader: false);
      final data = response?['data'];
      final list = data is Map ? data['items'] : data;
      if (list is List) {
        final grouped = <int, List<Map<String, dynamic>>>{};
        for (final raw in list.whereType<Map>()) {
          final categoryId = _categoryId(raw);
          grouped.putIfAbsent(categoryId, () => <Map<String, dynamic>>[]).add({
            'id': raw['id']?.toString() ?? '',
            'name': raw['name']?.toString() ?? '',
            'icon': _iconForCategory(categoryId),
            'iconUrl':
                raw['iconUrl']?.toString() ??
                raw['thumbnailUrl']?.toString() ??
                '',
            'price': _toInt(raw['price'] ?? raw['cost']),
            'duration':
                raw['duration']?.toString() ??
                '${_toInt(raw['durationDays'])} days',
            'description': raw['description']?.toString() ?? '',
          });
        }
        if (grouped.isNotEmpty) {
          storeItems.assignAll(grouped);
          final selectedItems = storeItems[selectedTab.value];
          selectedPreviewItem.value =
              selectedItems == null || selectedItems.isEmpty
              ? null
              : selectedItems.first;
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> buyItem(Map<String, dynamic> item) async {
    final price = _toInt(item['price']);
    final name = item['name'] as String;

    if (coinsBalance.value >= price) {
      final response = await _economyRepo.buyMallItem(
        itemId: item['id'].toString(),
        isShowLoader: true,
      );
      if (response == null || response['statusCode'] == 0) {
        Get.snackbar('Mall', 'Could not purchase "$name".');
        return;
      }

      // Deduct balance
      coinsBalance.value -= price;

      // Dynamically add to backpack if BackpackController is loaded
      try {
        if (Get.isRegistered<BackpackController>()) {
          final backpack = Get.find<BackpackController>();
          final catId = selectedTab.value;
          final currentList = backpack.mockItems[catId] ?? [];

          // Check if item already exists in backpack
          final existingIndex = currentList.indexWhere(
            (x) => x['name'] == name,
          );
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
          content: Text(
            'You have successfully purchased "$name" for $price Coins!\nThe item has been added to your Backpack.',
          ),
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
          content: Text(
            'You need ${price - coinsBalance.value} more Coins to purchase "$name". Would you like to recharge?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF761B65),
              ),
              onPressed: () {
                Get.back();
                // Route to recharge
                Get.snackbar('Redirecting', 'Opening recharge panel...');
              },
              child: const Text(
                'Recharge Now',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }
  }

  int _categoryId(Map raw) {
    final categoryId = _toInt(raw['categoryId']);
    if (categoryId > 0) return categoryId;
    final type = (raw['type'] ?? raw['category'] ?? '')
        .toString()
        .toLowerCase();
    if (type.contains('frame')) return 1;
    if (type.contains('effect') || type.contains('entrance')) return 2;
    if (type.contains('bubble') || type.contains('chat')) return 3;
    return selectedTab.value;
  }

  String _iconForCategory(int categoryId) {
    switch (categoryId) {
      case 1:
        return kIconUserLevel;
      case 2:
        return kIconActivity;
      case 3:
        return kIconPointerCenter;
      default:
        return kIconAward;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
