import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/models/room_background_theme.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/live_streaming_permissions.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

/// Create flow: live streaming (Zego) vs audio/video party room.
enum LiveRoomCreateMode { liveStreaming, audioVideoRoom }

class LiveRoomCreateController extends GetxController {
  final streamNameController = TextEditingController();
  final announcementController = TextEditingController();

  final mode = LiveRoomCreateMode.audioVideoRoom.obs;
  final liveStreamingId = ''.obs;
  final onlyFollows = false.obs;

  final roomType = 'AUDIO'.obs;
  final seatCount = '8'.obs;
  final isPrivate = false.obs;
  final selectedCategoryIndex = 0.obs;
  final selectedRegion = 'IN'.obs;

  /// Catalog from `GET /api/room/backgrounds` for create-room banner pick.
  final roomBackgrounds = <RoomBackgroundTheme>[].obs;
  final isLoadingBackgrounds = false.obs;
  final selectedBackgroundId = RxnString();
  final selectedBackgroundImage = RxnString();

  static const categories = <String>[
    'Just Chat',
    'Music',
    'Dance',
    'Gaming',
    'Cooking',
    'Comedy',
  ];

  static const regions = <({String label, String code})>[
    (label: 'India', code: 'IN'),
    (label: 'Bangladesh', code: 'BD'),
    (label: 'Global', code: 'GLOBAL'),
  ];

  final RoomRepo _roomRepo = RoomRepo();

  bool get isLiveStreamingMode =>
      mode.value == LiveRoomCreateMode.liveStreaming;

  @override
  void onInit() {
    super.onInit();
    _generateLiveStreamingId();

    final args = Get.arguments;
    if (args is Map) {
      if (args['mode'] == 'live_streaming') {
        mode.value = LiveRoomCreateMode.liveStreaming;
      }
      if (args.containsKey('type')) {
        roomType.value = args['type'].toString();
      }
    }

    // Audio/video rooms use the host profile as the room identity — no manual title.
    if (!isLiveStreamingMode) {
      _applyCreatorRoomTitle();
      loadRoomBackgrounds();
    }
  }

  /// Session used for host avatar / id / auto room title.
  UserSessionController? get _session {
    if (!Get.isRegistered<UserSessionController>()) return null;
    return Get.find<UserSessionController>();
  }

  /// Room title derived from the logged-in creator (e.g. "Kirit's Room").
  String get creatorRoomTitle {
    final name = _session?.displayName.trim();
    if (name == null || name.isEmpty) return 'My Room';
    return "$name's Room";
  }

  String get creatorDisplayName => _session?.displayName ?? 'User';

  String get creatorUserId {
    final id = _session?.userId.trim() ?? '';
    return id.isEmpty ? '—' : id;
  }

  String? get creatorAvatarUrl => _session?.displayPictureUrl;

  String get creatorFrameUrl => _session?.profileFrameUrl ?? '';

  /// Keeps [streamNameController] in sync for the create API payload.
  void _applyCreatorRoomTitle() {
    streamNameController.text = creatorRoomTitle;
  }

  void _generateLiveStreamingId() {
    liveStreamingId.value = ZegoLiveIdUtils.generate();
  }

  void regenerateLiveStreamingId() {
    _generateLiveStreamingId();
  }

  void selectRoomType(String type) => roomType.value = type;

  void selectSeats(String count) => seatCount.value = count;

  void selectCategory(int index) => selectedCategoryIndex.value = index;

  void selectRegion(String code) => selectedRegion.value = code;

  void setPrivate(bool value) => isPrivate.value = value;

  void setOnlyFollows(bool value) => onlyFollows.value = value;

  Future<void> loadRoomBackgrounds() async {
    if (isLoadingBackgrounds.value) return;
    isLoadingBackgrounds.value = true;
    try {
      final response = await _roomRepo.getRoomBackgrounds(isShowLoader: false);
      if (_isSuccess(response)) {
        final themes = RoomBackgroundTheme.listFromResponse(
          response?['data'] ?? response,
        );
        roomBackgrounds.assignAll(themes);
        if (themes.isEmpty) return;

        final currentId = selectedBackgroundId.value;
        final stillValid =
            currentId != null &&
            currentId.isNotEmpty &&
            themes.any((t) => t.id == currentId);
        if (stillValid) return;

        final preferred = themes.firstWhere(
          (t) => t.isDefault,
          orElse: () => themes.first,
        );
        selectBackground(preferred);
      }
    } finally {
      isLoadingBackgrounds.value = false;
    }
  }

  /// Updates the selected room-background thumbnail (pink border + check).
  void selectBackground(RoomBackgroundTheme theme) {
    final id = theme.id.trim();
    if (id.isEmpty) return;
    // Always assign so Obx rebuilds even if the same image URL is reused.
    selectedBackgroundId.value = id;
    selectedBackgroundImage.value = theme.imageUrl;
    selectedBackgroundId.refresh();
  }

  /// Host starts a Zego live stream (from Live Rooms → Go Live).
  Future<void> startLiveStreaming(BuildContext context) async {
    final name = streamNameController.text.trim();
    if (name.isEmpty) {
      AppToast.showError(context, 'Please enter a live streaming name');
      return;
    }

    final response = await _roomRepo.createLiveStreaming(
      name: name,
      liveStreamingId: liveStreamingId.value,
      onlyFollows: onlyFollows.value,
    );

    if (!context.mounted) return;

    if (_isSuccess(response)) {
      final data = _normalizeStreamPayload(response!['data'], name);
      final granted = await LiveStreamingPermissions.ensureHostVideoPermissions(
        context,
      );
      if (!context.mounted || !granted) return;
      AppToast.showSuccess(
        context,
        response['message']?.toString() ?? 'Live streaming started',
      );
      _openZegoHost(data);
      return;
    }

    // API not ready yet — still open Zego with client-generated channel id.
    final granted = await LiveStreamingPermissions.ensureHostVideoPermissions(
      context,
    );
    if (!context.mounted || !granted) return;
    final localData = _buildLocalStreamPayload(name);
    AppToast.showSuccess(context, 'Starting live stream');
    _openZegoHost(localData);
  }

  void _openZegoHost(Map<String, dynamic> roomData) {
    roomData['type'] = 'live_stream';
    Get.offNamed(
      Routes.LIVE_BROADCAST,
      arguments: {
        'isHost': true,
        'roomType': 'LIVE_STREAM',
        'roomData': roomData,
      },
    );
  }

  Map<String, dynamic> _buildLocalStreamPayload(String name) {
    final id = ZegoLiveIdUtils.sanitize(liveStreamingId.value);
    liveStreamingId.value = id;
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    return {
      'name': name,
      'type': 'live_stream',
      'liveStreamingId': id,
      'zegoLiveId': id,
      'onlyFollows': onlyFollows.value,
      'isLive': true,
      if (session != null) ...{
        'hostId': session.userId,
        'hostName': session.displayName,
        'hostAvatar': session.displayPicturePath,
        'displayPicture': session.displayPicturePath,
      },
    };
  }

  Future<void> createRoom(BuildContext context) async {
    // Title always comes from the creator profile — no manual Room Name field.
    _applyCreatorRoomTitle();
    final roomTitle = streamNameController.text.trim();
    if (roomTitle.isEmpty) {
      AppToast.showError(context, 'Unable to resolve your profile name');
      return;
    }

    final maxSeats = int.tryParse(seatCount.value) ?? 8;
    final selectedType = roomType.value.trim().toUpperCase();
    final isVideo = selectedType == 'VIDEO';
    bool granted;
    if (isVideo) {
      granted = await LiveStreamingPermissions.ensureHostVideoPermissions(
        context,
      );
    } else {
      granted = await LiveStreamingPermissions.ensureHostAudioPermissions(
        context,
      );
    }
    if (!context.mounted || !granted) return;

    final response = await _roomRepo.createRoom(
      name: roomTitle,
      title: roomTitle,
      type: selectedType,
      country: selectedRegion.value,
      maxSeats: maxSeats,
      category: categories[selectedCategoryIndex.value],
      backgroundId: selectedBackgroundId.value,
      backgroundImage: selectedBackgroundImage.value,
      isPrivate: isPrivate.value,
    );

    if (!context.mounted) return;

    if (_isSuccess(response)) {
      AppToast.showSuccess(
        context,
        response!['message']?.toString() ?? 'Room created successfully!',
      );
      await ZegoEngineUtils.resetForRoomProject();
      final roomData = _normalizeCreatedRoomData(
        response['data'],
        selectedType: selectedType,
      );
      Get.offNamed(
        Routes.LIVE_BROADCAST,
        arguments: {
          'isHost': true,
          // Always AUDIO/VIDEO so broadcast opens group-call UI, not live stream.
          'roomType': isVideo ? 'VIDEO' : 'AUDIO',
          'roomData': roomData,
        },
      );
    } else {
      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Failed to create room',
      );
    }
  }

  /// Ensures create-room opens the correct party-room UI even when the API
  /// nests the room object or omits `type` / `room_id` aliases.
  Map<String, dynamic> _normalizeCreatedRoomData(
    dynamic raw, {
    required String selectedType,
  }) {
    final root = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final nestedRoom = root['room'] is Map
        ? Map<String, dynamic>.from(root['room'] as Map)
        : const <String, dynamic>{};
    final map = <String, dynamic>{
      ...root,
      if (nestedRoom.isNotEmpty) ...nestedRoom,
    };

    final partyType = selectedType.toLowerCase() == 'audio' ? 'audio' : 'video';
    // Client selection wins — never let a mistyped API `type` open live UI.
    map['type'] = partyType;
    map['roomType'] = partyType;

    final roomId =
        _text(map['room_id']) ??
        _text(map['roomId']) ??
        _text(map['_id']) ??
        _text(map['id']) ??
        _text(root['room_id']) ??
        _text(root['roomId']) ??
        _text(root['_id']) ??
        _text(root['id']);
    if (roomId != null) {
      map['room_id'] = roomId;
      map['roomId'] = roomId;
      map.putIfAbsent('id', () => roomId);
    }

    final bgId = selectedBackgroundId.value?.trim();
    final bgImage = selectedBackgroundImage.value?.trim();
    if (bgId != null && bgId.isNotEmpty) {
      map.putIfAbsent('backgroundId', () => bgId);
      map.putIfAbsent('background_id', () => bgId);
    }
    if (bgImage != null && bgImage.isNotEmpty) {
      map.putIfAbsent('backgroundImage', () => bgImage);
      map.putIfAbsent('background_image', () => bgImage);
    }
    return map;
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  bool _isSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['statusCode'];
    return code == 1 || code == 200 || code == 201;
  }

  /// Ensures Zego receives `zegoLiveId` even if backend uses another key.
  Map<String, dynamic> _normalizeStreamPayload(dynamic raw, String name) {
    final map = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final zegoId = ZegoLiveIdUtils.sanitize(
      map['zegoLiveId']?.toString() ??
          map['zego_live_id']?.toString() ??
          map['liveStreamingId']?.toString() ??
          map['live_streaming_id']?.toString() ??
          liveStreamingId.value,
    );

    map['name'] = map['name'] ?? name;
    map['type'] = 'live_stream';
    map['liveStreamingId'] = zegoId;
    map['zegoLiveId'] = zegoId;
    map['onlyFollows'] = map['onlyFollows'] ?? onlyFollows.value;

    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    if (session != null) {
      map.putIfAbsent('hostId', () => session.userId);
      map.putIfAbsent('hostName', () => session.displayName);
      map.putIfAbsent('hostAvatar', () => session.displayPicturePath);
      map.putIfAbsent('displayPicture', () => session.displayPicturePath);
    }
    return map;
  }

  @override
  void onClose() {
    streamNameController.dispose();
    announcementController.dispose();
    super.onClose();
  }
}
