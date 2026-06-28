import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
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
  final selectedCoverPath = RxnString();

  final roomType = 'AUDIO'.obs;
  final seatCount = '8'.obs;
  final isPrivate = false.obs;
  final selectedCategoryIndex = 0.obs;
  final selectedRegion = 'IN'.obs;

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
  final ImagePicker _imagePicker = ImagePicker();

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

  Future<void> pickRoomCover(BuildContext context) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1280,
      );
      if (picked == null) return;
      selectedCoverPath.value = picked.path;
    } catch (_) {
      if (!context.mounted) return;
      AppToast.showError(context, 'Unable to open media picker');
    }
  }

  void clearRoomCover() {
    selectedCoverPath.value = null;
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
    Get.offNamed(
      Routes.LIVE_BROADCAST,
      arguments: {'isHost': true, 'roomType': 'VIDEO', 'roomData': roomData},
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
    if (streamNameController.text.trim().isEmpty) {
      AppToast.showError(context, 'Please enter a room name');
      return;
    }

    final maxSeats = int.tryParse(seatCount.value) ?? 8;
    final isVideo = roomType.value.toUpperCase() == 'VIDEO';
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
      name: streamNameController.text.trim(),
      type: roomType.value,
      country: selectedRegion.value,
      maxSeats: maxSeats,
      category: categories[selectedCategoryIndex.value],
      coverImageFilePath: selectedCoverPath.value,
      isPrivate: isPrivate.value,
    );

    if (!context.mounted) return;

    if (_isSuccess(response)) {
      AppToast.showSuccess(
        context,
        response!['message']?.toString() ?? 'Room created successfully!',
      );
      await ZegoEngineUtils.resetForLiveProject();
      Get.offNamed(
        Routes.LIVE_BROADCAST,
        arguments: {
          'isHost': true,
          'roomType': roomType.value,
          'roomData': response['data'],
        },
      );
    } else {
      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Failed to create room',
      );
    }
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
