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
  final totalRevenue = '1,500,000'.obs;
  final availableForPayout = '45,000'.obs;
  
  final historyList = <RevenueHistoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  void _loadHistory() {
    historyList.addAll([
      RevenueHistoryModel('15 May 2026', '12,000', 'Completed'),
      RevenueHistoryModel('01 May 2026', '25,000', 'Completed'),
      RevenueHistoryModel('15 Apr 2026', '18,500', 'Completed'),
    ]);
  }

  void requestPayout(BuildContext context) {
    AppToast.showSuccess(context, 'Payout of \$45,000 requested successfully!');
    availableForPayout.value = '0';
  }
}
