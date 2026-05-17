import 'package:get/get.dart';

class SvipController extends GetxController {
  final isSvipActive = false.obs;

  final List<Map<String, dynamic>> privileges = [
    {'title': 'SVIP Badge', 'desc': 'Exclusive profile badge'},
    {'title': 'Special Entrance', 'desc': 'Unique room entrance animation'},
    {'title': 'Prevent Kick', 'desc': 'Immunity from being kicked by hosts'},
    {'title': 'Secret Chat', 'desc': 'Send private messages in live rooms'},
  ];

  final List<Map<String, dynamic>> plans = [
    {'id': 1, 'duration': '1 Month', 'price': 5000, 'coins': 'Coins'},
    {'id': 2, 'duration': '3 Months', 'price': 14000, 'coins': 'Coins'},
    {'id': 3, 'duration': '12 Months', 'price': 50000, 'coins': 'Coins'},
  ];

  final selectedPlan = 1.obs;

  void selectPlan(int planId) {
    selectedPlan.value = planId;
  }

  void subscribe() {
    Get.snackbar('Subscription', 'Subscribed to SVIP successfully!');
    isSvipActive.value = true;
  }
}
