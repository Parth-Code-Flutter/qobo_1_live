import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/activity/activity_repo.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

/// Controller for live room flow.
class LiveRoomController extends GetxController {
  final RoomRepo _roomRepo = RoomRepo();
  final ActivityRepo _activityRepo = ActivityRepo();

  int selectedCategoryIndex = 0;
  final isLoading = false.obs;
  final rooms = <Map<String, dynamic>>[].obs;
  final promoBannerImageUrl = RxnString();
  final highlightJoinGrid = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPromoBanner();
    fetchActiveRooms();
  }

  void onCategorySelected(int index) {
    if (selectedCategoryIndex == index) return;
    selectedCategoryIndex = index;
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

      // Map UI tabs to API filters (backend may accept legacy keys too).
      if (selectedCategoryIndex == 0) {
        category = 'trending';
      } else if (selectedCategoryIndex == 1) {
        category = 'top';
      } else if (selectedCategoryIndex == 2) {
        category = 'new';
      } else if (selectedCategoryIndex == 3) {
        country = 'IN';
      }

      var response = await _roomRepo.listActiveRooms(
        country: country,
        category: category,
        isShowLoader: false,
      );
      if (selectedCategoryIndex == 3 && !_hasRoomData(response)) {
        response = await _roomRepo.listActiveRooms(
          country: 'BD',
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

      rooms.assignAll(fetchedList);
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
    Get.toNamed(
      '/live-room-create',
      arguments: {'mode': 'live_streaming'},
    );
  }

  void focusJoinLive() {
    highlightJoinGrid.value = true;
    Future.delayed(const Duration(seconds: 3), () {
      if (isClosed) return;
      highlightJoinGrid.value = false;
    });
  }

  void joinRoom(Map<String, dynamic> room) {
    Get.toNamed(
      '/live-broadcast',
      arguments: {
        'isHost': false,
        'roomType': room['roomType'] == 'AUDIO' ? 'AUDIO' : 'VIDEO',
        'roomData': room['roomData'],
      },
    );
  }
}
