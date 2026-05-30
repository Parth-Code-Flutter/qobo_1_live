import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';

class LiveBroadcastController extends GetxController {
  final isHost = false.obs;
  final roomType = 'VIDEO'.obs;
  final roomId = 'test_room'.obs;

  final chatMessages = <Map<String, dynamic>>[].obs;
  final chatTextController = TextEditingController();

  final isMicMuted = false.obs;
  final isCameraOff = false.obs;

  final coinsBalance = 1200.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args.containsKey('isHost')) isHost.value = args['isHost'];
      if (args.containsKey('roomType')) roomType.value = args['roomType'];
      if (args.containsKey('roomData') && args['roomData'] != null) {
        final roomData = args['roomData'];
        roomId.value = (roomData['room_id'] ?? roomData['id'] ?? 'test_room')
            .toString();
      }
    }
    chatMessages.clear();
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

  void sendGift(Map<String, String> gift) {
    final int price = int.tryParse(gift['price'] ?? '0') ?? 0;
    if (coinsBalance.value >= price) {
      coinsBalance.value -= price;

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
        'Insufficient Coins',
        'You need ${price - coinsBalance.value} more coins to send this gift.',
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
    isMicMuted.value = !isMicMuted.value;
  }

  void toggleCamera() {
    isCameraOff.value = !isCameraOff.value;
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
