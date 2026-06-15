import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';

class TransactionHistoryController extends GetxController {
  TransactionHistoryController({EconomyRepo? economyRepo})
    : _economyRepo = economyRepo ?? EconomyRepo();

  final EconomyRepo _economyRepo;

  final isLoading = false.obs;
  final loadError = ''.obs;

  // Selected tab index: 0 = Coins, 1 = Diamonds
  final selectedTab = 0.obs;

  final coinTransactions = <Map<String, dynamic>>[].obs;
  final diamondTransactions = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactionHistory();
  }

  Future<void> fetchTransactionHistory() async {
    isLoading.value = true;
    loadError.value = '';
    try {
      final response = await _economyRepo.getTransactionHistory(
        isShowLoader: false,
      );
      if (!isEconomyApiSuccess(response)) {
        coinTransactions.clear();
        diamondTransactions.clear();
        loadError.value =
            response?['message']?.toString() ?? 'Unable to load history.';
        return;
      }

      final parsed = _parseHistoryResponse(response?['data']);
      coinTransactions.assignAll(parsed.coins);
      diamondTransactions.assignAll(parsed.diamonds);
    } catch (_) {
      coinTransactions.clear();
      diamondTransactions.clear();
      loadError.value = 'Network error. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  ({List<Map<String, dynamic>> coins, List<Map<String, dynamic>> diamonds})
  _parseHistoryResponse(dynamic data) {
    final coins = <Map<String, dynamic>>[];
    final diamonds = <Map<String, dynamic>>[];

    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      _appendLedger(coins, map['coins'] ?? map['coinTransactions']);
      _appendLedger(diamonds, map['diamonds'] ?? map['diamondTransactions']);
      if (coins.isEmpty && diamonds.isEmpty) {
        _appendLedger(coins, map['transactions']);
      }
    } else if (data is List) {
      _appendLedger(coins, data);
    }

    if (coins.isEmpty && diamonds.isEmpty && data is List) {
      for (final raw in data.whereType<Map>()) {
        final tx = _mapTransaction(Map<String, dynamic>.from(raw));
        if (_isDiamondLedger(raw)) {
          diamonds.add(tx);
        } else {
          coins.add(tx);
        }
      }
    }

    return (coins: coins, diamonds: diamonds);
  }

  void _appendLedger(List<Map<String, dynamic>> target, dynamic raw) {
    if (raw is! List) return;
    for (final item in raw.whereType<Map>()) {
      target.add(_mapTransaction(Map<String, dynamic>.from(item)));
    }
  }

  bool _isDiamondLedger(Map<dynamic, dynamic> raw) {
    final currency =
        raw['currency']?.toString().toLowerCase() ??
        raw['walletType']?.toString().toLowerCase() ??
        raw['asset']?.toString().toLowerCase() ??
        '';
    if (currency.contains('diamond')) return true;
    final type = raw['type']?.toString().toLowerCase() ?? '';
    return type.contains('diamond');
  }

  Map<String, dynamic> _mapTransaction(Map<String, dynamic> raw) {
    final amountValue = _readAmount(raw);
    final isAddition = raw['isAddition'] == true ||
        raw['direction']?.toString().toLowerCase() == 'credit' ||
        raw['transactionType']?.toString().toLowerCase() == 'credit' ||
        amountValue > 0;

    final absAmount = formatLedgerAmount(amountValue.abs());
    final type = raw['type']?.toString() ??
        raw['category']?.toString() ??
        raw['transactionType']?.toString() ??
        'Transaction';

    return {
      'title': raw['title']?.toString() ??
          raw['description']?.toString() ??
          raw['message']?.toString() ??
          type,
      'subtitle': raw['subtitle']?.toString() ??
          raw['note']?.toString() ??
          raw['receiverName']?.toString() ??
          raw['hostName']?.toString() ??
          '',
      'amount': absAmount,
      'isAddition': isAddition,
      'date': _formatDate(
        raw['createdAt'] ??
            raw['created_at'] ??
            raw['date'] ??
            raw['timestamp'],
      ),
      'type': type,
    };
  }

  num _readAmount(Map<String, dynamic> raw) {
    final value = raw['amount'] ??
        raw['coins'] ??
        raw['diamonds'] ??
        raw['value'] ??
        raw['totalCoinsDeducted'] ??
        raw['hostEarnedDiamonds'];
    if (value is num) return value;
    return num.tryParse(value?.toString().replaceAll(',', '') ?? '') ?? 0;
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '';
    DateTime? parsed;
    if (raw is DateTime) {
      parsed = raw;
    } else {
      parsed = DateTime.tryParse(raw.toString());
    }
    if (parsed == null) return raw.toString();
    final local = parsed.toLocal();
    return DateFormat('MMM d, yyyy • h:mm a').format(local);
  }
}
