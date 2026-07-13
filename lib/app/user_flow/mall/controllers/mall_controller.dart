import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/repo/frame/frame_repo.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

class MallController extends GetxController {
  MallController({EconomyRepo? economyRepo, FrameRepo? frameRepo})
    : _economyRepo = economyRepo ?? EconomyRepo(),
      _frameRepo = frameRepo ?? FrameRepo();

  final EconomyRepo _economyRepo;
  final FrameRepo _frameRepo;
  final isLoading = false.obs;

  final coinsBalance = 0.obs;

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
        'id': 'frame_loading',
        'name': 'Loading frames',
        'icon': kIconUserLevel,
        'price': 0,
        'duration': 'Please wait',
        'description': 'Fetching latest avatar frames from the mall.',
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
    final items = storeItems[tabId];
    selectedPreviewItem.value = items == null || items.isEmpty
        ? null
        : items.first;
  }

  Future<void> fetchMall() async {
    isLoading.value = true;
    try {
      await _fetchWalletBalance();
      await _fetchFrameShop();
      selectTab(selectedTab.value);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchWalletBalance() async {
    final wallet = await _economyRepo.getWalletBalances(isShowLoader: false);
    final walletData = wallet?['data'];
    if (walletData is Map) {
      coinsBalance.value = _toInt(walletData['coins']);
    }
  }

  Future<void> _fetchFrameShop() async {
    final shopResponse = await _frameRepo.getShopFrames(isShowLoader: false);
    final backpackResponse = await _frameRepo.getMyBackpack(
      isShowLoader: false,
    );
    final purchasedByFrameId = _purchasedFramesByFrameId(
      _extractList(backpackResponse?['data']),
    );
    final frames = <Map<String, dynamic>>[];

    for (final raw in _extractList(shopResponse?['data']).whereType<Map>()) {
      final frameId = raw['id']?.toString() ?? '';
      if (frameId.isEmpty) continue;

      final purchased = purchasedByFrameId[frameId];
      final durationDays = _toInt(raw['durationDays']);
      final category = raw['category']?.toString() ?? 'Premium';
      frames.add({
        'id': frameId,
        'name': raw['name']?.toString() ?? 'Avatar Frame',
        'icon': kIconUserLevel,
        'imageUrl': ApiImageUtils.normalize(raw['image']?.toString()),
        'price': _toInt(raw['price']),
        'duration': durationDays > 0 ? '$durationDays days' : 'Limited time',
        'durationDays': durationDays,
        'category': category,
        'status': raw['status']?.toString() ?? 'active',
        'description': 'Premium $category frame for your profile and rooms.',
        'isOwned': purchased != null,
        'isEquipped': purchased?['isEquipped'] == true,
        'backpackItemId': purchased?['id']?.toString(),
        'expiresAt': purchased?['expiresAt']?.toString(),
      });
    }

    if (frames.isEmpty) return;

    final merged = Map<int, List<Map<String, dynamic>>>.from(storeItems);
    merged[1] = frames;
    storeItems.assignAll(merged);
  }

  Future<void> buyItem(Map<String, dynamic> item) async {
    if (selectedTab.value == 1) {
      if (item['isOwned'] == true) {
        await equipFrame(item);
      } else {
        await buyFrame(item);
      }
      return;
    }

    await _buyLegacyMallItem(item);
  }

  Future<void> buyFrame(Map<String, dynamic> item) async {
    final price = _toInt(item['price']);
    final name = item['name']?.toString() ?? 'Avatar Frame';

    if (coinsBalance.value < price) {
      _showInsufficientCoinsDialog(price: price, itemName: name);
      return;
    }

    final response = await _frameRepo.buyFrame(
      frameId: item['id'].toString(),
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      Get.snackbar('Mall', 'Could not purchase "$name".');
      return;
    }

    final data = response?['data'];
    final remaining = data is Map ? data['remainingCoins'] : null;
    coinsBalance.value = remaining == null
        ? coinsBalance.value - price
        : _toInt(remaining);

    await _fetchFrameShop();
    selectTab(1);
    _showPurchaseSuccessDialog(name: name, price: price);
  }

  Future<void> equipFrame(Map<String, dynamic> item) async {
    final backpackItemId = item['backpackItemId']?.toString();
    if (backpackItemId == null || backpackItemId.isEmpty) {
      Get.snackbar('Mall', 'Purchase this frame before equipping it.');
      return;
    }

    final shouldEquip = item['isEquipped'] != true;
    final response = await _frameRepo.equipFrame(
      backpackItemId: backpackItemId,
      equip: shouldEquip,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      Get.snackbar('Mall', 'Could not update this frame.');
      return;
    }

    await _fetchFrameShop();
    selectTab(1);
    Get.snackbar(
      'Mall',
      shouldEquip ? 'Frame equipped successfully.' : 'Frame removed.',
    );
  }

  Future<void> _buyLegacyMallItem(Map<String, dynamic> item) async {
    final price = _toInt(item['price']);
    final name = item['name']?.toString() ?? 'Mall item';

    if (coinsBalance.value < price) {
      _showInsufficientCoinsDialog(price: price, itemName: name);
      return;
    }

    final response = await _economyRepo.buyMallItem(
      itemId: item['id'].toString(),
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      Get.snackbar('Mall', 'Could not purchase "$name".');
      return;
    }

    coinsBalance.value -= price;
    _showPurchaseSuccessDialog(name: name, price: price);
  }

  void _showPurchaseSuccessDialog({required String name, required int price}) {
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
          TextButton(onPressed: () => Get.back(), child: const Text('Great!')),
        ],
      ),
    );
  }

  void _showInsufficientCoinsDialog({
    required int price,
    required String itemName,
  }) {
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
          'You need ${price - coinsBalance.value} more Coins to purchase "$itemName". Would you like to recharge?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF761B65),
            ),
            onPressed: () {
              Get.back();
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

  Map<String, Map<String, dynamic>> _purchasedFramesByFrameId(List items) {
    final result = <String, Map<String, dynamic>>{};
    for (final raw in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final frameDetails = item['frameDetails'];
      final frameId =
          item['itemId']?.toString() ??
          (frameDetails is Map ? frameDetails['id']?.toString() : null);
      if (frameId != null && frameId.isNotEmpty) {
        result[frameId] = item;
      }
    }
    return result;
  }

  List _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final nested = value['items'] ?? value['frames'] ?? value['data'];
      if (nested is List) return nested;
    }
    return const [];
  }

  bool _isSuccess(Map<String, dynamic>? response) {
    final code = response?['statusCode'];
    if (code == 1 || code == 200 || code == 201) return true;
    final data = response?['data'];
    return data is Map && data['success'] == true;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
