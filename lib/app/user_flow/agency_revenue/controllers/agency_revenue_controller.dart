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
  final totalRevenue = '0'.obs;
  final availableForPayout = '0'.obs;

  final historyList = <RevenueHistoryModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  void _loadHistory() {
    historyList.clear();
  }

  void requestPayout(BuildContext context) {
    AppToast.showSuccess(context, 'No payout amount is available yet.');
    availableForPayout.value = '0';
  }
}
