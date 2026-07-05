import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';

class PointCenterController extends GetxController {
  PointCenterController({UserRepo? userRepo})
    : _userRepo = userRepo ?? UserRepo();

  final UserRepo _userRepo;
  final isLoading = false.obs;
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

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    isLoading.value = true;
    try {
      final response = await _userRepo.getTasks(isShowLoader: false);
      final data = response?['data'];
      if (data is! Map) return;

      pointsBalance.value = _toInt(data['pointsBalance']);
      final apiTasks = data['tasks'];
      if (apiTasks is List) {
        tasks.assignAll(
          apiTasks
              .whereType<Map>()
              .map((task) {
                return <String, dynamic>{
                  'id': task['id']?.toString() ?? '',
                  'title': task['title']?.toString() ?? '',
                  'description': task['description']?.toString() ?? '',
                  'reward': _toInt(task['reward']),
                  'isCompleted': task['isCompleted'] == true,
                  'isClaimed': task['isClaimed'] == true,
                  'progress': _toInt(task['progress']),
                  'target': _toInt(task['target']),
                };
              })
              .where((task) => task['title'].toString().isNotEmpty),
        );
      }

      final apiStore = data['storeItems'];
      if (apiStore is List) {
        storeItems.assignAll(
          apiStore
              .whereType<Map>()
              .map((item) {
                return <String, dynamic>{
                  'id': item['id']?.toString() ?? '',
                  'name': item['name']?.toString() ?? '',
                  'cost': _toInt(item['cost']),
                  'duration': item['duration']?.toString() ?? '',
                  'icon': _iconForType(item['type']?.toString()),
                  'iconUrl': item['iconUrl']?.toString() ?? '',
                  'type': item['type']?.toString() ?? '',
                };
              })
              .where((item) => item['name'].toString().isNotEmpty),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> claimPoints(int index) async {
    final task = tasks[index];
    if (task['isCompleted'] && !task['isClaimed']) {
      final response = await _userRepo.claimTask(
        taskId: task['id']?.toString() ?? '',
        isShowLoader: true,
      );
      if (response == null || response['statusCode'] == 0) {
        Get.snackbar('Point Center', 'Could not claim this task.');
        return;
      }
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

  Future<void> redeemItem(Map<String, dynamic> item) async {
    final int cost = item['cost'];
    if (pointsBalance.value >= cost) {
      final response = await _userRepo.redeemPointsItem(
        itemId: item['id']?.toString() ?? '',
        isShowLoader: true,
      );
      if (response == null || response['statusCode'] == 0) {
        Get.snackbar('Point Center', 'Could not redeem this item.');
        return;
      }
      final data = response['data'];
      pointsBalance.value -= cost;
      if (data is Map && data['pointsBalance'] != null) {
        pointsBalance.value = _toInt(data['pointsBalance']);
      }
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

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _iconForType(String? type) {
    final value = (type ?? '').toLowerCase();
    if (value.contains('frame')) return kIconUserLevel;
    if (value.contains('coin')) return kIconRechargeCoins;
    if (value.contains('effect')) return kIconAward;
    return kIconPointerCenter;
  }
}
