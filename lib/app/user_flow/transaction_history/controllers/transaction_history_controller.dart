import 'package:get/get.dart';

class TransactionHistoryController extends GetxController {
  final isLoading = false.obs;

  // Selected tab index: 0 = Coins, 1 = Diamonds
  final selectedTab = 0.obs;

  // Coin Transaction logs
  final coinTransactions = <Map<String, dynamic>>[
    {
      'title': 'Google Pay Recharge',
      'subtitle': 'Coins purchased successfully',
      'amount': '+1,200',
      'isAddition': true,
      'date': 'May 18, 2026 • 2:30 PM',
      'type': 'Google Pay',
    },
    {
      'title': 'Gift Sent: Rose Bloom',
      'subtitle': 'Sent to Alina Khan',
      'amount': '-500',
      'isAddition': false,
      'date': 'May 18, 2026 • 1:15 PM',
      'type': 'Gift',
    },
    {
      'title': 'Local Seller Recharge',
      'subtitle': 'Coins recharged by agent',
      'amount': '+5,000',
      'isAddition': true,
      'date': 'May 16, 2026 • 6:45 PM',
      'type': 'Coin Seller',
    },
    {
      'title': 'Aristocracy Renewal',
      'subtitle': 'Knight rank renewal fee',
      'amount': '-2,000',
      'isAddition': false,
      'date': 'May 15, 2026 • 12:00 AM',
      'type': 'Noble Rank',
    },
  ].obs;

  // Diamond Transaction logs
  final diamondTransactions = <Map<String, dynamic>>[
    {
      'title': 'Live Stream Earnings',
      'subtitle': 'Received gifts in Stream #45',
      'amount': '+2,450',
      'isAddition': true,
      'date': 'May 18, 2026 • 4:30 PM',
      'type': 'Broadcasting',
    },
    {
      'title': 'Exchange for Coins',
      'subtitle': 'Converted diamonds to coins',
      'amount': '-1,000',
      'isAddition': false,
      'date': 'May 17, 2026 • 9:15 PM',
      'type': 'Exchange',
    },
    {
      'title': 'Weekly Host Bonus',
      'subtitle': 'Top host ranking reward',
      'amount': '+5,000',
      'isAddition': true,
      'date': 'May 14, 2026 • 12:05 PM',
      'type': 'Official Bonus',
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchTransactionHistory();
  }

  void fetchTransactionHistory() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isLoading.value = false;
  }
}
