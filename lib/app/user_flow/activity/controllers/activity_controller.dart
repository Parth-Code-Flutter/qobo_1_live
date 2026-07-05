import 'package:get/get.dart';
import 'package:qobo_one_live/repo/activity/activity_repo.dart';

class ActivityController extends GetxController {
  ActivityController({ActivityRepo? activityRepo})
    : _activityRepo = activityRepo ?? ActivityRepo();

  final ActivityRepo _activityRepo;
  final isLoading = false.obs;

  final activities = <Map<String, dynamic>>[
    {
      'title': 'Weekly Star Host Arena',
      'desc':
          'Compete against other top broadcasters to win the legendary Crown Profile Badge!',
      'status': 'Active',
      'timeLeft': '3 days left',
      'gradient': [0xFFE65C00, 0xFFF9D423], // Orange/Gold
    },
    {
      'title': 'Call King Festival',
      'desc':
          'Unlock call matches, send virtual roses, and climb the Love Leaderboard.',
      'status': 'Active',
      'timeLeft': '5 days left',
      'gradient': [0xFFFF42C3, 0xFFFF5EA7], // Pink/Rose
    },
    {
      'title': 'PK Battle Royale',
      'desc':
          'Join or start consecutive PK battles. Top 10 champions receive 50,000 Coins!',
      'status': 'Starting Soon',
      'timeLeft': 'Starts in 12 hours',
      'gradient': [0xFF5C2D84, 0xFF7E4EA8], // Purple
    },
    {
      'title': 'Daily Recharge Bonus',
      'desc':
          'Get up to 25% extra coins on every recharge via Razorpay or Google Pay.',
      'status': 'Active',
      'timeLeft': 'Ending today',
      'gradient': [0xFF11998E, 0xFF38EF7D], // Emerald
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    isLoading.value = true;
    try {
      final response = await _activityRepo.getActivities(isShowLoader: false);
      final data = response?['data'];
      if (data is List) {
        activities.assignAll(
          data
              .whereType<Map>()
              .map((activity) {
                return <String, dynamic>{
                  'id': activity['id']?.toString() ?? '',
                  'title': activity['title']?.toString() ?? '',
                  'desc': activity['description']?.toString() ?? '',
                  'status': _statusLabel(activity['status']),
                  'timeLeft': activity['timeLeft']?.toString() ?? '',
                  'gradient': _parseGradient(activity['gradient']),
                  'isJoined': activity['isJoined'] == true,
                };
              })
              .where((activity) => activity['title'].toString().isNotEmpty),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> openActivityDetails(String title) async {
    Map<String, dynamic>? activity;
    for (final item in activities) {
      if (item['title'] == title) {
        activity = item;
        break;
      }
    }
    final id = activity?['id']?.toString() ?? '';
    if (id.isEmpty) {
      Get.snackbar('Activity', 'Activity details are not available.');
      return;
    }

    final response = await _activityRepo.joinActivity(
      activityId: id,
      isShowLoader: true,
    );
    if (response == null || response['statusCode'] == 0) {
      Get.snackbar('Activity', 'Could not join "$title".');
      return;
    }
    activity?['isJoined'] = true;
    activities.refresh();
    Get.snackbar(
      'Activity Registered',
      response['message']?.toString() ??
          'You have successfully joined "$title"! Get ready to compete!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  String _statusLabel(dynamic value) {
    final status = value?.toString().toLowerCase() ?? '';
    if (status.contains('soon')) return 'Starting Soon';
    if (status == 'active') return 'Active';
    return status.isEmpty ? 'Active' : status.capitalizeFirst ?? status;
  }

  List<int> _parseGradient(dynamic value) {
    if (value is List && value.length >= 2) {
      return value.take(2).map((item) {
        final text = item.toString();
        if (text.startsWith('#')) {
          return int.tryParse('0xFF${text.substring(1)}') ?? 0xFF761B65;
        }
        return int.tryParse(text) ?? 0xFF761B65;
      }).toList();
    }
    return [0xFFE65C00, 0xFFF9D423];
  }
}
