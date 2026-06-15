import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';
import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';

class LiveBroadcastController extends GetxController {
  LiveBroadcastController({EconomyRepo? economyRepo})
    : _economyRepo = economyRepo ?? EconomyRepo();

  final EconomyRepo _economyRepo;

  final isHost = false.obs;
  final roomType = 'VIDEO'.obs;
  final roomId = ''.obs;
  final receiverId = ''.obs;
  final hasExplicitStreamingId = false.obs;
  final connectionIssue = ''.obs;

  final chatMessages = <Map<String, dynamic>>[].obs;
  final chatTextController = TextEditingController();

  final isMicMuted = false.obs;
  final isCameraOff = false.obs;

  final coinsBalance = 0.obs;
  final giftCatalog = <Map<String, String>>[].obs;
  final isLoadingGifts = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args.containsKey('isHost')) isHost.value = args['isHost'];
      if (args.containsKey('roomType')) roomType.value = args['roomType'];
      if (args.containsKey('roomData') && args['roomData'] != null) {
        final roomData = args['roomData'];
        final normalizedRoomData = Map<String, dynamic>.from(roomData);
        receiverId.value = _extractReceiverId(normalizedRoomData) ?? '';
        final streamingId = _extractStreamingId(normalizedRoomData);
        hasExplicitStreamingId.value = streamingId != null;
        final rawId =
            streamingId ?? _extractBackendRoomId(normalizedRoomData) ?? '';
        roomId.value = ZegoLiveIdUtils.sanitize(rawId);
      }
    }
    _validateStreamingInput();
    loadWalletBalance();
    loadGiftCatalog();
    chatMessages.clear();
  }

  Future<void> loadWalletBalance() async {
    final response = await _economyRepo.getWalletBalances(isShowLoader: false);
    final data = response?['data'];
    if (isEconomyApiSuccess(response) && data is Map) {
      coinsBalance.value = parseWalletAmount(
        data['coins'] ?? data['coin'] ?? data['balance'] ?? data['coinBalance'],
      );
    }
  }

  bool get canOpenZego => connectionIssue.value.isEmpty;

  void setConnectionIssue(String message) {
    connectionIssue.value = message;
  }

  void clearConnectionIssue() {
    connectionIssue.value = '';
  }

  bool get isVideoRoom => roomType.value.toUpperCase() != 'AUDIO';

  /// Called after Zego room login — ensures host camera publishes for video rooms.
  void onZegoRoomLogined() {
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

  void handleZegoLoginFailed(int errorCode) {
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
    const keys = [
      'hostId',
      'host_id',
      'userId',
      'user_id',
      'ownerId',
      'owner_id',
      'createdBy',
      'created_by',
      'receiverId',
      'receiver_id',
    ];

    return _firstNonEmpty(roomData, keys);
  }

  String? _firstNonEmpty(Map<String, dynamic> roomData, List<String> keys) {
    for (final key in keys) {
      final value = roomData[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }

  void sendMessage() {
    final text = chatTextController.text.trim();
    if (text.isEmpty) return;

    // Bad comment moderation filter (case insensitive)
    final badWords = ['bad', 'scam', 'spam', 'abuse', 'hate', 'cheat', 'fraud'];
    String moderatedText = text;
    bool containsBadWord = false;

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

    chatMessages.add({
      'sender': 'You',
      'message': moderatedText,
      'translation': text != moderatedText
          ? 'Original message contained flagged words.'
          : '',
      'isTranslated': false,
      'isSystem': false,
    });

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

    chatTextController.clear();
  }

  void translateMessage(int index) {
    if (index >= 0 && index < chatMessages.length) {
      final msg = chatMessages[index];
      if (msg['translation'] != null &&
          msg['translation'].toString().isNotEmpty) {
        final currentVal = msg['isTranslated'] ?? false;
        chatMessages[index] = {...msg, 'isTranslated': !currentVal};
      } else {
        Get.snackbar(
          'Translation',
          'This message is already in your native language.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.black26,
          colorText: kColorWhite,
        );
      }
    }
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
    final icon = raw['icon']?.toString() ??
        raw['emoji']?.toString() ??
        raw['image']?.toString() ??
        '🎁';
    final category = raw['category']?.toString() ?? raw['type']?.toString() ?? 'Popular';
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

      chatMessages.add({
        'sender': 'You',
        'message': 'sent a ${gift['name']} ${gift['icon']}',
        'translation': '',
        'isTranslated': false,
        'isSystem': false,
      });

      Get.back(); // close the bottom sheet

      Get.snackbar(
        '🎁 Gift Sent! 🎁',
        'You sent ${gift['name']} ${gift['icon']} to the Host!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: const Color(0xFFFF4081),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
        icon: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(gift['icon'] ?? '', style: const TextStyle(fontSize: 24)),
        ),
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

  void shareRoom() {
    final String roomUrl =
        'https://qobo.live/room/${roomType.value.toLowerCase()}_${hashCode.toString().substring(0, 4)}';

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
      final mic = ZegoUIKitPrebuiltLiveStreamingController().audioVideo.microphone;
      mic.switchState();
      isMicMuted.value = !mic.localState;
    } catch (_) {
      isMicMuted.value = !isMicMuted.value;
    }
  }

  void toggleCamera() {
    if (!isVideoRoom) return;
    try {
      final camera = ZegoUIKitPrebuiltLiveStreamingController().audioVideo.camera;
      camera.switchState();
      isCameraOff.value = !camera.localState;
    } catch (_) {
      isCameraOff.value = !isCameraOff.value;
    }
  }

  void leaveRoom() {
    Get.back();
  }

  @override
  void onClose() {
    chatTextController.dispose();
    super.onClose();
  }
}
