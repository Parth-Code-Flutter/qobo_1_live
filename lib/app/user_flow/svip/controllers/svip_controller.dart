import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class SvipController extends GetxController {
  SvipController({EconomyRepo? economyRepo})
    : _economyRepo = economyRepo ?? EconomyRepo();

  final EconomyRepo _economyRepo;
  final isLoading = false.obs;
  final isBuying = false.obs;
  final isSvipActive = false.obs;
  final coinsBalance = 12450.obs;
  final packageError = ''.obs;

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

  final plans = <Map<String, dynamic>>[].obs;

  final selectedPlan = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    isLoading.value = true;
    packageError.value = '';
    try {
      final wallet = await _economyRepo.getWalletBalances(isShowLoader: false);
      final walletData = wallet?['data'];
      if (walletData is Map) {
        coinsBalance.value = _toInt(walletData['coins']);
      }

      final response = await _economyRepo.getVipPackages(isShowLoader: false);
      final data = response?['data'];
      if (response?['statusCode'] == 1 && data is List) {
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
                  'price': _toInt(plan['price']),
                  'saving': _packageBadge(plan),
                  'benefits': plan['benefits'],
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
          selectedPlan.value = plans.first['id'].toString();
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
    } catch (_) {
      packageError.value = 'Unable to load SVIP packages.';
    } finally {
      isLoading.value = false;
    }
  }

  void selectPlan(dynamic planId) {
    selectedPlan.value = planId?.toString();
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
            'You need ${price - coinsBalance.value} more Coins to open SVIP. Would you like to recharge now?',
        icon: Icons.warning_amber_rounded,
        iconAccent: AdminAgencyUi.goldDeep,
        actions: [
          const CommonAppDialogAction(label: 'Cancel'),
          CommonAppDialogAction(
            label: 'Recharge Now',
            isPrimary: true,
            onPressed: () {
              _showToast('Redirecting', 'Opening recharge panel...');
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
      isSvipActive.value = true;
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

  void _applyWalletBalanceFromPurchase(
    Map<String, dynamic>? response,
    int fallbackPrice,
  ) {
    final data = response?['data'];
    if (data is Map) {
      final dynamic balance =
          data['coinsBalance'] ??
          data['coins_balance'] ??
          data['wallet']?['coins'] ??
          data['walletBalance'];
      final parsedBalance = _toNullableInt(balance);
      if (parsedBalance != null) {
        coinsBalance.value = parsedBalance;
        return;
      }
    }
    coinsBalance.value = (coinsBalance.value - fallbackPrice)
        .clamp(0, 1 << 31)
        .toInt();
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

  int? _toNullableInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
