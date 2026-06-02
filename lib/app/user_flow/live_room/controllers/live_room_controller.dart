import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_room/models/live_room_filter_state.dart';
import 'package:qobo_one_live/app/user_flow/live_room/widgets/live_room_filter_sheet.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/activity/activity_repo.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

/// Controller for live room flow.
class LiveRoomController extends GetxController {
  final RoomRepo _roomRepo = RoomRepo();
  final ActivityRepo _activityRepo = ActivityRepo();

  int selectedCategoryIndex = 0;
  LiveRoomFilterState filters = const LiveRoomFilterState();
  final isLoading = false.obs;
  final allRooms = <Map<String, dynamic>>[].obs;
  final rooms = <Map<String, dynamic>>[].obs;
  final promoBannerImageUrl = RxnString();
  final highlightJoinGrid = false.obs;
  final isSearchExpanded = false.obs;
  final searchQuery = ''.obs;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  bool get hasActiveFilters => filters.hasActiveFilters;

  bool get isSearching => searchQuery.value.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    fetchPromoBanner();
    fetchActiveRooms();
  }

  void _onSearchChanged() {
    final query = searchController.text.trim();
    if (searchQuery.value == query) return;
    searchQuery.value = query;
    _applySearchFilter();
  }

  void openSearch() {
    isSearchExpanded.value = true;
    Future.microtask(() {
      if (!searchFocusNode.hasFocus) {
        searchFocusNode.requestFocus();
      }
    });
  }

  void closeSearch() {
    searchController.clear();
    searchQuery.value = '';
    isSearchExpanded.value = false;
    searchFocusNode.unfocus();
    _applySearchFilter();
  }

  void _applySearchFilter() {
    final query = searchQuery.value.toLowerCase();
    if (query.isEmpty) {
      rooms.assignAll(allRooms);
      return;
    }

    rooms.assignAll(
      allRooms.where((room) {
        final title = (room['nameAge'] as String? ?? '').toLowerCase();
        final location = (room['location'] as String? ?? '').toLowerCase();
        final badge = (room['badge'] as String? ?? '').toLowerCase();
        return title.contains(query) ||
            location.contains(query) ||
            badge.contains(query);
      }),
    );
  }

  void onCategorySelected(int index) {
    if (selectedCategoryIndex == index) return;
    selectedCategoryIndex = index;
    update();
    fetchActiveRooms();
  }

  Future<void> openFilterSheet(BuildContext context) async {
    final result = await showLiveRoomFilterSheet(
      context: context,
      initial: filters,
    );
    if (result == null) return;
    filters = result;
    update();
    fetchActiveRooms();
  }

  Future<void> fetchPromoBanner() async {
    final response = await _activityRepo.getActivities(isShowLoader: false);
    if (response == null || response['statusCode'] != 1) return;
    final data = response['data'];
    if (data is! List) return;

    final events = data.whereType<Map>().toList()
      ..sort((a, b) {
        final aPriority = int.tryParse('${a['priority'] ?? 999}') ?? 999;
        final bPriority = int.tryParse('${b['priority'] ?? 999}') ?? 999;
        return aPriority.compareTo(bPriority);
      });

    for (final event in events) {
      final placement = event['placement']?.toString().toLowerCase();
      final status = event['status']?.toString().toLowerCase();
      final image = ApiImageUtils.normalize(event['imageUrl']?.toString());
      final isLiveRoomsPlacement =
          placement == null || placement.isEmpty || placement == 'live_rooms';
      if (isLiveRoomsPlacement && status == 'active' && image != null) {
        promoBannerImageUrl.value = image;
        return;
      }
    }
  }

  Future<void> fetchActiveRooms() async {
    try {
      isLoading.value = true;
      String? country;
      String? category;
      String? type;

      if (filters.roomType != LiveRoomFilterState.allTypes) {
        type = filters.roomType;
      }

      if (filters.region != LiveRoomFilterState.allRegions) {
        country = filters.region == 'GLOBAL' ? null : filters.region;
      }

      // Map UI tabs to API filters (backend may accept legacy keys too).
      if (selectedCategoryIndex == 0) {
        category = 'trending';
      } else if (selectedCategoryIndex == 1) {
        category = 'top';
      } else if (selectedCategoryIndex == 2) {
        category = 'new';
      } else if (selectedCategoryIndex == 3 && country == null) {
        country = 'IN';
      }

      var response = await _roomRepo.listActiveRooms(
        type: type,
        country: country,
        category: category,
        isShowLoader: false,
      );
      if (selectedCategoryIndex == 3 &&
          country == 'IN' &&
          !_hasRoomData(response)) {
        response = await _roomRepo.listActiveRooms(
          type: type,
          country: 'BD',
          category: category,
          isShowLoader: false,
        );
      }

      final List<Map<String, dynamic>> fetchedList = [];
      if (response != null &&
          response['statusCode'] == 1 &&
          response['data'] is List) {
        final rawRooms = response['data'] as List;
        for (final item in rawRooms) {
          if (item is Map) {
            fetchedList.add(_mapRoom(item));
          }
        }
      }

      allRooms.assignAll(fetchedList);
      _applySearchFilter();
    } catch (_) {
      // ignore
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _mapRoom(Map room) {
    final type = room['type']?.toString().toUpperCase() ?? 'VIDEO';
    final rankBadge = room['roomRankBadge'];
    final image = ApiImageUtils.normalize(
      room['coverImage']?.toString() ??
          room['image']?.toString() ??
          room['thumbnail']?.toString(),
    );
    final title =
        room['name']?.toString() ?? room['title']?.toString() ?? 'Room';
    final seats = room['maxSeats'] ?? room['seatConfig'] ?? 0;
    final count =
        room['heatScore'] ??
        room['viewerCount'] ??
        room['onlineCount'] ??
        room['listenerCount'] ??
        room['audienceCount'] ??
        0;

    return {
      'id': room['_id'] ?? room['id'] ?? '',
      'roomData': Map<String, dynamic>.from(room),
      'nameAge': seats == 0 ? title : '$title, $seats Seats',
      'badge': rankBadge is Map
          ? (rankBadge['label']?.toString() ?? type)
          : type,
      'roomType': type,
      'location':
          room['countryName']?.toString() ??
          room['countryCode']?.toString() ??
          room['country']?.toString() ??
          'IN',
      'points': count.toString(),
      'favorite': room['isFavorite'] == true || room['isFollowed'] == true,
      'image': image ?? (type == 'AUDIO' ? kImgTemp2 : kImgTemp3),
    };
  }

  bool _hasRoomData(Map<String, dynamic>? response) {
    return response != null &&
        response['statusCode'] == 1 &&
        response['data'] is List &&
        (response['data'] as List).isNotEmpty;
  }

  void openGoLive() {
    Get.toNamed(Routes.LIVE_ROOM_CREATE, arguments: {'mode': 'live_streaming'});
  }

  void focusJoinLive() {
    Get.toNamed(Routes.JOIN_LIVE);
  }

  void joinManualLive(String liveStreamId) {
    final id = liveStreamId.trim();
    if (id.isEmpty) return;

    Get.toNamed(
      Routes.LIVE_BROADCAST,
      arguments: {
        'isHost': false,
        'roomType': 'VIDEO',
        'roomData': {
          'id': id,
          'room_id': id,
          'zegoLiveId': id,
          'channelName': id,
          'name': 'Manual Live',
          'type': 'VIDEO',
        },
      },
    );
  }

  void joinRoom(Map<String, dynamic> room) {
    Get.toNamed(
      Routes.LIVE_BROADCAST,
      arguments: {
        'isHost': false,
        'roomType': room['roomType'] == 'AUDIO' ? 'AUDIO' : 'VIDEO',
        'roomData': room['roomData'],
      },
    );
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}
