import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';

class PointCenterController extends GetxController {
  PointCenterController({UserRepo? userRepo})
    : _userRepo = userRepo ?? UserRepo();

  final UserRepo _userRepo;
  final isLoading = false.obs;
  final pointsBalance = 0.obs;
  final coinsBalance = 0.0.obs;

  final tasks = <Map<String, dynamic>>[].obs;

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
      coinsBalance.value = _toDouble(data['coinsBalance']);
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
                  'targetCategory':
                      task['targetCategory']?.toString() ??
                      task['target_category']?.toString() ??
                      'ALL',
                  'frequency':
                      task['frequency']?.toString() ??
                      task['cycle']?.toString() ??
                      'DAILY',
                  'roomType':
                      task['roomType']?.toString() ??
                      task['room_type']?.toString() ??
                      'ANY',
                  'targetMetric':
                      task['targetMetric']?.toString() ??
                      task['target_metric']?.toString() ??
                      '',
                  'targetValue': _toDouble(
                    task['targetValue'] ??
                        task['target_value'] ??
                        task['target'],
                  ),
                  'progressValue': _toDouble(
                    task['progressValue'] ??
                        task['progress_value'] ??
                        task['progress'],
                  ),
                  'progressRatio': _progressRatio(task),
                  'reward': _toInt(task['reward']),
                  'rewardType':
                      task['rewardType']?.toString() ??
                      task['reward_type']?.toString() ??
                      'coins',
                  'isCompleted': task['isCompleted'] == true,
                  'isClaimed': task['isClaimed'] == true,
                  'status': task['status']?.toString() ?? 'pending',
                  'cycleKey':
                      task['cycleKey']?.toString() ??
                      task['cycle_key']?.toString() ??
                      '',
                  'completedAt': task['completedAt']?.toString() ?? '',
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
      task['status'] = 'claimed';
      if ((task['rewardType']?.toString().toLowerCase() ?? '') == 'coins') {
        coinsBalance.value += _toDouble(task['reward']);
      } else {
        pointsBalance.value += _toInt(task['reward']);
      }
      tasks[index] = Map<String, dynamic>.from(task);
      Get.snackbar(
        'Task Bonus Claimed',
        'Successfully claimed ${task['reward']} ${task['rewardType']}!',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  List<Map<String, dynamic>> tasksForFrequency(String frequency) {
    final expected = frequency.toUpperCase();
    return tasks
        .where(
          (task) =>
              (task['frequency']?.toString().toUpperCase() ?? '') == expected,
        )
        .toList();
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

  double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _progressRatio(Map task) {
    final direct = _toDouble(
      task['progressRatio'] ?? task['progress_ratio'] ?? task['ratio'],
    );
    if (direct > 0) return direct.clamp(0, 1);
    final target = _toDouble(
      task['targetValue'] ?? task['target_value'] ?? task['target'],
    );
    final progress = _toDouble(
      task['progressValue'] ?? task['progress_value'] ?? task['progress'],
    );
    if (target <= 0) return 0;
    return (progress / target).clamp(0, 1);
  }

  String _iconForType(String? type) {
    final value = (type ?? '').toLowerCase();
    if (value.contains('frame')) return kIconUserLevel;
    if (value.contains('coin')) return kIconRechargeCoins;
    if (value.contains('effect')) return kIconAward;
    return kIconPointerCenter;
  }
}
