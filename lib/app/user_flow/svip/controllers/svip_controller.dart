import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';

class SvipController extends GetxController {
  SvipController({EconomyRepo? economyRepo})
    : _economyRepo = economyRepo ?? EconomyRepo();

  final EconomyRepo _economyRepo;
  final isLoading = false.obs;
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

  final plans = <Map<String, dynamic>>[
    {'id': 1, 'duration': '1 Month', 'price': 5000, 'saving': 'Standard'},
    {'id': 2, 'duration': '3 Months', 'price': 14000, 'saving': 'Save 7%'},
    {'id': 3, 'duration': '12 Months', 'price': 50000, 'saving': 'Save 17%'},
  ].obs;

  final selectedPlan = Rx<dynamic>(1);

  @override
  void onInit() {
    super.onInit();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    isLoading.value = true;
    try {
      final wallet = await _economyRepo.getWalletBalances(isShowLoader: false);
      final walletData = wallet?['data'];
      if (walletData is Map) {
        coinsBalance.value = _toInt(walletData['coins']);
      }

      final response = await _economyRepo.getVipPackages(isShowLoader: false);
      final data = response?['data'];
      if (data is List && data.isNotEmpty) {
        plans.assignAll(
          data
              .whereType<Map>()
              .map((plan) {
                final id = plan['id']?.toString() ?? '';
                final durationDays = _toInt(plan['durationDays']);
                return <String, dynamic>{
                  'id': id,
                  'duration': durationDays > 0
                      ? '$durationDays Days'
                      : plan['name']?.toString() ?? 'SVIP',
                  'price': _toInt(plan['price']),
                  'saving': plan['status']?.toString() ?? 'Active',
                  'name': plan['name']?.toString() ?? '',
                };
              })
              .where((plan) => plan['id'].toString().isNotEmpty),
        );
        selectedPlan.value = plans.first['id'];
      }
    } finally {
      isLoading.value = false;
    }
  }

  void selectPlan(dynamic planId) {
    selectedPlan.value = planId;
  }

  Future<void> subscribe() async {
    final activePlan = plans.firstWhere((p) => p['id'] == selectedPlan.value);
    final price = _toInt(activePlan['price']);

    if (coinsBalance.value >= price) {
      final response = await _economyRepo.buyVip(
        packageId: activePlan['id'].toString(),
        isShowLoader: true,
      );
      if (response == null || response['statusCode'] == 0) {
        Get.snackbar('SVIP', 'Could not activate this SVIP package.');
        return;
      }
      coinsBalance.value -= price;
      isSvipActive.value = true;
      CommonAppDialog.showGet(
        title: 'SVIP Activated!',
        message:
            'Congratulations! You are now a Supreme VIP member. Your privileges are active immediately.',
        icon: Icons.stars_rounded,
        iconAccent: AdminAgencyUi.goldDeep,
        actions: const [
          CommonAppDialogAction(label: 'Enter Hub', isPrimary: true),
        ],
      );
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
              Get.snackbar('Redirecting', 'Opening recharge panel...');
            },
          ),
        ],
      );
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
