import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/agency_owner_dashboard/models/agency_revenue_demo.dart';
import 'package:qobo_one_live/repo/agency/agency_api_utils.dart';
import 'package:qobo_one_live/repo/agency/agency_repo.dart';
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
  final AgencyRepo _agencyRepo = AgencyRepo();

  static const monthOptions = agencyMonthLabels;

  final selectedMonth = 'June'.obs;
  final isLoading = false.obs;
  final loadError = ''.obs;

  final totalRevenue = '0'.obs;
  final availableForPayout = '0'.obs;
  final pendingCommissionCount = '0'.obs;
  final hostsCount = '0'.obs;
  final companyShare = '0'.obs;
  final hostShare = '0'.obs;
  final ownerCommission = '0'.obs;
  final giftsVolume = '0'.obs;

  final historyList = <RevenueHistoryModel>[].obs;

  int _payoutAmountRaw = 0;

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

  Future<void> _loadForMonth(String month) async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final response = await _agencyRepo.getAgencyRevenueStats(
        month: agencyMonthLabelToApi(month),
        isShowLoader: false,
      );
      final data = response?['data'];
      if (isAgencyApiSuccess(response) && data is Map) {
        _applyRevenueData(Map<String, dynamic>.from(data));
        return;
      }
      loadError.value = agencyApiMessage(response) ?? 'Could not load revenue.';
      _applyDemoFallback(month);
    } catch (_) {
      loadError.value = 'Network error.';
      _applyDemoFallback(month);
    } finally {
      isLoading.value = false;
    }
  }

  void _applyRevenueData(Map<String, dynamic> data) {
    final total = _toInt(data['totalRevenue']);
    _payoutAmountRaw = _toInt(data['availableForPayout']);
    totalRevenue.value = _format(total);
    availableForPayout.value = _format(_payoutAmountRaw);
    pendingCommissionCount.value = '${_toInt(data['pendingCommissionCount'])}';
    hostsCount.value = '${_toInt(data['hostsCount'])}';
    companyShare.value = _format(_toInt(data['companyShare']));
    hostShare.value = _format(_toInt(data['hostCallShare']));
    ownerCommission.value = _format(_toInt(data['ownerCommissionCoins']));
    giftsVolume.value = _format(_toInt(data['totalGifts']));

    final history = data['history'];
    if (history is List) {
      historyList.assignAll(
        history
            .whereType<Map>()
            .map(
              (e) => RevenueHistoryModel(
                date: e['date']?.toString() ?? '',
                title: e['title']?.toString() ?? '',
                amount: e['amountLabel']?.toString() ??
                    '+${_format(_toInt(e['amount']))}',
                subtitle: e['subtitle']?.toString() ?? '',
                type: _parseHistoryType(e['type']?.toString()),
              ),
            )
            .toList(),
      );
    } else {
      historyList.clear();
    }
  }

  void _applyDemoFallback(String month) {
    final isJune = month == 'June';
    totalRevenue.value = _format(AgencyRevenueDemo.totalAgencyEarnings);
    _payoutAmountRaw = AgencyRevenueDemo.availableForPayout;
    availableForPayout.value = _format(_payoutAmountRaw);
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

  AgencyRevenueLineType _parseHistoryType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'call':
        return AgencyRevenueLineType.call;
      case 'gift':
        return AgencyRevenueLineType.gift;
      case 'payout':
        return AgencyRevenueLineType.payout;
      default:
        return AgencyRevenueLineType.owner;
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _format(int n) => n.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );

  Future<void> requestPayout(BuildContext context) async {
    if (_payoutAmountRaw <= 0) {
      AppToast.showError(context, 'No payout balance available.');
      return;
    }
    try {
      final response = await _agencyRepo.processPayout(
        amount: _payoutAmountRaw,
        isShowLoader: true,
      );
      if (isAgencyApiSuccess(response)) {
        if (context.mounted) {
          AppToast.showSuccess(
            context,
            agencyApiMessage(response) ?? 'Payout request submitted.',
          );
        }
        await _loadForMonth(selectedMonth.value);
        return;
      }
      if (context.mounted) {
        AppToast.showError(
          context,
          agencyApiMessage(response) ?? 'Payout request failed.',
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppToast.showError(context, 'Payout request failed.');
      }
    }
  }

  void openDashboard() {
    Get.offNamed(Routes.AGENCY_OWNER);
  }
}
