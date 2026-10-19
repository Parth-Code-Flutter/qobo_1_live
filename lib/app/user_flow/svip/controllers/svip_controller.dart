import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class SvipController extends GetxController {
  SvipController({
    EconomyRepo? economyRepo,
    AuthRepo? authRepo,
    UserRepo? userRepo,
  }) : _economyRepo = economyRepo ?? EconomyRepo(),
       _authRepo = authRepo ?? AuthRepo(),
       _userRepo = userRepo ?? UserRepo();

  final EconomyRepo _economyRepo;
  final AuthRepo _authRepo;
  final UserRepo _userRepo;
  final isLoading = false.obs;
  final isBuying = false.obs;
  final isSvipActive = false.obs;
  final svipExpiresAt = Rxn<DateTime>();

  /// "Expires in N days" label; empty when expiry is unknown.
  String get svipExpiryLabel {
    final expires = svipExpiresAt.value;
    if (expires == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Expires: ${expires.day} ${months[expires.month - 1]} ${expires.year}';
  }

  final coinsBalance = 0.obs;
  final packageError = ''.obs;

  final privileges = <Map<String, dynamic>>[].obs;

  static const List<Map<String, dynamic>> _fallbackPrivileges = [
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

  final plans = <Map<String, dynamic>>[].obs;

  final selectedPlan = RxnString();

  @override
  void onInit() {
    super.onInit();
    privileges.assignAll(_fallbackPrivileges);
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    isLoading.value = true;
    packageError.value = '';
    await _restoreCachedSvip();
    await _loadSvipFromProfile();
    try {
      await _loadPurchasedCoins();
      final response = await _economyRepo.getVipPackages(isShowLoader: false);
      final rawData = response?['data'];
      if (rawData is Map) {
        _applySvipStatus(Map<String, dynamic>.from(rawData));
      }
      final data = _packageList(rawData);
      if (isEconomyApiSuccess(response) && data != null) {
        plans.assignAll(
          data
              .whereType<Map>()
              .map((plan) {
                final id = plan['id']?.toString() ?? '';
                final durationDays = _toInt(plan['durationDays']);
                final status = plan['status']?.toString().toLowerCase() ?? '';
                return <String, dynamic>{
                  'id': id,
                  'name': plan['name']?.toString() ?? 'SVIP',
                  'duration': durationDays > 0
                      ? '$durationDays Days'
                      : plan['name']?.toString() ?? 'SVIP',
                  'durationDays': durationDays,
                  'price': _toInt(plan['price']),
                  'saving': _packageBadge(plan),
                  'benefits': _benefitLines(plan['benefits']),
                  'status': status,
                };
              })
              .where(
                (plan) =>
                    plan['id'].toString().isNotEmpty &&
                    (plan['status'].toString().isEmpty ||
                        plan['status'] == 'active'),
              ),
        );
        if (plans.isNotEmpty) {
          final current = selectedPlan.value;
          final stillThere = plans.any(
            (plan) => plan['id'].toString() == current,
          );
          selectedPlan.value = stillThere
              ? current
              : plans.first['id'].toString();
        } else {
          selectedPlan.value = null;
          packageError.value = 'No active SVIP packages are available.';
        }
      } else {
        plans.clear();
        selectedPlan.value = null;
        packageError.value =
            response?['message']?.toString() ?? 'Unable to load SVIP packages.';
      }
      _syncPrivileges();
      await _loadBackpackVip();
    } catch (_) {
      packageError.value = 'Unable to load SVIP packages.';
    } finally {
      isLoading.value = false;
    }
  }

  void selectPlan(dynamic planId) {
    selectedPlan.value = planId?.toString();
    _syncPrivileges();
  }

  Future<void> subscribe() async {
    if (isBuying.value) return;

    final selectedId = selectedPlan.value;
    final activePlan = selectedId == null ? null : _selectedPlanMap(selectedId);
    if (activePlan == null) {
      _showToast('SVIP', 'Please select a membership package.', isError: true);
      return;
    }

    final price = _toInt(activePlan['price']);

    if (coinsBalance.value >= price) {
      await _buySelectedPackage(activePlan, price);
    } else {
      CommonAppDialog.showGet(
        title: 'Insufficient Coins',
        message:
            'You need ${price - coinsBalance.value} more coins to activate this SVIP plan.',
        icon: Icons.warning_amber_rounded,
        iconAccent: AdminAgencyUi.goldDeep,
        actions: [
          const CommonAppDialogAction(label: 'Cancel'),
          CommonAppDialogAction(
            label: 'Recharge Now',
            isPrimary: true,
            onPressed: () {
              unawaited(_openWalletToRecharge());
            },
          ),
        ],
      );
    }
  }

  Future<void> _buySelectedPackage(
    Map<String, dynamic> activePlan,
    int price,
  ) async {
    isBuying.value = true;
    try {
      final response = await _economyRepo.buyVip(
        packageId: activePlan['id'].toString(),
        isShowLoader: true,
      );
      if (response?['statusCode'] != 1 && response?['success'] != true) {
        _showToast(
          'SVIP',
          response?['message']?.toString() ??
              'Could not activate this SVIP package.',
          isError: true,
        );
        return;
      }

      _applyWalletBalanceFromPurchase(response, price);
      final purchaseData = response?['data'];
      final expiresFromApi = purchaseData is Map
          ? _parseDate(purchaseData['expiresAt'] ?? purchaseData['expires_at'])
          : null;
      final durationDays = _toInt(activePlan['durationDays']);
      final expires =
          expiresFromApi ??
          DateTime.now().add(
            Duration(days: durationDays > 0 ? durationDays : 30),
          );
      _setActive(expires);
      await _cacheSvipExpiry(expires);
      await _loadPurchasedCoins();
      await _loadBackpackVip();
      CommonAppDialog.showGet(
        title: 'SVIP Activated!',
        message:
            'Congratulations! Your ${activePlan['name']} membership is active immediately.',
        icon: Icons.stars_rounded,
        iconAccent: AdminAgencyUi.goldDeep,
        actions: const [
          CommonAppDialogAction(label: 'Enter Hub', isPrimary: true),
        ],
      );
    } finally {
      isBuying.value = false;
    }
  }

  Future<void> _openWalletToRecharge() async {
    await Get.to(() => const WalletView(), binding: WalletBinding());
    await _loadPurchasedCoins();
  }

  Future<void> _loadPurchasedCoins() async {
    final wallet = await _economyRepo.getWalletBalances(isShowLoader: false);
    final walletData = wallet?['data'];
    if (walletData is Map) {
      coinsBalance.value = _purchasedCoins(
        Map<String, dynamic>.from(walletData),
      );
    }
  }

  /// SVIP is paid with purchased coins. The wallet API stores those in
  /// `purchasedCoins` / `diamonds`. `coins` on this payload is earnings.
  int _purchasedCoins(Map<String, dynamic> data) {
    for (final key in ['purchasedCoins', 'purchased_coins', 'diamonds']) {
      if (data.containsKey(key) && data[key] != null) {
        return _toInt(data[key]);
      }
    }
    return _toInt(data['coins']);
  }

  List? _packageList(dynamic rawData) {
    if (rawData is List) return rawData;
    if (rawData is Map) {
      final nested = rawData['packages'] ?? rawData['items'] ?? rawData['list'];
      if (nested is List) return nested;
    }
    return null;
  }

  List<String> _benefitLines(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      return raw
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  void _syncPrivileges() {
    final selected = _selectedPlanMap(selectedPlan.value ?? '');
    final lines = selected == null
        ? const <String>[]
        : _benefitLines(selected['benefits']);
    if (lines.isEmpty) {
      privileges.assignAll(_fallbackPrivileges);
      return;
    }
    privileges.assignAll(lines.map(_privilegeFromBenefit));
  }

  Map<String, dynamic> _privilegeFromBenefit(String benefit) {
    final key = benefit.toLowerCase();
    IconData icon = Icons.stars_rounded;
    Color color = const Color(0xFFFFD700);
    var desc = 'Included with this SVIP plan.';
    if (key.contains('badge')) {
      icon = Icons.workspace_premium_rounded;
      desc = 'Shown on your profile and in live rooms.';
    } else if (key.contains('entrance')) {
      icon = Icons.sports_kabaddi_rounded;
      color = const Color(0xFFFF4500);
      desc = 'Plays when you join a live room.';
    } else if (key.contains('kick') ||
        key.contains('mute') ||
        key.contains('immunity')) {
      icon = Icons.security_rounded;
      color = const Color(0xFF1E90FF);
      desc = 'Protection from room moderators.';
    } else if (key.contains('chat')) {
      icon = Icons.chat_bubble_rounded;
      color = const Color(0xFFBA55D3);
      desc = 'A distinct chat style in live rooms.';
    } else if (key.contains('background') || key.contains('frame')) {
      icon = Icons.wallpaper_rounded;
      color = const Color(0xFF3CB371);
      desc = 'Premium frames and profile backgrounds.';
    } else if (key.contains('support')) {
      icon = Icons.support_agent_rounded;
      color = const Color(0xFFFF8C00);
      desc = 'Priority help from support.';
    } else if (key.contains('discount') || key.contains('gift')) {
      icon = Icons.card_giftcard_rounded;
      color = const Color(0xFFFF8A48);
      desc = 'A discount on selected gifts.';
    }
    return {'title': benefit, 'desc': desc, 'icon': icon, 'color': color};
  }

  Future<void> _loadBackpackVip() async {
    final response = await _userRepo.getBackpack(isShowLoader: false);
    if (!isEconomyApiSuccess(response)) return;
    final items = _backpackItems(response?['data']);
    DateTime? latestFuture;
    var anyVip = false;
    var anyOpenEnded = false;
    for (final item in items) {
      if (!_isVipBadge(item)) continue;
      anyVip = true;
      final expires = _parseDate(item['expiresAt'] ?? item['expires_at']);
      if (expires == null) {
        anyOpenEnded = true;
        continue;
      }
      if (!expires.isAfter(DateTime.now())) continue;
      if (latestFuture == null || expires.isAfter(latestFuture)) {
        latestFuture = expires;
      }
    }
    if (latestFuture != null) {
      _setActive(latestFuture);
      await _cacheSvipExpiry(latestFuture);
      return;
    }
    if (anyOpenEnded) {
      _setActive(svipExpiresAt.value);
      return;
    }
    if (anyVip) {
      isSvipActive.value = false;
      svipExpiresAt.value = null;
    }
  }

  List<Map<String, dynamic>> _backpackItems(dynamic data) {
    dynamic raw = data;
    if (data is Map) {
      raw = data['items'] ?? data['inventory'] ?? data['backpack'] ?? data;
    }
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  bool _isVipBadge(Map<String, dynamic> item) {
    final type = (item['itemType'] ?? item['item_type'] ?? item['type'] ?? '')
        .toString()
        .toUpperCase();
    if (type == 'VIP_BADGE' || type.contains('VIP')) return true;
    final label =
        '${item['name'] ?? ''} ${item['itemId'] ?? ''} ${item['title'] ?? ''}'
            .toLowerCase();
    return label.contains('svip') || label.contains('vip badge');
  }

  void _applyWalletBalanceFromPurchase(
    Map<String, dynamic>? response,
    int fallbackPrice,
  ) {
    final data = response?['data'];
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final wallet = map['wallet'];
      final source = wallet is Map ? Map<String, dynamic>.from(wallet) : map;
      if (source.containsKey('purchasedCoins') ||
          source.containsKey('purchased_coins') ||
          source.containsKey('diamonds')) {
        coinsBalance.value = _purchasedCoins(source);
        return;
      }
    }
    coinsBalance.value = (coinsBalance.value - fallbackPrice)
        .clamp(0, 1 << 31)
        .toInt();
  }

  String get _svipCacheKey {
    final userId = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>().userId.trim()
        : '';
    return 'svip_expires_at_$userId';
  }

  void _setActive(DateTime? expiresAt) {
    if (expiresAt != null && !expiresAt.isAfter(DateTime.now())) return;
    isSvipActive.value = true;
    if (expiresAt != null) svipExpiresAt.value = expiresAt;
  }

  /// Keeps the purchase visible on revisit even when the API omits SVIP status.
  Future<void> _cacheSvipExpiry(DateTime expiresAt) async {
    await LocalStorage.shared.writeStringStorage(
      _svipCacheKey,
      expiresAt.toUtc().toIso8601String(),
    );
  }

  Future<void> _restoreCachedSvip() async {
    final raw = await LocalStorage.shared.getStringFromStorage(_svipCacheKey);
    _setActive(_parseDate(raw));
  }

  Future<void> _loadSvipFromProfile() async {
    final response = await _authRepo.getProfile();
    final data = response?['data'];
    if (data is! Map) return;
    final profile = Map<String, dynamic>.from(data);
    final nested = profile['user'];
    if (nested is Map) profile.addAll(Map<String, dynamic>.from(nested));
    _applySvipStatus(profile);
  }

  /// Reads SVIP status from a profile or vip-packages payload.
  void _applySvipStatus(Map<String, dynamic> data) {
    final activePlan = data['activePlan'] ?? data['svip'] ?? data['vip'];
    final planMap = activePlan is Map ? activePlan : const {};
    final expires = _parseDate(
      data['svipExpiresAt'] ??
          data['vipExpiresAt'] ??
          data['vip_expires_at'] ??
          data['svip_expires_at'] ??
          planMap['expiresAt'] ??
          planMap['expires_at'],
    );
    final flag = [
      'isSvipActive',
      'isSvip',
      'isSVIP',
      'is_svip',
      'isVip',
      'isVIP',
      'is_vip',
    ].any((key) => data[key] == true);
    final level = _toInt(data['vipLevel'] ?? data['vip_level']);

    if (expires != null) {
      if (expires.isAfter(DateTime.now())) {
        _setActive(expires);
        unawaited(_cacheSvipExpiry(expires));
      }
      return;
    }
    if (flag || level > 0 || planMap.isNotEmpty) _setActive(null);
  }

  DateTime? _parseDate(dynamic raw) {
    final text = raw?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  Map<String, dynamic>? _selectedPlanMap(String selectedId) {
    for (final plan in plans) {
      if (plan['id'].toString() == selectedId) return plan;
    }
    return null;
  }

  String _packageBadge(Map plan) {
    final name = plan['name']?.toString().trim();
    if (name != null && name.isNotEmpty) {
      return name.replaceAll(RegExp(r'\s+'), ' ');
    }
    final status = plan['status']?.toString().trim();
    return status == null || status.isEmpty ? 'Popular' : status;
  }

  void _showToast(String title, String message, {bool isError = false}) {
    final context = Get.context ?? Get.key.currentContext;
    if (context == null || !context.mounted) return;
    if (isError) {
      AppToast.showError(context, message, title: title);
    } else {
      AppToast.showSuccess(context, message, title: title);
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
