import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

class BackpackController extends GetxController {
  final List<Map<String, dynamic>> categories = [
    {'id': 1, 'name': 'Gifts'},
    {'id': 2, 'name': 'Frames'},
    {'id': 3, 'name': 'Effects'},
  ];

  final selectedCategory = 1.obs;

  final Map<int, List<Map<String, dynamic>>> mockItems = {
    1: [
      {'name': 'Rose', 'icon': kIconHeart, 'quantity': 12},
      {'name': 'Diamond', 'icon': kIconDiamond, 'quantity': 3},
    ],
    2: [
      {'name': 'Silver Frame', 'icon': kIconUserLevel, 'quantity': 1},
    ],
    3: [
      {'name': 'Entrance Magic', 'icon': kIconActivity, 'quantity': 1},
    ],
  };

  void selectCategory(int categoryId) {
    selectedCategory.value = categoryId;
  }
}
