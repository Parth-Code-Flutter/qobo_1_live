import 'package:get/get.dart';

class PointCenterController extends GetxController {
  final pointsBalance = 2450.obs;
  
  final tasks = <Map<String, dynamic>>[
    {
      'title': 'Daily Check-in',
      'reward': 100,
      'isCompleted': true,
      'isClaimed': true,
    },
    {
      'title': 'Watch Live Stream for 15 mins',
      'reward': 200,
      'isCompleted': true,
      'isClaimed': false,
    },
    {
      'title': 'Send a virtual gift to any host',
      'reward': 300,
      'isCompleted': false,
      'isClaimed': false,
    },
    {
      'title': 'Broadcaster for 30 mins',
      'reward': 500,
      'isCompleted': false,
      'isClaimed': false,
    },
  ].obs;

  final storeItems = <Map<String, dynamic>>[
    {
      'name': 'Golden Crown Frame',
      'cost': 1500,
      'duration': '7 Days',
      'icon': 'assets/icons/badge_icon.svg',
    },
    {
      'name': '100 Coins Package',
      'cost': 2000,
      'duration': 'Instant',
      'icon': 'assets/icons/recharge_coins_icon.svg',
    },
    {
      'name': 'Royal Dragon Entry Effect',
      'cost': 5000,
      'duration': '30 Days',
      'icon': 'assets/icons/medal_icon.svg',
    },
  ].obs;

  void claimPoints(int index) {
    final task = tasks[index];
    if (task['isCompleted'] && !task['isClaimed']) {
      task['isClaimed'] = true;
      pointsBalance.value += task['reward'] as int;
      tasks[index] = Map<String, dynamic>.from(task);
      Get.snackbar(
        'Points Claimed',
        'Successfully claimed ${task['reward']} points!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void redeemItem(Map<String, dynamic> item) {
    final int cost = item['cost'];
    if (pointsBalance.value >= cost) {
      pointsBalance.value -= cost;
      Get.snackbar(
        'Redemption Successful',
        'Successfully redeemed "${item['name']}"!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Insufficient Points',
        'You need ${cost - pointsBalance.value} more points to redeem this item.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
