import 'package:get/get.dart';

class FamilyController extends GetxController {
  final hasFamily = false.obs;

  final List<Map<String, dynamic>> popularFamilies = [
    {'name': 'The Royals', 'members': 450, 'level': 5, 'leader': 'KingArthur'},
    {'name': 'Star Gazers', 'members': 320, 'level': 4, 'leader': 'Luna'},
    {'name': 'Dragon Fire', 'members': 890, 'level': 7, 'leader': 'Draco'},
  ];

  void joinFamily(String name) {
    Get.snackbar('Family Request', 'Request sent to join $name!');
  }

  void createFamily() {
    Get.snackbar('Create Family', 'Family creation feature coming soon.');
  }
}
