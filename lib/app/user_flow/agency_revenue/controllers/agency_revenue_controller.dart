import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class RevenueHistoryModel {
  RevenueHistoryModel({
    required this.date,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.type,
  });

  final String date;
  final String title;
  final String amount;
  final String subtitle;
  final AgencyRevenueLineType type;
}

class AgencyRevenueController extends GetxController {
  static const monthOptions = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final selectedMonth = 'June'.obs;
  final totalRevenue = '0'.obs;
  final availableForPayout = '0'.obs;
  final pendingCommissionCount = '0'.obs;
  final hostsCount = '0'.obs;
  final companyShare = '0'.obs;
  final hostShare = '0'.obs;
  final ownerCommission = '0'.obs;
  final giftsVolume = '0'.obs;

  final historyList = <RevenueHistoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadForMonth(selectedMonth.value);
  }

  void selectMonth(String month) {
    if (selectedMonth.value == month) return;
    selectedMonth.value = month;
    _loadForMonth(month);
  }

  void _loadForMonth(String month) {
    // Demo: June shows full sample; other months show reduced placeholder.
    final isJune = month == 'June';
    totalRevenue.value = _format(AgencyRevenueDemo.totalAgencyEarnings);
    availableForPayout.value = _format(AgencyRevenueDemo.availableForPayout);
    pendingCommissionCount.value = isJune ? '2' : '0';
    hostsCount.value = '${AgencyRevenueDemo.activeHosts}';
    companyShare.value = _format(AgencyRevenueDemo.companyShare);
    hostShare.value = _format(AgencyRevenueDemo.hostCallShare);
    ownerCommission.value = _format(AgencyRevenueDemo.ownerCommissionCoins);
    giftsVolume.value = _format(AgencyRevenueDemo.totalGiftsVolume);

    historyList.assignAll(
      isJune
          ? AgencyRevenueDemo.revenueHistory
                .map(
                  (e) => RevenueHistoryModel(
                    date: e.date,
                    title: e.title,
                    amount: e.amount,
                    subtitle: e.subtitle,
                    type: e.type,
                  ),
                )
                .toList()
          : [],
    );
  }

  String _format(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  void requestPayout(BuildContext context) {
    AppToast.showSuccess(
      context,
      'Demo: Payout request for ${availableForPayout.value} coins (API pending).',
    );
  }

  void openDashboard() {
    Get.offNamed(Routes.AGENCY_OWNER);
  }
}
