import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_room/models/live_room_filter_state.dart';
import 'package:qobo_one_live/app/user_flow/live_room/widgets/live_room_filter_sheet.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/models/live_streaming/live_stream_access_result.dart';
import 'package:qobo_one_live/repo/activity/activity_repo.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_dialogs/live_stream_access_denied_dialog.dart';
import 'package:qobo_one_live/utils/live_streaming_permissions.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

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
  final isStartingLiveStream = false.obs;
  final isLiveActionMenuOpen = false.obs;
  final selectedRoomsMode = 'audio'.obs;
  final videoRooms = <Map<String, dynamic>>[].obs;
  final audioRooms = <Map<String, dynamic>>[].obs;
  final isVideoRoomsLoading = false.obs;
  final isAudioRoomsLoading = false.obs;

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
    fetchSelectedRoomMode();
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

  bool get isRoomsAudioMode => selectedRoomsMode.value == 'audio';

  bool get isRoomsVideoMode => selectedRoomsMode.value == 'video';

  void selectRoomsMode(String mode) {
    final normalized = mode.toLowerCase() == 'video' ? 'video' : 'audio';
    if (selectedRoomsMode.value == normalized) return;
    selectedRoomsMode.value = normalized;
    unawaited(fetchSelectedRoomMode());
  }

  Future<void> fetchSelectedRoomMode({bool refresh = true}) {
    return isRoomsAudioMode
        ? fetchAudioRooms(refresh: refresh)
        : fetchVideoRooms(refresh: refresh);
  }

  Future<void> fetchVideoRooms({bool refresh = true}) async {
    await _fetchTypedRooms(
      type: 'video',
      target: videoRooms,
      loading: isVideoRoomsLoading,
      refresh: refresh,
    );
  }

  Future<void> fetchAudioRooms({bool refresh = true}) async {
    await _fetchTypedRooms(
      type: 'audio',
      target: audioRooms,
      loading: isAudioRoomsLoading,
      refresh: refresh,
    );
  }

  Future<void> _fetchTypedRooms({
    required String type,
    required RxList<Map<String, dynamic>> target,
    required RxBool loading,
    required bool refresh,
  }) async {
    if (loading.value) return;
    try {
      loading.value = true;
      final response = await _roomRepo.listActiveRooms(
        type: type,
        page: 1,
        limit: 30,
        isShowLoader: false,
      );
      if (_isRoomApiSuccess(response)) {
        final rooms = _extractRoomList(
          response?['data'],
        ).map((room) => _withRoomType(room, type)).toList();
        target.assignAll(rooms);
        return;
      }
      if (refresh) target.clear();
    } catch (_) {
      if (refresh) target.clear();
    } finally {
      loading.value = false;
    }
  }

  void openCreateSelectedRoom() {
    Get.toNamed(
      Routes.LIVE_ROOM_CREATE,
      arguments: {'type': isRoomsAudioMode ? 'AUDIO' : 'VIDEO'},
    );
  }

  void openCreateVideoRoom() {
    Get.toNamed(Routes.LIVE_ROOM_CREATE, arguments: {'type': 'VIDEO'});
  }

  void openCreateAudioRoom() {
    Get.toNamed(Routes.LIVE_ROOM_CREATE, arguments: {'type': 'AUDIO'});
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
    isLiveActionMenuOpen.value = false;
    unawaited(_openGoLiveWithAccessCheck());
  }

  void toggleLiveActionMenu() {
    isLiveActionMenuOpen.toggle();
  }

  void closeLiveActionMenu() {
    isLiveActionMenuOpen.value = false;
  }

  Future<void> _openGoLiveWithAccessCheck() async {
    final context = Get.context;
    if (context == null) return;

    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    await session?.loadFromStorage();
    if (!context.mounted) return;
    final userId = session?.userId ?? '';
    if (userId.isEmpty) {
      AppToast.showError(context, 'Please log in to go live');
      return;
    }

    final response = await _roomRepo.verifyLiveStreamingAccess(
      userId: userId,
      isShowLoader: true,
    );
    final access = LiveStreamAccessResult.fromApiResponse(response);
    if (!context.mounted) return;

    if (access == null) {
      await _showLiveAccessDeniedDialog(
        context,
        message:
            response?['message']?.toString() ??
            'Unable to verify live streaming access',
      );
      return;
    }
    if (!access.accessAllowed) {
      await _showLiveAccessDeniedDialog(
        context,
        message: access.message.isNotEmpty
            ? access.message
            : 'You can\'t access this feature. Please join an agency or add coins.',
        coins: access.coins > 0 ? access.coins : null,
      );
      return;
    }

    await _startLiveStreamingNow(context, session);
  }

  Future<void> _startLiveStreamingNow(
    BuildContext context,
    UserSessionController? session,
  ) async {
    if (isStartingLiveStream.value) return;
    isStartingLiveStream.value = true;
    try {
      final title = _currentUserLiveTitle(session);
      final liveId = ZegoLiveIdUtils.sanitize(ZegoLiveIdUtils.generate());

      final response = await _roomRepo.createLiveStreaming(
        name: title,
        liveStreamingId: liveId,
        onlyFollows: false,
        isShowLoader: true,
      );
      if (!context.mounted) return;

      final roomData = _isRoomApiSuccess(response)
          ? _normalizeLiveStreamingPayload(response?['data'], title, liveId)
          : _buildLocalLiveStreamingPayload(title, liveId, session);

      final granted = await LiveStreamingPermissions.ensureHostVideoPermissions(
        context,
      );
      if (!context.mounted || !granted) return;

      await ZegoEngineUtils.resetForLiveProject().timeout(
        const Duration(milliseconds: 700),
        onTimeout: () {},
      );
      if (!context.mounted) return;

      final successMessage = _isRoomApiSuccess(response)
          ? (response?['message']?.toString() ?? 'Live streaming started')
          : 'Starting live stream';
      AppToast.showSuccess(context, successMessage);
      Get.offNamed(
        Routes.LIVE_BROADCAST,
        arguments: {'isHost': true, 'roomType': 'VIDEO', 'roomData': roomData},
      );
    } finally {
      isStartingLiveStream.value = false;
    }
  }

  String _currentUserLiveTitle(UserSessionController? session) {
    final name = session?.displayName.trim() ?? '';
    return name.isEmpty ? 'My Live' : name;
  }

  Map<String, dynamic> _normalizeLiveStreamingPayload(
    dynamic raw,
    String title,
    String liveId,
  ) {
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final zegoId = ZegoLiveIdUtils.sanitize(
      _text(map['zegoLiveId']) ??
          _text(map['zego_live_id']) ??
          _text(map['liveStreamingId']) ??
          _text(map['live_streaming_id']) ??
          liveId,
    );
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;

    map['name'] = _text(map['name']) ?? title;
    map['title'] = _text(map['title']) ?? title;
    map['liveStreamingId'] = zegoId;
    map['zegoLiveId'] = zegoId;
    map['isLive'] = true;
    map.putIfAbsent('hostId', () => session?.userId ?? '');
    map.putIfAbsent('hostName', () => session?.displayName ?? title);
    map.putIfAbsent('hostAvatar', () => session?.displayPicturePath ?? '');
    map.putIfAbsent('displayPicture', () => session?.displayPicturePath ?? '');
    return map;
  }

  Map<String, dynamic> _buildLocalLiveStreamingPayload(
    String title,
    String liveId,
    UserSessionController? session,
  ) {
    final zegoId = ZegoLiveIdUtils.sanitize(liveId);
    return {
      'name': title,
      'title': title,
      'liveStreamingId': zegoId,
      'zegoLiveId': zegoId,
      'onlyFollows': false,
      'isLive': true,
      if (session != null) ...{
        'hostId': session.userId,
        'hostName': session.displayName,
        'hostAvatar': session.displayPicturePath,
        'displayPicture': session.displayPicturePath,
      },
    };
  }

  Future<void> _showLiveAccessDeniedDialog(
    BuildContext context, {
    required String message,
    double? coins,
  }) {
    return LiveStreamAccessDeniedDialog.show(
      context,
      message: message,
      coins: coins,
      onBecomeAgency: () {
        Get.toNamed(Routes.AGENCY_ACCESS, arguments: {'mode': 'owner'});
      },
      onAddCoins: () {
        Get.to(() => const WalletView(), binding: WalletBinding());
      },
    );
  }

  void focusJoinLive() {
    isLiveActionMenuOpen.value = false;
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

  Future<void> joinTypedRoom(
    BuildContext context,
    Map<String, dynamic> room,
  ) async {
    final roomId = _roomId(room);
    if (roomId.isEmpty) {
      AppToast.showError(context, 'Room id is missing');
      return;
    }

    final response = await _roomRepo.joinRoom(roomId: roomId);
    if (!context.mounted) return;

    if (!_isRoomApiSuccess(response)) {
      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Could not join room',
      );
      return;
    }

    final payload = _normalizeJoinPayload(
      response?['data'],
      fallbackRoom: room,
      fallbackRoomId: roomId,
    );
    final roomType = _text(payload['type'])?.toUpperCase() ?? 'VIDEO';
    await ZegoEngineUtils.resetForRoomProject().timeout(
      const Duration(milliseconds: 700),
      onTimeout: () {},
    );
    Get.toNamed(
      Routes.LIVE_BROADCAST,
      arguments: {'isHost': false, 'roomType': roomType, 'roomData': payload},
    );
  }

  List<Map<String, dynamic>> _extractRoomList(dynamic raw) {
    final list = raw is List
        ? raw
        : raw is Map
        ? raw['rooms'] ?? raw['items'] ?? raw['list'] ?? raw['data']
        : null;
    if (list is! List) return const <Map<String, dynamic>>[];
    return list
        .whereType<Map>()
        .map((room) => Map<String, dynamic>.from(room))
        .toList();
  }

  Map<String, dynamic> _withRoomType(Map<String, dynamic> room, String type) {
    final next = Map<String, dynamic>.from(room);
    next.putIfAbsent('type', () => type);
    return next;
  }

  Map<String, dynamic> _normalizeJoinPayload(
    dynamic raw, {
    required Map<String, dynamic> fallbackRoom,
    required String fallbackRoomId,
  }) {
    final data = raw is Map ? Map<String, dynamic>.from(raw) : {};
    final joinedRoom = data['room'] is Map
        ? Map<String, dynamic>.from(data['room'] as Map)
        : <String, dynamic>{};
    final payload = <String, dynamic>{
      ...fallbackRoom,
      ...joinedRoom,
      if (data['room'] is! Map) ...data,
    };
    final zegoStreaming = data['zegoStreaming'];
    if (zegoStreaming is Map) {
      payload['zegoStreaming'] = Map<String, dynamic>.from(zegoStreaming);
      payload.putIfAbsent('zegoToken', () => zegoStreaming['token']);
      payload.putIfAbsent('streamId', () => zegoStreaming['streamId']);
    }
    payload['room_id'] =
        _text(data['room_id']) ??
        _text(payload['room_id']) ??
        _text(payload['roomId']) ??
        fallbackRoomId;
    payload['id'] = _text(payload['id']) ?? payload['room_id'];
    payload['zegoLiveId'] =
        _text(data['zegoLiveId']) ??
        _text(data['channelName']) ??
        _text(payload['zegoLiveId']) ??
        _text(payload['channelName']) ??
        (zegoStreaming is Map ? _text(zegoStreaming['roomId']) : null) ??
        fallbackRoomId;
    payload['channelName'] =
        _text(data['channelName']) ??
        _text(payload['channelName']) ??
        payload['zegoLiveId'];
    payload['type'] =
        _text(payload['type']) ?? (isRoomsAudioMode ? 'audio' : 'video');
    return payload;
  }

  String _roomId(Map<String, dynamic> room) {
    return _text(room['room_id']) ??
        _text(room['roomId']) ??
        _text(room['_id']) ??
        _text(room['id']) ??
        '';
  }

  bool _isRoomApiSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['statusCode'];
    return code == 1 || code == 200 || code == 201 || code == true;
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    super.onClose();
  }
}
