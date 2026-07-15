import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/wallet/bindings/wallet_binding.dart';
import 'package:qobo_one_live/app/user_flow/wallet/views/wallet_view.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_navigation_helper.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_celebration_overlay.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

import '../models/audio_room_models.dart';
import '../utils/live_room_profile_utils.dart';
import '../widgets/gifts_bottom_sheet.dart';
import '../widgets/live_filters_sheet.dart';
import '../widgets/live_viewers_sheet.dart';

class LiveBroadcastController extends GetxController {
  LiveBroadcastController({
    EconomyRepo? economyRepo,
    AuthRepo? authRepo,
    RoomRepo? roomRepo,
  }) : _economyRepo = economyRepo ?? EconomyRepo(),
       _authRepo = authRepo ?? AuthRepo(),
       _roomRepo = roomRepo ?? RoomRepo();

  final EconomyRepo _economyRepo;
  final AuthRepo _authRepo;
  final RoomRepo _roomRepo;

  final isHost = false.obs;
  final roomType = 'VIDEO'.obs;
  final roomId = ''.obs;
  final receiverId = ''.obs;
  final hasExplicitStreamingId = false.obs;
  final connectionIssue = ''.obs;

  final streamTitle = ''.obs;
  final hostName = 'Live Host'.obs;
  final hostAvatarUrl = RxnString();
  final likesLabel = '0'.obs;
  final viewerCount = 0.obs;
  final liveViewers = <Map<String, dynamic>>[].obs;
  final isFollowingHost = false.obs;
  final isZegoConnected = false.obs;

  final chatMessages = <Map<String, dynamic>>[].obs;
  final chatTextController = TextEditingController();

  final isMicMuted = false.obs;
  final isCameraOff = false.obs;

  final coinsBalance = 0.obs;
  final diamondsBalance = 0.obs;
  final giftCatalog = <Map<String, String>>[].obs;
  final isLoadingGifts = false.obs;
  final selectedGiftReceiverId = RxnString();
  final selectedGiftReceiverName = RxnString();
  final isRoomGiftMode = true.obs;
  final audioRoomSeats = <AudioRoomSeatModel>[].obs;
  final audioInviteCandidates = <AudioRoomInviteCandidate>[].obs;
  final isLoadingAudioSeats = false.obs;
  final isLoadingInviteCandidates = false.obs;
  final liveBeautyEnabled = false.obs;
  final liveSmooth = 35.obs;
  final liveSkinTone = 25.obs;
  final liveBlush = 12.obs;
  final liveSharpen = 15.obs;

  Map<String, dynamic> _roomData = {};
  StreamSubscription<List<ZegoInRoomMessage>>? _messageSub;
  StreamSubscription<List<ZegoUIKitUser>>? _userSub;

  /// Dedupes audio-room gift celebrations triggered by Zego gift chat events.
  String? _lastCelebratedGiftKey;
  final Set<String> _seenGiftMessageKeys = <String>{};
  bool _giftChatBootstrapDone = false;
  Timer? _seatRefreshTimer;
  VoidCallback? _viewerCountListener;
  var _exitReported = false;
  var _hostEndConfirmed = false;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args.containsKey('isHost')) isHost.value = args['isHost'];
      if (args.containsKey('roomType')) roomType.value = args['roomType'];
      if (args.containsKey('roomData') && args['roomData'] != null) {
        _roomData = Map<String, dynamic>.from(args['roomData']);
        receiverId.value = _extractReceiverId(_roomData) ?? '';
        final streamingId = _extractStreamingId(_roomData);
        hasExplicitStreamingId.value = streamingId != null;
        final backendRoomId = _extractBackendRoomId(_roomData);
        final rawId = _isAudioVideoRoomPayload()
            ? (backendRoomId ?? streamingId ?? '')
            : (streamingId ?? backendRoomId ?? '');
        roomId.value = ZegoLiveIdUtils.sanitize(rawId);
      }
    }
    _hydrateHostProfile();
    _validateStreamingInput();
    loadWalletBalance();
    loadGiftCatalog();
    if (isAudioVideoRoom) {
      final initialSeats = _parseAudioSeats(_roomData);
      if (initialSeats.isNotEmpty) {
        audioRoomSeats.assignAll(initialSeats);
      }
      _startSeatRefreshPolling();
    }
    chatMessages.clear();
  }

  void _hydrateHostProfile() {
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;

    hostName.value = resolveHostName(
      isHost: isHost.value,
      sessionName: session?.displayName ?? '',
      roomData: _roomData,
    );
    hostAvatarUrl.value = resolveHostAvatarUrl(
      isHost: isHost.value,
      sessionAvatarUrl: session?.displayPictureUrl,
      roomData: _roomData,
    );
    streamTitle.value =
        readRoomField(_roomData, ['name', 'title', 'streamName']) ??
        hostName.value;

    final engagement = readEngagementCount(_roomData);
    likesLabel.value = formatCompactCount(engagement);

    if (receiverId.value.trim().isEmpty) {
      final hostId = resolveHostId(_roomData);
      if (hostId != null) receiverId.value = hostId;
    }
    if (isHost.value && session != null && receiverId.value.trim().isEmpty) {
      receiverId.value = session.userId;
    }

    final following =
        _roomData['isFollowing'] == true ||
        _roomData['isFollowed'] == true ||
        readNestedHost(_roomData)?['isFollowing'] == true;
    isFollowingHost.value = following;
  }

  Future<void> loadWalletBalance() async {
    final response = await _economyRepo.getWalletBalances(isShowLoader: false);
    final data = response?['data'];
    if (isEconomyApiSuccess(response) && data is Map) {
      coinsBalance.value = parseWalletAmount(
        data['coins'] ?? data['coin'] ?? data['balance'] ?? data['coinBalance'],
      );
      diamondsBalance.value = parseWalletAmount(
        data['diamonds'] ?? data['diamond'] ?? data['diamondBalance'],
      );
    }
  }

  void openWithdrawalWallet() {
    Get.to(() => const WalletView(), binding: WalletBinding());
  }

  List<String> get giftCategories {
    if (giftCatalog.isEmpty) return const [];
    final categories = <String>{};
    for (final gift in giftCatalog) {
      final category = gift['category']?.trim();
      if (category != null && category.isNotEmpty) {
        categories.add(category);
      }
    }
    final sorted = categories.toList()..sort();
    return sorted.isEmpty ? const ['Gifts'] : sorted;
  }

  List<Map<String, String>> giftsForCategory(String category) {
    if (giftCatalog.isEmpty) return const [];
    final normalized = category.trim().toLowerCase();
    if (normalized == 'gifts' || normalized == 'all') {
      return giftCatalog.toList();
    }
    final filtered = giftCatalog
        .where((gift) => (gift['category'] ?? '').toLowerCase() == normalized)
        .toList();
    return filtered.isNotEmpty ? filtered : giftCatalog.toList();
  }

  bool get canOpenZego => connectionIssue.value.isEmpty;

  void setConnectionIssue(String message) {
    connectionIssue.value = message;
  }

  void clearConnectionIssue() {
    connectionIssue.value = '';
  }

  bool get isVideoRoom => roomType.value.toUpperCase() != 'AUDIO';

  bool get isAudioVideoRoom => _isAudioVideoRoomPayload();

  bool get isAudioRoom {
    final payloadType = readRoomField(_roomData, [
      'type',
      'roomType',
    ])?.toLowerCase();
    return roomType.value.toUpperCase() == 'AUDIO' || payloadType == 'audio';
  }

  bool get isGroupCallRoom => isAudioVideoRoom;

  bool get canSendGifts => !isHost.value;

  /// Zego can emit call-end lifecycle events during participant changes.
  /// Hosts may leave the route only after explicitly confirming room end.
  bool get canProcessGroupCallEnd =>
      !isHost.value || (_hostEndConfirmed && _exitReported);

  String get giftTargetLabel {
    if (isRoomGiftMode.value) return 'Everyone in this room';
    final name = selectedGiftReceiverName.value?.trim();
    return name?.isNotEmpty == true ? name! : hostName.value;
  }

  String get giftSheetDescription => isRoomGiftMode.value
      ? 'This gift will be shared with everyone in the room.'
      : 'This gift will be sent privately to $giftTargetLabel.';

  /// Called after Zego room login — ensures host camera publishes and binds chat/users.
  void onZegoRoomLogined() {
    isZegoConnected.value = true;
    _bindZegoListeners();

    if (!isHost.value || !isVideoRoom) return;
    _turnOnHostMedia();
    Future.delayed(const Duration(milliseconds: 700), _turnOnHostMedia);
  }

  void _turnOnHostMedia() {
    try {
      final av = ZegoUIKitPrebuiltLiveStreamingController().audioVideo;
      av.camera.turnOn(true);
      av.microphone.turnOn(true);
      isCameraOff.value = false;
      isMicMuted.value = false;
    } catch (_) {
      // Zego controller not ready yet — turnOnCameraWhenJoining handles it.
    }
  }

  void _bindZegoListeners() {
    final zego = ZegoUIKitPrebuiltLiveStreamingController();

    _messageSub?.cancel();
    _messageSub = zego.message.stream().listen(_syncChatFromZego);
    _syncChatFromZego(zego.message.list());

    _userSub?.cancel();
    _userSub = zego.user.stream(includeFakeUser: false).listen(_syncViewers);

    if (_viewerCountListener != null) {
      zego.user.countNotifier.removeListener(_viewerCountListener!);
    }
    _viewerCountListener = _onViewerCountChanged;
    zego.user.countNotifier.addListener(_viewerCountListener!);
    _onViewerCountChanged();

    Future.microtask(() {
      try {
        _syncViewers(ZegoUIKit().getAllUsers());
      } catch (_) {}
    });
  }

  /// Group-call rooms share the same Zego message bus but not the live-stream
  /// controller facade. Subscribe through the base UIKit for peer gift events.
  void _bindGroupCallMessageListener() {
    _messageSub?.cancel();
    final zego = ZegoUIKit();
    _messageSub = zego.getInRoomMessageListStream().listen(_syncChatFromZego);
    _syncChatFromZego(zego.getInRoomMessages());
  }

  void _onViewerCountChanged() {
    viewerCount.value =
        ZegoUIKitPrebuiltLiveStreamingController().user.countNotifier.value;
  }

  void _syncViewers(List<ZegoUIKitUser> users) {
    final normalizedHostId = ZegoLiveIdUtils.sanitizeUserId(receiverId.value);
    final hostTargetId = receiverId.value.trim();
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    final mySanitized = ZegoLiveIdUtils.sanitizeUserId(
      session?.userId.isNotEmpty == true ? session!.userId : '',
    );

    liveViewers.assignAll(
      users.map((user) {
        final normalizedUserId = ZegoLiveIdUtils.sanitizeUserId(user.id);
        final isHost =
            normalizedHostId.isNotEmpty && normalizedUserId == normalizedHostId;
        final isCurrentUser =
            mySanitized.isNotEmpty && normalizedUserId == mySanitized;
        return <String, dynamic>{
          'id': user.id,
          'targetId': isHost && hostTargetId.isNotEmpty
              ? hostTargetId
              : user.id,
          'name': user.name.isNotEmpty ? user.name : 'Viewer',
          'avatarUrl': isHost ? hostAvatarUrl.value : null,
          'isHost': isHost,
          'isCurrentUser': isCurrentUser,
        };
      }),
    );
  }

  void _syncChatFromZego(List<ZegoInRoomMessage> messages) {
    final session = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    final myId = ZegoLiveIdUtils.sanitizeUserId(
      session?.userId.isNotEmpty == true
          ? session!.userId
          : 'user_${session?.hashCode ?? 0}',
    );

    chatMessages.assignAll(
      messages.map((message) => _mapZegoMessage(message, myId)),
    );

    // When someone else shares a gift in an audio room, play the celebration.
    _maybeCelebrateIncomingGift(messages, myId);
  }

  /// Plays the gift GIF for peer (non-self) gift chat events in audio rooms.
  void _maybeCelebrateIncomingGift(
    List<ZegoInRoomMessage> messages,
    String myUserId,
  ) {
    if (!isAudioRoom) return;

    final giftMessages = messages
        .where((m) => m.message.trim().startsWith('🎁 '))
        .toList();
    // First sync after join: mark existing gifts as seen (no replay/pop).
    if (!_giftChatBootstrapDone) {
      for (final message in giftMessages) {
        _seenGiftMessageKeys.add('${message.messageID}_${message.timestamp}');
      }
      _giftChatBootstrapDone = true;
      return;
    }
    if (giftMessages.isEmpty) return;

    // Celebrate only newly arrived peer gift messages (newest first).
    for (var i = giftMessages.length - 1; i >= 0; i--) {
      final message = giftMessages[i];
      final key = '${message.messageID}_${message.timestamp}';
      if (!_seenGiftMessageKeys.add(key)) continue;
      if (key == _lastCelebratedGiftKey) continue;

      final senderId = ZegoLiveIdUtils.sanitizeUserId(message.user.id);
      final isMine = senderId.isNotEmpty && senderId == myUserId;
      // Sender already celebrates on send-gift API success — skip duplicates.
      if (isMine) continue;

      _lastCelebratedGiftKey = key;
      final animUrl = parseGiftAnimUrl(message.message);
      final soundUrl = parseGiftSoundUrl(message.message);
      GiftCelebrationOverlay.show(
        giftName: _giftNameFromChatLabel(message.message),
        // Peer gifts play the same API animationUrl embedded in the chat payload.
        svgaUrl: animUrl,
        soundUrl: soundUrl,
        // svgaAsset: GiftCelebrationOverlay.jellyfishGiftAsset,
      );
      return;
    }
  }

  /// Extracts a readable gift name from labels like "🎁 sent Red Rose 🌹".
  String _giftNameFromChatLabel(String text) {
    final visible = stripGiftAnimMarker(text).replaceFirst('🎁 ', '').trim();
    final withoutSent = visible.startsWith('sent ')
        ? visible.substring(5).trim()
        : visible;
    if (withoutSent.isEmpty) return 'Gift';
    // Drop a trailing emoji/icon token when present.
    final parts = withoutSent.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts.last.runes.length <= 2) {
      return parts.sublist(0, parts.length - 1).join(' ');
    }
    return withoutSent;
  }

  /// Builds the Zego gift chat line, optionally embedding the animation URL.
  String _buildGiftChatLabel({
    required String? giftName,
    required String? giftIcon,
    required String animationUrl,
    required String soundUrl,
  }) {
    final name = giftName?.trim().isNotEmpty == true
        ? giftName!.trim()
        : 'Gift';
    final iconPart = isNetworkGiftIcon(giftIcon) ? '' : (giftIcon ?? '');
    final base = '🎁 sent $name $iconPart'.trim();
    final markers = <String>[
      if (animationUrl.isNotEmpty) '[[giftAnim:$animationUrl]]',
      if (soundUrl.isNotEmpty) '[[giftSound:$soundUrl]]',
    ];
    // Hidden markers let peers play the exact gift animation and sound.
    return markers.isEmpty ? base : '$base\n${markers.join('\n')}';
  }

  Map<String, dynamic> _mapZegoMessage(
    ZegoInRoomMessage message,
    String myUserId,
  ) {
    final senderName = message.user.name.isNotEmpty
        ? message.user.name
        : 'Viewer';
    final isMine = message.user.id == myUserId;
    final text = message.message;
    final isGift = text.startsWith('🎁 ');

    return {
      'sender': isMine ? 'You' : senderName,
      // Hide the embedded animation marker from the chat bubble.
      'message': isGift ? stripGiftAnimMarker(text) : text,
      'translation': '',
      'isTranslated': false,
      'isSystem': isGift,
    };
  }

  void handleZegoLoginFailed(int errorCode) {
    isZegoConnected.value = false;
    connectionIssue.value =
        'Could not join live room (error $errorCode). '
        'Verify Zego App ID / App Sign in the console.';
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    Get.snackbar(
      'Live stream',
      connectionIssue.value,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: kColorWhite,
      duration: const Duration(seconds: 4),
    );
  }

  void onGroupCallRoomConnected({bool bindMessages = true}) {
    isZegoConnected.value = true;
    connectionIssue.value = '';
    if (bindMessages) {
      _bindGroupCallMessageListener();
    }
  }

  void handleGroupCallRoomLoginFailed(int errorCode) {
    if (isZegoConnected.value) return;
    _showGroupCallLoginError(errorCode: errorCode);
  }

  void handleGroupCallRoomError(ZegoUIKitError error) {
    final method = error.method.toLowerCase();
    final isLoginError =
        error.code == ZegoUIKitErrorCode.roomLoginError ||
        method.contains('loginroom') ||
        method.contains('joinroom');

    // The prebuilt call error stream also reports participant media/device
    // errors. Those are not local room-login failures and must not alarm hosts.
    if (!isLoginError || isZegoConnected.value) return;
    _showGroupCallLoginError(errorCode: error.code);
  }

  void _showGroupCallLoginError({required int errorCode}) {
    isZegoConnected.value = false;
    connectionIssue.value =
        'Could not join room (error $errorCode). Please try again.';
    if (Get.isSnackbarOpen) {
      Get.closeAllSnackbars();
    }
    Get.snackbar(
      'Room call',
      connectionIssue.value,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: kColorWhite,
      duration: const Duration(seconds: 4),
    );
  }

  void _validateStreamingInput() {
    final liveId = roomId.value.trim();
    if (liveId.isEmpty || liveId == 'test_room' || liveId == 'null') {
      connectionIssue.value = isGroupCallRoom
          ? 'Room id is missing. Please ask backend to return room_id, roomId, zegoLiveId, or channelName.'
          : 'Live stream id is missing. Please ask backend to return zegoLiveId or channelName for this room.';
      return;
    }

    if (!isGroupCallRoom && !isHost.value && !hasExplicitStreamingId.value) {
      connectionIssue.value =
          'This room has only backend room id. Audience join needs zegoLiveId/channelName from API.';
      return;
    }

    connectionIssue.value = '';
  }

  String? _extractStreamingId(Map<String, dynamic> roomData) {
    const keys = [
      'zegoLiveId',
      'zego_live_id',
      'zegoRoomId',
      'zego_room_id',
      'channelName',
      'channel_name',
      'liveStreamingId',
      'livestreamingId',
      'live_streaming_id',
      'liveStreamId',
      'live_id',
      'liveId',
    ];

    return _firstNonEmpty(roomData, keys);
  }

  String? _extractBackendRoomId(Map<String, dynamic> roomData) {
    const keys = ['room_id', 'roomId', '_id', 'id'];

    return _firstNonEmpty(roomData, keys);
  }

  String? _extractReceiverId(Map<String, dynamic> roomData) {
    return resolveHostId(roomData);
  }

  String? _firstNonEmpty(Map<String, dynamic> roomData, List<String> keys) {
    return readRoomField(roomData, keys);
  }

  Future<void> sendMessage() async {
    final text = chatTextController.text.trim();
    if (text.isEmpty) return;

    final badWords = ['bad', 'scam', 'spam', 'abuse', 'hate', 'cheat', 'fraud'];
    var moderatedText = text;
    var containsBadWord = false;

    for (final word in badWords) {
      if (moderatedText.toLowerCase().contains(word)) {
        containsBadWord = true;
        final replacement = '*' * word.length;
        moderatedText = moderatedText.replaceAll(
          RegExp(word, caseSensitive: false),
          replacement,
        );
      }
    }

    chatTextController.clear();

    if (!isZegoConnected.value) {
      chatMessages.add({
        'sender': 'You',
        'message': moderatedText,
        'translation': '',
        'isTranslated': false,
        'isSystem': false,
      });
      return;
    }

    try {
      final sent = await ZegoUIKitPrebuiltLiveStreamingController().message
          .send(moderatedText);
      if (!sent) {
        Get.snackbar(
          'Message not sent',
          'Unable to send message to the room.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black87,
          colorText: kColorWhite,
        );
      }
    } catch (_) {
      Get.snackbar(
        'Message not sent',
        'Chat is not ready yet. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
    }

    if (containsBadWord) {
      Get.snackbar(
        'Moderation Filter',
        'Your comment was automatically filtered to keep the room safe.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.amber.shade900,
        colorText: kColorWhite,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> translateMessage(int index) async {
    if (index < 0 || index >= chatMessages.length) return;
    final msg = chatMessages[index];
    final text = msg['message']?.toString() ?? '';
    if (text.isEmpty || msg['isSystem'] == true) return;

    if (msg['translation'] != null &&
        msg['translation'].toString().isNotEmpty) {
      final currentVal = msg['isTranslated'] ?? false;
      chatMessages[index] = {...msg, 'isTranslated': !currentVal};
      return;
    }

    try {
      final response = await _roomRepo.translateText(
        text: text,
        targetLang: 'en',
        isShowLoader: false,
      );
      final translated =
          response?['data']?['translatedText']?.toString() ??
          response?['data']?['text']?.toString();
      if (translated != null && translated.isNotEmpty) {
        chatMessages[index] = {
          ...msg,
          'translation': translated,
          'isTranslated': true,
        };
        return;
      }
    } catch (_) {}

    Get.snackbar(
      'Translation',
      'This message is already in your native language.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black26,
      colorText: kColorWhite,
    );
  }

  Future<void> loadGiftCatalog() async {
    isLoadingGifts.value = true;
    try {
      final response = await _economyRepo.getGiftList(isShowLoader: false);
      final data = response?['data'];
      if (isEconomyApiSuccess(response) && data is List) {
        giftCatalog.assignAll(
          data
              .whereType<Map>()
              .map((raw) => _mapGift(Map<String, dynamic>.from(raw)))
              .where((gift) => (gift['id'] ?? '').isNotEmpty)
              .toList(),
        );
      }
    } finally {
      isLoadingGifts.value = false;
    }
  }

  Map<String, String> _mapGift(Map<String, dynamic> raw) {
    final name = raw['name']?.toString() ?? raw['title']?.toString() ?? 'Gift';
    final price = raw['price'] ?? raw['coins'] ?? raw['amount'] ?? 0;
    final icon =
        raw['icon']?.toString() ??
        raw['emoji']?.toString() ??
        raw['image']?.toString() ??
        raw['imageUrl']?.toString() ??
        '🎁';
    final category =
        raw['category']?.toString() ?? raw['type']?.toString() ?? 'Popular';
    // Backend gift animation clip (SVGA) — played after send-gift success.
    final animationUrl =
        raw['animationUrl']?.toString() ??
        raw['animation_url']?.toString() ??
        raw['svgaUrl']?.toString() ??
        '';
    final soundUrl =
        raw['soundUrl']?.toString() ??
        raw['sound_url']?.toString() ??
        raw['audioUrl']?.toString() ??
        raw['audio_url']?.toString() ??
        '';
    return {
      'id': raw['id']?.toString() ?? raw['_id']?.toString() ?? '',
      'name': name,
      'price': price.toString(),
      'icon': icon,
      'category': category,
      'animationUrl': animationUrl.trim(),
      'soundUrl': soundUrl.trim(),
    };
  }

  String _giftAnimationUrlFromResponse(
    Map<String, dynamic>? response,
    Map<String, String> gift,
  ) {
    final data = response?['data'];
    final responseGift = data is Map ? data['gift'] : null;
    final apiAnimationUrl = responseGift is Map
        ? (responseGift['animationUrl'] ??
                  responseGift['animation_url'] ??
                  responseGift['svgaUrl'])
              ?.toString()
              .trim()
        : null;
    if (apiAnimationUrl != null && apiAnimationUrl.isNotEmpty) {
      return apiAnimationUrl;
    }
    return gift['animationUrl']?.trim() ?? '';
  }

  String _giftSoundUrlFromResponse(
    Map<String, dynamic>? response,
    Map<String, String> gift,
  ) {
    final data = response?['data'];
    final responseGift = data is Map ? data['gift'] : null;
    final soundValue =
        (responseGift is Map
            ? responseGift['soundUrl'] ??
                  responseGift['sound_url'] ??
                  responseGift['audioUrl'] ??
                  responseGift['audio_url']
            : null) ??
        (data is Map
            ? data['soundUrl'] ??
                  data['sound_url'] ??
                  data['audioUrl'] ??
                  data['audio_url']
            : null);
    final apiSoundUrl = soundValue?.toString().trim();
    if (apiSoundUrl != null && apiSoundUrl.isNotEmpty) return apiSoundUrl;
    return gift['soundUrl']?.trim() ?? '';
  }

  Future<void> sendGift(Map<String, String> gift) async {
    final int price = int.tryParse(gift['price'] ?? '0') ?? 0;
    if (coinsBalance.value < price) {
      Get.snackbar(
        'Insufficient Coins',
        'You need ${price - coinsBalance.value} more coins to send this gift.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
      );
      return;
    }

    final giftId = gift['id']?.trim() ?? '';
    final currentRoomId = roomId.value.trim();
    final currentReceiverId =
        selectedGiftReceiverId.value?.trim().isNotEmpty == true
        ? selectedGiftReceiverId.value!.trim()
        : receiverId.value.trim();
    final scope = isRoomGiftMode.value ? 'room' : 'user';
    if (giftId.isEmpty ||
        currentRoomId.isEmpty ||
        (scope == 'user' && currentReceiverId.isEmpty)) {
      Get.snackbar(
        'Gift not sent',
        scope == 'room'
            ? 'Gift or room id is missing from live room data.'
            : 'Gift, receiver, or room id is missing from live room data.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
      );
      return;
    }

    final response = await _economyRepo.sendGift(
      receiverId: currentReceiverId.isEmpty ? null : currentReceiverId,
      giftId: giftId,
      roomId: currentRoomId,
      scope: scope,
      isShowLoader: true,
    );

    if (isEconomyApiSuccess(response)) {
      final showAudioRoomGiftAnimation = isAudioRoom;
      final animationUrl = _giftAnimationUrlFromResponse(response, gift);
      final soundUrl = _giftSoundUrlFromResponse(response, gift);
      if (showAudioRoomGiftAnimation) {
        // Close sheet first so the gift animation is visible over the room UI.
        Get.back();
        await Future<void>.delayed(const Duration(milliseconds: 300));
        GiftCelebrationOverlay.show(
          giftName: gift['name'],
          // Dynamic SVGA from gift-list API `animationUrl`.
          svgaUrl: animationUrl.isNotEmpty ? animationUrl : null,
          soundUrl: soundUrl.isNotEmpty ? soundUrl : null,
          // Local jellyfish SVGA disabled — API animationUrl is the source of truth.
          // svgaAsset: GiftCelebrationOverlay.jellyfishGiftAsset,
        );
      }

      unawaited(loadWalletBalance());

      final giftLabel = _buildGiftChatLabel(
        giftName: gift['name'],
        giftIcon: gift['icon'],
        animationUrl: animationUrl,
        soundUrl: soundUrl,
      );
      if (isZegoConnected.value) {
        if (isGroupCallRoom) {
          unawaited(ZegoUIKit().sendInRoomMessage(giftLabel));
        } else {
          unawaited(
            ZegoUIKitPrebuiltLiveStreamingController().message.send(giftLabel),
          );
        }
      } else {
        chatMessages.add({
          'sender': 'You',
          'message': stripGiftAnimMarker(giftLabel),
          'translation': '',
          'isTranslated': false,
          'isSystem': true,
        });
      }

      if (!showAudioRoomGiftAnimation) {
        Get.back();
        GiftCelebrationOverlay.show(
          giftName: gift['name'],
          svgaUrl: animationUrl.isNotEmpty ? animationUrl : null,
          soundUrl: soundUrl.isNotEmpty ? soundUrl : null,
        );
      }
    } else {
      Get.snackbar(
        'Gift not sent',
        response?['message']?.toString() ?? 'Unable to send this gift.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
      );
    }
  }

  void openViewersSheet() {
    Get.bottomSheet(
      const LiveViewersSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void openViewerProfile(Map<String, dynamic> viewer) {
    Get.dialog(
      LiveViewerProfileDialog(viewer: viewer),
      barrierColor: Colors.black.withValues(alpha: 0.68),
    );
  }

  void openGiftsSheet({
    String? receiverId,
    String? receiverName,
    bool roomGift = true,
  }) {
    isRoomGiftMode.value = roomGift;
    selectedGiftReceiverId.value = roomGift
        ? this.receiverId.value
        : receiverId;
    selectedGiftReceiverName.value = roomGift
        ? 'Everyone in this room'
        : receiverName;

    if (Get.isDialogOpen == true) Get.back();
    if (Get.isBottomSheetOpen == true) Get.back();

    Future.delayed(const Duration(milliseconds: 140), () {
      Get.bottomSheet(
        const GiftsBottomSheet(),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    });
  }

  void openLiveFiltersSheet() {
    if (!isHost.value || !isVideoRoom) return;
    Get.bottomSheet(
      const LiveFiltersSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> setLiveBeautyEnabled(bool value) async {
    liveBeautyEnabled.value = value;
    await _applyLiveBeauty();
  }

  Future<void> updateLiveFilter({
    int? smooth,
    int? skinTone,
    int? blush,
    int? sharpen,
  }) async {
    if (smooth != null) liveSmooth.value = smooth;
    if (skinTone != null) liveSkinTone.value = skinTone;
    if (blush != null) liveBlush.value = blush;
    if (sharpen != null) liveSharpen.value = sharpen;
    if (!liveBeautyEnabled.value) {
      liveBeautyEnabled.value = true;
    }
    await _applyLiveBeauty();
  }

  Future<void> resetLiveFilters() async {
    liveBeautyEnabled.value = false;
    liveSmooth.value = 35;
    liveSkinTone.value = 25;
    liveBlush.value = 12;
    liveSharpen.value = 15;
    try {
      await ZegoUIKit().resetBeautyEffect();
      await ZegoUIKit().enableBeauty(false);
    } catch (_) {}
  }

  Future<void> _applyLiveBeauty() async {
    try {
      await ZegoUIKit().startEffectsEnv();
      await ZegoUIKit().enableBeauty(liveBeautyEnabled.value);
      if (!liveBeautyEnabled.value) return;
      ZegoUIKit().setBeautifyValue(liveSkinTone.value, BeautyEffectType.whiten);
      ZegoUIKit().setBeautifyValue(liveBlush.value, BeautyEffectType.rosy);
      ZegoUIKit().setBeautifyValue(liveSmooth.value, BeautyEffectType.smooth);
      ZegoUIKit().setBeautifyValue(liveSharpen.value, BeautyEffectType.sharpen);
    } catch (_) {
      Get.snackbar(
        'Filters',
        'Unable to apply filters on this device right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
    }
  }

  /// Opens 1:1 chat with a viewer/host from the live room list.
  Future<void> openChatWithViewer(
    BuildContext context,
    Map<String, dynamic> viewer,
  ) async {
    if (viewer['isCurrentUser'] == true) return;

    final targetId =
        viewer['targetId']?.toString().trim() ??
        viewer['id']?.toString().trim() ??
        '';
    if (targetId.isEmpty) {
      _showToast(context, 'User profile is not available', isError: true);
      return;
    }

    if (_isViewerCurrentUser(targetId)) return;

    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }

    final launchContext = Get.context ?? context;
    await ChatNavigationHelper.openDirectChat(
      launchContext,
      targetId: targetId,
      name: viewer['name']?.toString() ?? 'User',
      imageUrl: viewer['avatarUrl']?.toString(),
    );
  }

  void _showToast(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    if (!context.mounted) return;
    if (isError) {
      AppToast.showError(context, message);
    } else {
      AppToast.showSuccess(context, message);
    }
  }

  bool _isViewerCurrentUser(String targetId) {
    if (!Get.isRegistered<UserSessionController>()) return false;
    final myId = Get.find<UserSessionController>().userId.trim();
    if (myId.isEmpty) return false;
    return myId == targetId ||
        ZegoLiveIdUtils.sanitizeUserId(myId) ==
            ZegoLiveIdUtils.sanitizeUserId(targetId);
  }

  String get audioRoomApiId {
    return (_extractBackendRoomId(_roomData) ?? roomId.value).trim();
  }

  void _startSeatRefreshPolling() {
    _seatRefreshTimer?.cancel();
    unawaited(loadAudioRoomSeats());
    _seatRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_exitReported || !isAudioVideoRoom) {
        _stopSeatRefreshPolling();
        return;
      }
      unawaited(loadAudioRoomSeats());
    });
  }

  void _stopSeatRefreshPolling() {
    _seatRefreshTimer?.cancel();
    _seatRefreshTimer = null;
  }

  Future<void> loadAudioRoomSeats({bool showErrors = false}) async {
    if (!isAudioVideoRoom) return;
    if (isLoadingAudioSeats.value) return;
    final apiRoomId = audioRoomApiId;
    if (apiRoomId.isEmpty) {
      audioRoomSeats.assignAll(_buildFallbackAudioSeats());
      return;
    }

    isLoadingAudioSeats.value = true;
    try {
      final response = await _roomRepo.getRoomSeats(
        roomId: apiRoomId,
        isShowLoader: false,
      );
      if (_isApiSuccess(response)) {
        final seats = _parseAudioSeats(response?['data']);
        audioRoomSeats.assignAll(
          seats.isNotEmpty ? seats : _buildFallbackAudioSeats(),
        );
        return;
      }

      if (audioRoomSeats.isEmpty) {
        audioRoomSeats.assignAll(_buildFallbackAudioSeats());
      }
      if (showErrors) {
        _showRoomApiError('Seats', response, 'Unable to fetch room seats.');
      }
    } finally {
      isLoadingAudioSeats.value = false;
    }
  }

  Future<void> loadAudioInviteCandidates({
    String search = '',
    bool showErrors = true,
  }) async {
    final apiRoomId = audioRoomApiId;
    if (apiRoomId.isEmpty) {
      audioInviteCandidates.clear();
      if (showErrors) {
        Get.snackbar(
          'Invite users',
          'Room id is missing, so followers cannot be loaded.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFD32F2F),
          colorText: kColorWhite,
        );
      }
      return;
    }

    isLoadingInviteCandidates.value = true;
    try {
      final response = await _roomRepo.getInviteCandidates(
        roomId: apiRoomId,
        search: search,
        isShowLoader: false,
      );
      if (_isApiSuccess(response)) {
        audioInviteCandidates.assignAll(
          _parseInviteCandidates(response?['data']),
        );
        return;
      }

      audioInviteCandidates.clear();
      if (showErrors) {
        _showRoomApiError(
          'Invite users',
          response,
          'Unable to fetch followers for invite.',
        );
      }
    } finally {
      isLoadingInviteCandidates.value = false;
    }
  }

  Future<void> inviteUserToAudioSeat({
    required int seatNo,
    required AudioRoomInviteCandidate user,
  }) async {
    final apiRoomId = audioRoomApiId;
    if (apiRoomId.isEmpty || user.id.trim().isEmpty) return;

    final response = await _roomRepo.inviteUserToSeat(
      roomId: apiRoomId,
      targetUserId: user.id,
      seatId: seatNo,
      message: '${hostName.value} invited you to join the mic',
      isShowLoader: true,
    );

    if (_isApiSuccess(response)) {
      if (Get.isBottomSheetOpen == true) Get.back();
      Get.snackbar(
        'Invite sent',
        '${user.name} has been invited to seat $seatNo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }

    _showRoomApiError('Invite failed', response, 'Unable to send invite.');
  }

  Future<void> updateAudioSeatMic({
    required AudioRoomSeatModel seat,
    required bool mute,
  }) async {
    await _runSeatAction(
      label: mute ? 'Mute' : 'Unmute',
      action: () => _roomRepo.micAction(
        roomId: audioRoomApiId,
        seatId: seat.seatNo,
        targetUserId: seat.userId,
        action: mute ? 'mute' : 'unmute',
        isShowLoader: true,
      ),
    );
  }

  Future<void> kickAudioRoomUser(AudioRoomSeatModel seat) async {
    await _runSeatAction(
      label: 'Kick off',
      action: () => _roomRepo.kickParticipant(
        roomId: audioRoomApiId,
        targetUserId: seat.userId,
        isShowLoader: true,
      ),
    );
  }

  Future<void> setAudioRoomAdmin({
    required AudioRoomSeatModel seat,
    required bool makeAdmin,
  }) async {
    await _runSeatAction(
      label: makeAdmin ? 'Make admin' : 'Remove admin',
      action: () => _roomRepo.adminAction(
        roomId: audioRoomApiId,
        targetUserId: seat.userId,
        action: makeAdmin ? 'make_admin' : 'remove_admin',
        isShowLoader: true,
      ),
    );
  }

  Future<void> requestAudioSeat() async {
    AudioRoomSeatModel? targetSeat;
    for (final seat in audioRoomSeats) {
      if (!seat.occupied && !seat.isLocked) {
        targetSeat = seat;
        break;
      }
    }
    if (targetSeat == null) {
      Get.snackbar(
        'Request',
        'No open mic seats are available right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }

    final selectedSeat = targetSeat;
    await _runSeatAction(
      label: 'Request',
      action: () => _roomRepo.micAction(
        roomId: audioRoomApiId,
        seatId: selectedSeat.seatNo,
        action: 'request_to_speak',
        isShowLoader: true,
      ),
      successMessage: 'Request sent to the host.',
    );
  }

  Future<void> _runSeatAction({
    required String label,
    required Future<Map<String, dynamic>?> Function() action,
    String? successMessage,
  }) async {
    final response = await action();
    if (_isApiSuccess(response)) {
      if (Get.isBottomSheetOpen == true) Get.back();
      await loadAudioRoomSeats();
      Get.snackbar(
        label,
        successMessage ?? '$label updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }

    _showRoomApiError(label, response, 'Unable to complete this action.');
  }

  List<AudioRoomSeatModel> _parseAudioSeats(dynamic data) {
    final seatConfig = _readSeatConfig(data);
    final rawSeats = data is Map ? data['seats'] : data;
    final parsed = rawSeats is List
        ? rawSeats
              .whereType<Map>()
              .map(
                (raw) =>
                    AudioRoomSeatModel.fromMap(Map<String, dynamic>.from(raw)),
              )
              .where((seat) => seat.seatNo > 0)
              .toList()
        : <AudioRoomSeatModel>[];

    final seatsByNo = <int, AudioRoomSeatModel>{
      for (final seat in parsed) seat.seatNo: seat,
    };
    final maxSeat = seatConfig > 0
        ? seatConfig
        : seatsByNo.keys.fold<int>(
            16,
            (max, value) => value > max ? value : max,
          );

    final seats = <AudioRoomSeatModel>[];
    for (var seatNo = 2; seatNo <= maxSeat; seatNo++) {
      seats.add(seatsByNo[seatNo] ?? AudioRoomSeatModel.empty(seatNo));
    }

    final hostSeat = seatsByNo[1];
    if (hostSeat != null && hostSeat.occupied) {
      if (hostSeat.name.trim().isNotEmpty) hostName.value = hostSeat.name;
      if (hostSeat.avatarUrl?.trim().isNotEmpty == true) {
        hostAvatarUrl.value = hostSeat.avatarUrl;
      }
      if (receiverId.value.trim().isEmpty) receiverId.value = hostSeat.userId;
    }

    return seats;
  }

  int _readSeatConfig(dynamic data) {
    final value = data is Map
        ? data['seatConfig'] ?? data['maxSeats'] ?? data['seat_count']
        : null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
    final roomConfig =
        _roomData['seatConfig'] ?? _roomData['maxSeats'] ?? _roomData['seats'];
    if (roomConfig is int) return roomConfig;
    if (roomConfig is num) return roomConfig.toInt();
    return int.tryParse(roomConfig?.toString() ?? '') ?? 16;
  }

  List<AudioRoomInviteCandidate> _parseInviteCandidates(dynamic data) {
    final users = data is Map ? data['users'] ?? data['data'] : data;
    if (users is! List) return const [];
    return users
        .whereType<Map>()
        .map(
          (raw) =>
              AudioRoomInviteCandidate.fromMap(Map<String, dynamic>.from(raw)),
        )
        .where((user) => user.id.trim().isNotEmpty && !user.isInRoom)
        .toList();
  }

  List<AudioRoomSeatModel> _buildFallbackAudioSeats() {
    final maxSeats = _readSeatConfig(_roomData);
    final seats = <AudioRoomSeatModel>[];
    var seatNo = 2;

    for (final viewer in liveViewers) {
      if (seatNo > maxSeats) break;
      if (viewer['isHost'] == true) continue;
      seats.add(
        AudioRoomSeatModel(
          seatNo: seatNo,
          userId:
              viewer['targetId']?.toString() ?? viewer['id']?.toString() ?? '',
          name: viewer['name']?.toString() ?? 'Member',
          avatarUrl: viewer['avatarUrl']?.toString(),
          diamonds: 0,
        ),
      );
      seatNo++;
    }

    while (seatNo <= maxSeats) {
      seats.add(AudioRoomSeatModel.empty(seatNo));
      seatNo++;
    }
    return seats;
  }

  bool _isApiSuccess(Map<String, dynamic>? response) {
    return response?['statusCode'] == 1 || response?['success'] == true;
  }

  void _showRoomApiError(
    String title,
    Map<String, dynamic>? response,
    String fallback,
  ) {
    Get.snackbar(
      title,
      response?['message']?.toString() ?? fallback,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFD32F2F),
      colorText: kColorWhite,
    );
  }

  Future<void> toggleFollowHost() async {
    if (isHost.value) return;
    final targetId = receiverId.value.trim();
    if (targetId.isEmpty) {
      Get.snackbar(
        'Follow',
        'Host profile is not available for this room.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }

    final action = isFollowingHost.value ? 'unfollow' : 'follow';
    final response = await _authRepo.followUnfollow(
      targetId: targetId,
      action: action,
      isShowLoader: true,
    );

    if (response != null && response['statusCode'] == 1) {
      final data = response['data'];
      final following = data is Map
          ? data['isFollowing'] == true
          : action == 'follow';
      isFollowingHost.value = following;
      Get.snackbar(
        following ? 'Following' : 'Unfollowed',
        following
            ? 'You are now following ${hostName.value}.'
            : 'You unfollowed ${hostName.value}.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: kColorWhite,
      );
      return;
    }

    Get.snackbar(
      'Follow',
      response?['message']?.toString() ?? 'Unable to update follow status.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: kColorWhite,
    );
  }

  Future<void> shareRoom() async {
    final shareId = audioRoomApiId.isNotEmpty ? audioRoomApiId : 'room';
    var roomUrl = 'https://qobo.live/room/$shareId';
    final response = await _roomRepo.getShareLink(
      roomId: shareId,
      isShowLoader: false,
    );
    if (_isApiSuccess(response)) {
      final data = response?['data'];
      if (data is Map) {
        final backendLink =
            data['link']?.toString() ??
            data['url']?.toString() ??
            data['shareUrl']?.toString();
        if (backendLink != null && backendLink.trim().isNotEmpty) {
          roomUrl = backendLink.trim();
        }
      }
    }

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E2D),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SemiBoldText(
                text: 'Share Room Link',
                fontSize: 16,
                color: kColorWhite,
              ),
            ),
            Spacing.v20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _shareOption(Icons.copy_rounded, 'Copy Link', Colors.blue, () {
                  Clipboard.setData(ClipboardData(text: roomUrl));
                  Get.back();
                  Get.snackbar(
                    'Link Copied!',
                    'Room URL copied to clipboard: $roomUrl',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: Colors.green,
                    colorText: kColorWhite,
                  );
                }),
                _shareOption(
                  Icons.wechat_rounded,
                  'WhatsApp',
                  Colors.green,
                  () {
                    Get.back();
                    Get.snackbar(
                      'Shared',
                      'Room shared successfully to WhatsApp!',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                _shareOption(
                  Icons.facebook_rounded,
                  'Facebook',
                  Colors.indigo,
                  () {
                    Get.back();
                    Get.snackbar(
                      'Shared',
                      'Room shared successfully to Facebook!',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
                _shareOption(
                  Icons.message_rounded,
                  'Messages',
                  Colors.orange,
                  () {
                    Get.back();
                    Get.snackbar(
                      'Shared',
                      'Room shared successfully via SMS!',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Widget _shareOption(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          Spacing.v6,
          AppText(text: label, fontSize: 10, color: kColorWhite),
        ],
      ),
    );
  }

  void toggleMic() {
    try {
      final mic =
          ZegoUIKitPrebuiltLiveStreamingController().audioVideo.microphone;
      mic.switchState();
      isMicMuted.value = !mic.localState;
    } catch (_) {
      isMicMuted.value = !isMicMuted.value;
    }
  }

  void toggleCamera() {
    if (!isVideoRoom) return;
    try {
      final camera =
          ZegoUIKitPrebuiltLiveStreamingController().audioVideo.camera;
      camera.switchState();
      isCameraOff.value = !camera.localState;
    } catch (_) {
      isCameraOff.value = !isCameraOff.value;
    }
  }

  void leaveRoom() {
    if (isHost.value) {
      if (_isAudioVideoRoomPayload()) {
        confirmEndRoom();
      } else {
        confirmEndLiveStream();
      }
      return;
    }
    _stopSeatRefreshPolling();
    unawaited(_reportAudioVideoRoomExit());
    Get.back();
  }

  void confirmEndRoom() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1D102F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const SemiBoldText(
          text: 'End audio room?',
          fontSize: TextStyles.k18FontSize,
          color: kColorWhite,
        ),
        content: AppText(
          text:
              'This will end the room for everyone and close the live session.',
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite.withValues(alpha: 0.72),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: AppText(
              text: 'Cancel',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.72),
            ),
          ),
          TextButton(
            onPressed: endRoomForEveryone,
            child: const SemiBoldText(
              text: 'End Room',
              fontSize: TextStyles.k12FontSize,
              color: Color(0xFFFF5A7A),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  void confirmEndLiveStream() {
    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1D102F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const SemiBoldText(
          text: 'End live stream?',
          fontSize: TextStyles.k18FontSize,
          color: kColorWhite,
        ),
        content: AppText(
          text:
              'This will end your live stream for all viewers and close the session.',
          fontSize: TextStyles.k12FontSize,
          color: kColorWhite.withValues(alpha: 0.72),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: AppText(
              text: 'Cancel',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.72),
            ),
          ),
          TextButton(
            onPressed: endLiveStreamForEveryone,
            child: const SemiBoldText(
              text: 'End Live',
              fontSize: TextStyles.k12FontSize,
              color: Color(0xFFFF5A7A),
            ),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }

  Future<void> endLiveStreamForEveryone() async {
    if (_exitReported) return;
    final liveStreamingId = liveStreamingApiId;
    Map<String, dynamic>? response;

    // Live streaming and audio/video rooms use different backend resources.
    // Keep this path isolated so closing a Go Live stream never calls room APIs.
    if (liveStreamingId.isNotEmpty) {
      try {
        response = await _roomRepo.endLiveStreaming(
          liveStreamingId: liveStreamingId,
          isShowLoader: true,
        );
      } catch (_) {
        response = null;
      }
    }

    final apiConfirmed = liveStreamingId.isNotEmpty && _isApiSuccess(response);
    await _closeLiveStreamLocally();

    if (apiConfirmed) return;

    final fallback = liveStreamingId.isEmpty
        ? 'Live stream id was missing, but the stream was closed on this device.'
        : 'Backend could not confirm the end request, but the stream was closed on this device.';
    Get.snackbar(
      'Live stream closed',
      response?['message']?.toString() ?? fallback,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: kColorWhite,
    );
  }

  Future<void> _closeLiveStreamLocally() async {
    _exitReported = true;
    _stopSeatRefreshPolling();
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    if (Get.isBottomSheetOpen == true) {
      Get.back();
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final poppedLiveRoute = _popLiveBroadcastRoute();
    if (!poppedLiveRoute) {
      Get.offAllNamed(Routes.BOTTOM_NAV);
    }
  }

  bool _popLiveBroadcastRoute() {
    final navigator = Get.key.currentState;
    if (navigator == null) return false;

    if (Get.currentRoute == Routes.LIVE_BROADCAST) {
      if (!navigator.canPop()) return false;
      navigator.pop();
      return true;
    }

    var removedLiveBroadcast = false;
    if (navigator.canPop()) {
      navigator.popUntil((route) {
        if (route.settings.name == Routes.LIVE_BROADCAST) {
          removedLiveBroadcast = true;
          return false;
        }
        return removedLiveBroadcast || route.isFirst;
      });
    }

    // If GetX/Zego placed the page on an unnamed route, still leave the
    // current live screen after the backend confirms the stream has ended.
    if (!removedLiveBroadcast && navigator.canPop()) {
      navigator.pop();
      return true;
    }

    return removedLiveBroadcast;
  }

  Future<void> endRoomForEveryone() async {
    if (_exitReported) return;
    final backendRoomId = audioRoomApiId;
    if (backendRoomId.isEmpty) {
      Get.back();
      Get.snackbar(
        'End room',
        'Room id is missing, so this room cannot be ended.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: kColorWhite,
      );
      return;
    }

    final response = await _roomRepo.endRoom(
      roomId: backendRoomId,
      isShowLoader: true,
    );

    if (_isApiSuccess(response)) {
      _hostEndConfirmed = true;
      _exitReported = true;
      _stopSeatRefreshPolling();
      if (Get.isDialogOpen == true) Get.back();
      Get.back();
      return;
    }

    if (Get.isDialogOpen == true) Get.back();
    _showRoomApiError('End room', response, 'Unable to end this room.');
  }

  /// Ends a host room only after Zego's hang-up confirmation was accepted.
  ///
  /// This deliberately does not navigate; returning `true` lets the prebuilt
  /// call widget perform its normal, single route exit.
  Future<bool> endRoomAfterConfirmedHangUp() async {
    if (!isHost.value || !_isAudioVideoRoomPayload()) return true;
    if (_exitReported) return true;

    final backendRoomId = audioRoomApiId;
    if (backendRoomId.isEmpty) {
      Get.snackbar(
        'End room',
        'Room id is missing, so this room cannot be ended.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: kColorWhite,
      );
      return false;
    }

    final response = await _roomRepo.endRoom(
      roomId: backendRoomId,
      isShowLoader: true,
    );
    if (!_isApiSuccess(response)) {
      _showRoomApiError('End room', response, 'Unable to end this room.');
      return false;
    }

    _exitReported = true;
    _hostEndConfirmed = true;
    _stopSeatRefreshPolling();
    return true;
  }

  void reportRoomExit() {
    // Host room termination must only happen through an explicit confirmed
    // action, never from Zego lifecycle/rebuild callbacks.
    if (isHost.value) return;
    unawaited(_reportAudioVideoRoomExit());
  }

  String get liveStreamingApiId {
    return (_extractStreamingId(_roomData) ?? roomId.value).trim();
  }

  Future<void> _reportAudioVideoRoomExit() async {
    if (isHost.value || _exitReported || !_isAudioVideoRoomPayload()) return;
    _exitReported = true;
    _stopSeatRefreshPolling();
    final backendRoomId = _extractBackendRoomId(_roomData);
    if (backendRoomId == null || backendRoomId.trim().isEmpty) return;

    await _roomRepo.leaveRoom(roomId: backendRoomId, isShowLoader: false);
  }

  bool _isAudioVideoRoomPayload() {
    final type = readRoomField(_roomData, ['type', 'roomType'])?.toLowerCase();
    return type == 'audio' ||
        type == 'video' ||
        _roomData.containsKey('room_id') ||
        _roomData.containsKey('roomId');
  }

  @override
  void onClose() {
    _stopSeatRefreshPolling();
    _messageSub?.cancel();
    _userSub?.cancel();
    if (_viewerCountListener != null) {
      try {
        ZegoUIKitPrebuiltLiveStreamingController().user.countNotifier
            .removeListener(_viewerCountListener!);
      } catch (_) {}
    }
    chatTextController.dispose();
    super.onClose();
  }
}
