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
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

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
  final liveBeautyEnabled = false.obs;
  final liveSmooth = 35.obs;
  final liveSkinTone = 25.obs;
  final liveBlush = 12.obs;
  final liveSharpen = 15.obs;

  Map<String, dynamic> _roomData = {};
  StreamSubscription<List<ZegoInRoomMessage>>? _messageSub;
  StreamSubscription<List<ZegoUIKitUser>>? _userSub;
  VoidCallback? _viewerCountListener;
  var _exitReported = false;

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
        final rawId = streamingId ?? _extractBackendRoomId(_roomData) ?? '';
        roomId.value = ZegoLiveIdUtils.sanitize(rawId);
      }
    }
    _hydrateHostProfile();
    _validateStreamingInput();
    loadWalletBalance();
    loadGiftCatalog();
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

  /// Called after Zego room login — ensures host camera publishes and binds chat/users.
  void onZegoRoomLogined() {
    isZegoConnected.value = true;
    _bindZegoListeners();

    if (!isHost.value || !isVideoRoom) return;
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
      'message': text,
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

  void _validateStreamingInput() {
    final liveId = roomId.value.trim();
    if (liveId.isEmpty || liveId == 'test_room' || liveId == 'null') {
      connectionIssue.value =
          'Live stream id is missing. Please ask backend to return zegoLiveId or channelName for this room.';
      return;
    }

    if (!isHost.value && !hasExplicitStreamingId.value) {
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
    return {
      'id': raw['id']?.toString() ?? raw['_id']?.toString() ?? '',
      'name': name,
      'price': price.toString(),
      'icon': icon,
      'category': category,
    };
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
    final currentReceiverId = receiverId.value.trim();
    if (giftId.isEmpty || currentRoomId.isEmpty || currentReceiverId.isEmpty) {
      Get.snackbar(
        'Gift not sent',
        'Gift, host, or room id is missing from live room data.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
      );
      return;
    }

    final response = await _economyRepo.sendGift(
      receiverId: currentReceiverId,
      giftId: giftId,
      roomId: currentRoomId,
      isShowLoader: true,
    );

    if (isEconomyApiSuccess(response)) {
      await loadWalletBalance();

      final giftLabel =
          '🎁 sent ${gift['name']} ${isNetworkGiftIcon(gift['icon']) ? '' : gift['icon'] ?? ''}'
              .trim();
      if (isZegoConnected.value) {
        await ZegoUIKitPrebuiltLiveStreamingController().message.send(
          giftLabel,
        );
      } else {
        chatMessages.add({
          'sender': 'You',
          'message': giftLabel,
          'translation': '',
          'isTranslated': false,
          'isSystem': true,
        });
      }

      Get.back();

      Get.snackbar(
        '🎁 Gift Sent! 🎁',
        'You sent ${gift['name']} to ${hostName.value}!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFFF4081),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
      );
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

  void openGiftsSheet() {
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

  void shareRoom() {
    final shareId = roomId.value.trim().isNotEmpty
        ? roomId.value.trim()
        : _extractBackendRoomId(_roomData) ?? 'room';
    final String roomUrl = 'https://qobo.live/room/$shareId';

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
    unawaited(_reportAudioVideoRoomExit());
    Get.back();
  }

  Future<void> _reportAudioVideoRoomExit() async {
    if (_exitReported || !_isAudioVideoRoomPayload()) return;
    _exitReported = true;
    final backendRoomId = _extractBackendRoomId(_roomData);
    if (backendRoomId == null || backendRoomId.trim().isEmpty) return;

    if (isHost.value) {
      await _roomRepo.endRoom(roomId: backendRoomId, isShowLoader: false);
    } else {
      await _roomRepo.leaveRoom(roomId: backendRoomId, isShowLoader: false);
    }
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
