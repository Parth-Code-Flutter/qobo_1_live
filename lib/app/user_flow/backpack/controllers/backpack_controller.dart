import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

class BackpackController extends GetxController {
  final List<Map<String, dynamic>> categories = [
    {'id': 1, 'name': 'Gifts'},
    {'id': 2, 'name': 'Avatar Frames'},
    {'id': 3, 'name': 'Entrance Effects'},
    {'id': 4, 'name': 'Chat Bubbles'},
  ];

  final selectedCategory = 1.obs;

  // Active equipped items
  final equippedFrame = RxnString('frame_gold');
  final equippedEffect = RxnString();
  final equippedBubble = RxnString();

  // Reactive Map of items currently owned
  final RxMap<int, List<Map<String, dynamic>>> mockItems = <int, List<Map<String, dynamic>>>{
    1: [
      {'id': 'gift_rose', 'name': 'Rose', 'icon': kIconHeart, 'quantity': 12, 'description': 'A beautiful red rose. Sends 1 love point.'},
      {'id': 'gift_diamond', 'name': 'Diamond', 'icon': kIconDiamond, 'quantity': 3, 'description': 'Precious diamond. Sends 100 diamond points.'},
    ],
    2: [
      {'id': 'frame_gold', 'name': 'Golden Crown', 'icon': kIconUserLevel, 'quantity': 1, 'description': 'Look like royalty with this gleaming golden crown frame.'},
    ],
    3: [
      {'id': 'effect_dragon', 'name': 'Dragon Arrival', 'icon': kIconActivity, 'quantity': 1, 'description': 'A massive fire-breathing dragon flies across the screen when you join.'},
    ],
    4: [
      {'id': 'bubble_ocean', 'name': 'Ocean Bubble', 'icon': kIconPointerCenter, 'quantity': 1, 'description': 'A cooling light-blue bubble theme for all room text chats.'},
    ],
  }.obs;

  void selectCategory(int categoryId) {
    selectedCategory.value = categoryId;
  }

  void equipItem(int categoryId, Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    final name = item['name'] as String;

    if (categoryId == 2) {
      if (equippedFrame.value == itemId) {
        equippedFrame.value = null;
        Get.snackbar('Backpack', 'Unequipped $name');
      } else {
        equippedFrame.value = itemId;
        Get.snackbar('Backpack', 'Equipped $name successfully!');
      }
    } else if (categoryId == 3) {
      if (equippedEffect.value == itemId) {
        equippedEffect.value = null;
        Get.snackbar('Backpack', 'Disabled $name effect');
      } else {
        equippedEffect.value = itemId;
        Get.snackbar('Backpack', 'Enabled $name effect!');
      }
    } else if (categoryId == 4) {
      if (equippedBubble.value == itemId) {
        equippedBubble.value = null;
        Get.snackbar('Backpack', 'Disabled $name bubble');
      } else {
        equippedBubble.value = itemId;
        Get.snackbar('Backpack', 'Activated $name chat bubble!');
      }
    } else {
      Get.snackbar('Gifts', 'Gifts can only be sent inside a Live Broadcast room.');
    }
  }
}
