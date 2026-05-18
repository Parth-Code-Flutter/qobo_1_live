import 'package:get/get.dart';

class AwardController extends GetxController {
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
    await Future.delayed(const Duration(milliseconds: 600));
    isLoading.value = false;
  }

  void claimAwardRewards(int index) {
    final award = awards[index];
    Get.snackbar(
      'Rewards Claimed!',
      'You claimed ${award['points']} points for "${award['title']}"!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
