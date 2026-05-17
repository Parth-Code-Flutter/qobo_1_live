import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

class MallController extends GetxController {
  final List<Map<String, dynamic>> tabs = [
    {'id': 1, 'name': 'Avatar Frames'},
    {'id': 2, 'name': 'Entrance Effects'},
    {'id': 3, 'name': 'Chat Bubbles'},
  ];

  final selectedTab = 1.obs;

  final Map<int, List<Map<String, dynamic>>> storeItems = {
    1: [
      {'name': 'Golden Crown', 'icon': kIconUserLevel, 'price': 500, 'duration': '7 days'},
      {'name': 'Neon Border', 'icon': kIconVisitor, 'price': 1200, 'duration': '30 days'},
    ],
    2: [
      {'name': 'Dragon Arrival', 'icon': kIconActivity, 'price': 2000, 'duration': '30 days'},
      {'name': 'Star Shower', 'icon': kIconAward, 'price': 800, 'duration': '7 days'},
    ],
    3: [
      {'name': 'Ocean Bubble', 'icon': kIconPointerCenter, 'price': 300, 'duration': '7 days'},
    ],
  };

  void selectTab(int tabId) {
    selectedTab.value = tabId;
  }

  void buyItem(Map<String, dynamic> item) {
    Get.snackbar('Purchase', 'Bought ${item['name']} for ${item['price']} coins');
  }
}
