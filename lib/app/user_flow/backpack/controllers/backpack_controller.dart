import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/frame/frame_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

class BackpackController extends GetxController {
  BackpackController({UserRepo? userRepo, FrameRepo? frameRepo})
    : _userRepo = userRepo ?? UserRepo(),
      _frameRepo = frameRepo ?? FrameRepo();

  final UserRepo _userRepo;
  final FrameRepo _frameRepo;
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
  final equippedFrameName = RxnString('Golden Crown');
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
      if (data is Map) {
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
          equippedEffect.value = _nullableText(equipped['effect']);
          equippedBubble.value = _nullableText(equipped['bubble']);
        }

        final apiItems = data['items'];
        if (apiItems is List) {
          final grouped = <int, List<Map<String, dynamic>>>{};
          for (final raw in apiItems.whereType<Map>()) {
            final categoryId = _toInt(raw['categoryId']);
            if (categoryId == 0 || categoryId == 2) continue;
            grouped
                .putIfAbsent(categoryId, () => <Map<String, dynamic>>[])
                .add({
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
            final merged = Map<int, List<Map<String, dynamic>>>.from(mockItems);
            merged.addAll(grouped);
            mockItems.assignAll(merged);
          }
        }
      }

      await _fetchAvatarFrames();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchAvatarFrames() async {
    final response = await _frameRepo.getMyBackpack(isShowLoader: false);
    final frames = <Map<String, dynamic>>[];
    String? activeFrameId;
    String? activeFrameName;

    for (final raw in _extractList(response?['data']).whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final frameDetails = item['frameDetails'];
      final frame = frameDetails is Map
          ? Map<String, dynamic>.from(frameDetails)
          : const <String, dynamic>{};
      final itemId = item['id']?.toString() ?? '';
      if (itemId.isEmpty) continue;

      final name = frame['name']?.toString() ?? 'Avatar Frame';
      final isEquipped = item['isEquipped'] == true;
      if (isEquipped) {
        activeFrameId = itemId;
        activeFrameName = name;
      }

      frames.add({
        'id': itemId,
        'frameId': frame['id']?.toString() ?? item['itemId']?.toString() ?? '',
        'name': name,
        'icon': kIconUserLevel,
        // `/my-backpack` may return an animated SVGA frame. Keep the static
        // image fields as fallback for older purchased-frame records.
        'svgaUrl':
            ApiImageUtils.normalize(
              _firstText([
                frame['animationUrl'],
                frame['animation_url'],
                frame['svgaUrl'],
                frame['svga_url'],
                item['animationUrl'],
                item['svgaUrl'],
              ]),
            ) ??
            '',
        'imageUrl':
            ApiImageUtils.normalize(
              _firstText([
                frame['image'],
                frame['imageUrl'],
                frame['previewUrl'],
                item['image'],
                item['imageUrl'],
              ]),
            ) ??
            '',
        'quantity': 1,
        'description': _frameExpiryLabel(item['expiresAt']),
        'isEquipped': isEquipped,
        'expiresAt': item['expiresAt']?.toString() ?? '',
      });
    }

    final merged = Map<int, List<Map<String, dynamic>>>.from(mockItems);
    merged[2] = frames;
    mockItems.assignAll(merged);
    equippedFrame.value = activeFrameId;
    equippedFrameName.value = activeFrameName;
  }

  Future<void> equipItem(int categoryId, Map<String, dynamic> item) async {
    final itemId = item['id'] as String;
    final name = item['name'] as String;
    final isCurrentlyEquipped =
        categoryId == 2 && equippedFrame.value == itemId ||
        categoryId == 3 && equippedEffect.value == itemId ||
        categoryId == 4 && equippedBubble.value == itemId;

    if (categoryId == 2) {
      await _equipAvatarFrame(itemId: itemId, name: name);
      return;
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

  Future<void> _equipAvatarFrame({
    required String itemId,
    required String name,
  }) async {
    final shouldEquip = equippedFrame.value != itemId;
    final response = await _frameRepo.equipFrame(
      backpackItemId: itemId,
      equip: shouldEquip,
      isShowLoader: true,
    );
    if (response == null || response['statusCode'] == 0) {
      Get.snackbar('Backpack', 'Could not update this frame.');
      return;
    }

    await _fetchAvatarFrames();
    Get.snackbar(
      'Backpack',
      shouldEquip ? 'Equipped $name successfully!' : 'Unequipped $name',
    );
  }

  List _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final nested = value['items'] ?? value['frames'] ?? value['data'];
      if (nested is List) return nested;
    }
    return const [];
  }

  String _frameExpiryLabel(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.trim().isEmpty || text == 'null') return 'Purchased frame';
    return 'Expires $text';
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

  String? _firstText(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
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
