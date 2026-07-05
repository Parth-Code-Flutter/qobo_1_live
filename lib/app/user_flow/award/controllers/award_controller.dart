import 'package:get/get.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';

class AwardController extends GetxController {
  AwardController({UserRepo? userRepo}) : _userRepo = userRepo ?? UserRepo();

  final UserRepo _userRepo;
  final isLoading = false.obs;

  // Medals / Achievements list
  final awards = <Map<String, dynamic>>[
    {
      'title': 'Broadcasting Star',
      'desc': 'Stream for 10 hours or more to show off your talent.',
      'type': 'Streamer',
      'level': 3,
      'isUnlocked': true,
      'progress': 1.0,
      'progressText': '10h / 10h',
      'icon': 'star_rounded',
      'points': 500,
    },
    {
      'title': 'Top Contributor',
      'desc': 'Send 10,000 coins in gifts to support your favorite hosts.',
      'type': 'Supporter',
      'level': 1,
      'isUnlocked': true,
      'progress': 1.0,
      'progressText': '10,000 / 10,000',
      'icon': 'card_giftcard_rounded',
      'points': 1000,
    },
    {
      'title': 'Loyal Listener',
      'desc': 'Watch 50 hours of live streams to earn your listener badge.',
      'type': 'Viewer',
      'level': 2,
      'isUnlocked': false,
      'progress': 0.7,
      'progressText': '35h / 50h',
      'icon': 'visibility_rounded',
      'points': 300,
    },
    {
      'title': 'Elite Aristocrat',
      'desc': 'Subscribe to any Noble Rank in the Aristocracy Center.',
      'type': 'Elite',
      'level': 1,
      'isUnlocked': false,
      'progress': 0.0,
      'progressText': '0 / 1',
      'icon': 'shield_rounded',
      'points': 1500,
    },
    {
      'title': 'Social Butterfly',
      'desc': 'Follow 20 creative hosts to expand your circle.',
      'type': 'Social',
      'level': 1,
      'isUnlocked': false,
      'progress': 0.75,
      'progressText': '15 / 20',
      'icon': 'people_rounded',
      'points': 200,
    },
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAwards();
  }

  void fetchAwards() async {
    isLoading.value = true;
    try {
      final response = await _userRepo.getAchievements(isShowLoader: false);
      final data = response?['data'];
      final list = data is Map ? data['items'] : data;
      if (list is List) {
        awards.assignAll(
          list
              .whereType<Map>()
              .map((award) {
                return <String, dynamic>{
                  'id': award['id']?.toString() ?? '',
                  'title': award['title']?.toString() ?? '',
                  'desc':
                      award['description']?.toString() ??
                      award['desc']?.toString() ??
                      '',
                  'type': award['type']?.toString() ?? 'Achievement',
                  'level': _toInt(award['level']),
                  'isUnlocked':
                      award['isUnlocked'] == true || award['unlocked'] == true,
                  'progress': _toDouble(award['progress']),
                  'progressText': award['progressText']?.toString() ?? '',
                  'icon': award['icon']?.toString() ?? 'star_rounded',
                  'points': _toInt(award['points'] ?? award['reward']),
                  'isClaimed': award['isClaimed'] == true,
                };
              })
              .where((award) => award['title'].toString().isNotEmpty),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> claimAwardRewards(int index) async {
    final award = awards[index];
    final id = award['id']?.toString() ?? '';
    if (id.isNotEmpty) {
      final response = await _userRepo.claimAchievement(
        achievementId: id,
        isShowLoader: true,
      );
      if (response == null || response['statusCode'] == 0) {
        Get.snackbar('Awards', 'Could not claim this reward.');
        return;
      }
      award['isClaimed'] = true;
      awards[index] = Map<String, dynamic>.from(award);
    }
    Get.snackbar(
      'Rewards Claimed!',
      'You claimed ${award['points']} points for "${award['title']}"!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _toDouble(dynamic value) {
    if (value is double) return value.clamp(0.0, 1.0);
    if (value is num) return value.toDouble().clamp(0.0, 1.0);
    return double.tryParse(value?.toString() ?? '')?.clamp(0.0, 1.0) ?? 0;
  }
}
