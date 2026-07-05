import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';

class BackpackController extends GetxController {
  BackpackController({UserRepo? userRepo}) : _userRepo = userRepo ?? UserRepo();

  final UserRepo _userRepo;
  final isLoading = false.obs;

  final categories = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Gifts'},
    {'id': 2, 'name': 'Avatar Frames'},
    {'id': 3, 'name': 'Entrance Effects'},
    {'id': 4, 'name': 'Chat Bubbles'},
  ].obs;

  final selectedCategory = 1.obs;

  // Active equipped items
  final equippedFrame = RxnString('frame_gold');
  final equippedEffect = RxnString();
  final equippedBubble = RxnString();

  // Reactive Map of items currently owned
  final RxMap<int, List<Map<String, dynamic>>>
  mockItems = <int, List<Map<String, dynamic>>>{
    1: [
      {
        'id': 'gift_rose',
        'name': 'Rose',
        'icon': kIconHeart,
        'quantity': 12,
        'description': 'A beautiful red rose. Sends 1 love point.',
      },
      {
        'id': 'gift_diamond',
        'name': 'Diamond',
        'icon': kIconDiamond,
        'quantity': 3,
        'description': 'Precious diamond. Sends 100 diamond points.',
      },
    ],
    2: [
      {
        'id': 'frame_gold',
        'name': 'Golden Crown',
        'icon': kIconUserLevel,
        'quantity': 1,
        'description':
            'Look like royalty with this gleaming golden crown frame.',
      },
    ],
    3: [
      {
        'id': 'effect_dragon',
        'name': 'Dragon Arrival',
        'icon': kIconActivity,
        'quantity': 1,
        'description':
            'A massive fire-breathing dragon flies across the screen when you join.',
      },
    ],
    4: [
      {
        'id': 'bubble_ocean',
        'name': 'Ocean Bubble',
        'icon': kIconPointerCenter,
        'quantity': 1,
        'description':
            'A cooling light-blue bubble theme for all room text chats.',
      },
    ],
  }.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBackpack();
  }

  void selectCategory(int categoryId) {
    selectedCategory.value = categoryId;
  }

  Future<void> fetchBackpack() async {
    isLoading.value = true;
    try {
      final response = await _userRepo.getBackpack(isShowLoader: false);
      final data = response?['data'];
      if (data is! Map) return;

      final apiCategories = data['categories'];
      if (apiCategories is List && apiCategories.isNotEmpty) {
        categories.assignAll(
          apiCategories
              .whereType<Map>()
              .map((cat) {
                return <String, dynamic>{
                  'id': _toInt(cat['id']),
                  'name': cat['name']?.toString() ?? '',
                };
              })
              .where(
                (cat) => cat['id'] != 0 && cat['name'].toString().isNotEmpty,
              ),
        );
      }

      final equipped = data['equipped'];
      if (equipped is Map) {
        equippedFrame.value = _nullableText(equipped['frame']);
        equippedEffect.value = _nullableText(equipped['effect']);
        equippedBubble.value = _nullableText(equipped['bubble']);
      }

      final apiItems = data['items'];
      if (apiItems is List) {
        final grouped = <int, List<Map<String, dynamic>>>{};
        for (final raw in apiItems.whereType<Map>()) {
          final categoryId = _toInt(raw['categoryId']);
          if (categoryId == 0) continue;
          grouped.putIfAbsent(categoryId, () => <Map<String, dynamic>>[]).add({
            'id': raw['id']?.toString() ?? '',
            'name': raw['name']?.toString() ?? '',
            'icon': _iconForCategory(categoryId),
            'iconUrl': raw['iconUrl']?.toString() ?? '',
            'thumbnailUrl': raw['thumbnailUrl']?.toString() ?? '',
            'quantity': _toInt(raw['quantity']),
            'description': raw['description']?.toString() ?? '',
            'isEquipped': raw['isEquipped'] == true,
            'expiresAt': raw['expiresAt']?.toString() ?? '',
          });
        }
        if (grouped.isNotEmpty) {
          mockItems.assignAll(grouped);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> equipItem(int categoryId, Map<String, dynamic> item) async {
    final itemId = item['id'] as String;
    final name = item['name'] as String;
    final isCurrentlyEquipped =
        categoryId == 2 && equippedFrame.value == itemId ||
        categoryId == 3 && equippedEffect.value == itemId ||
        categoryId == 4 && equippedBubble.value == itemId;

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
      Get.snackbar(
        'Gifts',
        'Gifts can only be sent inside a Live Broadcast room.',
      );
      return;
    }

    final response = await _userRepo.equipBackpackItem(
      itemId: itemId,
      isEquipped: !isCurrentlyEquipped,
      isShowLoader: false,
    );
    if (response == null || response['statusCode'] == 0) {
      await fetchBackpack();
      Get.snackbar('Backpack', 'Could not update this item.');
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String? _nullableText(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty || text == 'null' ? null : text;
  }

  String _iconForCategory(int categoryId) {
    switch (categoryId) {
      case 1:
        return kIconHeart;
      case 2:
        return kIconUserLevel;
      case 3:
        return kIconActivity;
      case 4:
        return kIconPointerCenter;
      default:
        return kIconAward;
    }
  }
}
