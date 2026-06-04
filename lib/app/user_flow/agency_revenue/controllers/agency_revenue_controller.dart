import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

class RevenueHistoryModel {
  final String date;
  final String amount;
  final String status;

  RevenueHistoryModel(this.date, this.amount, this.status);
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
    // UI placeholder until GET /api/agency/revenue?month= is wired.
    totalRevenue.value = '0';
    availableForPayout.value = '0';
    pendingCommissionCount.value = '0';
    hostsCount.value = '0';
    historyList.clear();
  }

  void requestPayout(BuildContext context) {
    AppToast.showSuccess(
      context,
      'Payout will be available once revenue API is connected.',
    );
  }
}
