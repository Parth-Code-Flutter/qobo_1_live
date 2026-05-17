import 'package:get/get.dart';

class UserLevelController extends GetxController {
  final currentLevel = 12.obs;
  final currentExp = 4500.obs;
  final nextLevelExp = 10000.obs;

  double get progress => currentExp.value / nextLevelExp.value;

  final perks = <Map<String, String>>[
    {'title': 'Special Avatar Frame', 'subtitle': 'Unlock the silver frame at level 15'},
    {'title': 'Broadcast Effects', 'subtitle': 'Custom entrance animation'},
    {'title': 'Exclusive Gifts', 'subtitle': 'Send VIP gifts in live rooms'},
  ].obs;

  @override
  void onInit() {
    super.onInit();
    // In the future, fetch user level from API
  }
}
