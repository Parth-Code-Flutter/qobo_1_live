import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/repo/frame/frame_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/app/user_flow/vip_store/widgets/vip_purchase_success_dialog.dart';

/// VIP Frames shop (Profile → VIP Frames).
///
/// Buys via `POST /api/frame/buy`. Backend auto-equips VIP frames —
/// no manual equip/unequip on mobile.
class VipStoreController extends GetxController {
  VipStoreController({
    FrameRepo? frameRepo,
    EconomyRepo? economyRepo,
  })  : _frameRepo = frameRepo ?? FrameRepo(),
        _economyRepo = economyRepo ?? EconomyRepo();

  final FrameRepo _frameRepo;
  final EconomyRepo _economyRepo;

  final isLoading = false.obs;
  final isPurchasing = false.obs;
  final userCoins = 0.obs;
  final loadError = ''.obs;
  final vipFrames = <Map<String, dynamic>>[].obs;

  String get formattedCoins {
    final digits = userCoins.value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
    }
    return buffer.toString();
  }

  @override
  void onInit() {
    super.onInit();
    loadStore();
  }

  Future<void> loadStore({bool showLoader = false}) async {
    isLoading.value = true;
    loadError.value = '';
    try {
      await Future.wait([
        _fetchWalletBalance(showLoader: showLoader),
        _fetchVipFrames(showLoader: showLoader),
      ]);
    } catch (_) {
      if (vipFrames.isEmpty) {
        loadError.value = 'Network error. Pull to refresh and try again.';
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchWalletBalance({bool showLoader = false}) async {
    final wallet = await _economyRepo.getWalletBalances(
      isShowLoader: showLoader,
    );
    final data = wallet?['data'];
    if (data is Map) {
      userCoins.value = _toInt(data['coins']);
    }
  }

  Future<void> _fetchVipFrames({bool showLoader = false}) async {
    final shopResponse = await _frameRepo.getShopFrames(
      isShowLoader: showLoader,
    );
    if (shopResponse == null) {
      loadError.value = 'Unable to reach frame shop. Please try again.';
      return;
    }
    if (!_isSuccess(shopResponse) && _extractList(shopResponse['data']).isEmpty) {
      loadError.value =
          shopResponse['message']?.toString() ?? 'Could not load VIP frames.';
      return;
    }

    final backpackResponse = await _frameRepo.getMyBackpack(
      isShowLoader: false,
    );
    final ownedByFrameId = _ownedByFrameId(
      _extractList(backpackResponse?['data']),
    );
    final frames = <Map<String, dynamic>>[];

    for (final raw in _extractList(shopResponse['data']).whereType<Map>()) {
      final category = raw['category']?.toString().trim() ?? '';
      if (!_isVipCategory(category)) continue;

      final status = raw['status']?.toString().toLowerCase() ?? 'active';
      if (status.isNotEmpty && status != 'active') continue;

      final frameId = raw['id']?.toString().trim() ?? '';
      if (frameId.isEmpty) continue;

      final owned = ownedByFrameId[frameId];
      final durationDays = _toInt(raw['durationDays'] ?? raw['duration_days']);
      final animationUrl = ApiImageUtils.normalize(
        _firstText([
          raw['animationUrl'],
          raw['animation_url'],
          raw['svgaUrl'],
          raw['svga_url'],
        ]),
      );
      final imageUrl = ApiImageUtils.normalize(
        _firstText([
          raw['previewUrl'],
          raw['imageUrl'],
          raw['image'],
          raw['iconUrl'],
        ]),
      );
      final mediaCandidate = animationUrl ?? imageUrl ?? '';
      final isSvga = mediaCandidate.toLowerCase().contains('.svga');
      final descRaw = raw['description']?.toString().trim() ?? '';

      frames.add({
        'id': frameId,
        'name': raw['name']?.toString().trim().isNotEmpty == true
            ? raw['name'].toString().trim()
            : 'VIP Frame',
        'desc': descRaw.isNotEmpty
            ? descRaw
            : 'Auto-equipped VIP frame for your profile and room entrance.',
        'price': _toInt(raw['price']),
        'duration': durationDays > 0 ? '$durationDays Days' : 'Limited time',
        'category': category,
        'tag': 'VIP',
        'svgaUrl': isSvga ? mediaCandidate : (animationUrl ?? ''),
        'imageUrl': isSvga
            ? (imageUrl != null && imageUrl != mediaCandidate ? imageUrl : '')
            : (imageUrl ?? ''),
        'isOwned': owned != null,
        'isEquipped': owned?['isEquipped'] == true,
        'expiresAt': owned?['expiresAt']?.toString() ?? '',
      });
    }

    vipFrames.assignAll(frames);
    if (frames.isEmpty) {
      loadError.value = '';
    }
  }

  Future<void> purchaseFrame(Map<String, dynamic> item) async {
    if (isPurchasing.value) return;
    if (item['isOwned'] == true) {
      Get.snackbar(
        'VIP Frames',
        'You already own "${item['name']}". VIP frames equip automatically.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }

    final price = _toInt(item['price']);
    final name = item['name']?.toString() ?? 'VIP Frame';
    final frameId = item['id']?.toString().trim() ?? '';
    if (frameId.isEmpty) return;

    if (userCoins.value < price) {
      final need = price - userCoins.value;
      final goWallet = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Insufficient Coins'),
          content: Text(
            'You need $need more coins to buy "$name". Recharge now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Recharge'),
            ),
          ],
        ),
      );
      if (goWallet == true) {
        await Get.to(() => const WalletView(), binding: WalletBinding());
        await _fetchWalletBalance();
      }
      return;
    }

    isPurchasing.value = true;
    try {
      final response = await _frameRepo.buyFrame(
        frameId: frameId,
        isShowLoader: true,
      );
      if (!_isSuccess(response)) {
        Get.snackbar(
          'VIP Frames',
          response?['message']?.toString() ?? 'Could not purchase "$name".',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent,
          colorText: kColorWhite,
        );
        return;
      }

      final data = response?['data'];
      if (data is Map && data['remainingCoins'] != null) {
        userCoins.value = _toInt(data['remainingCoins']);
      } else {
        userCoins.value = (userCoins.value - price).clamp(0, 1 << 30);
      }

      // Backend auto-equips VIP frames — refresh profile so avatar updates.
      if (Get.isRegistered<UserSessionController>()) {
        await Get.find<UserSessionController>().refreshProfileFromApi();
      }
      await loadStore();

      await VipPurchaseSuccessDialog.show(
        name: name,
        imageUrl: item['imageUrl']?.toString().trim() ?? '',
        svgaUrl: item['svgaUrl']?.toString().trim() ?? '',
        durationLabel: item['duration']?.toString(),
      );
    } finally {
      isPurchasing.value = false;
    }
  }

  void openBackpack() => Get.toNamed(Routes.BACKPACK);

  Map<String, Map<String, dynamic>> _ownedByFrameId(List items) {
    final result = <String, Map<String, dynamic>>{};
    for (final raw in items.whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final details = item['frameDetails'] ?? item['frame_details'];
      final frame = details is Map
          ? Map<String, dynamic>.from(details)
          : const <String, dynamic>{};
      final frameId =
          frame['id']?.toString() ??
          item['itemId']?.toString() ??
          item['item_id']?.toString() ??
          '';
      if (frameId.isEmpty) continue;
      result[frameId] = item;
    }
    return result;
  }

  List _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      final nested =
          data['frames'] ?? data['items'] ?? data['list'] ?? data['data'];
      if (nested is List) return nested;
    }
    return const [];
  }

  static bool _isVipCategory(String category) =>
      category.trim().toLowerCase() == 'vip';

  bool _isSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    if (response['success'] == true) return true;
    final code = response['statusCode'];
    return code == 1 ||
        code == 200 ||
        code == 201 ||
        code?.toString() == '1' ||
        code?.toString() == '200' ||
        code?.toString() == '201';
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String? _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }
}
