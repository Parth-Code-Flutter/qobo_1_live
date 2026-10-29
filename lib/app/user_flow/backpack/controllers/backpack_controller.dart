import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/background/background_repo.dart';
import 'package:qobo_one_live/repo/frame/frame_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';

class BackpackController extends GetxController {
  BackpackController({
    UserRepo? userRepo,
    FrameRepo? frameRepo,
    BackgroundRepo? backgroundRepo,
  }) : _userRepo = userRepo ?? UserRepo(),
       _frameRepo = frameRepo ?? FrameRepo(),
       _backgroundRepo = backgroundRepo ?? BackgroundRepo();

  final UserRepo _userRepo;
  final FrameRepo _frameRepo;
  final BackgroundRepo _backgroundRepo;
  final isLoading = false.obs;

  final categories = <Map<String, dynamic>>[
    {'id': 1, 'name': 'Gifts'},
    {'id': 2, 'name': 'Avatar Frames'},
    {'id': 3, 'name': 'Entrance Effects'},
    {'id': 4, 'name': 'Chat Bubbles'},
    {'id': 5, 'name': 'Profile Backgrounds'},
  ].obs;

  final selectedCategory = 1.obs;

  // Active equipped items
  final equippedFrame = RxnString('frame_gold');
  final equippedFrameName = RxnString('Golden Crown');
  final equippedEffect = RxnString();

  /// Name of the equipped VIP entry frame. Independent from [equippedFrame].
  final equippedEntryName = RxnString();
  final equippedBubble = RxnString();
  final equippedBackground = RxnString();
  final equippedBackgroundName = RxnString();

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
    5: [
      {
        'id': 'background_loading',
        'name': 'Loading backgrounds',
        'icon': kIconMall,
        'quantity': 1,
        'description': 'Fetching purchased profile backgrounds.',
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
            if (categoryId == 0 || categoryId == 2 || categoryId == 5) {
              continue;
            }
            grouped
                .putIfAbsent(categoryId, () => <Map<String, dynamic>>[])
                .add({
                  'id': raw['id']?.toString() ?? '',
                  'name': () {
                    final name = raw['name']?.toString().trim() ?? '';
                    final title = raw['title']?.toString().trim() ?? '';
                    final giftName = raw['giftName']?.toString().trim() ?? '';
                    if (giftName.isNotEmpty) return giftName;
                    if (title.isNotEmpty) return title;
                    if (name.isNotEmpty &&
                        !RegExp(
                          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
                        ).hasMatch(name)) {
                      return name;
                    }
                    return 'Gift';
                  }(),
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
      await _fetchEntryFrames();
      await _fetchProfileBackgrounds();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchAvatarFrames() async {
    final response = await _frameRepo.getMyBackpack(
      type: FrameCatalogType.avatar,
      isShowLoader: false,
    );
    if (response == null) return;
    final frames = _mapOwnedFrames(response, entry: false);
    final active = _equippedOwnedFrame(frames);

    final merged = Map<int, List<Map<String, dynamic>>>.from(mockItems);
    merged[2] = frames;
    mockItems.assignAll(merged);
    equippedFrame.value = active?['id']?.toString();
    equippedFrameName.value = active?['name']?.toString();
  }

  /// Owned VIP arrival frames. Equipping one does not clear the avatar frame.
  Future<void> _fetchEntryFrames() async {
    final response = await _frameRepo.getMyBackpack(
      type: FrameCatalogType.entry,
      isShowLoader: false,
    );
    if (response == null) return;
    final frames = _mapOwnedFrames(response, entry: true);
    final active = _equippedOwnedFrame(frames);
    final entryIds = frames.map((frame) => frame['id']?.toString()).toSet();

    final kept = (mockItems[3] ?? const <Map<String, dynamic>>[]).where((item) {
      final id = item['id']?.toString() ?? '';
      if (id == 'effect_dragon' || item['catalog'] == 'frame') return false;
      return true;
    }).toList();
    final merged = Map<int, List<Map<String, dynamic>>>.from(mockItems);
    merged[3] = [...frames, ...kept];
    mockItems.assignAll(merged);

    if (active != null) {
      equippedEffect.value = active['id']?.toString();
      equippedEntryName.value = active['name']?.toString();
    } else if (entryIds.contains(equippedEffect.value)) {
      equippedEffect.value = null;
      equippedEntryName.value = null;
    }
  }

  List<Map<String, dynamic>> _mapOwnedFrames(
    Map<String, dynamic> response, {
    required bool entry,
  }) {
    final frames = <Map<String, dynamic>>[];
    for (final raw in _extractList(response['data']).whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final frameDetails = item['frameDetails'] ?? item['frame_details'];
      final frame = frameDetails is Map
          ? Map<String, dynamic>.from(frameDetails)
          : const <String, dynamic>{};
      final isEntry = frameCatalogIsEntry(item, details: frame);
      if (entry != isEntry) continue;

      final itemId = item['id']?.toString() ?? '';
      if (itemId.isEmpty) continue;

      final name = frame['name']?.toString() ??
          (entry ? 'Entry Frame' : 'Avatar Frame');
      final category = frame['category']?.toString() ?? '';
      final isEquipped = item['isEquipped'] == true;
      frames.add({
        'id': itemId,
        'frameId': frame['id']?.toString() ?? item['itemId']?.toString() ?? '',
        'name': name,
        'category': category,
        'isVip': isEntry,
        'frameKind': entry ? 'entry' : 'avatar',
        'catalog': 'frame',
        'icon': kIconUserLevel,
        // Backpack rows may be SVGA. Static image fields cover older records.
        'svgaUrl':
            ApiImageUtils.normalize(
              _firstText([
                frame['svgaUrl'],
                frame['svga_url'],
                frame['animationUrl'],
                frame['animation_url'],
                item['svgaUrl'],
                item['animationUrl'],
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
        'description': entry
            ? 'Entry · ${_frameExpiryLabel(item['expiresAt'])}'
            : _frameExpiryLabel(item['expiresAt']),
        'isEquipped': isEquipped,
        'expiresAt': item['expiresAt']?.toString() ?? '',
      });
    }
    return frames;
  }

  Map<String, dynamic>? _equippedOwnedFrame(List<Map<String, dynamic>> frames) {
    for (final frame in frames) {
      if (frame['isEquipped'] == true) return frame;
    }
    return null;
  }

  Future<void> _fetchProfileBackgrounds() async {
    final response = await _backgroundRepo.getMyBackpack(isShowLoader: false);
    final backgrounds = <Map<String, dynamic>>[];
    String? activeBackgroundId;
    String? activeBackgroundName;

    for (final raw in _extractList(response?['data']).whereType<Map>()) {
      final item = Map<String, dynamic>.from(raw);
      final itemType = item['itemType']?.toString().toUpperCase() ?? '';
      if (itemType.isNotEmpty &&
          itemType != 'PROFILE_BACKGROUND' &&
          itemType != 'BACKGROUND') {
        continue;
      }

      final backgroundDetails =
          item['backgroundDetails'] ?? item['background_details'];
      final background = backgroundDetails is Map
          ? Map<String, dynamic>.from(backgroundDetails)
          : const <String, dynamic>{};
      final itemId = item['id']?.toString() ?? '';
      if (itemId.isEmpty) continue;

      final name = background['name']?.toString() ?? 'Profile Background';
      final isEquipped = item['isEquipped'] == true;
      final expiresAt = item['expiresAt']?.toString() ?? '';
      final isExpired = _isExpired(expiresAt);
      if (isEquipped && !isExpired) {
        activeBackgroundId = itemId;
        activeBackgroundName = name;
      }

      backgrounds.add({
        'id': itemId,
        'backgroundId':
            background['id']?.toString() ??
            item['itemId']?.toString() ??
            item['item_id']?.toString() ??
            '',
        'name': name,
        'icon': kIconMall,
        'imageUrl':
            ApiImageUtils.normalize(
              ProfileBackgroundMedia.preferredDisplayUrl([
                background['previewUrl'],
                background['thumbnail'],
                background['thumbnailUrl'],
                background['coverImage'],
                background['image'],
                background['imageUrl'],
                item['previewUrl'],
                item['thumbnail'],
                item['thumbnailUrl'],
                item['image'],
                item['imageUrl'],
                background['animationUrl'],
                background['svgaUrl'],
                background['svga'],
              ]),
            ) ??
            '',
        'previewImageUrl':
            ApiImageUtils.normalize(
              _firstNonSvgaText([
                background['previewUrl'],
                background['thumbnail'],
                background['thumbnailUrl'],
                background['coverImage'],
                background['image'],
                background['imageUrl'],
                item['image'],
                item['imageUrl'],
              ]),
            ) ??
            '',
        'quantity': 1,
        'description': isExpired
            ? 'Expired'
            : _itemExpiryLabel(expiresAt),
        'isEquipped': isEquipped && !isExpired,
        'isExpired': isExpired,
        'expiresAt': expiresAt,
        'durationDays': _toInt(
          background['durationDays'] ?? background['duration_days'],
        ),
        'category': background['category']?.toString() ?? '',
      });
    }

    // Always clear the loading placeholder, even when inventory is empty.
    final merged = Map<int, List<Map<String, dynamic>>>.from(mockItems);
    merged[5] = backgrounds;
    mockItems.assignAll(merged);
    equippedBackground.value = activeBackgroundId;
    equippedBackgroundName.value = activeBackgroundName;
  }

  Future<void> equipItem(int categoryId, Map<String, dynamic> item) async {
    final itemId = item['id'] as String;
    final name = item['name'] as String;
    final isCurrentlyEquipped =
        categoryId == 2 && equippedFrame.value == itemId ||
        categoryId == 3 && equippedEffect.value == itemId ||
        categoryId == 4 && equippedBubble.value == itemId ||
        categoryId == 5 && equippedBackground.value == itemId;

    if (categoryId == 2) {
      await _equipAvatarFrame(item: item);
      return;
    } else if (categoryId == 3 && item['catalog'] == 'frame') {
      await _equipEntryFrame(item: item);
      return;
    } else if (categoryId == 5) {
      await _equipProfileBackground(itemId: itemId, name: name);
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
    required Map<String, dynamic> item,
  }) async {
    final itemId = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Avatar Frame';
    if (itemId.isEmpty) return;

    // Avatar slot only. An equipped entry frame stays on its own slot.
    final shouldEquip = equippedFrame.value != itemId;
    final response = await _frameRepo.equipFrame(
      backpackItemId: itemId,
      equip: shouldEquip,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      _showBackpackDialog('Could not update this frame.');
      return;
    }

    // Refresh backpack list + session so Profile tab picks up the new frame URL.
    await _fetchAvatarFrames();
    await _refreshProfileSession();
    _showBackpackDialog(
      shouldEquip ? 'Equipped $name successfully!' : 'Unequipped $name',
    );
  }

  Future<void> _equipEntryFrame({
    required Map<String, dynamic> item,
  }) async {
    final itemId = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Entry Frame';
    if (itemId.isEmpty) return;

    final shouldEquip = equippedEffect.value != itemId;
    final response = await _frameRepo.equipFrame(
      backpackItemId: itemId,
      equip: shouldEquip,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      _showBackpackDialog('Could not update this entry frame.');
      return;
    }

    await _fetchEntryFrames();
    await _refreshProfileSession();
    _showBackpackDialog(
      shouldEquip ? 'Equipped $name successfully!' : 'Unequipped $name',
    );
  }

  Future<void> _equipProfileBackground({
    required String itemId,
    required String name,
  }) async {
    final items = mockItems[5] ?? const <Map<String, dynamic>>[];
    Map<String, dynamic>? target;
    for (final item in items) {
      if (item['id']?.toString() == itemId) {
        target = item;
        break;
      }
    }
    if (target?['isExpired'] == true) {
      _showBackpackDialog('This background has expired.');
      return;
    }

    final shouldEquip = equippedBackground.value != itemId;
    final response = await _backgroundRepo.equipBackground(
      backpackItemId: itemId,
      equip: shouldEquip,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      _showBackpackDialog('Could not update this background.');
      return;
    }

    await _fetchProfileBackgrounds();
    await _refreshProfileSession();
    _showBackpackDialog(
      shouldEquip ? 'Equipped $name successfully!' : 'Unequipped $name',
    );
  }

  /// Syncs equipped cosmetics into [UserSessionController] for Profile / other tabs.
  Future<void> _refreshProfileSession() async {
    if (!Get.isRegistered<UserSessionController>()) return;
    await Get.find<UserSessionController>().refreshProfileFromApi();
  }

  /// Prefer our shared dialog over snackbars for equip / unequip feedback.
  void _showBackpackDialog(String message) {
    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    CommonAppDialog.show(
      context,
      title: 'Backpack',
      message: message,
      actions: [
        CommonAppDialogAction(label: 'OK', isPrimary: true, onPressed: () {}),
      ],
    );
  }

  List _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final nested =
          value['items'] ??
          value['backgrounds'] ??
          value['frames'] ??
          value['data'] ??
          value['list'];
      if (nested is List) return nested;
    }
    return const [];
  }

  String _frameExpiryLabel(dynamic value) {
    return _itemExpiryLabel(
      value,
    ).replaceFirst('Purchased item', 'Purchased frame');
  }

  String _itemExpiryLabel(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return 'Purchased item';
    final date = DateTime.tryParse(text);
    if (date == null) return 'Expires $text';
    final local = date.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return 'Expires $y-$m-$d';
  }

  bool _isSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['statusCode'];
    if (code == 1 || code == 200 || code == 201) return true;
    final data = response['data'];
    return data is Map && data['success'] == true;
  }

  bool _isExpired(String raw) {
    final text = raw.trim();
    if (text.isEmpty || text == 'null') return false;
    final date = DateTime.tryParse(text);
    if (date == null) return false;
    return date.toUtc().isBefore(DateTime.now().toUtc());
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

  /// Same as [_firstText] but skips `.svga` URLs — used to find a real static
  /// thumbnail distinct from the animated file for SVGA-failure fallback.
  String? _firstNonSvgaText(Iterable<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty || text == 'null') continue;
      if (ProfileBackgroundMedia.isSvgaUrl(text)) continue;
      return text;
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
      case 5:
        return kIconMall;
      default:
        return kIconAward;
    }
  }
}
