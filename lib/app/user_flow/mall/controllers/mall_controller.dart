import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/background/background_repo.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/repo/frame/frame_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_giffy_dialog.dart';

class MallController extends GetxController {
  MallController({
    EconomyRepo? economyRepo,
    FrameRepo? frameRepo,
    BackgroundRepo? backgroundRepo,
  })
    : _economyRepo = economyRepo ?? EconomyRepo(),
      _frameRepo = frameRepo ?? FrameRepo(),
      _backgroundRepo = backgroundRepo ?? BackgroundRepo();

  final EconomyRepo _economyRepo;
  final FrameRepo _frameRepo;
  final BackgroundRepo _backgroundRepo;
  final isLoading = false.obs;

  final coinsBalance = 0.obs;

  final tabs = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Avatar Frames'},
    {'id': 2, 'name': 'Entrance Effects'},
    {'id': 3, 'name': 'Chat Bubbles'},
    {'id': 4, 'name': 'Profile Backgrounds'},
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
    4: [
      {
        'id': 'background_loading',
        'name': 'Loading backgrounds',
        'icon': kIconMall,
        'price': 0,
        'duration': 'Please wait',
        'description': 'Fetching latest profile backgrounds from the mall.',
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
      await _fetchBackgroundShop();
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
      // New frame-shop responses can return a network SVGA URL. Prefer the
      // explicit animation fields and keep `image` as a legacy fallback.
      final svgaUrl = ApiImageUtils.normalize(
        raw['animationUrl']?.toString() ??
            raw['animation_url']?.toString() ??
            raw['svgaUrl']?.toString() ??
            raw['svga_url']?.toString(),
      );
      final imageUrl = ApiImageUtils.normalize(
        raw['image']?.toString() ??
            raw['imageUrl']?.toString() ??
            raw['previewUrl']?.toString() ??
            raw['iconUrl']?.toString(),
      );
      frames.add({
        'id': frameId,
        'name': raw['name']?.toString() ?? 'Avatar Frame',
        'icon': kIconUserLevel,
        'svgaUrl': svgaUrl,
        'imageUrl': imageUrl,
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

  Future<void> _fetchBackgroundShop() async {
    final shopResponse = await _backgroundRepo.getShopBackgrounds(
      isShowLoader: false,
    );
    final backpackResponse = await _backgroundRepo.getMyBackpack(
      isShowLoader: false,
    );
    final purchasedByBackgroundId = _purchasedBackgroundsByBackgroundId(
      _extractList(backpackResponse?['data']),
    );
    final backgrounds = <Map<String, dynamic>>[];

    for (final raw in _extractList(shopResponse?['data']).whereType<Map>()) {
      final backgroundId = raw['id']?.toString() ?? '';
      if (backgroundId.isEmpty) continue;

      final status = raw['status']?.toString().toLowerCase() ?? 'active';
      if (status.isNotEmpty && status != 'active') continue;

      final purchased = purchasedByBackgroundId[backgroundId];
      final durationDays = _toInt(raw['durationDays'] ?? raw['duration_days']);
      final category = raw['category']?.toString() ?? 'Premium';
      final imageUrl = ApiImageUtils.normalize(
        raw['image']?.toString() ??
            raw['imageUrl']?.toString() ??
            raw['previewUrl']?.toString(),
      );
      final expiresAt = purchased?['expiresAt']?.toString() ?? '';
      final isExpired = _isExpired(expiresAt);
      final isOwned = purchased != null && !isExpired;
      final isEquipped =
          purchased?['isEquipped'] == true && isOwned && !isExpired;

      backgrounds.add({
        'id': backgroundId,
        'name': raw['name']?.toString() ?? 'Profile Background',
        'icon': kIconMall,
        'imageUrl': imageUrl,
        'price': _toInt(raw['price']),
        'duration': _backgroundValidityLabel(
          durationDays: durationDays,
          expiresAt: expiresAt,
          isOwned: purchased != null,
          isExpired: isExpired,
        ),
        'durationDays': durationDays,
        'category': category,
        'status': status.isEmpty ? 'active' : status,
        'description': 'Premium $category background for your profile.',
        'isOwned': isOwned,
        'isExpired': isExpired,
        'isEquipped': isEquipped,
        'backpackItemId': purchased?['id']?.toString(),
        'expiresAt': expiresAt,
      });
    }

    // Always replace the loading placeholder — even when the catalog is empty.
    final merged = Map<int, List<Map<String, dynamic>>>.from(storeItems);
    merged[4] = backgrounds.isEmpty
        ? [
            {
              'id': 'background_empty',
              'name': 'No backgrounds yet',
              'icon': kIconMall,
              'price': 0,
              'duration': 'Check back soon',
              'description':
                  'The profile background shop has no active items right now.',
              'isOwned': false,
              'isEquipped': false,
              'isPlaceholder': true,
            },
          ]
        : backgrounds;
    storeItems.assignAll(merged);
  }

  String _backgroundValidityLabel({
    required int durationDays,
    required String expiresAt,
    required bool isOwned,
    required bool isExpired,
  }) {
    if (isExpired) return 'Expired';
    if (isOwned && expiresAt.trim().isNotEmpty && expiresAt != 'null') {
      return 'Expires ${_formatExpiryDate(expiresAt)}';
    }
    if (durationDays > 0) return '$durationDays days';
    return 'Limited time';
  }

  String _formatExpiryDate(String raw) {
    final date = DateTime.tryParse(raw.trim());
    if (date == null) return raw;
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  bool _isExpired(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == 'null') return false;
    final date = DateTime.tryParse(text);
    if (date == null) return false;
    return date.toUtc().isBefore(DateTime.now().toUtc());
  }

  Future<void> buyItem(Map<String, dynamic> item) async {
    if (item['isPlaceholder'] == true) return;

    if (selectedTab.value == 1) {
      if (item['isOwned'] == true) {
        // Purchased frames are managed from Backpack so Mall remains focused
        // on discovering and purchasing new customizations.
        await Get.toNamed(Routes.BACKPACK);
      } else {
        await buyFrame(item);
      }
      return;
    }

    if (selectedTab.value == 4) {
      if (item['isExpired'] == true) {
        Get.snackbar(
          'Mall',
          'This background expired. Buy it again to use it.',
        );
        return;
      }
      if (item['isOwned'] == true) {
        await Get.toNamed(Routes.BACKPACK);
      } else {
        await buyBackground(item);
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
    await _showPurchaseSuccessDialog(name: name, price: price);
  }

  Future<void> buyBackground(Map<String, dynamic> item) async {
    final price = _toInt(item['price']);
    final name = item['name']?.toString() ?? 'Profile Background';

    if (coinsBalance.value < price) {
      _showInsufficientCoinsDialog(price: price, itemName: name);
      return;
    }

    final response = await _backgroundRepo.buyBackground(
      backgroundId: item['id'].toString(),
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

    await _fetchBackgroundShop();
    selectTab(4);
    if (Get.isRegistered<UserSessionController>()) {
      await Get.find<UserSessionController>().refreshProfileFromApi();
    }
    await _showPurchaseSuccessDialog(name: name, price: price);
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
    await _showPurchaseSuccessDialog(name: name, price: price);
  }

  Future<void> _showPurchaseSuccessDialog({
    required String name,
    required int price,
  }) async {
    final context = Get.context;
    if (context == null) return;

    await CommonGiffyDialog.showSuccess(
      context,
      title: 'Purchase Complete!',
      subtitle:
          '"$name" is now yours\n'
          '$price Coins paid • Added to your Backpack',
      buttonText: 'Awesome!',
      gifAssetPath: kGifCongratulation,
      barrierDismissible: false,
      // The common dialog closes itself before invoking this callback.
      onPressed: () {},
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

  Map<String, Map<String, dynamic>> _purchasedBackgroundsByBackgroundId(
    List items,
  ) {
    final result = <String, Map<String, dynamic>>{};
    for (final raw in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final itemType = item['itemType']?.toString().toUpperCase() ?? '';
      if (itemType.isNotEmpty &&
          itemType != 'PROFILE_BACKGROUND' &&
          itemType != 'BACKGROUND') {
        continue;
      }
      final backgroundDetails =
          item['backgroundDetails'] ?? item['background_details'];
      final backgroundId =
          item['itemId']?.toString() ??
          item['item_id']?.toString() ??
          (backgroundDetails is Map
              ? backgroundDetails['id']?.toString()
              : null);
      if (backgroundId != null && backgroundId.isNotEmpty) {
        result[backgroundId] = item;
      }
    }
    return result;
  }

  List _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final nested =
          value['items'] ??
          value['backgrounds'] ??
          value['frames'] ??
          value['data'] ??
          value['list'];
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
