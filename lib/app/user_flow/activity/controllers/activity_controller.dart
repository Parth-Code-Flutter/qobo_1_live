import 'package:get/get.dart';

class ActivityController extends GetxController {
  final isLoading = false.obs;
  
  final activities = <Map<String, dynamic>>[
    {
      'title': 'Weekly Star Host Arena',
      'desc': 'Compete against other top broadcasters to win the legendary Crown Profile Badge!',
      'status': 'Active',
      'timeLeft': '3 days left',
      'gradient': [0xFFE65C00, 0xFFF9D423], // Orange/Gold
    },
    {
      'title': 'Dating King Festival',
      'desc': 'Unlock dating matches, send virtual roses, and climb the Love Leaderboard.',
      'status': 'Active',
      'timeLeft': '5 days left',
      'gradient': [0xFFFF42C3, 0xFFFF5EA7], // Pink/Rose
    },
    {
      'title': 'PK Battle Royale',
      'desc': 'Join or start consecutive PK battles. Top 10 champions receive 50,000 Coins!',
      'status': 'Starting Soon',
      'timeLeft': 'Starts in 12 hours',
      'gradient': [0xFF5C2D84, 0xFF7E4EA8], // Purple
    },
    {
      'title': 'Daily Recharge Bonus',
      'desc': 'Get up to 25% extra coins on every recharge via Razorpay or Google Pay.',
      'status': 'Active',
      'timeLeft': 'Ending today',
      'gradient': [0xFF11998E, 0xFF38EF7D], // Emerald
    },
  ].obs;

  void openActivityDetails(String title) {
    Get.snackbar(
      'Activity Registered',
      'You have successfully joined "$title"! Get ready to compete!',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
